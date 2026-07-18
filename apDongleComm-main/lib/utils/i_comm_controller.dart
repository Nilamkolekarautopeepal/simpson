import 'dart:typed_data';
import 'package:ap_dongle_comm/utils/enums/connectivity.dart';

abstract class ICommController {
  Connectivity get connectivity;
  Uint8List hexToBytes(String hexStr);
  Future<Uint8List?> readData();
  Future<Uint8List?> sendCommand(Uint8List finalPacket, {Duration timeout});
  Future<void> disconnectVCI();
}