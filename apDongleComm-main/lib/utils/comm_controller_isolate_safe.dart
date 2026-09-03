// ════════════════════════════════════════════════════════════
// ISOLATE-SAFE WiFi-only CommController
//
// This is a deliberately minimal twin of CommController, containing
// ONLY the WiFi code paths actually used by ParallelFlash (this app
// never uses USB/serial/RP1210 — those branches in the original file
// are dead code for our purposes). GetX/.obs reactive fields are
// replaced with plain fields because Dart Isolates have no Flutter
// engine binding and cannot use GetX.
//
// An instance of this class is created FRESH inside each ECU's
// dedicated Isolate (via Isolate.run / Isolate.spawn) — giving each
// ECU's flash session a completely independent OS-level execution
// context, matching how the .NET reference app uses Task.Run to give
// each ECU's StartECUFlashing its own thread-pool thread. This is
// the real fix for true ~2.5-3 min parallel flashing: Dart's normal
// async/await is cooperative single-threaded concurrency and cannot
// achieve this on its own, no matter how the code is structured.
// ════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ap_dongle_comm/utils/enums/connectivity.dart';
import 'package:ap_dongle_comm/utils/helper/crc16_ccitt_kermit.dart';
import 'package:convert/convert.dart';
import 'i_comm_controller.dart';

class CommControllerIsolateSafe implements ICommController {
  @override
  Connectivity connectivity = Connectivity.none;
  bool isConnected = false;
  Socket? _socket;
  StreamSubscription? _socketSub;
  List<int> _buffer = [];

