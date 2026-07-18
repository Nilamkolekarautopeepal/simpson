// // // ════════════════════════════════════════════════════════════
// // // PFS-ONLY isolate-based flash entry point.
// // //
// // // Does not touch Test Station or any of its files. This gives each
// // // lane's flash its own real OS-scheduled Dart isolate — genuine
// // // parallelism, unlike async/await on the main isolate (which is
// // // cooperative and single-threaded no matter how it's structured).
// // //
// // // CRITICAL RULE (this is what broke the earlier isolate attempt):
// // // the dongle connection is created FRESH, from scratch, entirely
// // // INSIDE this isolate. A live Socket/connection can never be handed
// // // off between isolates — Dart isolates share no memory, and native
// // // resources like sockets aren't transferable. Every single thing
// // // this function touches (CommControllerIsolateSafe, DongleComm,
// // // UDSDiagnostic) is created here, used here, and discarded here.
// // // ════════════════════════════════════════════════════════════
// import 'dart:async';
// import 'dart:convert';
// import 'dart:isolate';
// import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
// import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
// import 'package:ap_diagnostic/structure/flash_structures.dart';
// import 'package:ap_diagnostic/usd_diagnostic.dart';
// import 'package:ap_dongle_comm/utils/dongleComm.dart';
// import 'package:ap_dongle_comm/utils/enums/connectivity.dart';
// import 'package:ap_dongle_comm/utils/enums/protocol.dart';
// import 'package:ecu_seedkey/ecu_seedkey.dart';

// import 'comm_controller_isolate_safe.dart';

// /// Everything the isolate needs to do its job — only simple,
// /// isolate-transferable types (String, int). No GetX objects, no
// /// app model classes, no live connections.
// class PfsFlashArgs {
//   final String host;
//   final int port;
//   final String protocolName; // e.g. "ISO15765_1MB_11BIT_CAN"
//   final String protocolHex; // e.g. "04"
//   final String txHeader;
//   final String rxHeader;
//   final String flashJson;
//   final String interpreter;
//   final String seedKeyAlgo; // e.g. "SIMPSON_MDCS162_SECURITY"
//   final int laneNumber; // for logging only

//   PfsFlashArgs({
//     required this.host,
//     required this.port,
//     required this.protocolName,
//     required this.protocolHex,
//     required this.txHeader,
//     required this.rxHeader,
//     required this.flashJson,
//     required this.interpreter,
//     required this.seedKeyAlgo,
//     required this.laneNumber,
//   });
// }

// /// Messages sent back from the isolate to the main isolate.
// /// type is one of: 'progress', 'done', 'error'
// class PfsFlashMessage {
//   final String type;
//   final double? percent;
//   final String? result;
//   PfsFlashMessage.progress(this.percent) : type = 'progress', result = null;
//   PfsFlashMessage.done(this.result) : type = 'done', percent = null;
//   PfsFlashMessage.error(this.result) : type = 'error', percent = null;
// }

// /// Call this from the main isolate with Isolate.spawn. It expects
// /// [initialMessage] to be a 2-element List: [SendPort, PfsFlashArgs].
// void pfsFlashIsolateEntry(List<dynamic> initialMessage) async {
//   final SendPort mainSendPort = initialMessage[0] as SendPort;
//   final PfsFlashArgs args = initialMessage[1] as PfsFlashArgs;

//   Timer? progressTimer;
//   UDSDiagnostic? uds;

//   void reportError(String msg) {
//     print('❌ [Lane ${args.laneNumber} isolate] $msg');
//     mainSendPort.send(PfsFlashMessage.error(msg));
//   }

//   try {
//     print('🚀 [Lane ${args.laneNumber} isolate] starting — own fresh connection to ${args.host}:${args.port}');

//     // Step 1: brand-new connection, created entirely inside this isolate.
//     final comm = CommControllerIsolateSafe();
//     await comm.connectWifi(
//       host: args.host,
//       port: args.port,
//       selectedType: Connectivity.wiFi,
//     );

