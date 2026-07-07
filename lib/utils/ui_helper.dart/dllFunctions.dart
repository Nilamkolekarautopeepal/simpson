import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:ap_diagnostic/enum/readDTCIndex.dart' show ReadDtcIndex;
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
import 'package:ap_diagnostic/models/readDtcResponseModel.dart';
import 'package:ap_diagnostic/structure/flash_structures.dart';
import 'package:ap_diagnostic/usd_diagnostic.dart';
import 'package:ap_dongle_comm/utils/commController.dart';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:ap_dongle_comm/utils/enums/protocol.dart';
import 'package:ap_dongle_comm/utils/model/sessionLogModel.dart';
import 'package:simpson/modals/all.models.dart' hide Protocol;
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/modals/pidDataset.model.dart';
import 'package:simpson/modals/staticData.dart';

class DLLFunctions {
  final DongleComm mDongleComm;
  CommController? comm;
  final UDSDiagnostic mUdsDiagnostic;
  DLLFunctions(this.mDongleComm, this.mUdsDiagnostic);

  String txHeaderTemp = '';
  String rxHeaderTemp = '';
  int protocolValue = 0;

  Future<String> setDongleProperties1() async {
    try {
      if (StaticData.ecuInfo.isEmpty) {
        print("❌ setDongleProperties1: StaticData.ecuInfo is empty");
        return "";
      }

      final firstEcu = StaticData.ecuInfo.first;

      if (firstEcu.protocol?.name == null ||
          firstEcu.protocol?.autopeepal == null ||
          firstEcu.txHeader == null ||
          firstEcu.rxHeader == null) {
        print("❌ setDongleProperties1: ECU missing protocol/txHeader/rxHeader "
            "(protocol=${firstEcu.protocol?.name}, "
            "autopeepal=${firstEcu.protocol?.autopeepal}, "
            "tx=${firstEcu.txHeader}, rx=${firstEcu.rxHeader})");
        return "";
      }

      final String value = firstEcu.protocol!.name!.replaceAll("-", "_");
      Protocol? matchedProtocol;
      for (final p in Protocol.values) {
        if (p.name == value) {
          matchedProtocol = p;
          break;
        }
      }
      if (matchedProtocol == null) {
        print("❌ setDongleProperties1: No Protocol enum matches API value "
            "\"$value\" — check Protocol enum definitions against API protocol names");
        return "";
      }
      mDongleComm.protocol = matchedProtocol;

      protocolValue = int.parse(firstEcu.protocol!.autopeepal!, radix: 16);
      txHeaderTemp = firstEcu.txHeader!;
      rxHeaderTemp = firstEcu.rxHeader!;

      print("🔹 setDongleProperties1: protocol=$matchedProtocol "
          "(0x${protocolValue.toRadixString(16)}), "
          "tx=$txHeaderTemp, rx=$rxHeaderTemp");

      await mDongleComm.dongleSetProtocol(protocolValue);
      await mDongleComm.canSetTxHeader(txHeaderTemp);
      await mDongleComm.canSetRxHeaderMask(rxHeaderTemp);
      await mDongleComm.canStartPadding("00");

      final dynamic firmwareResult = await mDongleComm.getFirmwareVersion();

      if (firmwareResult == null) {
        print("❌ setDongleProperties1: getFirmwareVersion() returned null");
        return "";
      }
      if (firmwareResult is! Uint8List) {
        print("❌ setDongleProperties1: unexpected firmware response type "
            "(${firmwareResult.runtimeType})");
        return "";
      }
      if (firmwareResult.length < 6) {
        print("❌ setDongleProperties1: firmware response too short "
            "(${firmwareResult.length} bytes)");
        return "";
      }

      final version = "${firmwareResult[3].toString().padLeft(2, '0')}."
          "${firmwareResult[4].toString().padLeft(2, '0')}."
          "${firmwareResult[5].toString().padLeft(2, '0')}";

      print("✅ setDongleProperties1: firmware version = $version");
      return version;
    } catch (e, stack) {
      print("❌ setDongleProperties1 exception: $e");
      print(stack);
      return "";
    }
  }

