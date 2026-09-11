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

/// type values:
///  'controlPort' — sent once, immediately, at isolate start. Carries
///                  the SendPort the main isolate must use to tell
///                  this isolate it's safe to close its socket.
///  'progress'    — periodic flash percent updates.
///  'done'        — flash finished successfully. Socket is still OPEN
///                  at this point — the main isolate gets the result
///                  right away, but the isolate will not touch the
///                  network again until told 'proceed'.
///  'error'       — flash failed / exception. Same "socket still
///                  open, waiting for proceed" contract as 'done'.
///  'closed'      — sent after the isolate has actually closed its
///                  socket gracefully, post-'proceed'. Safe to kill
///                  the isolate once this arrives.
class PfsFlashMessage {
  final String type;
  final double? percent;
  final String? result;
  final SendPort? controlPort;

  PfsFlashMessage.progress(this.percent)
      : type = 'progress',
        result = null,
        controlPort = null;
  PfsFlashMessage.done(this.result)
      : type = 'done',
        percent = null,
        controlPort = null;
  PfsFlashMessage.error(this.result)
      : type = 'error',
        percent = null,
        controlPort = null;
  PfsFlashMessage.controlPort(this.controlPort)
      : type = 'controlPort',
        percent = null,
        result = null;
  PfsFlashMessage.closed()
      : type = 'closed',
        percent = null,
        result = null,
        controlPort = null;
}

/// A dongle that never answers returns this exact fallback string
/// instead of throwing — so getting a non-null byte array back is
/// NOT proof the dongle actually spoke. This checks the response
/// content itself, so a silently-dead dongle fails fast instead of
/// being logged as a false success and dragging the whole flash
/// attempt down 20 seconds at a time on every subsequent command.
bool _looksLikeNoResponse(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return false;
  try {
    final text = String.fromCharCodes(bytes).toLowerCase();
    return text.contains('no resp') || text.contains('socket_closed');
  } catch (_) {
    return false;
  }
}

/// Call this from the main isolate with Isolate.spawn. It expects
/// [initialMessage] to be a 2-element List: [SendPort, PfsFlashArgs].
void pfsFlashIsolateEntry(List<dynamic> initialMessage) async {
  final SendPort mainSendPort = initialMessage[0] as SendPort;
  final PfsFlashArgs args = initialMessage[1] as PfsFlashArgs;

  Timer? progressTimer;
  UDSDiagnostic? uds;
  CommControllerIsolateSafe? comm;

  // The main isolate uses this port to tell us "it's safe now" once no
  // other lane is mid-flash. Hand its sendPort over first thing, before
  // doing anything else, so the main isolate has it on file for the
  // entire lifetime of this flash.
  final controlPort = ReceivePort();
  mainSendPort.send(PfsFlashMessage.controlPort(controlPort.sendPort));

  void reportError(String msg) {
    print('❌ [Lane ${args.laneNumber} isolate] $msg');
    mainSendPort.send(PfsFlashMessage.error(msg));
  }

  // Shared teardown path for BOTH the success and failure branches.
  // Whatever happened, hold the socket open and idle — generating zero
  // network traffic — until the main isolate confirms no other lane is
  // still actively flashing. Only then close it, so a finishing lane
  // can never disrupt one that's still mid-transfer, regardless of how
  // "clean" the close itself is.
  Future<void> waitThenDisconnect() async {
    try {
      print('⏸️ [Lane ${args.laneNumber} isolate] flash finished — '
          'holding connection open, waiting for "safe to close" signal...');
      await controlPort.first; // blocks until main isolate sends 'proceed'
    } catch (e) {
      print('⚠️ [Lane ${args.laneNumber} isolate] control port error '
          '(closing anyway): $e');
    } finally {
      controlPort.close();
    }

    try {
      await comm?.disconnect();
      print('🔌 [Lane ${args.laneNumber} isolate] socket closed gracefully '
          '(deferred until safe)');
    } catch (e) {
      print(
          '⚠️ [Lane ${args.laneNumber} isolate] graceful disconnect failed (non-fatal): $e');
    }

    mainSendPort.send(PfsFlashMessage.closed());
  }

  try {
    print(
        '🚀 [Lane ${args.laneNumber} isolate] starting — own fresh connection to ${args.host}:${args.port}');

    // Step 1: brand-new connection, created entirely inside this isolate.
    comm = CommControllerIsolateSafe();
    await comm.connectWifi1(
      host: args.host,
      port: args.port,
      selectedType: Connectivity.wiFi,
    );

    if (!comm.isConnected) {
      reportError('Could not connect to dongle at ${args.host}:${args.port}');
      await waitThenDisconnect();
      return;
    }

    final dongleComm =
        DongleComm(comm: comm as dynamic, isChannel: true, channelId: '00');

    print('🔐 [Lane ${args.laneNumber} isolate] sending Security Access...');
    final secAccessResp = await dongleComm.securityAccess();
    if (secAccessResp == null || _looksLikeNoResponse(secAccessResp)) {
      reportError(
          'Security Access failed — dongle at ${args.host}:${args.port} did not respond '
          '(likely not settled yet after reconnect)');
      await waitThenDisconnect();
      return;
    }
    print('✅ [Lane ${args.laneNumber} isolate] Security Access response: '
        '${secAccessResp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    // Get MAC ID is now treated as fatal too — if the dongle went
    // silent right after appearing to pass Security Access, it's not
    // genuinely there, and continuing just wastes minutes failing
    // later inside flashInterpreter instead of failing fast here.
    final macResp = await dongleComm.getWifiMacId();
    if (macResp != null && _looksLikeNoResponse(macResp)) {
      reportError(
          'Get MAC ID got no real response — dongle at ${args.host}:${args.port} is not answering');
      await waitThenDisconnect();
      return;
    }
    if (macResp != null) {
      print('✅ [Lane ${args.laneNumber} isolate] Get MAC ID response: '
          '${macResp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    } else {
      print(
          '⚠️ [Lane ${args.laneNumber} isolate] Get MAC ID returned null (non-fatal, continuing)');
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
      await waitThenDisconnect();
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

    print('🚀 [Lane ${args.laneNumber} isolate] calling flashInterpreter2...');
    final result = await uds.flashInterpreter(
      flashConfig,
      jsonData.noOfSectors ?? 0,
      jsonData.sectorData ?? [],
      args.interpreter,
    );

    progressTimer.cancel();
    progressTimer = null;
    print('🏁 [Lane ${args.laneNumber} isolate] result: $result');

    // Report the result to the main isolate RIGHT AWAY — the UI/lane
    // state machine should react to flash completion immediately. The
    // socket itself is deliberately left open and untouched until
    // waitThenDisconnect() gets the green light below.
    mainSendPort.send(PfsFlashMessage.done(result));

    await waitThenDisconnect();
  } catch (e, stack) {
    progressTimer?.cancel();
    print('❌ [Lane ${args.laneNumber} isolate] exception: $e');
    print(stack);
    reportError(e.toString());
    await waitThenDisconnect();
  }
}