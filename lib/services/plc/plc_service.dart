// import 'dart:async';
// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:simpson/services/local_storage_services/localstorage_services.dart';

// class PlcService extends GetxService {
//   static const _ipKey = 'plc_ip';
//   static const _portKey = 'plc_port';

//   final RxBool isConnected = false.obs;
//   final RxBool isConnecting = false.obs;
//   final RxString status = 'Idle'.obs;
//   final RxString lastIp = ''.obs;

//   Socket? _socket;
//   StreamSubscription<List<int>>? _sub;
//   List<int> _rxBuffer = [];
//   final Map<int, Completer<List<int>>> _pending = {};

//   int _lockRegister = 999;
//   Timer? _lockTimer;
//   static const Duration _lockRenewInterval = Duration(seconds: 2);
//   final int _ownerToken = 1 + (DateTime.now().microsecondsSinceEpoch % 65000);
//   final RxBool lockLost = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     lastIp.value = LocalServices.retrieveDataFromLocalStorage(key: _ipKey);
//   }

//   // ── Saved settings ──

//   Future<void> saveSettings({required String ip, required String port}) async {
//     await LocalServices.storeDataInLocalStorage(key: _ipKey, value: ip);
//     await LocalServices.storeDataInLocalStorage(key: _portKey, value: port);
//     lastIp.value = ip;
//   }

//   String get savedIp => LocalServices.retrieveDataFromLocalStorage(key: _ipKey);
//   String get savedPort {
//     final p = LocalServices.retrieveDataFromLocalStorage(key: _portKey);
//     return p.isEmpty ? '502' : p;
//   }

//   // ── Connect / disconnect ──

//   Future<void> connect(
//     String ip, {
//     int port = 502,
//     int? lockRegister,
//   }) async {
//     if (isConnecting.value) return;
//     await disconnect();

//     if (lockRegister != null) _lockRegister = lockRegister;
//     lockLost.value = false;

//     try {
//       isConnecting.value = true;
//       status.value = 'Connecting…';

//       _socket =
//           await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
//       _socket!.setOption(SocketOption.tcpNoDelay, true);

//       isConnected.value = true;
//       status.value = 'Connected';
//       lastIp.value = ip;
//       await saveSettings(ip: ip, port: port.toString());

//       _sub = _socket!.listen(
//         _onData,
//         onError: (_) => disconnect(),
//         onDone: () => disconnect(),
//         cancelOnError: true,
//       );

//       // ── Claim ownership before declaring the connection usable ──
//       final claimed = await _claimLock();
//       if (!claimed) {
//         status.value = 'In use by another station';
//         lockLost.value = true;
//         await disconnect();
//         throw StateError('PLC at $ip is already claimed by another station.');
//       }

//       _startLockRenewal();
//     } on SocketException {
//       status.value = 'Unreachable';
//       //print('❌ [PLC] Unreachable: ${e.message}');
//       await disconnect();
//       rethrow;
//     } catch (e) {
//       if (status.value != 'In use by another station') {
//         status.value = 'Connect error';
//       }
//       print('❌ [PLC] Connect error: $e');
//       await disconnect();
//       rethrow;
//     } finally {
//       isConnecting.value = false;
//     }
//   }

//   Future<bool> _claimLock() async {
//     try {
//       final current =
//           await readRegister(_lockRegister).timeout(const Duration(seconds: 2));
//       if (current != 0 && current != _ownerToken) {
//         // Someone else already owns it.
//         return false;
//       }
//     } catch (e) {
//       print('⚠️ [PLC LOCK] Could not read lock register: $e — proceeding '
//           'without ownership check');
//       return true;
//     }

//     try {
//       await writeRegister(_lockRegister, _ownerToken)
//           .timeout(const Duration(seconds: 2));
//     } catch (e) {
//       print('⚠️ [PLC LOCK] Could not write lock register: $e — proceeding '
//           'without ownership check');
//     }
//     return true;
//   }

