// wifi_comm_isolate.dart
//
// Moves the WiFi socket connect/read/write/framing loop into a dedicated
// Isolate so the main (UI) isolate never does CRC/hex-format/BytesBuilder
// work during a flash burst. Only fully-framed responses and lightweight
// progress pings cross the isolate boundary.
//
// SAFE for the WiFi path (dart:io Socket has no platform-channel dependency).
// Do NOT reuse this pattern for usb_serial (mobile USB) without first
// confirming it supports BackgroundIsolateBinaryMessenger — most
// community serial plugins don't, and it'll silently break USB.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Toggle verbose logging. Keep false during real flash runs —
/// hex-formatting every packet is pure CPU tax.
const bool kVerboseLog = false;

void _log(String Function() msg) {
  if (kVerboseLog) print(msg());
}

// ── Message types crossing the isolate boundary ────────────────────────

class _ConnectMsg {
  final String host;
  final int port;
  _ConnectMsg(this.host, this.port);
}

class _WriteMsg {
  final Uint8List bytes;
  _WriteMsg(this.bytes);
}

class _DisconnectMsg {}

/// Reads the next framed response WITHOUT writing anything first.
/// Mirrors the app's existing "read again" flow (getWifiResponse /
/// readData) for cases where the caller detected NRC 0x78 itself and
/// wants another read on the same open connection.
class _ReadAgainMsg {}

class WorkerConnected {
  final SendPort workerSendPort;
  WorkerConnected(this.workerSendPort);
}

class SocketConnected {}

class SocketError {
  final String message;
  SocketError(this.message);
}

class SocketDisconnected {}

/// A fully-framed response ready to hand back to the app layer.
class FramedResponse {
  final Uint8List bytes;
  FramedResponse(this.bytes);
}

/// Lightweight progress ping — raw byte count seen so far for THIS
/// in-flight response, so the UI can update a percentage bar smoothly
/// during erase/verify without waiting for the full frame to complete.
class ByteProgress {
  final int bytesSoFar;
  ByteProgress(this.bytesSoFar);
}

// ── Isolate entry point ─────────────────────────────────────────────────

void _wifiIsolateEntry(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(WorkerConnected(workerReceivePort.sendPort));

  Socket? socket;
  StreamSubscription? socketSub;
  final List<int> buffer = [];
  Completer<void>? dataCompleter;
  int _progressBaseline = 0; // buffer length when current read started

  void handleIncoming(Uint8List data) {
    buffer.addAll(data);
    if (dataCompleter != null && !dataCompleter!.isCompleted) {
      dataCompleter!.complete();
    }
    // Report progress relative to the current pending read so the UI
    // can move the percentage bar even mid-frame.
    final soFar = buffer.length - _progressBaseline;
    if (soFar > 0) {
      mainSendPort.send(ByteProgress(soFar));
    }
  }

  Future<Uint8List> readExactBytes(int length, {int timeoutSec = 5}) async {
    final stopwatch = Stopwatch()..start();
    while (buffer.length < length) {
      dataCompleter = Completer<void>();
      await dataCompleter!.future.timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => null,
      );
      if (buffer.length < length && stopwatch.elapsed.inSeconds > timeoutSec) {
        buffer.clear();
        return Uint8List(0);
      }
    }
    final result = Uint8List.fromList(buffer.sublist(0, length));
    buffer.removeRange(0, length);
    return result;
  }

  Future<Uint8List> readFramedResponse() async {
    while (true) {
      _progressBaseline = buffer.length;

      final header = await readExactBytes(2, timeoutSec: 5);
      if (header.isEmpty) {
        return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
      }

      final msglen = ((header[0] & 0x0F) << 8) + header[1];
      final remData = await readExactBytes(msglen + 3, timeoutSec: 5);
      if (remData.isEmpty) {
        return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
      }

      final builder = BytesBuilder();
      builder.add(header);
      builder.add(remData);
      final retArray = builder.toBytes();

      _log(() => 'Worker frame: ${retArray.length} bytes');

      // NRC 0x78 (ECU busy) — read again, matches existing app logic.
      if (retArray.length >= 6 &&
          retArray[3] == 0x7F &&
          retArray[5] == 0x78) {
        _log(() => 'NRC 0x78 — retrying read');
        continue;
      }

      return retArray;
    }
  }

  workerReceivePort.listen((message) async {
    if (message is _ConnectMsg) {
      try {
        await socketSub?.cancel();
        await socket?.close();
        buffer.clear();

        socket = await Socket.connect(
          message.host,
          message.port,
          timeout: const Duration(minutes: 1),
        );
        try {
          socket!.setOption(SocketOption.tcpNoDelay, true);
        } catch (_) {}

        socketSub = socket!.listen(
          handleIncoming,
          onError: (e) {
            mainSendPort.send(SocketError('$e'));
          },
          onDone: () {
            mainSendPort.send(SocketDisconnected());
          },
          cancelOnError: false,
        );

        mainSendPort.send(SocketConnected());
      } catch (e) {
        mainSendPort.send(SocketError('$e'));
      }
    } else if (message is _WriteMsg) {
      if (socket == null) {
        mainSendPort.send(SocketError('Write attempted with no socket'));
        return;
      }
      buffer.clear();
      socket!.add(message.bytes);
      await socket!.flush();
      final response = await readFramedResponse();
      mainSendPort.send(FramedResponse(response));
    } else if (message is _ReadAgainMsg) {
      if (socket == null) {
        mainSendPort.send(SocketError('Read attempted with no socket'));
        return;
      }
      final response = await readFramedResponse();
      mainSendPort.send(FramedResponse(response));
    } else if (message is _DisconnectMsg) {
      await socketSub?.cancel();
      socketSub = null;
      await socket?.close();
      socket = null;
      buffer.clear();
      mainSendPort.send(SocketDisconnected());
    }
  });
}