//     if (!comm.isConnected) {
//       reportError('Could not connect to dongle at ${args.host}:${args.port}');
//       return;
//     }

//     final dongleComm = DongleComm(comm: comm as dynamic, isChannel: true, channelId: '00');

//     // Step 2: setDongleProperties — same logic as DLLFunctions.setDongleProperties,
//     // replicated here since DLLFunctions itself isn't isolate-safe (it holds a
//     // concrete CommController field), but the actual work it does is simple.
//     final protoValue = args.protocolName.replaceAll('-', '_');
//     Protocol? matchedProtocol;
//     for (final p in Protocol.values) {
//       if (p.name == protoValue) {
//         matchedProtocol = p;
//         break;
//       }
//     }
//     if (matchedProtocol == null) {
//       reportError('No Protocol enum matches "${args.protocolName}"');
//       return;
//     }
//     dongleComm.protocol = matchedProtocol;

//     final protocolInt = int.parse(args.protocolHex, radix: 16);
//     await dongleComm.dongleSetProtocol(protocolInt);
//     await dongleComm.canSetTxHeader(args.txHeader);
//     await dongleComm.canSetRxHeaderMask(args.rxHeader);
//     print('✅ [Lane ${args.laneNumber} isolate] dongle configured — protocol=$matchedProtocol tx=${args.txHeader} rx=${args.rxHeader}');

//     // Step 3: the actual flash, using the real flashInterpreter2 logic.
//     uds = UDSDiagnostic(dongleComm, ECUCalculateSeedkey());

//     final sklFN = args.seedKeyAlgo.replaceAll('-', '_');
//     final jsonMap = jsonDecode(args.flashJson);
//     final jsonData = FlashingMatrixData.fromJson(jsonMap);

//     final seedkeyindx = SEEDKEYINDEXTYPE.values.firstWhere(
//       (e) => e.toString().split('.').last.toUpperCase() == sklFN.toUpperCase(),
//       orElse: () => SEEDKEYINDEXTYPE.values.first,
//     );

//     final flashConfig = FlashConfig(seedKeyIndex: seedkeyindx);

//     // Report progress every 500ms by reading the SAME local counters
//     // flashInterpreter2 updates internally (getRuntimeFlashPercent() —
//     // confirmed pure local math, no network I/O, safe to poll from a
//     // timer running alongside the flash on this isolate's own event loop).
//     progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
//       try {
//         final pct = await uds!.getRuntimeFlashPercent();
//         mainSendPort.send(PfsFlashMessage.progress(pct));
//       } catch (_) {}
//     });

//     print('🚀 [Lane ${args.laneNumber} isolate] calling flashInterpreter2...');
//     final result = await uds.flashInterpreter2(
//       flashConfig,
//       jsonData.noOfSectors ?? 0,
//       jsonData.sectorData ?? [],
//       args.interpreter,
//     );

//     progressTimer.cancel();
//     print('🏁 [Lane ${args.laneNumber} isolate] result: $result');
//     mainSendPort.send(PfsFlashMessage.done(result));
//   } catch (e, stack) {
//     progressTimer?.cancel();
//     print('❌ [Lane ${args.laneNumber} isolate] exception: $e');
//     print(stack);
//     reportError(e.toString());
//   }
// }
// ════════════════════════════════════════════════════════════
// PFS-ONLY isolate-based flash entry point.

// Does not touch Test Station or any of its files. This gives each
// lane's flash its own real OS-scheduled Dart isolate — genuine
// parallelism, unlike async/await on the main isolate (which is
// cooperative and single-threaded no matter how it's structured).