//   void _startLockRenewal() {
//     _lockTimer?.cancel();
//     _lockTimer = Timer.periodic(_lockRenewInterval, (_) async {
//       if (!isConnected.value) return;
//       try {
//         final current = await readRegister(_lockRegister)
//             .timeout(const Duration(seconds: 2));
//         if (current != _ownerToken && current != 0) {
//           print('❌ [PLC LOCK] Ownership lost — register now holds '
//               'token $current, expected $_ownerToken');
//           lockLost.value = true;
//           status.value = 'In use by another station';
//           await disconnect();
//           return;
//         }

//         await writeRegister(_lockRegister, _ownerToken)
//             .timeout(const Duration(seconds: 2));
//       } catch (e) {
//         print('⚠️ [PLC LOCK] Renewal check failed (ignored): $e');
//       }
//     });
//   }

//   Future<void> _releaseLock() async {
//     _lockTimer?.cancel();
//     _lockTimer = null;
//     if (_socket == null || !isConnected.value) return;
//     try {
//       await writeRegister(_lockRegister, 0).timeout(const Duration(seconds: 1));
//     } catch (_) {
//       // Best-effort — socket may already be on its way down.
//     }
//   }

//   Future<void> disconnect() async {
//     await _releaseLock();
//     await _sub?.cancel();
//     _socket?.destroy();
//     _socket = null;
//     _sub = null;
//     _rxBuffer = [];
//     isConnected.value = false;
//     status.value = 'Disconnected';
//     for (final c in _pending.values) {
//       if (!c.isCompleted) c.completeError('Disconnected');
//     }
//     _pending.clear();
//   }

//   // ── Read / write ──

//   Future<int> readRegister(int registerAddress,
//       {Duration timeout = const Duration(seconds: 3)}) async {
//     final frame = await _sendAndWait(
//       functionCode: 0x03,
//       registerAddress: registerAddress,
//       extra: [0x00, 0x01],
//       timeout: timeout,
//     );
//     final hi = frame[frame.length - 2];
//     final lo = frame[frame.length - 1];
//     return (hi << 8) | lo;
//   }

//   Future<bool> writeRegister(int registerAddress, int value,
//       {Duration timeout = const Duration(seconds: 3)}) async {
//     final hiVal = (value >> 8) & 0xFF;
//     final loVal = value & 0xFF;

//     final frame = await _sendAndWait(
//       functionCode: 0x06,
//       registerAddress: registerAddress,
//       extra: [hiVal, loVal],
//       timeout: timeout,
//     );

//     final echoedAddr = (frame[frame.length - 4] << 8) | frame[frame.length - 3];
//     final echoedVal = (frame[frame.length - 2] << 8) | frame[frame.length - 1];
//     return echoedAddr == registerAddress && echoedVal == value;
//   }

//   Future<List<int>> _sendAndWait({
//     required int functionCode,
//     required int registerAddress,
//     required List<int> extra,
//     required Duration timeout,
//   }) async {
//     if (_socket == null || !isConnected.value) {
//       throw StateError('PLC not connected');
//     }

//     final txId = _takeTransactionId();
//     final hiAddr = (registerAddress >> 8) & 0xFF;
//     final loAddr = registerAddress & 0xFF;

//     final pdu = [0x01, functionCode, hiAddr, loAddr, ...extra];
//     final packet = [
//       (txId >> 8) & 0xFF,
//       txId & 0xFF,
//       0x00,
//       0x00,
//       (pdu.length >> 8) & 0xFF,
//       pdu.length & 0xFF,
//       ...pdu,
//     ];

//     final completer = Completer<List<int>>();
//     _pending[txId] = completer;
//     print('[MODBUS TX] fn=0x${functionCode.toRadixString(16)} '
//         'reg=$registerAddress bytes=$packet');
//     _socket!.add(packet);

