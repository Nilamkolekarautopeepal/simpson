// ════════════════════════════════════════════════════════════
// ICommController — shared interface for DongleComm's comm field
//
// DongleComm only ever calls 4 things on its `comm` field:
//   connectivity, hexToBytes(), readData(), sendCommand()
// This interface captures exactly that surface, so DongleComm can
// accept EITHER the original GetX-based CommController (used on
// the main isolate for UI-bound operations like checkEcuStatus)
// OR the isolate-safe CommControllerIsolateSafe (used inside a
// spawned Isolate for true parallel flashing) interchangeably.
// ════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'package:ap_dongle_comm/utils/enums/connectivity.dart';

abstract class ICommController {
  Connectivity get connectivity;
  Uint8List hexToBytes(String hexStr);
  Future<Uint8List?> readData();
  Future<Uint8List?> sendCommand(Uint8List finalPacket, {Duration timeout});
  Future<void> disconnectVCI();
}