  /// Single-dongle path only — no connectivity/RP1210 branching.
  Future<void> setDongleProperties(
      String protocolName, String txHeaderTemp, String rxHeaderTemp) async {
    try {
      print(
          "📡 [DEBUG] setDongleProperties Start | Protocol: $protocolName, TX: $txHeaderTemp, RX: $rxHeaderTemp");

      final protocolInt = int.parse(protocolName, radix: 16);

      await mDongleComm.dongleSetProtocol(protocolInt);
      print("🔸 Protocol set to 0x${protocolInt.toRadixString(16)}");

      await mDongleComm.canSetTxHeader(txHeaderTemp);
      print("🔸 TX Header set: $txHeaderTemp");

      await mDongleComm.canSetRxHeaderMask(rxHeaderTemp);
      print("🔸 RX Mask set: $rxHeaderTemp");

      print("✅ [DEBUG] setDongleProperties completed successfully.");
    } catch (ex, stack) {
      print("❌ [ERROR] setDongleProperties failed: $ex");
      print(stack);
    }
  }

  Uint8List hexToBytes(String hex) {
    hex = hex.replaceAll(" ", "");

    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }

    return Uint8List.fromList(bytes);
  }

  Future<void> disconnectVCI1() async {
    try {
      final comm = mDongleComm.comm1;

      if (comm == null) {
        print("⚠️ comm is null, skipping VCI disconnect");
        return;
      }

      print("🔄 Sending Dongle Reset...");
      await comm.disconnectVCI();

      print("✅ VCI disconnected successfully");
    } catch (e, stack) {
      print("❌ Error disconnecting VCI: $e");
      print(stack);
    }
  }

  Future<String> checkEcuStatus() async {
    try {
      final resp = await mDongleComm.can2xTxRx(2, '1003');
      return resp.ecuResponseStatus ?? '';
    } catch (_) {
      return '';
    }
  }

  List<SessionLogsModel> getLogs() {
    print("DLLFunctions.getLogs: Start");
    print("DLLFunctions.getLogs: mDongleComm exists");

    final logs = mDongleComm.logs;
    print("DLLFunctions.getLogs: raw logs = $logs");

    final List<SessionLogsModel> sessionLogsModel = [];
    for (final item in logs) {
      print("DLLFunctions.getLogs: processing item = $item");
      sessionLogsModel.add(SessionLogsModel(
        header: item.header,
        message: item.message,
        status: item.status == "NOERROR" ? '' : item.status,
      ));
    }

    print(
        "DLLFunctions.getLogs: Finished, returning ${sessionLogsModel.length} items");
    return sessionLogsModel;
  }

  void clearLogs() {
    print("DLLFunctions.clearLogs: Start");
    mDongleComm.logs = <SessionLogsModel>[];
    print("DLLFunctions.clearLogs: Logs cleared");
  }

  Future<String> getFirmware() async {
    try {
      final response = await mDongleComm.getFirmwareVersion();

      if (response == null) {
        print("Firmware response is null");
        return '';
      }

      if (response.length < 6) {
        print("Firmware response too short: $response");
        return '';
      }

      final version = '${response[3].toString().padLeft(2, '0')}.'
          '${response[4].toString().padLeft(2, '0')}.'
          '${response[5].toString().padLeft(2, '0')}';

      print("Parsed Firmware Version: $version");

      return version;
    } catch (e) {
      print("Firmware Exception: $e");
      return '';
    }
  }

  Future<bool> updateFirmware(String command) async {
    try {
      final hexCommand = toHex(command);
      final firmwareVersion = await mDongleComm.updateFirmware(hexCommand);

      return firmwareVersion == "20010000E1F0";
    } catch (e) {
      return false;
    }
  }

  /// Converts a string to its hexadecimal representation (like C# ToHex)
  String toHex(String input) {
    final buffer = StringBuffer();
    for (final c in input.codeUnits) {
      buffer.write(c.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  Future<ReadDtcResponseModel?> readDtc(String dtcIndex) async {
    print("🔹 [readDtc] Start - Received index string: $dtcIndex");

    try {
      ReadDtcIndex index = ReadDtcIndex.values.firstWhere(
        (e) => e.toString().split('.').last == dtcIndex,
        orElse: () {
          print("❌ No matching ReadDtcIndex enum found for: $dtcIndex");
          throw Exception("Invalid DTC index: $dtcIndex");
        },
      );
      print("✅ [readDtc] Mapped string '$dtcIndex' to enum: $index");

      ReadDtcResponseModel readDtcResponseModel = ReadDtcResponseModel();

      int attempt = 0;

      do {
        attempt++;
        print("⏳ [readDtc] Attempt #$attempt to read DTC...");

        final rawResponse = await mUdsDiagnostic.readDTC(index);

        readDtcResponseModel.dtcs = rawResponse.dtcs;
        readDtcResponseModel.status = rawResponse.status;
        readDtcResponseModel.noofdtc = rawResponse.noofdtc;

        print("📡 [readDtc] Status received: ${readDtcResponseModel.status}");
        print(
            "📡 [readDtc] Number of DTCs: ${readDtcResponseModel.dtcs?.length ?? 0}");

        if (readDtcResponseModel.status ==
                "GENERALERROR_INVALIDRESPFROMDONGLE" ||
            readDtcResponseModel.status?.contains("BUSY") == true) {
          print("⏳ [readDtc] ECU busy or invalid response, retrying...");
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          break;
        }
      } while (attempt < 10);

      if (readDtcResponseModel.dtcs != null) {
        print(
            "✅ [readDtc] Success - DTCs parsed: ${readDtcResponseModel.dtcs!.length}");
      } else {
        print("⚠️ [readDtc] Warning - dtcs array is null");
      }

      return readDtcResponseModel;
    } catch (e, st) {
      print("❌ [readDtc] EXCEPTION: $e");
      print("❌ StackTrace: $st");
      return null;
    }
  }

  List<Code> readPID(pid_ds.PidDataset dataset) {
    final List<Code> pidCodes = [];

    for (final result in dataset.results ?? <pid_ds.Result>[]) {
      for (final code in result.codes ?? <pid_ds.Code>[]) {
        final variables = <PiCodeVariable>[];

        for (final v in code.piCodeVariable ?? <pid_ds.PiCodeVariable>[]) {
          final dynamic rawStart = v.startBitPosition;
          final int startBit = rawStart == null
              ? 0
              : rawStart is int
                  ? rawStart
                  : rawStart is num
                      ? rawStart.toInt()
                      : int.tryParse(rawStart.toString()) ?? 0;

          final dynamic rawEnd = v.endBitPosition;
          final int endBit = rawEnd == null
              ? 0
              : rawEnd is int
                  ? rawEnd
                  : rawEnd is num
                      ? rawEnd.toInt()
                      : int.tryParse(rawEnd.toString()) ?? 0;

          final messageTypeName = v.messageType == null
              ? null
              : pid_ds.messageTypeValues.reverse[v.messageType];

          variables.add(PiCodeVariable(
            id: v.id,
            shortName: v.shortName,
            bytePosition: v.bytePosition,
            length: v.length,
            bitcoded: v.bitcoded ?? false,
            startBitPosition: startBit,
            endBitPosition: endBit,
            resolution: v.resolution ?? 1.0,
            offset: v.offset ?? 0.0,
            messageType: messageTypeName == null
                ? null
                : MessageType.values.firstWhere(
                    (e) => e.name == messageTypeName,
                    orElse: () => MessageType.ASCII,
                  ),
            messages: (v.messages ?? <pid_ds.Message>[])
                .map((m) => Message(
                      code: m.code ?? '',
                      message: m.message ?? '',
                    ))
                .toList(),
          ));
        }

        pidCodes.add(Code(
          id: code.id,
          code: code.code,
          memoryAddress: code.memoryAddress ?? false,
          piCodeVariable: variables,
        ));
      }
    }
    return pidCodes;
  }

  String byteArrayToString(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  void cancel() {
    throw UnimplementedError('Cancel() is not implemented yet.');
  }

  Future<String?> startECUFlashing(
    String flashJson,
    String interpreter,
    Ecu ecu2,
    String sklFN,
  ) async {
    try {
      print("🚀 [FLASH] ===== START ECU FLASHING =====");

      print("📥 [INPUT] sklFN (raw): $sklFN");
      print("📥 [INPUT] interpreter: $interpreter");
      print("📥 [INPUT] flashJson length: ${flashJson.length}");

      sklFN = sklFN.replaceAll('-', '_');
      print("🔄 [PROCESS] sklFN normalized: $sklFN");

      final jsonMap = jsonDecode(flashJson);
      print("📦 [JSON] Parsed successfully");

      final jsonData = FlashingMatrixData.fromJson(jsonMap);
      print("📦 [JSON] noOfSectors: ${jsonData.noOfSectors}");
      print("📦 [JSON] sectorData count: ${jsonData.sectorData?.length}");

      final seedkeyindx = SEEDKEYINDEXTYPE.values.firstWhere(
        (e) {
          final enumName = e.toString().split('.').last;
          print("🔍 [ENUM CHECK] comparing $enumName with $sklFN");
          return enumName.toUpperCase() == sklFN.toUpperCase();
        },
        orElse: () {
          print("⚠️ [ENUM] No match found, using default");
          return SEEDKEYINDEXTYPE.values.first;
        },
      );

      print("✅ [ENUM] Selected: $seedkeyindx");

      final flashConfig = FlashConfig(
        seedKeyIndex: seedkeyindx,
      );

      print("⚙️ [CONFIG] FlashConfig created");

      print("📡 [UDS] Starting tester present...");
      await startTesterPresent();
      print("✅ [UDS] Tester present started");

      print("🚀 [FLASH] Calling flashInterpreter...");
      final response = await mUdsDiagnostic.flashInterpreter(
        flashConfig,
        jsonData.noOfSectors ?? 0,
        jsonData.sectorData!,
        interpreter,
      );

      print("📥 [FLASH RESPONSE]: $response");

      print("🛑 [UDS] Stopping tester present...");
      await stopTesterPresent();
      print("✅ [UDS] Tester present stopped");

      print("🎉 [FLASH] ===== COMPLETED SUCCESS =====");

      return response;
    } catch (e, stackTrace) {
      print("❌ [ERROR] Flashing failed: $e");
      print("📍 [STACKTRACE]: $stackTrace");

      return null;
    }
  }

  double? flashingPercent;

  Future<void> startTesterPresent() async {
    await mDongleComm.canStartTP();
  }

  Future<void> stopTesterPresent() async {
    await mDongleComm.canStopTP();
  }

  Future<void> txHeader(String txHeader) async {
    final setHeader = await mDongleComm.canSetTxHeader(txHeader);
    final headerResponse = byteArrayToString(setHeader);
    print(
        "------DTC TX Header Set------ $txHeader , Header Response-- $headerResponse");
  }

  Future<void> rxHeader(String rxHeader) async {
    final setHeader = await mDongleComm.canSetRxHeaderMask(rxHeader);
    final headerResponse = byteArrayToString(setHeader);
    print(
        "------DTC RX Header Set------ $rxHeader , RX Header Response-- $headerResponse");
  }

  static String convertedByteToString(List<int>? bytes) {
    if (bytes == null) return "";
    return utf8.decode(bytes);
  }

  Future<double> flashingData() async {
    try {
      double flashingPercent = await mUdsDiagnostic.getRuntimeFlashPercent();
      return flashingPercent;
    } catch (e) {
      return 0;
    }
  }

  Future<double> resetPercentage() async {
    try {
      await mUdsDiagnostic.resetPercentage();
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> writeSSID(String routerSSID) async {
    try {
      Uint8List? setHotspot =
          await mDongleComm.wifiWriteSSID(toHex(routerSSID));

      if (setHotspot == null) {
        print("SSID response is NULL");
        return false;
      }

      String resp = byteArrayToString(setHotspot);
      print("SSID Response: $resp");

      return resp.contains("00E1F0");
    } catch (e) {
      print("SSID Error: $e");
      return false;
    }
  }

  Future<bool> writePassword(String routerPassword) async {
    try {
      Uint8List? setHotspot =
          await mDongleComm.wifiWritePassword(toHex(routerPassword));

      if (setHotspot == null) {
        print("Password response is NULL");
        return false;
      }

      String resp = byteArrayToString(setHotspot);
      print("Password Response: $resp");

      return resp.contains("00E1F0");
    } catch (e) {
      print("Password Error: $e");
      return false;
    }
  }
}

extension HexUtils on String {
  Uint8List toReversedUint32() {
    final value = int.parse(this, radix: 16);
    final data = ByteData(4)..setUint32(0, value);
    return Uint8List.fromList(
      data.buffer.asUint8List().reversed.toList(),
    );
  }
}