//     try {
//       return await completer.future.timeout(timeout);
//     } finally {
//       _pending.remove(txId);
//     }
//   }

//   int _takeTransactionId() {
//     return 1;
//   }

//   void _onData(List<int> chunk) {
//     _rxBuffer.addAll(chunk);
//     while (_rxBuffer.length >= 6) {
//       final declaredLen = (_rxBuffer[4] << 8) | _rxBuffer[5];
//       final totalLen = 6 + declaredLen;
//       if (_rxBuffer.length < totalLen) break;
//       final frame = _rxBuffer.sublist(0, totalLen);
//       _rxBuffer = _rxBuffer.sublist(totalLen);
//       _handleFrame(frame);
//     }
//   }

//   void _handleFrame(List<int> frame) {
//     if (frame.length < 8) return;
//     final txId = (frame[0] << 8) | frame[1];
//     final completer = _pending[txId];
//     if (completer == null || completer.isCompleted) return;

//     final functionCode = frame[7];
//     if (functionCode & 0x80 != 0) {
//       final exceptionCode = frame.length > 8 ? frame[8] : -1;
//       completer.completeError('Modbus exception code $exceptionCode');
//       return;
//     }
//     completer.complete(frame);
//   }

//   @override
//   void onClose() {
//     disconnect();
//     super.onClose();
//   }
// }
import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:simpson/services/local_storage_services/localstorage_services.dart';

class PlcService extends GetxService {
  static const _ipKey = 'plc_ip';
  static const _portKey = 'plc_port';

  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxString status = 'Idle'.obs;
  final RxString lastIp = ''.obs;

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  List<int> _rxBuffer = [];
  final Map<int, Completer<List<int>>> _pending = {};

  int _lockRegister = 999;
  Timer? _lockTimer;
  static const Duration _lockRenewInterval = Duration(seconds: 2);
  final int _ownerToken = 1 + (DateTime.now().microsecondsSinceEpoch % 65000);
  final RxBool lockLost = false.obs;