  Future<void> connectWifi1({
    required String host,
    required int port,
    required Connectivity selectedType,
  }) async {
    try {
      print(
        "🌐 [connectWifi] Attempting $selectedType connection to $host:$port...",
      );
      await disconnect();

      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(minutes: 1),
      );

      // CRITICAL FIX: without this, Windows' default TCP behavior
      // (Nagle's algorithm combined with delayed ACK) adds 200-500ms
      // of pure network-stack latency to EVERY small send/response
      // round-trip — and the flash protocol does thousands of these.
      // Same fix already applied to the main-isolate CommController;
      // this isolate-safe twin was missing it.
      try {
        _socket!.setOption(SocketOption.tcpNoDelay, true);
        print(
          '⚡ TCP_NODELAY enabled — small packets sent immediately, no Nagle delay',
        );
      } catch (e) {
        print('⚠️ Could not set TCP_NODELAY: $e');
      }

      print('✅ SOCKET CONNECTED $host:$port');
      isConnected = true;
      connectivity = selectedType;

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

      print('🚀 $selectedType Ready over WiFi');
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

  Uint8List wrapPacket1(Uint8List payload, int headerByte, {int? channel}) {
    final builder = BytesBuilder();
    builder.addByte(headerByte);
    builder.addByte(payload.length);
    builder.addByte(channel!);
    builder.add(payload);
    List<int> crc = Crc16CcittKermit.computeChecksumBytes(payload);
    builder.add(crc);
    return builder.toBytes();
  }

  Uint8List wrapPacket(Uint8List payload, int headerByte, {int? channel}) {
    final builder = BytesBuilder();
    builder.addByte(headerByte);
    builder.addByte(payload.length);
    builder.addByte(channel!);
    builder.add(payload);
    Uint8List packetSoFar = builder.toBytes();
    List<int> crc = Crc16CcittKermit.computeChecksumBytes(packetSoFar);
    builder.add(crc);
    return builder.toBytes();
  }

  String formatHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  @override
  Uint8List hexToBytes(String hexStr) {
    hexStr = hexStr.replaceAll(' ', '');
    return Uint8List.fromList(hex.decode(hexStr));
  }

  String bytesToHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  // FIX: sendCommand now retries the whole send+read cycle a few times
  // if the read times out, instead of failing on the very first
  // transient network hiccup. Each retry re-sends the command (safe —
  // these are idempotent request/response exchanges like Security
  // Access, CAN config, etc., not bulk data writes) and waits again.
  @override
  Future<Uint8List?> sendCommand(
    Uint8List finalPacket, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (connectivity == Connectivity.none) return null;

    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("[SENDING HEX] ${bytesToHex(finalPacket)}"
            "${attempt > 1 ? ' (retry $attempt/$maxRetries)' : ''}");

        final socket = _socket;
        if (socket == null) return null;

        _buffer.clear();
        socket.add(finalPacket);
        await socket.flush();
        print("📥 Waiting for WiFi response...");

        final result = await _readDirect(socket);

        // _readDirect returns the "No Resp From Dongle" fallback on a
        // genuine timeout — treat that as a retryable failure rather
        // than accepting it as a real (bad) response on the first try.
        final isFallback = result != null &&
            String.fromCharCodes(result).contains('No Resp From Dongle');

        if (isFallback && attempt < maxRetries) {
          print(
              "⚠️ sendCommand: no response (attempt $attempt/$maxRetries) — retrying...");
          continue;
        }

        return result;
      } catch (e) {
        print("[EXCEPTION in sendCommand] $e");
        if (attempt == maxRetries) {
          return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
        }
      }
    }
    return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
  }

  void _handleData(Uint8List data) {
    if (data.isEmpty) return;
    print("🧠 BEFORE ADD Buffer: ${bytesToHex(Uint8List.fromList(_buffer))}");
    _buffer.addAll(data);
    print("📥 RAW RX: ${bytesToHex(data)}");
    print("📦 Buffer Size: ${_buffer.length}");
  }

  Future<void> disconnect() async {
    try {
      print("🔌 Starting full disconnect...");
      await _socketSub?.cancel();
      _socketSub = null;
      await _socket?.close();
      _socket = null;
      isConnected = false;
      connectivity = Connectivity.none;
      await Future.delayed(const Duration(milliseconds: 500));
      print("✅ Full disconnect completed");
    } catch (e) {
      print("🔥 Disconnect error: $e");
    }
  }

  Future<void> disconnectVCI() async {
    try {
      await _socketSub?.cancel();
      _socketSub = null;
      if (_socket != null) {
        await _socket!.flush();
        await _socket!.close();
        _socket = null;
      }
      isConnected = false;
      print("VCI Disconnected successfully.");
    } catch (e) {
      print("Error during disconnectVCI: $e");
    }
  }

  void _handleDisconnect() async {
    print("⚠️ Handling unexpected disconnect...");
    await disconnect();
  }

  Future<void> clearBuffer() async {
    print("🧹 [clearBuffer] Draining RX Buffer...");
    if (_buffer.isEmpty) {
      print("      -> Buffer already empty. Ready.");
      return;
    }
    int discardedCount = _buffer.length;
    String discardedHex = bytesToHex(Uint8List.fromList(_buffer));
    _buffer.clear();
    print(
      "🧹 [clearBuffer] Drain complete. Discarded $discardedCount bytes: [$discardedHex]",
    );
  }

  @override
  Future<Uint8List?> readData() async {
    print("------Read Again Data------");
    try {
      final result = await getWifiResponse();
      print("------END Read Again Data------");
      return result;
    } catch (e) {
      print("Error during ReadData: $e");
      return null;
    }
  }

  // 25s per individual read attempt. Combined with the retry loop in
  // getWifiResponse() below, a single bulk-transfer step now tolerates
  // up to 3 × 25s = 75s of cumulative network trouble before actually
  // failing, instead of dying on the very first 25s hiccup.
  Future<Uint8List> _readExactBytes(int length, {int timeoutSec = 25}) async {
    final DateTime startTime = DateTime.now();
    while (_buffer.length < length) {
      await Future.delayed(const Duration(milliseconds: 1));
      if (DateTime.now().difference(startTime).inSeconds > timeoutSec) {
        print(
          "❌ TIMEOUT: Needed $length, Have ${_buffer.length}. Clearing Buffer.",
        );
        _buffer.clear();
        return Uint8List(0);
      }
    }
    final result = Uint8List.fromList(_buffer.sublist(0, length));
    _buffer.removeRange(0, length);
    print("✅ [_readExactBytes] Extracted $length bytes: ${bytesToHex(result)}");
    return result;
  }

  Future<Uint8List?> _readDirect(
    Socket socket, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (_buffer.length < 2) {
      if (DateTime.now().isAfter(deadline)) {
        print(
          '⏰ _readDirect: timeout waiting for header, buf=${_buffer.length}',
        );
        return Uint8List.fromList(utf8.encode('No Resp From Dongle'));
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }

    final hdr0 = _buffer[0];
    final hdr1 = _buffer[1];
    final msgLen = ((hdr0 & 0x0F) << 8) + hdr1;
    final totalExpected = 2 + msgLen + 3;
    print('🧠 _readDirect: msgLen=$msgLen expecting=$totalExpected');

    while (_buffer.length < totalExpected) {
      if (DateTime.now().isAfter(deadline)) {
        print(
          '⏰ _readDirect: timeout waiting for body, have=${_buffer.length} need=$totalExpected',
        );
        break;
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }

    final n = _buffer.length < totalExpected ? _buffer.length : totalExpected;
    final result = Uint8List.fromList(_buffer.sublist(0, n));
    _buffer.removeRange(0, n);
    print('✅ _readDirect: ${bytesToHex(result)}');
    return result;
  }

  // FIX: getWifiResponse now retries up to 3 times on a read timeout
  // before giving up, instead of failing on the very first 25s hiccup.
  // This is the path used during the bulk-transfer loop, so it's the
  // one that matters most for surviving a brief mid-flash network
  // congestion event like the one that was killing Lane 1 at 84%.
  Future<Uint8List> getWifiResponse() async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        while (true) {
          print("WiFi Communication : ---------INSIDE READ DATA -----------");

          Uint8List trgtlen = await _readExactBytes(2);
          if (trgtlen.isEmpty) {
            if (attempt < maxRetries) {
              print(
                  "⚠️ getWifiResponse: header read timed out (attempt $attempt/$maxRetries) — retrying...");
              break; // exit inner while, retry from outer for-loop
            }
            return Uint8List.fromList(utf8.encode("No Resp From Dongle"));
          }

          int msglen = ((trgtlen[0] & 0x0F) << 8) + trgtlen[1];
          Uint8List remData = await _readExactBytes(msglen + 3);
          if (remData.isEmpty) {
            if (attempt < maxRetries) {
              print(
                  "⚠️ getWifiResponse: body read timed out (attempt $attempt/$maxRetries) — retrying...");
              break;
            }
            return Uint8List.fromList(utf8.encode("No Resp From Dongle"));
          }

          final builder = BytesBuilder();
          builder.add(trgtlen);
          builder.add(remData);
          Uint8List retArray = builder.toBytes();

          print(
            "WiFi Communication : ---------Response Received = ${bytesToHex(retArray)} -----------",
          );

          if (retArray.length >= 6 &&
              retArray[3] == 0x7F &&
              retArray[5] == 0x78) {
            print("⚠️ NRC 0x78 Detected: ECU Busy. Reading again...");
            continue;
          }

          return retArray;
        }
      } catch (e) {
        print("Exception @getWifiResponse (attempt $attempt/$maxRetries): $e");
        if (attempt == maxRetries) {
          return Uint8List.fromList(utf8.encode("No Resp From Dongle"));
        }
      }
    }

    return Uint8List.fromList(utf8.encode("No Resp From Dongle"));
  }
}