// ── Main-isolate-side client ─────────────────────────────────────────────

/// Drop-in replacement for the WiFi half of CommController's socket logic.
/// Keeps the same request/response shape (`write` -> awaited `Uint8List`)
/// so callers barely need to change.
class IsolateWifiComm {
  Isolate? _isolate;
  SendPort? _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();

  final _connectCompleter = <Completer<void>>[];
  Completer<void>? _pendingConnect;
  Completer<Uint8List>? _pendingWrite;

  final _progressController = StreamController<int>.broadcast();
  Stream<int> get byteProgress => _progressController.stream;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionUpdates => _connectionController.stream;

  bool _ready = false;

  Future<void> _ensureSpawned() async {
    if (_isolate != null) return;
    _isolate = await Isolate.spawn(_wifiIsolateEntry, _mainReceivePort.sendPort);
    _mainReceivePort.listen(_handleMessage);
  }

  void _handleMessage(dynamic message) {
    if (message is WorkerConnected) {
      _workerSendPort = message.workerSendPort;
      _ready = true;
      for (final c in _connectCompleter) {
        if (!c.isCompleted) c.complete();
      }
      _connectCompleter.clear();
    } else if (message is SocketConnected) {
      _connectionController.add(true);
      if (_pendingConnect != null && !_pendingConnect!.isCompleted) {
        _pendingConnect!.complete();
        _pendingConnect = null;
      }
    } else if (message is SocketDisconnected) {
      _connectionController.add(false);
    } else if (message is SocketError) {
      _log(() => 'Isolate socket error: ${message.message}');
      _connectionController.add(false);
      if (_pendingConnect != null && !_pendingConnect!.isCompleted) {
        _pendingConnect!.completeError(SocketException(message.message));
        _pendingConnect = null;
      }
      if (_pendingWrite != null && !_pendingWrite!.isCompleted) {
        _pendingWrite!.complete(
          Uint8List.fromList(utf8.encode('No Resp From Dongle')),
        );
        _pendingWrite = null;
      }
    } else if (message is ByteProgress) {
      _progressController.add(message.bytesSoFar);
    } else if (message is FramedResponse) {
      if (_pendingWrite != null && !_pendingWrite!.isCompleted) {
        _pendingWrite!.complete(message.bytes);
        _pendingWrite = null;
      }
    }
  }

  Future<void> connect(String host, int port) async {
    await _ensureSpawned();
    if (!_ready) {
      final c = Completer<void>();
      _connectCompleter.add(c);
      await c.future;
    }
    final connectCompleter = Completer<void>();
    _pendingConnect = connectCompleter;
    _workerSendPort!.send(_ConnectMsg(host, port));
    return connectCompleter.future.timeout(
      const Duration(minutes: 1),
      onTimeout: () {
        _pendingConnect = null;
        throw SocketException('Connect timed out: $host:$port');
      },
    );
  }

  Future<Uint8List> write(Uint8List packet, {Duration timeout = const Duration(seconds: 1)}) async {
    if (_workerSendPort == null) {
      return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
    }
    _pendingWrite = Completer<Uint8List>();
    _workerSendPort!.send(_WriteMsg(packet));
    return _pendingWrite!.future.timeout(
      timeout,
      onTimeout: () => Uint8List.fromList(utf8.encode('No Resp From Dongle')),
    );
  }

  /// Reads the next framed response without writing first — for the
  /// same "read again after NRC 0x78" flow the original getWifiResponse/
  /// readData path supported.
  Future<Uint8List> readAgain({Duration timeout = const Duration(seconds: 1)}) async {
    if (_workerSendPort == null) {
      return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
    }
    _pendingWrite = Completer<Uint8List>();
    _workerSendPort!.send(_ReadAgainMsg());
    return _pendingWrite!.future.timeout(
      timeout,
      onTimeout: () => Uint8List.fromList(utf8.encode('No Resp From Dongle')),
    );
  }

  Future<void> disconnect() async {
    _workerSendPort?.send(_DisconnectMsg());
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _mainReceivePort.close();
    _progressController.close();
    _connectionController.close();
  }
}