  // Serializes every PLC call across ALL lanes — Modbus over one TCP
  // connection can only handle one request/response pair at a time.
  // Without this, two lanes calling read/write at nearly the same
  // moment can interleave, and combined with the fixed transaction ID
  // bug below, this was the actual cause of the lock-register
  // timeouts seen when multiple lanes finish flashing around the
  // same time.
  bool _plcBusy = false;
  Future<T> _serialized<T>(Future<T> Function() action) async {
    while (_plcBusy) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    _plcBusy = true;
    try {
      return await action();
    } finally {
      _plcBusy = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    lastIp.value = LocalServices.retrieveDataFromLocalStorage(key: _ipKey);
  }

  // ── Saved settings ──

  Future<void> saveSettings({required String ip, required String port}) async {
    await LocalServices.storeDataInLocalStorage(key: _ipKey, value: ip);
    await LocalServices.storeDataInLocalStorage(key: _portKey, value: port);
    lastIp.value = ip;
  }

  String get savedIp => LocalServices.retrieveDataFromLocalStorage(key: _ipKey);
  String get savedPort {
    final p = LocalServices.retrieveDataFromLocalStorage(key: _portKey);
    return p.isEmpty ? '502' : p;
  }

  // ── Connect / disconnect ──

  Future<void> connect(
    String ip, {
    int port = 502,
    int? lockRegister,
  }) async {
    if (isConnecting.value) return;
    await disconnect();

    if (lockRegister != null) _lockRegister = lockRegister;
    lockLost.value = false;

    try {
      isConnecting.value = true;
      status.value = 'Connecting…';

      _socket =
          await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      isConnected.value = true;
      status.value = 'Connected';
      lastIp.value = ip;
      await saveSettings(ip: ip, port: port.toString());

            _sub = _socket!.listen(
        _onData,
        onError: (_) => disconnect(),
        onDone: () => disconnect(),
        cancelOnError: true,
      );

      // Some PLCs need a brief moment after the TCP handshake before
      // they're ready to actually respond to Modbus requests — without
      // this, the very first read (the lock claim) can hit the socket
      // mid-settle and get disconnected.
      await Future.delayed(const Duration(milliseconds: 300));

      // ── Claim ownership before declaring the connection usable ──
      final claimed = await _claimLock();
      if (!claimed) {
        status.value = 'In use by another station';
        lockLost.value = true;
        await disconnect();
        throw StateError('PLC at $ip is already claimed by another station.');
      }

      _startLockRenewal();
    } on SocketException {
      status.value = 'Unreachable';
      //print('❌ [PLC] Unreachable: ${e.message}');
      await disconnect();
      rethrow;
    } catch (e) {
      if (status.value != 'In use by another station') {
        status.value = 'Connect error';
      }
      print('❌ [PLC] Connect error: $e');
      await disconnect();
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

    Future<bool> _claimLock() async {
    int? current;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        current = await readRegister(_lockRegister)
            .timeout(const Duration(seconds: 2));
        break;
      } catch (e) {
        if (attempt == 1) {
          print('⚠️ [PLC LOCK] First attempt failed ($e) — retrying once '
              'after a short delay...');
          await Future.delayed(const Duration(milliseconds: 400));
          continue;
        }
        print('⚠️ [PLC LOCK] Could not read lock register after retry: $e — '
            'proceeding without ownership check');
        return true;
      }
    }

    if (current != null && current != 0 && current != _ownerToken) {
      // Someone else already owns it.
      return false;
    }

    try {
      await writeRegister(_lockRegister, _ownerToken)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      print('⚠️ [PLC LOCK] Could not write lock register: $e — proceeding '
          'without ownership check');
    }
    return true;
  }

  void _startLockRenewal() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(_lockRenewInterval, (_) async {
      if (!isConnected.value) return;
      try {
        final current = await readRegister(_lockRegister)
            .timeout(const Duration(seconds: 2));
        if (current != _ownerToken && current != 0) {
          print('❌ [PLC LOCK] Ownership lost — register now holds '
              'token $current, expected $_ownerToken');
          lockLost.value = true;
          status.value = 'In use by another station';
          await disconnect();
          return;
        }

        await writeRegister(_lockRegister, _ownerToken)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ [PLC LOCK] Renewal check failed (ignored): $e');
      }
    });
  }

  Future<void> _releaseLock() async {
    _lockTimer?.cancel();
    _lockTimer = null;
    if (_socket == null || !isConnected.value) return;
    try {
      await writeRegister(_lockRegister, 0).timeout(const Duration(seconds: 1));
    } catch (_) {
      // Best-effort — socket may already be on its way down.
    }
  }

