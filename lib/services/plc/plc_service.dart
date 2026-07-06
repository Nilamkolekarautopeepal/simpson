import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:simpson/services/local_storage_services/localstorage_services.dart';

/// Modbus TCP client for the PFS Station's PLC.
///
/// Registered once as a GetxService (`Get.put(PlcService(), permanent: true)`
/// in your bindings) so any screen can do `Get.find<PlcService>()`.
///
/// Improvements over the earlier prototype this is based on:
///  - Each request gets its own transaction ID; responses are matched back
///    to the exact request that asked for them (a Completer per txId), so
///    a burst of reads can't get their responses crossed.
///  - Writes are confirmed: Modbus echoes the address+value back on
///    success, and [writeRegister] actually checks that before resolving.
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
  int _nextTransactionId = 1;
  final Map<int, Completer<List<int>>> _pending = {};

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

  Future<void> connect(String ip, {int port = 502}) async {
    if (isConnecting.value) return;
    await disconnect();

    try {
      isConnecting.value = true;
      status.value = 'Connecting…';

      _socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
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
    } on SocketException catch (e) {
      status.value = 'Unreachable';
      print('❌ [PLC] Unreachable: ${e.message}');
      await disconnect();
      rethrow;
    } catch (e) {
      status.value = 'Connect error';
      print('❌ [PLC] Connect error: $e');
      await disconnect();
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> disconnect() async {
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

  // ── Read / write ──

  Future<int> readRegister(int registerAddress, {Duration timeout = const Duration(seconds: 3)}) async {
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

  Future<bool> writeRegister(int registerAddress, int value, {Duration timeout = const Duration(seconds: 3)}) async {
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
      (txId >> 8) & 0xFF, txId & 0xFF,
      0x00, 0x00,
      (pdu.length >> 8) & 0xFF, pdu.length & 0xFF,
      ...pdu,
    ];

    final completer = Completer<List<int>>();
    _pending[txId] = completer;
    _socket!.add(packet);

    try {
      return await completer.future.timeout(timeout);
    } finally {
      _pending.remove(txId);
    }
  }

  int _takeTransactionId() {
    final id = _nextTransactionId;
    _nextTransactionId = (_nextTransactionId + 1) & 0xFFFF;
    if (_nextTransactionId == 0) _nextTransactionId = 1;
    return id;
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

  void _handleFrame(List<int> frame) {
    if (frame.length < 8) return;
    final txId = (frame[0] << 8) | frame[1];
    final completer = _pending[txId];
    if (completer == null || completer.isCompleted) return;

    final functionCode = frame[7];
    if (functionCode & 0x80 != 0) {
      final exceptionCode = frame.length > 8 ? frame[8] : -1;
      completer.completeError('Modbus exception code $exceptionCode');
      return;
    }
    completer.complete(frame);
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
