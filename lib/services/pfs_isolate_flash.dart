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

class PfsFlashMessage {
  final String type;
  final double? percent;
  final String? result;
  PfsFlashMessage.progress(this.percent)
      : type = 'progress',
        result = null;
  PfsFlashMessage.done(this.result)
      : type = 'done',
        percent = null;
  PfsFlashMessage.error(this.result)
      : type = 'error',
        percent = null;
}

/// Call this from the main isolate with Isolate.spawn. It expects
/// [initialMessage] to be a 2-element List: [SendPort, PfsFlashArgs].
void pfsFlashIsolateEntry(List<dynamic> initialMessage) async {
  final SendPort mainSendPort = initialMessage[0] as SendPort;
  final PfsFlashArgs args = initialMessage[1] as PfsFlashArgs;

  Timer? progressTimer;
  UDSDiagnostic? uds;

  void reportError(String msg) {
    print('❌ [Lane ${args.laneNumber} isolate] $msg');
    mainSendPort.send(PfsFlashMessage.error(msg));
  }

  try {
    print(
        '🚀 [Lane ${args.laneNumber} isolate] starting — own fresh connection to ${args.host}:${args.port}');

    // Step 1: brand-new connection, created entirely inside this isolate.
    final comm = CommControllerIsolateSafe();
    await comm.connectWifi(
      host: args.host,
      port: args.port,
      selectedType: Connectivity.wiFi,
    );

    if (!comm.isConnected) {
      reportError('Could not connect to dongle at ${args.host}:${args.port}');
      return;
    }

    final dongleComm =
        DongleComm(comm: comm as dynamic, isChannel: true, channelId: '00');

    print('🔐 [Lane ${args.laneNumber} isolate] sending Security Access...');
    final secAccessResp = await dongleComm.securityAccess();
    if (secAccessResp == null) {
      reportError(
          'Security Access failed — no response from dongle at ${args.host}:${args.port}');
      return;
    }
    print('✅ [Lane ${args.laneNumber} isolate] Security Access response: '
        '${secAccessResp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    try {
      final macResp = await dongleComm.getWifiMacId();
      if (macResp != null) {
        print('✅ [Lane ${args.laneNumber} isolate] Get MAC ID response: '
            '${macResp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      } else {
        print(
            '⚠️ [Lane ${args.laneNumber} isolate] Get MAC ID returned null (non-fatal, continuing)');
      }
    } catch (e) {
      print(
          '⚠️ [Lane ${args.laneNumber} isolate] Get MAC ID failed (non-fatal, continuing): $e');
    }

    final protoValue = args.protocolName.replaceAll('-', '_');
    Protocol? matchedProtocol;
    for (final p in Protocol.values) {
      if (p.name == protoValue) {
        matchedProtocol = p;
        break;
      }
    }
    if (matchedProtocol == null) {
      reportError('No Protocol enum matches "${args.protocolName}"');
      return;
    }
    dongleComm.protocol = matchedProtocol;

    final protocolInt = int.parse(args.protocolHex, radix: 16);
    await dongleComm.dongleSetProtocol(protocolInt);
    await dongleComm.canSetTxHeader(args.txHeader);
    await dongleComm.canSetRxHeaderMask(args.rxHeader);
    await dongleComm.canStartPadding('00');

    print(
        '✅ [Lane ${args.laneNumber} isolate] dongle configured — protocol=$matchedProtocol tx=${args.txHeader} rx=${args.rxHeader}');

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

       progressTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        final pct = await uds!.getRuntimeFlashPercent();
        mainSendPort.send(PfsFlashMessage.progress(pct));
      },
    );
    ;

        print('🚀 [Lane ${args.laneNumber} isolate] calling flashInterpreter2...');
    final result = await uds.flashInterpreter(
      flashConfig,
      jsonData.noOfSectors ?? 0,
      jsonData.sectorData ?? [],
      args.interpreter,
    );

       progressTimer.cancel();
    print('🏁 [Lane ${args.laneNumber} isolate] result: $result');
    // Deliberately NOT calling comm.disconnect() here — for protocols
    // like this, a "graceful" disconnect can itself transmit one more
    // real command over the wire, which may be the actual disruptive
    // event hitting another lane's live transfer. Let the isolate just
    // end without sending any extra network traffic.
    mainSendPort.send(PfsFlashMessage.done(result));
  } 
  catch (e, stack) {
    progressTimer?.cancel();
    print('❌ [Lane ${args.laneNumber} isolate] exception: $e');
    print(stack);
    reportError(e.toString());
  }
}