  Future<void> disconnect() async {
    await _releaseLock();
    await _sub?.cancel();
    _socket?.destroy();
    _socket = null;
    _sub = null;
    _rxBuffer = [];
    isConnected.value = false;
    status.value = 'Disconnected';
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError('Disconnected');
    }
    _pending.clear();
  }

  // ── Read / write — public API unchanged, now serialized ──

  Future<int> readRegister(int registerAddress,
      {Duration timeout = const Duration(seconds: 3)}) {
    return _serialized(
        () => _readRegisterInternal(registerAddress, timeout: timeout));
  }

  Future<bool> writeRegister(int registerAddress, int value,
      {Duration timeout = const Duration(seconds: 3)}) {
    return _serialized(
        () => _writeRegisterInternal(registerAddress, value, timeout: timeout));
  }

  Future<int> _readRegisterInternal(int registerAddress,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final frame = await _sendAndWait(
      functionCode: 0x03,
      registerAddress: registerAddress,
      extra: [0x00, 0x01],
      timeout: timeout,
    );
    final hi = frame[frame.length - 2];
    final lo = frame[frame.length - 1];
    return (hi << 8) | lo;
  }

  Future<bool> _writeRegisterInternal(int registerAddress, int value,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final hiVal = (value >> 8) & 0xFF;
    final loVal = value & 0xFF;

    final frame = await _sendAndWait(
      functionCode: 0x06,
      registerAddress: registerAddress,
      extra: [hiVal, loVal],
      timeout: timeout,
    );

    final echoedAddr = (frame[frame.length - 4] << 8) | frame[frame.length - 3];
    final echoedVal = (frame[frame.length - 2] << 8) | frame[frame.length - 1];
    return echoedAddr == registerAddress && echoedVal == value;
  }

  Future<List<int>> _sendAndWait({
    required int functionCode,
    required int registerAddress,
    required List<int> extra,
    required Duration timeout,
  }) async {
    if (_socket == null || !isConnected.value) {
      throw StateError('PLC not connected');
    }

    final txId = _takeTransactionId();
    final hiAddr = (registerAddress >> 8) & 0xFF;
    final loAddr = registerAddress & 0xFF;

    final pdu = [0x01, functionCode, hiAddr, loAddr, ...extra];
    final packet = [
      (txId >> 8) & 0xFF,
      txId & 0xFF,
      0x00,
      0x00,
      (pdu.length >> 8) & 0xFF,
      pdu.length & 0xFF,
      ...pdu,
    ];

    final completer = Completer<List<int>>();
    _pending[txId] = completer;
    print('[MODBUS TX] fn=0x${functionCode.toRadixString(16)} '
        'reg=$registerAddress txId=$txId bytes=$packet');
    _socket!.add(packet);

    try {
      return await completer.future.timeout(timeout);
    } finally {
      _pending.remove(txId);
    }
  }

  // FIXED: was returning a hardcoded 1 for every request, which meant
  // any two requests in flight at once collided in _pending, silently
  // losing the first one's response until it timed out. Now cycles
  // through the valid Modbus TCP transaction ID range (1–65535,
  // wrapping around) so every in-flight request is uniquely tracked.
  int _lastTxId = 0;
  int _takeTransactionId() {
    _lastTxId = (_lastTxId % 65535) + 1;
    return _lastTxId;
  }

  void _onData(List<int> chunk) {
    _rxBuffer.addAll(chunk);
    while (_rxBuffer.length >= 6) {
      final declaredLen = (_rxBuffer[4] << 8) | _rxBuffer[5];
      final totalLen = 6 + declaredLen;
      if (_rxBuffer.length < totalLen) break;
      final frame = _rxBuffer.sublist(0, totalLen);
      _rxBuffer = _rxBuffer.sublist(totalLen);
      _handleFrame(frame);
    }
  }

  // void _handleFrame(List<int> frame) {
  //   if (frame.length < 8) return;
  //   final txId = (frame[0] << 8) | frame[1];
  //   final completer = _pending[txId];
  //   if (completer == null || completer.isCompleted) return;

  //   final functionCode = frame[7];
  //   if (functionCode & 0x80 != 0) {
  //     final exceptionCode = frame.length > 8 ? frame[8] : -1;
  //     completer.completeError('Modbus exception code $exceptionCode');
  //     return;
  //   }
  //   completer.complete(frame);
  // }


    void _handleFrame(List<int> frame) {
    print('[MODBUS RX] bytes=$frame');

    if (frame.length < 8) return;
    final txId = (frame[0] << 8) | frame[1];
    final completer = _pending[txId];
    if (completer == null || completer.isCompleted) return;

    final functionCode = frame[7];
    if (functionCode & 0x80 != 0) {
      final exceptionCode = frame.length > 8 ? frame[8] : -1;
      print('[MODBUS RX] ❌ Exception response — code $exceptionCode (txId=$txId)');
      completer.completeError('Modbus exception code $exceptionCode');
      return;
    }
    print('[MODBUS RX] ✅ Success response (txId=$txId, fn=0x${functionCode.toRadixString(16)})');
    completer.complete(frame);
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}