// CRITICAL RULE (this is what broke the earlier isolate attempt):
// the dongle connection is created FRESH, from scratch, entirely
// INSIDE this isolate. A live Socket/connection can never be handed
// off between isolates — Dart isolates share no memory, and native
// resources like sockets aren't transferable. Every single thing
// this function touches (CommControllerIsolateSafe, DongleComm,
// UDSDiagnostic) is created here, used here, and discarded here.
// ════════════════════════════════════════════════════════════
// import 'dart:async';
// import 'dart:convert';
// import 'dart:isolate';
// import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
// import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
// import 'package:ap_diagnostic/structure/flash_structures.dart';
// import 'package:ap_diagnostic/usd_diagnostic.dart';
// import 'package:ap_dongle_comm/utils/comm_controller_isolate_safe.dart';
// import 'package:ap_dongle_comm/utils/dongleComm.dart';
// import 'package:ap_dongle_comm/utils/enums/connectivity.dart';
// import 'package:ap_dongle_comm/utils/enums/protocol.dart';
// import 'package:ecu_seedkey/ecu_seedkey.dart';


//import 'comm_controller_isolate_safe.dart';

/// Everything the isolate needs to do its job — only simple,
/// isolate-transferable types (String, int). No GetX objects, no
/// app model classes, no live connections.
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
import 'package:ap_diagnostic/structure/flash_structures.dart';
import 'package:ap_diagnostic/usd_diagnostic.dart';
import 'package:ap_dongle_comm/utils/comm_controller_isolate_safe.dart';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:ap_dongle_comm/utils/enums/connectivity.dart';
import 'package:ap_dongle_comm/utils/enums/protocol.dart';
import 'package:ecu_seedkey/ecu_seedkey.dart';

//import 'comm_controller_isolate_safe.dart';

/// Everything the isolate needs to do its job — only simple,
/// isolate-transferable types (String, int). No GetX objects, no
/// app model classes, no live connections.
class PfsFlashArgs {
  final String host;
  final int port;
  final String protocolName; // e.g. "ISO15765_1MB_11BIT_CAN"
  final String protocolHex; // e.g. "04"
  final String txHeader;
  final String rxHeader;
  final String flashJson;
  final String interpreter;
  final String seedKeyAlgo; // e.g. "SIMPSON_MDCS162_SECURITY"
  final int laneNumber; // for logging only

  PfsFlashArgs({
    required this.host,
    required this.port,
    required this.protocolName,
    required this.protocolHex,
    required this.txHeader,
    required this.rxHeader,
    required this.flashJson,
    required this.interpreter,
    required this.seedKeyAlgo,
    required this.laneNumber,
  });
}

/// Messages sent back from the isolate to the main isolate.
/// type is one of: 'progress', 'done', 'error'
class PfsFlashMessage {
  final String type;
  final double? percent;
  final String? result;
  PfsFlashMessage.progress(this.percent) : type = 'progress', result = null;
  PfsFlashMessage.done(this.result) : type = 'done', percent = null;
  PfsFlashMessage.error(this.result) : type = 'error', percent = null;
}

