import 'dart:async';
import 'dart:isolate';

import 'package:simpson/modals/all.models.dart';
import 'package:simpson/services/connectionWifiService.dart';

/// Everything the isolate needs to connect its own dongle socket and
/// run one flash — all primitives/strings, so this is safe to send
/// across the isolate boundary via Isolate.spawn's argument.
class FlashIsolateRequest {
  final SendPort sendPort;
  final String ip;
  final String channelId;
  final String protocolName;
  final String protocolHex;
  final String txHeader;
  final String rxHeader;
  final int? ecuId;
  final String ecuName;
  final String channel;
  final String seedKeyAlgo;
  final String flashJson;
  final String sequenceContent;

  FlashIsolateRequest({
    required this.sendPort,
    required this.ip,
    required this.channelId,
    required this.protocolName,
    required this.protocolHex,
    required this.txHeader,
    required this.rxHeader,
    required this.ecuId,
    required this.ecuName,
    required this.channel,
    required this.seedKeyAlgo,
    required this.flashJson,
    required this.sequenceContent,
  });
}

/// Messages sent back from the isolate to the main isolate while a
/// flash is running.
class FlashProgressMessage {
  final double percent;
  FlashProgressMessage(this.percent);
}

class FlashLogMessage {
  final String text;
  FlashLogMessage(this.text);
}

class FlashResultMessage {
  final String result;
  FlashResultMessage(this.result);
}

/// Runs entirely inside a spawned isolate: connects its OWN fresh
/// dongle socket (the package's own connect logic already tears down
/// any stale prior session on this same IP automatically — you can see
/// "Starting full disconnect... Full disconnect completed" in the logs
/// every time a connect happens, even for a brand new connection), then
/// configures and flashes the ECU. Progress/log lines stream back to
/// the main isolate via sendPort so the UI can keep updating live.
///
/// This is the actual fix for parallel-lane flash speed: the JSON
/// conversion being isolated earlier was necessary but not sufficient
/// — the real bottleneck is this function's body (thousands of UDS
/// message exchanges, each with real Dart-side frame building/parsing)
/// which previously ran on the single shared main isolate for every
/// lane. Running it here means N lanes' flashes genuinely execute on N
/// separate OS threads at the same time.
Future<void> flashEcuIsolateEntry(FlashIsolateRequest request) async {
  final sendPort = request.sendPort;
  Timer? progressTimer;

  try {
    sendPort.send(FlashLogMessage('[Isolate] Connecting to ${request.ip} (channelId=${request.channelId})…'));

    final connectionWifi = ConnectionWifi();
    final connected = await connectionWifi.connectDongleForLane(request.ip, channelId: request.channelId);

    if (connected == null) {
      sendPort.send(FlashResultMessage('Failed to connect to dongle at ${request.ip}'));
      return;
    }

    final dll = connected.dll;
    sendPort.send(FlashLogMessage('[Isolate] Connected. MAC: ${connected.macId}'));

    await dll.setDongleProperties(
      request.protocolName,
      request.protocolHex,
      request.txHeader,
      request.rxHeader,
    );
    sendPort.send(FlashLogMessage('[Isolate] Dongle configured — starting flash…'));

    progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final percent = await dll.flashingData();
        sendPort.send(FlashProgressMessage(percent));
      } catch (_) {
        // Ignore — the flash's own final result is what actually matters.
      }
    });

    final ecu = Ecu(
      id: request.ecuId,
      name: request.ecuName,
      txHeader: request.txHeader,
      rxHeader: request.rxHeader,
      channel: request.channel,
      protocol: Protocol(name: request.protocolName, autopeepal: request.protocolHex),
      seedkeyalgoFnIndex: FnIndex(value: request.seedKeyAlgo),
    );

    final result = await dll.startECUFlashing(
      request.flashJson,
      request.sequenceContent,
      ecu,
      request.seedKeyAlgo,
    );

    sendPort.send(FlashResultMessage(result ?? 'Unknown error'));
  } catch (e) {
    sendPort.send(FlashResultMessage(e.toString()));
  } finally {
    progressTimer?.cancel();
  }
}
