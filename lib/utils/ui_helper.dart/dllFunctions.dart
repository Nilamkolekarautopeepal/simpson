import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:ap_diagnostic/enum/readDTCIndex.dart' show ReadDtcIndex, ClearDtcIndex;
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/enum/writeParameter.dart';
import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
import 'package:ap_diagnostic/models/readDtcResponseModel.dart';
import 'package:ap_diagnostic/models/readParameterPIDModel.dart'
show ReadParameterPID, SelectedParameterMessage, PidVariable;
import 'package:ap_diagnostic/models/readParameterResponseModel.dart';
import 'package:ap_diagnostic/models/writeParameterPIDModel.dart';
import 'package:ap_diagnostic/structure/flash_structures.dart';
import 'package:ap_diagnostic/usd_diagnostic.dart';
import 'package:ap_dongle_comm/utils/commController.dart';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:ap_dongle_comm/utils/enums/protocol.dart';
import 'package:ap_dongle_comm/utils/model/sessionLogModel.dart';
import 'package:simpson/modals/all.models.dart' hide Protocol;
import 'package:simpson/modals/liveParameter_model.dart';
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/modals/staticData.dart';
import '../../modals/writeParameter_model.dart';

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
        print("ÔØî setDongleProperties1: StaticData.ecuInfo is empty");
        return "";
      }

      final firstEcu = StaticData.ecuInfo.first;

      if (firstEcu.protocol?.name == null ||
          firstEcu.protocol?.autopeepal == null ||
          firstEcu.txHeader == null ||
          firstEcu.rxHeader == null) {
        print(
            "ÔØî setDongleProperties1: ECU missing protocol/txHeader/rxHeader "
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
        print("ÔØî setDongleProperties1: No Protocol enum matches API value "
            "\"$value\" ÔÇö check Protocol enum definitions against API protocol names");
        return "";
      }
      mDongleComm.protocol = matchedProtocol;

      protocolValue = int.parse(firstEcu.protocol!.autopeepal!, radix: 16);
      txHeaderTemp = firstEcu.txHeader!;
      rxHeaderTemp = firstEcu.rxHeader!;

      print("­ƒö╣ setDongleProperties1: protocol=$matchedProtocol "
          "(0x${protocolValue.toRadixString(16)}), "
          "tx=$txHeaderTemp, rx=$rxHeaderTemp");

      await mDongleComm.dongleSetProtocol(protocolValue);
      await mDongleComm.canSetTxHeader(txHeaderTemp);
      await mDongleComm.canSetRxHeaderMask(rxHeaderTemp);
      await mDongleComm.canStartPadding("00");

      final dynamic firmwareResult = await mDongleComm.getFirmwareVersion();

      if (firmwareResult == null) {
        print("ÔØî setDongleProperties1: getFirmwareVersion() returned null");
        return "";
      }
      if (firmwareResult is! Uint8List) {
        print("ÔØî setDongleProperties1: unexpected firmware response type "
            "(${firmwareResult.runtimeType})");
        return "";
      }
      if (firmwareResult.length < 6) {
        print("ÔØî setDongleProperties1: firmware response too short "
            "(${firmwareResult.length} bytes)");
        return "";
      }

      final version = "${firmwareResult[3].toString().padLeft(2, '0')}."
          "${firmwareResult[4].toString().padLeft(2, '0')}."
          "${firmwareResult[5].toString().padLeft(2, '0')}";

      print("Ô£à setDongleProperties1: firmware version = $version");
      return version;
    } catch (e, stack) {
      print("ÔØî setDongleProperties1 exception: $e");
      print(stack);
      return "";
    }
  }

  Future<String?> clearDtc(String dtcIndex) async {
    print("🔹 [clearDtc] Start - Received index string: $dtcIndex");

    try {
      // Matches C#'s alias handling:
      //   if (dtc_index == "UDS-4BYTES") dtc_index = "UDS_4BYTES";
      // plus normalizing any other dashes to underscores so the enum
      // lookup below succeeds regardless of which separator the API sent.
      String normalized = dtcIndex == 'UDS-4BYTES'
          ? 'UDS_4BYTES'
          : dtcIndex.replaceAll('-', '_');

      if (normalized != dtcIndex) {
        print("🔧 [clearDtc] Normalized '$dtcIndex' -> '$normalized'");
      }

      final ClearDtcIndex index = ClearDtcIndex.values.firstWhere(
        (e) => e.toString().split('.').last == normalized,
        orElse: () {
          print("❌ No matching ClearDtcIndex enum found for: $normalized");
          throw Exception("Invalid Clear DTC index: $normalized");
        },
      );
      print("✅ [clearDtc] Mapped string '$normalized' to enum: $index");

      final result = await mUdsDiagnostic.clearDTC(index);

      if (result == null) {
        print("⚠️ [clearDtc] clearDTC returned null");
        return null;
      }

      // result is the raw ResponseArrayStatus-style object from
      // UDSDiagnostic.clearDTC() — pull the status field directly via
      // dynamic dispatch, same field the C# version extracts through
      // JsonConvert as Response.ECUResponseStatus.
      final status = (result as dynamic).ecuResponseStatus as String?;

      print("📡 [clearDtc] Status received: $status");

      return status;
    } catch (e, st) {
      print("❌ [clearDtc] EXCEPTION: $e");
      print("❌ StackTrace: $st");
      return null;
    }
  }

  /// Single-dongle path only ÔÇö no connectivity/RP1210 branching.
  // Future<void> setDongleProperties(
  //     String protocolName, String txHeaderTemp, String rxHeaderTemp) async {
  //   try {
  //     print(
  //         "­ƒôí [DEBUG] setDongleProperties Start | Protocol: $protocolName, TX: $txHeaderTemp, RX: $rxHeaderTemp");

  //     final protocolInt = int.parse(protocolName, radix: 16);

  //     await mDongleComm.dongleSetProtocol(protocolInt);
  //     print("­ƒö© Protocol set to 0x${protocolInt.toRadixString(16)}");

  //     await mDongleComm.canSetTxHeader(txHeaderTemp);
  //     print("­ƒö© TX Header set: $txHeaderTemp");

  //     await mDongleComm.canSetRxHeaderMask(rxHeaderTemp);
  //     print("­ƒö© RX Mask set: $rxHeaderTemp");

  //     print("Ô£à [DEBUG] setDongleProperties completed successfully.");
  //   } catch (ex, stack) {
  //     print("ÔØî [ERROR] setDongleProperties failed: $ex");
  //     print(stack);
  //   }
  // }
  /// Single-dongle path only ÔÇö no connectivity/RP1210 branching.
 Future<void> setDongleProperties(String protocolNameRaw, String protocolHex,
    String txHeaderTemp, String rxHeaderTemp) async {
  try {
    print(
        "📍 [DEBUG] setDongleProperties Start | ProtocolName: $protocolNameRaw, Hex: $protocolHex, TX: $txHeaderTemp, RX: $rxHeaderTemp");

    final String value = protocolNameRaw.replaceAll("-", "_");
    Protocol? matchedProtocol;
    for (final p in Protocol.values) {
      if (p.name == value) {
        matchedProtocol = p;
        break;
      }
    }
    if (matchedProtocol == null) {
      print("❌ setDongleProperties: no Protocol enum matches \"$value\"");
      throw Exception("Unsupported protocol: $protocolNameRaw");
    }
    mDongleComm.protocol = matchedProtocol;
    print("🔍 [DEBUG] mDongleComm.protocol assigned: $matchedProtocol");

    final protocolInt = int.parse(protocolHex, radix: 16);
    await mDongleComm.dongleSetProtocol(protocolInt);
    print("🔧 Protocol set to 0x${protocolInt.toRadixString(16)} ($matchedProtocol)");

    await mDongleComm.canSetTxHeader(txHeaderTemp);
    print("🔧 TX Header set: $txHeaderTemp");

    await mDongleComm.canSetRxHeaderMask(rxHeaderTemp);
    print("🔧 RX Mask set: $rxHeaderTemp");

    // ✅ Must re-arm padding any time TX/RX headers are (re)configured —
    // matches setDongleProperties1(), which does this on connect/reconnect.
    // Without this, the very next send on this header config can go into
    // a channel with no flow-control padding and simply time out with
    // "No Resp From Dongle" (this was the flash-start failure).
    await mDongleComm.canStartPadding("00");
    print("🔧 CAN padding (re)started");

    print("✅ [DEBUG] setDongleProperties completed successfully.");
  } catch (ex, stack) {
    print("❌ [ERROR] setDongleProperties failed: $ex");
    print(stack);
    rethrow;
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
      final comm = mDongleComm.comm;

      if (comm == null) {
        print("ÔÜá´©Å comm is null, skipping VCI disconnect");
        return;
      }

      print("­ƒöä Sending Dongle Reset...");
      await comm.disconnect();

      print("Ô£à VCI disconnected successfully");
    } catch (e, stack) {
      print("ÔØî Error disconnecting VCI: $e");
      print(stack);
    }
  }

  Future<String> checkEcuStatus() async {
    try {
      final resp = await mDongleComm.can2xTxRx(2,( '1003'));
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

  // Future<ReadDtcResponseModel?> readDtc(String dtcIndex) async {
  //   print("­ƒö╣ [readDtc] Start - Received index string: $dtcIndex");

  //   try {
  //     ReadDtcIndex index = ReadDtcIndex.values.firstWhere(
  //       (e) => e.toString().split('.').last == dtcIndex,
  //       orElse: () {
  //         print("ÔØî No matching ReadDtcIndex enum found for: $dtcIndex");
  //         throw Exception("Invalid DTC index: $dtcIndex");
  //       },
  //     );
  //     print("Ô£à [readDtc] Mapped string '$dtcIndex' to enum: $index");

  //     ReadDtcResponseModel readDtcResponseModel = ReadDtcResponseModel();

  //     int attempt = 0;

  //     do {
  //       attempt++;
  //       print("ÔÅ│ [readDtc] Attempt #$attempt to read DTC...");

  //       final rawResponse = await mUdsDiagnostic.readDTC(index);

  //       readDtcResponseModel.dtcs = rawResponse.dtcs;
  //       readDtcResponseModel.status = rawResponse.status;
  //       readDtcResponseModel.noofdtc = rawResponse.noofdtc;

  //       print("­ƒôí [readDtc] Status received: ${readDtcResponseModel.status}");
  //       print(
  //           "­ƒôí [readDtc] Number of DTCs: ${readDtcResponseModel.dtcs?.length ?? 0}");

  //       if (readDtcResponseModel.status ==
  //               "GENERALERROR_INVALIDRESPFROMDONGLE" ||
  //           readDtcResponseModel.status?.contains("BUSY") == true) {
  //         print("ÔÅ│ [readDtc] ECU busy or invalid response, retrying...");
  //         await Future.delayed(const Duration(milliseconds: 100));
  //       } else {
  //         break;
  //       }
  //     } while (attempt < 10);

  //     if (readDtcResponseModel.dtcs != null) {
  //       print(
  //           "Ô£à [readDtc] Success - DTCs parsed: ${readDtcResponseModel.dtcs!.length}");
  //     } else {
  //       print("ÔÜá´©Å [readDtc] Warning - dtcs array is null");
  //     }

  //     return readDtcResponseModel;
  //   } catch (e, st) {
  //     print("ÔØî [readDtc] EXCEPTION: $e");
  //     print("ÔØî StackTrace: $st");
  //     return null;
  //   }
  // }

  Future<ReadDtcResponseModel?> readDtc(String dtcIndex) async {
    print("­ƒö╣ [readDtc] Start - Received index string: $dtcIndex");

    try {
      // Normalize to match C# ReadDtc(string dtc_index):
      //   - "UDS-2BYTE-DTC" is a special legacy alias -> "UDS_2BYTE12_DTC"
      //   - all other dashes get replaced with underscores
      String normalized = dtcIndex == 'UDS-2BYTE-DTC'
          ? 'UDS_2BYTE12_DTC'
          : dtcIndex.replaceAll('-', '_');

      if (normalized != dtcIndex) {
        print("­ƒöº [readDtc] Normalized '$dtcIndex' -> '$normalized'");
      }

      ReadDtcIndex index = ReadDtcIndex.values.firstWhere(
        (e) => e.toString().split('.').last == normalized,
        orElse: () {
          print("ÔØî No matching ReadDtcIndex enum found for: $normalized");
          throw Exception("Invalid DTC index: $normalized");
        },
      );
      print("Ô£à [readDtc] Mapped string '$normalized' to enum: $index");

      ReadDtcResponseModel readDtcResponseModel = ReadDtcResponseModel();

      int attempt = 0;

      do {
        attempt++;
        print("ÔÅ│ [readDtc] Attempt #$attempt to read DTC...");

        final rawResponse = await mUdsDiagnostic.readDTC(index);

        readDtcResponseModel.dtcs = rawResponse.dtcs;
        readDtcResponseModel.status = rawResponse.status;
        readDtcResponseModel.noofdtc = rawResponse.noofdtc;

        print("­ƒôí [readDtc] Status received: ${readDtcResponseModel.status}");
        print(
            "­ƒôí [readDtc] Number of DTCs: ${readDtcResponseModel.dtcs?.length ?? 0}");

        if (readDtcResponseModel.status ==
                "GENERALERROR_INVALIDRESPFROMDONGLE" ||
            readDtcResponseModel.status?.contains("BUSY") == true) {
          print("ÔÅ│ [readDtc] ECU busy or invalid response, retrying...");
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          break;
        }
      } while (attempt < 10);

      if (readDtcResponseModel.dtcs != null) {
        print(
            "Ô£à [readDtc] Success - DTCs parsed: ${readDtcResponseModel.dtcs!.length}");
      } else {
        print("ÔÜá´©Å [readDtc] Warning - dtcs array is null");
      }

      return readDtcResponseModel;
    } catch (e, st) {
      print("ÔØî [readDtc] EXCEPTION: $e");
      print("ÔØî StackTrace: $st");
      return null;
    }
  }

  Future<List<ReadParameterResponse>?> readPid(
      List<pid_ds.Code> pidList) async {
    try {
      print("­ƒÜÇ readPid() called");
      print("­ƒôî Total PID requested: ${pidList.length}");

      // Build ReadParameterPID list
      List<ReadParameterPID> list = [];

      for (var item in pidList) {
        print("Ô×í´©Å Building PID: ${item.id}, Code: ${item.code}");

        List<PidVariable> variables = [];

        for (var vari in item.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
          int startBit = vari.startBitPosition ?? 0;
          int endBit = vari.endBitPosition ?? 0;
          int noOfBits = endBit - startBit + 1;

          print(
              "   ­ƒö╣ Variable ID: ${vari.id}, StartBit: $startBit, EndBit: $endBit");

          final messages = (vari.messages ?? <pid_ds.Message>[])
              .map((m) => SelectedParameterMessage(
                    code: m.code,
                    message: m.message,
                  ))
              .toList();

          final pidVariable = PidVariable(
            datatype: vari.messageType == null
                ? null
                : pid_ds.messageTypeValues.reverse[vari.messageType],
            isBitcoded: vari.bitcoded ?? false,
            noofBits: noOfBits,
            noOfBytes: vari.length ?? 0,
            offset: vari.offset ?? 0.0,
            resolution: vari.resolution ?? 1.0,
            startBit: startBit,
            startByte: vari.bytePosition ?? 0,
            pidNumber: vari.id ?? 0,
            pidName: vari.shortName ?? "",
            messages: messages,
          );

          variables.add(pidVariable);
        }

        list.add(
          ReadParameterPID(
            pidId: item.id ?? 0,
            variables: variables,
            totalLen: (item.code?.length ?? 0) ~/ 2,
            pid: item.code ?? "",
          ),
        );
      }

      print("­ƒôñ Reading ${list.length} PID(s) directly via dongle comm...");

      final result = await mUdsDiagnostic.readParameters(list.length, list);

      print("­ƒôÑ Result count: ${result.length}");
      for (var item in result) {
        print("Ô×í´©Å PID: ${item.pidId}, Status: ${item.status}");
      }

      return result;
    } catch (ex) {
      print("­ƒöÑ Error reading PIDs: $ex");
      return null;
    }
  }

  String byteArrayToString(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Future<double> resetPercentage() async {
    try {
      await mUdsDiagnostic.resetPercentage();
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> startECUFlashing(
    String flashJson,
    String interpreter,
    Ecu ecu2,
    String sklFN,
  ) async {
    try {
      print("­ƒÜÇ [FLASH] ===== START ECU FLASHING =====");

      print("­ƒôÑ [INPUT] sklFN (raw): $sklFN");
      print("­ƒôÑ [INPUT] interpreter: $interpreter");
      print("­ƒôÑ [INPUT] flashJson length: ${flashJson.length}");

      sklFN = sklFN.replaceAll('-', '_');
      print("­ƒöä [PROCESS] sklFN normalized: $sklFN");

      final jsonMap = jsonDecode(flashJson);
      print("­ƒôª [JSON] Parsed successfully");

      final jsonData = FlashingMatrixData.fromJson(jsonMap);
      print("­ƒôª [JSON] noOfSectors: ${jsonData.noOfSectors}");
      print("­ƒôª [JSON] sectorData count: ${jsonData.sectorData?.length}");

      final seedkeyindx = SEEDKEYINDEXTYPE.values.firstWhere(
        (e) {
          final enumName = e.toString().split('.').last;
          print("­ƒöì [ENUM CHECK] comparing $enumName with $sklFN");
          return enumName.toUpperCase() == sklFN.toUpperCase();
        },
        orElse: () {
          print("ÔÜá´©Å [ENUM] No match found, using default");
          return SEEDKEYINDEXTYPE.values.first;
        },
      );

      print("Ô£à [ENUM] Selected: $seedkeyindx");

      final flashConfig = FlashConfig(
        seedKeyIndex: seedkeyindx,
      );

      // print("ÔÜÖ´©Å [CONFIG] FlashConfig created");


  //     print("­ƒÜÇ [FLASH] Calling flashInterpreter...");
  //     final response = await mUdsDiagnostic.flashInterpreter(
  //       flashConfig,
  //       jsonData.noOfSectors ?? 0,
  //       jsonData.sectorData!,
  //       interpreter,
  //     );

  //     print("­ƒôÑ [FLASH RESPONSE]: $response");

  //  ;

  //     print("­ƒÄë [FLASH] ===== COMPLETED SUCCESS =====");
  print("ÔÜÖ´©Å [CONFIG] FlashConfig created");
 
      //print("­ƒôí [UDS] Starting tester present...");

      await startTesterPresent();

      print("Ô£à [UDS] Tester present started");
 
      print("­ƒÜÇ [FLASH] Calling flashInterpreter...");

      final response = await mUdsDiagnostic.flashInterpreter(

        flashConfig,

        jsonData.noOfSectors ?? 0,

        jsonData.sectorData!,

        interpreter,

      );
 
      print("­ƒôÑ [FLASH RESPONSE]: $response");
 
      // print("­ƒøæ [UDS] Stopping tester present...");

       await stopTesterPresent();

      // print("Ô£à [UDS] Tester present stopped");
 
      print("­ƒÄë [FLASH] ===== COMPLETED SUCCESS =====");
 

      return response;
    } catch (e, stackTrace) {
      print("ÔØî [ERROR] Flashing failed: $e");
      print("­ƒôì [STACKTRACE]: $stackTrace");

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

  Future<List<WriteParameterStatus>?> writePid(
      String writePidIndex, List<WriteParameterPid> pidList) async {
    try {
      print("========== WRITE PID START ==========");
      print("Incoming writePidIndex: $writePidIndex");
      print("PID List Length: ${pidList.length}");

      // Parse write parameter index
      late final WriteParameterIndex index;
      try {
        index = WriteParameterIndex.values
            .firstWhere((e) => e.toString().split('.').last == writePidIndex);
      } catch (e) {
        print("ÔØî Failed to parse WriteParameterIndex from "
            "writePidIndex=\"$writePidIndex\": $e");
        rethrow;
      }

      print("Parsed WriteParameterIndex: $index");

      List<WriteParameterPID> list = [];

      for (var item in pidList) {
        print("------------- PID ITEM -------------");
        print("writePid: ${item.writePid}");
        print("seedKeyIndex (raw): ${item.seedKeyIndex}");
        print("writePamIndex (raw): ${item.writePamIndex}");
        print("writeParaDataSize: ${item.writeParaDataSize}");
        print("writeInput: ${item.writeInput}");
        print("pid: ${item.pid}");
        print("startByte: ${item.startByte}");
        print("totalBytes: ${item.totalBytes}");
        print("readParameterPidDataType: ${item.readParameterPidDataType}");

        // Parse seed key index
        late final SEEDKEYINDEXTYPE seedIndex;
        try {
          seedIndex = SEEDKEYINDEXTYPE.values.firstWhere(
              (e) => e.toString().split('.').last == item.seedKeyIndex);
        } catch (e) {
          print("ÔØî Failed to parse SEEDKEYINDEXTYPE from "
              "seedKeyIndex=\"${item.seedKeyIndex}\" (pid=${item.pid}): $e");
          rethrow;
        }

        print("Parsed SeedKeyIndex Enum: $seedIndex");

        // Parse write parameter index
        late final WriteParameterIndex writeIndex;
        try {
          writeIndex = WriteParameterIndex.values.firstWhere(
              (e) => e.toString().split('.').last == item.writePamIndex);
        } catch (e) {
          print("ÔØî Failed to parse WriteParameterIndex from "
              "writePamIndex=\"${item.writePamIndex}\" (pid=${item.pid}): $e");
          rethrow;
        }

        print("Parsed WriteParamIndex Enum: $writeIndex");

        // Build variant data list
        List<VariantDataList> variantDataLists = [];

        if (item.variantList != null) {
          print("Variant List Count: ${item.variantList!.length}");

          for (var v in item.variantList!) {
            print("  ---- Variant ----");
            print("  pidId: ${v.pidId}");
            print("  pidName: ${v.pidName}");
            print("  datatype: ${v.datatype}");
            print("  isBitcoded: ${v.isBitcoded}");
            print("  noOfBits: ${v.noofBits}");
            print("  noOfBytes: ${v.noOfBytes}");
            print("  startByte: ${v.startByte}");
            print("  startBit: ${v.startBit}");
            print("  offset: ${v.offset}");
            print("  resolution: ${v.resolution}");
            print("  unit: ${v.unit}");

            variantDataLists.add(VariantDataList(
              datatype: v.datatype,
              isBitcoded: v.isBitcoded,
              noofBits: v.noofBits,
              noOfBytes: v.noOfBytes,
              offset: v.offset,
              pidId: v.pidId,
              pidName: v.pidName,
              resolution: v.resolution,
              startBit: v.startBit,
              startByte: v.startByte,
              unit: v.unit,
            ));
          }

          print("Built variantDataLists count: ${variantDataLists.length}");
        } else {
          print("Variant List: null (no variant entries for this pid)");
        }

        list.add(WriteParameterPID(
          seedKeyIndex: seedIndex,
          writePamIndex: writeIndex,
          writeInputSize: item.writeParaDataSize,
          writeInput: item.writeInput,
          writePid: item.writePid,
          readParameterPidDataType: item.readParameterPidDataType,
          pid: item.pid,
          startByte: item.startByte,
          totalBytes: item.totalBytes,
          variantList: variantDataLists,
        ));

        print("PID Added to Write List");
      }

      print("Final WriteParameterPID List Length: ${list.length}");

      print("Calling writeParameters()...");
      print("Parameters:");
      print("  PID Count: ${pidList.length}");
      print("  Write Index: $index");

      // Call UDS diagnostic write method
      final result =
          await mUdsDiagnostic.writeParameters(pidList.length, index, list);

      print("Raw Result from writeParameters(): $result");

      if (result == null) {
        print("ÔÜá writeParameters returned NULL");
        return null;
      }

      print("Converting result to JSON...");

      final resJson = jsonEncode(result);

      print("JSON Result: $resJson");

      final resList = (jsonDecode(resJson) as List)
          .map((e) => WriteParameterStatus.fromJson(e))
          .toList();

      print("Parsed WriteParameterStatus List Length: ${resList.length}");

      for (int i = 0; i < resList.length; i++) {
        print("  ÔÇó Result[$i].status: ${resList[i].status}");
      }

      print("========== WRITE PID END ==========");

      return resList;
    } catch (e, stack) {
      print("ÔØî Error in writePid: $e");
      print("StackTrace: $stack");

      return null;
    }
  }

  Future<List<WriteParameterStatus>?> writePid1(
      String writePidIndex, List<WriteParameterPid> pidList) async {
    try {
      print("========== WRITE PID START ==========");
      print("Incoming writePidIndex: $writePidIndex");
      print("PID List Length: ${pidList.length}");

      // Parse write parameter index
      final WriteParameterIndex index = WriteParameterIndex.values
          .firstWhere((e) => e.toString().split('.').last == writePidIndex);

      print("Parsed WriteParameterIndex: $index");

      List<WriteParameterPID> list = [];

      for (var item in pidList) {
        print("------------- PID ITEM -------------");
        print("writePid: ${item.writePid}");
        print("seedKeyIndex (raw): ${item.seedKeyIndex}");
        print("writePamIndex (raw): ${item.writePamIndex}");
        print("writeParaDataSize: ${item.writeParaDataSize}");
        print("writeInput: ${item.writeInput}");
        print("pid: ${item.pid}");
        print("startByte: ${item.startByte}");
        print("totalBytes: ${item.totalBytes}");

        // Parse seed key index
        final SEEDKEYINDEXTYPE seedIndex = SEEDKEYINDEXTYPE.values.firstWhere(
            (e) => e.toString().split('.').last == item.seedKeyIndex);

        print("Parsed SeedKeyIndex Enum: $seedIndex");

        // Parse write parameter index
        final WriteParameterIndex writeIndex = WriteParameterIndex.values
            .firstWhere(
                (e) => e.toString().split('.').last == item.writePamIndex);

        print("Parsed WriteParamIndex Enum: $writeIndex");

        // Build variant data list
        List<VariantDataList> variantDataLists = [];

        if (item.variantList != null) {
          print("Variant List Count: ${item.variantList!.length}");

          for (var v in item.variantList!) {
            print("  ---- Variant ----");
            print("  pidId: ${v.pidId}");
            print("  pidName: ${v.pidName}");
            print("  datatype: ${v.datatype}");
            print("  isBitcoded: ${v.isBitcoded}");
            print("  noOfBits: ${v.noofBits}");
            print("  noOfBytes: ${v.noOfBytes}");
            print("  startByte: ${v.startByte}");
            print("  startBit: ${v.startBit}");
            print("  offset: ${v.offset}");
            print("  resolution: ${v.resolution}");
            print("  unit: ${v.unit}");

            variantDataLists.add(VariantDataList(
              datatype: v.datatype,
              isBitcoded: v.isBitcoded,
              noofBits: v.noofBits,
              noOfBytes: v.noOfBytes,
              offset: v.offset,
              pidId: v.pidId,
              pidName: v.pidName,
              resolution: v.resolution,
              startBit: v.startBit,
              startByte: v.startByte,
              unit: v.unit,
            ));
          }
        }

        list.add(WriteParameterPID(
          seedKeyIndex: seedIndex,
          writePamIndex: writeIndex,
          writeInputSize: item.writeParaDataSize,
          writeInput: item.writeInput,
          writePid: item.writePid,
          readParameterPidDataType: item.readParameterPidDataType,
          pid: item.pid,
          startByte: item.startByte,
          totalBytes: item.totalBytes,
          variantList: variantDataLists,
        ));

        print("PID Added to Write List");
      }

      print("Final WriteParameterPID List Length: ${list.length}");

      print("Calling writeParameters()...");
      print("Parameters:");
      print("  PID Count: ${pidList.length}");
      print("  Write Index: $index");

      // Call UDS diagnostic write method
      final result =
          await mUdsDiagnostic.writeParameters(pidList.length, index, list);

      print("Raw Result from writeParameters(): $result");

      if (result == null) {
        print("ÔÜá writeParameters returned NULL");
        return null;
      }

      print("Converting result to JSON...");

      final resJson = jsonEncode(result);

      print("JSON Result: $resJson");

      final resList = (jsonDecode(resJson) as List)
          .map((e) => WriteParameterStatus.fromJson(e))
          .toList();

      print("Parsed WriteParameterStatus List Length: ${resList.length}");

      print("========== WRITE PID END ==========");

      return resList;
    } catch (e, stack) {
      print("ÔØî Error in writePid: $e");
      print("StackTrace: $stack");

      return null;
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
