// ignore: file_names
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:ap_dongle_comm/utils/enums/connectivity.dart';
import 'package:ap_dongle_comm/utils/helper/foreground_servie_helper.dart';
import 'package:get/get.dart';
import 'package:convert/convert.dart';
import 'i_comm_controller.dart';

class CommController extends GetxController implements ICommController {
  var connectivityRx = Connectivity.none.obs;
  @override
  Connectivity get connectivity => connectivityRx.value;

  late DongleComm? dongleComm;
  var isConnected = false.obs;

  Socket? _socket;
  StreamSubscription? _socketSub;

  final StreamController<Uint8List> _responseStream =
      StreamController.broadcast();
  final StreamController<bool> _connectionStream = StreamController.broadcast();

  Stream<Uint8List> get responses => _responseStream.stream;
  Stream<bool> get connectionUpdates => _connectionStream.stream;

  // ---------------- CONNECT ----------------

  Future<void> connectWifi({required String host, required int port}) async {
    try {
      print("🌐 [connectWifi] Connecting to $host:$port...");
      await disconnect();

      _socket = await Socket.connect(host, port);

      try {
        _socket!.setOption(SocketOption.tcpNoDelay, true);
      } catch (e) {
        print('⚠️ Could not set TCP_NODELAY: $e');
      }

      print('✅ SOCKET CONNECTED $host:$port');

      isConnected.value = true;
      connectivityRx.value = Connectivity.wiFi;
      _connectionStream.add(true);

      try {
        startForegroundService();
      } catch (_) {}

      _socketSub = _socket!.listen(
        (data) => _handleData(data),
        onError: (e) {
          print('❌ Socket error: $e');
          _handleDisconnect();
        },
        onDone: () {
          print('⚠️ Socket closed by dongle');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      print('🚀 WiFi Ready');
    } on SocketException catch (e) {
      print('🔥 SocketException: $e');
      _handleDisconnect();
      rethrow;
    } catch (e) {
      print('🔥 Connection Error: $e');
      _handleDisconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      print("🔌 Starting full disconnect...");

      await _socketSub?.cancel();
      _socketSub = null;

      await _socket?.close();
      _socket = null;

      isConnected.value = false;
      connectivityRx.value = Connectivity.none;
      _connectionStream.add(false);
      await stopForegroundService();
      print("✅ Full disconnect completed");
    } catch (e) {
      print("🔥 Disconnect error: $e");
    }
  }

  void _handleDisconnect() {
    print("⚠️ Handling unexpected disconnect...");
    disconnect();
  }

  String formatHex(Uint8List bytes) => bytesToHex(bytes);

  Uint8List hexToBytes(String hexStr) {
    hexStr = hexStr.replaceAll(' ', '');
    return Uint8List.fromList(hex.decode(hexStr));
  }

  String bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  // ---------------- SEND / RECEIVE ----------------

  Future<Uint8List?> sendCommand(Uint8List finalPacket) async {
    if (connectivityRx.value != Connectivity.wiFi || _socket == null) {
      return null;
    }

    try {
      print("[SENDING HEX] ${bytesToHex(finalPacket)}");

      _buffer.clear();
      _socket!.add(finalPacket);
      await _socket!.flush();

      print("📥 Waiting for WiFi response...");
      return await _readDirect();
    } catch (e) {
      print("[EXCEPTION in sendCommand] $e");
      return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
    }
  }

  Future<Uint8List?> readData() async {
    print("------Read Again Data------");
    try {
      final result = await _readDirect();
      print("------END Read Again Data------");
      return result;
    } catch (e) {
      print("Error during ReadData: $e");
      return null;
    }
  }

  Future<void> clearBuffer() async {
    if (_buffer.isEmpty) return;
    print(
      "🧹 [clearBuffer] Discarding ${_buffer.length} bytes: "
      "${bytesToHex(Uint8List.fromList(_buffer))}",
    );
    _buffer.clear();
  }

  // ---------------- FRAMING ----------------

  final _buffer = <int>[];
  Completer<void>? _dataCompleter;

  void _handleData(Uint8List data) {
    if (data.isEmpty) return;
    _buffer.addAll(data);
    if (isConnected.value) {
      _responseStream.add(data);
    }
    if (_dataCompleter != null && !_dataCompleter!.isCompleted) {
      _dataCompleter!.complete();
    }
  }

  Future<Uint8List> _readExactBytes(int length, {int timeoutSec = 5}) async {
    final stopwatch = Stopwatch()..start();

    while (_buffer.length < length) {
      _dataCompleter = Completer<void>();
      await _dataCompleter!.future.timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => null,
      );

      if (_buffer.length < length && stopwatch.elapsed.inSeconds > timeoutSec) {
        _buffer.clear();
        return Uint8List(0);
      }
    }

    final result = Uint8List.fromList(_buffer.sublist(0, length));
    _buffer.removeRange(0, length);
    return result;
  }

  Future<Uint8List?> _readDirect() async {
    while (true) {
      final header = await _readExactBytes(2);
      if (header.isEmpty) {
        print('⏰ _readDirect: timeout waiting for header');
        return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
      }

      final msgLen = ((header[0] & 0x0F) << 8) + header[1];

      final body = await _readExactBytes(msgLen + 3);
      if (body.isEmpty) {
        print('⏰ _readDirect: timeout waiting for body');
        return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
      }

      final builder = BytesBuilder();
      builder.add(header);
      builder.add(body);
      final result = builder.toBytes();

      print('✅ _readDirect: ${bytesToHex(result)}');

      // NRC 0x78 (ECU busy) — read the next frame instead of returning.
      if (result.length >= 6 && result[3] == 0x7F && result[5] == 0x78) {
        print("⚠️ NRC 0x78 Detected: ECU Busy. Reading again...");
        continue;
      }

      return result;
    }
  }
}