/// Call this from the main isolate with Isolate.spawn. It expects
/// [initialMessage] to be a 2-element List: [SendPort, PfsFlashArgs].
void pfsFlashIsolateEntry(List<dynamic> initialMessage) async {
  final SendPort mainSendPort = initialMessage[0] as SendPort;
  final PfsFlashArgs args = initialMessage[1] as PfsFlashArgs;

  Timer? progressTimer;
  UDSDiagnostic? uds;
  CommControllerIsolateSafe? comm;

  // Confirmed root cause of the post-flash reconnect failures: this
  // dongle only supports one active session. If the main isolate tries
  // to reconnect before THIS isolate's own connection is actually
  // closed, the dongle still thinks the old session is alive and
  // ignores the new one. So: disconnect first, confirm it's done, and
  // only THEN tell the main isolate we're finished — never the other
  // way around.
  Future<void> disconnectCleanly() async {
    try {
      await comm?.disconnect();
      print('🔌 [Lane ${args.laneNumber} isolate] connection cleanly closed');
    } catch (_) {}
  }

  try {
    print('🚀 [Lane ${args.laneNumber} isolate] starting — own fresh connection to ${args.host}:${args.port}');

    // Step 1: brand-new connection, created entirely inside this isolate.
    comm = CommControllerIsolateSafe();
    await comm.connectWifi(
      host: args.host,
      port: args.port,
      selectedType: Connectivity.wiFi,
    );

    if (!comm.isConnected) {
      await disconnectCleanly();
      mainSendPort.send(PfsFlashMessage.error(
          'Could not connect to dongle at ${args.host}:${args.port}'));
      return;
    }

    final dongleComm = DongleComm(comm: comm, isChannel: true, channelId: '00');

    // Step 2: setDongleProperties — same logic as DLLFunctions.setDongleProperties,
    // replicated here since DLLFunctions itself isn't isolate-safe (it holds a
    // concrete CommController field), but the actual work it does is simple.
    final protoValue = args.protocolName.replaceAll('-', '_');
    Protocol? matchedProtocol;
    for (final p in Protocol.values) {
      if (p.name == protoValue) {
        matchedProtocol = p;
        break;
      }
    }
    if (matchedProtocol == null) {
      await disconnectCleanly();
      mainSendPort.send(
          PfsFlashMessage.error('No Protocol enum matches "${args.protocolName}"'));
      return;
    }
    dongleComm.protocol = matchedProtocol;

    final protocolInt = int.parse(args.protocolHex, radix: 16);
    await dongleComm.dongleSetProtocol(protocolInt);
    await dongleComm.canSetTxHeader(args.txHeader);
    await dongleComm.canSetRxHeaderMask(args.rxHeader);
    print('✅ [Lane ${args.laneNumber} isolate] dongle configured — protocol=$matchedProtocol tx=${args.txHeader} rx=${args.rxHeader}');

    // Step 3: the actual flash, using the real flashInterpreter2 logic.
    uds = UDSDiagnostic(dongleComm, ECUCalculateSeedkey());

    final sklFN = args.seedKeyAlgo.replaceAll('-', '_');
    final jsonMap = jsonDecode(args.flashJson);
    final jsonData = FlashingMatrixData.fromJson(jsonMap);

    final seedkeyindx = SEEDKEYINDEXTYPE.values.firstWhere(
      (e) => e.toString().split('.').last.toUpperCase() == sklFN.toUpperCase(),
      orElse: () => SEEDKEYINDEXTYPE.values.first,
    );

    final flashConfig = FlashConfig(seedKeyIndex: seedkeyindx);

    // Report progress every 500ms by reading the SAME local counters
    // flashInterpreter2 updates internally (getRuntimeFlashPercent() —
    // confirmed pure local math, no network I/O, safe to poll from a
    // timer running alongside the flash on this isolate's own event loop).
    progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final pct = await uds!.getRuntimeFlashPercent();
        mainSendPort.send(PfsFlashMessage.progress(pct));
      } catch (_) {}
    });

    print('🚀 [Lane ${args.laneNumber} isolate] calling flashInterpreter2...');
    final result = await uds.flashInterpreter2(
      flashConfig,
      jsonData.noOfSectors ?? 0,
      jsonData.sectorData ?? [],
      args.interpreter,
    );

    progressTimer.cancel();
    print('🏁 [Lane ${args.laneNumber} isolate] result: $result');

    // Disconnect FIRST, confirm it's actually done, THEN tell the main
    // isolate — so it never starts reconnecting while this isolate's
    // socket is still open.
    await disconnectCleanly();
    mainSendPort.send(PfsFlashMessage.done(result));
  } catch (e, stack) {
    progressTimer?.cancel();
    print('❌ [Lane ${args.laneNumber} isolate] exception: $e');
    print(stack);
    await disconnectCleanly();
    mainSendPort.send(PfsFlashMessage.error(e.toString()));
  }
}

