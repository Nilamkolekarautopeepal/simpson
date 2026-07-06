import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:ap_diagnostic/enum/readDTCIndex.dart';
import 'package:ap_diagnostic/enum/readParameters.dart';
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/models/flashingMtrixModel.dart';
import 'package:ap_diagnostic/models/freezeFrameModel.dart';
import 'package:ap_diagnostic/models/loopModel.dart';
import 'package:ap_diagnostic/models/readDtcResponseModel.dart';
import 'package:ap_diagnostic/models/readParameterPIDModel.dart';
import 'package:ap_diagnostic/models/readParameterResponseModel.dart';
import 'package:ap_diagnostic/models/writeParameterPIDModel.dart';
import 'package:ap_diagnostic/models/writeParameterResponse.dart';
import 'package:ap_diagnostic/structure/flash_structures.dart';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:convert/convert.dart';
import 'package:ap_diagnostic/enum/writeParameter.dart';
import 'package:ap_dongle_comm/utils/model/responseArrayStatusModel.dart';
import 'package:ecu_seedkey/ecu_seedkey.dart';


class UDSDiagnostic {
  final DongleComm _dongleComm;
  final ECUCalculateSeedkey _calculateSeedKey;
  UDSDiagnostic(this._dongleComm, this._calculateSeedKey);



  Future<ResponseArrayStatus?> enterExtendedSession(
    WriteParameterIndex writeParameterIndex,
    SEEDKEYINDEXTYPE seedKeyIndex,
    DongleComm dongleComm,
  ) async {
    ResponseArrayStatus? responseBytes;

    try {
      int diagnosticsMode = 0x00;
      int getSeedIndex = 0x00;

      switch (writeParameterIndex) {
        case WriteParameterIndex.UDS_DS1003_SK090A:
          diagnosticsMode = 0x03;
          getSeedIndex = 0x09;
          break;
        case WriteParameterIndex.UDS_DS1003_SK0102:
          diagnosticsMode = 0x03;
          getSeedIndex = 0x01;
          break;
        case WriteParameterIndex.UDS_DS1003_SK0B0C:
          diagnosticsMode = 0x03;
          getSeedIndex = 0x0B;
          break;
        case WriteParameterIndex.UDS_DS1003_SK0304:
          diagnosticsMode = 0x03;
          getSeedIndex = 0x03;
          break;
        case WriteParameterIndex.UDS_DS1003_SK0506:
          diagnosticsMode = 0x03;
          getSeedIndex = 0x05;
          break;
        case WriteParameterIndex.UDS:
          // TODO: Handle this case.
          throw UnimplementedError();
        case WriteParameterIndex.UDS_SK0102_DS1003:
          // TODO: Handle this case.
          throw UnimplementedError();
        case WriteParameterIndex.UDS_DS1003:
          // TODO: Handle this case.
          throw UnimplementedError();
      }

      // Send start diagnostics mode command
      Uint8List txFrame = Uint8List.fromList([0x10, diagnosticsMode]);
      int frameLength = txFrame.length;

      responseBytes = await dongleComm.can2xTxRx(
        frameLength,
        byteArrayToHexString(txFrame),
      );

      if (responseBytes.ecuResponseStatus == "NOERROR") {
        // Send get seed command to ECU
        txFrame = Uint8List.fromList([0x27, getSeedIndex]);
        frameLength = txFrame.length;

        responseBytes = await dongleComm.can2xTxRx(
          frameLength,
          byteArrayToHexString(txFrame),
        );
        String? status = responseBytes.ecuResponseStatus;

        while (status == "ECUERROR REQUIREDTIMEDELAYNOTEXPIRED") {
          await Future.delayed(Duration(milliseconds: 300));
          responseBytes = await dongleComm.can2xTxRx(
            frameLength,
            byteArrayToHexString(txFrame),
          );
          status = responseBytes.ecuResponseStatus;
        }

        if (status == "NOERROR") {
          Uint8List? rxArray = responseBytes!.actualDataBytes;
          int _ = rxArray!.length;

          Uint8List seedArray = rxArray.sublist(2); // skip first 2 bytes

          int numKeyBytes = 0;
          Uint8List actualKey = Uint8List(32);
          ECUCalculateSeedkey calculateSeedkey = ECUCalculateSeedkey();

          // Using ValueSetter to mimic ref/out behavior
          calculateSeedkey.calculateSeedKey(
            seedKeyIndex,
            seedArray.length,
            seedArray,
          );

          if (status == "NOERROR") {
            Uint8List newTxFrame = Uint8List(numKeyBytes + 2);
            newTxFrame[0] = 0x27;
            newTxFrame[1] = (getSeedIndex + 1) & 0xFF;

            newTxFrame.setRange(2, 2 + numKeyBytes, actualKey);

            frameLength = newTxFrame.length;

            responseBytes = await dongleComm.can2xTxRx(
              frameLength,
              byteArrayToHexString(newTxFrame),
            );

            if (seedArray.every((b) => b == 0)) {
              responseBytes.ecuResponseStatus = "NOERROR";
            }
          }
        }
      }

      return responseBytes;
    } catch (e) {
      print("Error in enterExtendedSession: $e");
      return null;
    }
  }

  // Helper function to convert Uint8List to hex string
  String byteArrayToHexString(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<ReadDtcResponseModel> readDTC(ReadDtcIndex dtcIndex) async {
    String status = '';
    String returnStatus = '';
    List<List<String>>? dtcArray;

    try {
      if (dtcIndex == ReadDtcIndex.KWP_2BYTE_DTC ||
          dtcIndex == ReadDtcIndex.UDS_2BYTE12_DTC ||
          dtcIndex == ReadDtcIndex.UDS_2BYTE13_DTC ||
          dtcIndex == ReadDtcIndex.UDS_3BYTE_DTC) {
        // Standard DTC read
        int frameLength = 3;
        final responseBytes = await _dongleComm.can2xTxRx(
          frameLength,
          '1902FF',
        );
        status = responseBytes.ecuResponseStatus ?? '';
        final actualData = responseBytes.actualDataBytes;
        returnStatus = '';

        if (status == 'NOERROR' && actualData != null) {
          returnStatus = 'NO_ERROR';
          final rxArray = actualData;
          int dtcStartByteIndex = 3;
          final noOfDtc = ((rxArray.length) - 3) ~/ 4;
          dtcArray = List.generate(noOfDtc, (_) => List.filled(2, ''));

          for (int i = 0; i < noOfDtc; i++) {
            // Determine DTC type
            final dtcTypeBits = (rxArray[dtcStartByteIndex] & 0xC0) >> 6;
            String dtcType = '';
            switch (dtcTypeBits) {
              case 0x00:
                dtcType = 'P';
                break;
              case 0x01:
                dtcType = 'C';
                break;
              case 0x02:
                dtcType = 'B';
                break;
              case 0x03:
                dtcType = 'U';
                break;
            }

            // Determine DTC status
            final value = rxArray[dtcStartByteIndex + 3] & 0x01;
            String dtcStatus = (value == 0x00) ? 'Inactive' : 'Active';

            // Parse DTC code based on type
            String dtcCode = '';
            switch (dtcIndex) {
              case ReadDtcIndex.UDS_3BYTE_DTC:
                dtcCode =
                    '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}-${rxArray[dtcStartByteIndex + 2].toRadixString(16).padLeft(2, '0')}';
                break;
              case ReadDtcIndex.UDS_2BYTE12_DTC:
                dtcCode =
                    '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}';
                break;
              case ReadDtcIndex.UDS_2BYTE13_DTC:
                dtcCode =
                    '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 2].toRadixString(16).padLeft(2, '0')}';
                break;
              case ReadDtcIndex.KWP_2BYTE_DTC:
                dtcCode =
                    '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}';
                break;
              default:
                dtcCode = '';
            }

            dtcArray[i][0] = dtcCode;
            dtcArray[i][1] = dtcStatus;

            dtcStartByteIndex += 4;
          }
        } else {
          returnStatus = status;
        }
      } else if (dtcIndex == ReadDtcIndex.GENERIC_OBD) {
        // Generic OBD DTC read
        int frameLength = 1;
        final responseBytes03 = await _dongleComm.can2xTxRx(frameLength, '03');
        status = responseBytes03.ecuResponseStatus ?? '';
        final actualData03 = responseBytes03.actualDataBytes;

        if (status == 'NOERROR' && actualData03 != null) {
          final rxArray03 = actualData03;
          final responseBytes07 = await _dongleComm.can2xTxRx(
            frameLength,
            '07',
          );
          status = responseBytes07.ecuResponseStatus ?? '';
          final actualData07 = responseBytes07.actualDataBytes;

          if (status == 'NOERROR' && actualData07 != null) {
            returnStatus = 'NO_ERROR';
            final rxArray07 = actualData07;

            final noOfDtc03 = rxArray03[1];
            final noOfDtc07 = rxArray07[1];

            dtcArray = List.generate(
              (noOfDtc03 + noOfDtc07),
              (_) => List.filled(2, ''),
            );

            // Current DTCs
            for (int i = 0; i < noOfDtc03; i++) {
              final dtcTypeBits = (rxArray03[i * 2 + 2] & 0xC0) >> 6;
              String dtcType = '';
              switch (dtcTypeBits) {
                case 0x00:
                  dtcType = 'P';
                  break;
                case 0x01:
                  dtcType = 'C';
                  break;
                case 0x02:
                  dtcType = 'B';
                  break;
                case 0x03:
                  dtcType = 'U';
                  break;
              }
              dtcArray[i][0] =
                  '$dtcType${(rxArray03[i * 2 + 2] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray03[i * 2 + 3].toRadixString(16).padLeft(2, '0')}';
              dtcArray[i][1] = 'Current';
            }

            // Pending DTCs
            for (int j = 0; j < noOfDtc07; j++) {
              final dtcTypeBits = (rxArray07[j * 2 + 2] & 0xC0) >> 6;
              String dtcType = '';
              switch (dtcTypeBits) {
                case 0x00:
                  dtcType = 'P';
                  break;
                case 0x01:
                  dtcType = 'C';
                  break;
                case 0x02:
                  dtcType = 'B';
                  break;
                case 0x03:
                  dtcType = 'U';
                  break;
              }
              dtcArray[noOfDtc03 + j][0] =
                  '$dtcType${(rxArray07[j * 2 + 2] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray07[j * 2 + 3].toRadixString(16).padLeft(2, '0')}';
              dtcArray[noOfDtc03 + j][1] = 'Pending';
            }
          } else {
            returnStatus = status;
          }
        } else {
          returnStatus = status;
        }
      }

      return ReadDtcResponseModel(dtcs: dtcArray, status: returnStatus);
    } catch (e) {
      return ReadDtcResponseModel(dtcs: null, status: e.toString());
    }
  }

  Future<String> getFreezeFrameDtcCode() async {
    try {
      String dtcCode = "";

      // Service 02, PID 02, Sequence 00
      var response = await _dongleComm.can2xTxRx(3, "020200");

      if (response.ecuResponseStatus == "NOERROR" &&
          response.actualDataBytes != null &&
          response.actualDataBytes!.isNotEmpty) {
        Uint8List rxArray = response.actualDataBytes!;

        // 1. Get the Prefix (P, C, B, U)
        // OBD II standard: high 2 bits of the first DTC byte
        int statusFlag = rxArray[3] >> 6;
        switch (statusFlag) {
          case 0:
            dtcCode = "P";
            break;
          case 1:
            dtcCode = "C";
            break;
          case 2:
            dtcCode = "B";
            break;
          case 3:
            dtcCode = "U";
            break;
          default:
            dtcCode = "";
        }

        // 2. Get the 4-digit code number
        // Mask the first 2 bits (prefix) and combine with the next byte
        int codeNumber = (rxArray[3] & 0x3F) << 8 | rxArray[4];

        // 3. Format as Hex and Pad
        // .toRadixString(16) converts to hex, padLeft(4, '0') ensures 4 digits
        dtcCode += codeNumber.toRadixString(16).padLeft(4, '0').toUpperCase();

        return dtcCode;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  Future<dynamic> clearDTC(ClearDtcIndex readDtcIndex) async {
    print('🔹 clearDTC called with index: $readDtcIndex');

    try {
      switch (readDtcIndex) {
        case ClearDtcIndex.UDS_4BYTES:
          print('🔹 Sending CAN frame for UDS_4BYTES: 14FFFFFF');
          return await _dongleComm.can2xTxRx(4, '14FFFFFF');

        case ClearDtcIndex.UDS_3BYTES:
          print('🔹 Sending CAN frame for UDS_3BYTES: 14FFFF');
          return await _dongleComm.can2xTxRx(3, '14FFFF');

        case ClearDtcIndex.GENERIC_OBD:
          print('🔹 Sending CAN frame for GENERIC_OBD: 04');
          return await _dongleComm.can2xTxRx(1, '04');

        case ClearDtcIndex.KWP_PRIMITIVE:
          print('🔹 Sending CAN frame for KWP_PRIMITIVE: 14');
          return await _dongleComm.can2xTxRx(1, '14');
        case ClearDtcIndex.KWP:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    } catch (e, stackTrace) {
      print('❌ Error in clearDTC: $e');
      print(stackTrace);
      return null;
    }
  }

  Future<FreezeFrameResponseModel> getFreezeFrame(
    String dtcCode,
    FreezeFrameModel freezeFrameConfig,
  ) async {
    FreezeFrameResponseModel responseModel = FreezeFrameResponseModel();
    List<FreezeFrame> dummyList = [];

    try {
      // 1. Clean the DTC Code
      String completeCode = dtcCode.replaceAll('-', '');

      // 2. Identify DTC Type Bits
      int dtcTypeBits = 0;
      String prefix = completeCode[0].toUpperCase();
      if (prefix == 'P')
        dtcTypeBits = 0x00;
      else if (prefix == 'C')
        dtcTypeBits = 0x01;
      else if (prefix == 'B')
        dtcTypeBits = 0x02;
      else if (prefix == 'U')
        dtcTypeBits = 0x03;

      // 3. Remove prefix and convert Hex string to Bytes
      // completeCode.substring(1) is equivalent to completeCode.Remove(0,1)
      Uint8List frame = Uint8List.fromList(
        hex.decode(completeCode.substring(1)),
      );

      // 4. Apply DTC type bits to the first byte
      frame[0] = (frame[0] | (dtcTypeBits << 6));

      // 5. Send Service 19 04 Request
      // Request format: [Service][Sub-function][DTC High][DTC Mid][DTC Low][RecordNumber]
      String requestHex = "1904${hex.encode(frame)}FF";
      var response = await _dongleComm.can2xTxRx(frame.length + 3, requestHex);

      String? status = response.ecuResponseStatus;

      if (status == null || status.isEmpty) {
        responseModel.status = "Status not found.";
      } else if (status == "NOERROR") {
        Uint8List? actualData = response.actualDataBytes;
        int index = 8; // Starting index after headers

        if (actualData != null && actualData.isNotEmpty) {
          for (var item in freezeFrameConfig.freezeFrameCode ?? []) {
            FreezeFrame freeze = FreezeFrame(code: item.code);

            try {
              int itemCode = int.parse(item.code ?? "0", radix: 16);
              int highByte = (itemCode >> 8) & 0xFF;
              int lowByte = itemCode & 0xFF;

              bool found = false;

              void search(int startIdx) {
                // Safe check: data.length - 1 to prevent index + 1 crash
                for (int i = startIdx; i < actualData.length - 1; i++) {
                  if (actualData[i] == highByte &&
                      actualData[i + 1] == lowByte) {
                    freeze.value = getFreezeValue(response, item, i);
                    index = i;
                    found = true;
                    break;
                  }
                }
              }

              search(index);
              if (!found) search(0);
            } catch (e) {
              freeze.value = "Exception";
            }

            // The Fix: Ensure the addition result remains an int
            int lengthVal = (item.length ?? 0).toInt();
            index += 2 + lengthVal;

            dummyList.add(freeze);
          }
        }
        responseModel.status = status;
        responseModel.dtcs = dummyList;
      } else {
        responseModel.status = status;
      }
    } catch (ex) {
      responseModel.status = ex.toString();
    }

    return responseModel;
  }

  String getFreezeValue(
    dynamic responseBytes,
    FreezeFrameCode item,
    int index,
  ) {
    String retValue = "";
    Uint8List actualData = responseBytes.actualDataBytes;

    // 1. Reconstruct the Received Code (2 bytes)
    // Standard UDS/OBD DID is usually Big Endian
    int receivedCode = (actualData[index] << 8) | actualData[index + 1];

    // 2. Parse Item Code from Hex String
    int itemCode = int.parse(item.code ?? "0", radix: 16);

    if (receivedCode == itemCode) {
      int len = (item.length ?? 0).toInt();

      // Safety check for array bounds
      if (index + 2 + len > actualData.length) return "NA";

      // 3. Extract the value bytes
      Uint8List valueBytes = actualData.sublist(index + 2, index + 2 + len);

      if (item.messageType == "CONTINUOUS") {
        if (len <= 4) {
          int unsignedPidValue = 0;

          // 4. Convert Bytes to Unsigned Integer
          // We use ByteData to handle variable lengths (1-4 bytes)
          ByteData bData = ByteData(4); // Create a 4-byte buffer

          // Copy existing bytes into the buffer (handling Endianness)
          // C# used Array.Reverse + ToUInt32 (Little Endian conversion)
          // Here we'll manually pack it or use ByteData
          for (int i = 0; i < valueBytes.length; i++) {
            // Replicating your logic: padding to 4 bytes and treating as Little Endian
            bData.setUint8(i, valueBytes[i]);
          }

          // Read as 32-bit Little Endian (matching BitConverter.ToUInt32 + Reverse)
          unsignedPidValue = bData.getUint32(0, Endian.little);

          // 5. Apply Scaling (Formula: Value * Resolution + Offset)
          double resolution = item.resolution ?? 1.0;
          double offset = item.offset ?? 0.0;
          double floatPidValue = (unsignedPidValue * resolution) + offset;

          // 6. Format to 3 decimal places (Equivalent to C# "0.###")
          // toStringAsFixed produces a string, replace trailing zeros if needed
          retValue = floatPidValue
              .toStringAsFixed(3)
              .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), "");

          if (retValue.endsWith(".")) {
            retValue = retValue.substring(0, retValue.length - 1);
          }
        } else {
          // Handle lengths > 4 if needed
          retValue = "Length Error";
        }
      } else {
        // Handle NON-CONTINUOUS / STATE values (e.g., bitcoded)
        retValue = valueBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      }
    } else {
      retValue = "NA";
    }

    return retValue;
  }

  Future<List<String>?> genericOBDSupportedPidList() async {
    try {
      List<String> supportedPids = [];

      // Mode 01 PID support is usually checked in increments of 0x20 (32 pids)
      // 0100, 0120, 0140, etc.
      // Note: your C# loop goes up to 0x0C, checking 0100 through 010B.
      // Standard OBD II usually checks 0x00, 0x20, 0x40... in steps of 32.
      for (int i = 0; i < 0x0C; i++) {
        var frameLength = 2;
        String pidHex = i.toRadixString(16).padLeft(2, '0').toUpperCase();

        var response = await _dongleComm.can2xTxRx(frameLength, "01$pidHex");

        if (response.ecuResponseStatus == "NOERROR" &&
            response.actualDataBytes != null &&
            response.actualDataBytes!.isNotEmpty &&
            response.actualDataBytes![0] == 0x41) {
          // 0x41 is Mode 01 Positive Response

          Uint8List data = response.actualDataBytes!;
          int len = data.length;
          int cmpresp = 0;

          // Reconstructing the 32-bit bitmask from variable response lengths
          if (len == 2) {
            /* Do Nothing */
          } else if (len == 3) {
            cmpresp = (data[2] << 24) & 0xFF000000;
          } else if (len == 4) {
            cmpresp = ((data[2] << 24) | (data[3] << 16)) & 0xFFFF0000;
          } else if (len == 5) {
            cmpresp =
                ((data[2] << 24) | (data[3] << 16) | (data[4] << 8)) &
                0xFFFFFF00;
          } else if (len >= 6) {
            cmpresp =
                (data[2] << 24) | (data[3] << 16) | (data[4] << 8) | data[5];
          }

          // Bit 31 (MSB) represents PID + 0x01
          // Bit 0 (LSB) represents PID + 0x20 (which indicates if next block is supported)
          for (int j = 31; j >= 0; j--) {
            // Check if bit is set
            if ((cmpresp & (1 << j)) != 0) {
              // Calculate actual PID number
              // offset is based on the block i (0x00, 0x20, etc)
              int pidNum = (i * 32) + (32 - j);
              supportedPids.add(
                "01${pidNum.toRadixString(16).padLeft(2, '0').toUpperCase()}",
              );
            }
          }
        }
      }

      return supportedPids.isEmpty ? null : supportedPids;
    } catch (ex) {
      print("Error getting supported PIDs: $ex");
      return null;
    }
  }

  void _populateErrorVariableResponse(
    List<ReadParameterResponse> list,
    ReadParameterPID item,
    String status,
  ) {
    list.add(
      ReadParameterResponse(
        status: status,
        pidId: item.pidId,
        pidName: item.pid,
        variables: (item.variables ?? [])
            .map(
              (v) => ReadParameterVariableResponse(
                pidName: v.pidName,
                pidNumber: v.pidNumber,
                responseValue: "",
              ),
            )
            .toList(),
      ),
    );
  }

  Future<List<ReadParameterResponse>> readParameters(
    int noOfParameters,
    List<ReadParameterPID> readParameterCollection,
  ) async {
    List<ReadParameterResponse> dataByteArray = [];

    for (int i = 0; i < readParameterCollection.length; i++) {
      var pidItem = readParameterCollection[i];
      int frameLength = (pidItem.pid!.length / 2).toInt();

      print("--- START LOOP PID: ${pidItem.pid} ---");

      var pidResponse = await _dongleComm.can2xTxRx(frameLength, pidItem.pid!);

      // 🔁 Retry for NRC 0x78
      int retryCount = 0;
      while (pidResponse.actualDataBytes != null &&
          pidResponse.actualDataBytes!.length >= 3 &&
          pidResponse.actualDataBytes![0] == 0x7F &&
          pidResponse.actualDataBytes![2] == 0x78 &&
          retryCount < 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        pidResponse = await _dongleComm.can2xTxRx(frameLength, pidItem.pid!);
        retryCount++;
      }

      try {
        Uint8List? rxArray = pidResponse.actualDataBytes;
        String ecuStatus = pidResponse.ecuResponseStatus ?? "NOERROR";

        if (ecuStatus == "NOERROR" || (rxArray != null && rxArray.isNotEmpty)) {
          if (rxArray == null || rxArray.isEmpty) {
            _populateErrorVariableResponse(
              dataByteArray,
              pidItem,
              "EMPTY_RESPONSE",
            );
            continue;
          }

          int txFrameLen = frameLength;
          List<ReadParameterVariableResponse> variableResponses = [];

          for (var variable in pidItem.variables ?? []) {
            String dataValue = "";
            int baseOffset = (variable.startByte ?? 0) + txFrameLen - 1;

            if (baseOffset >= rxArray.length) {
              dataValue = "OFFSET_ERR";
            } else {
              switch (variable.datatype) {
                case "CONTINUOUS":
                  int unsignedValue = 0;
                  for (int j = 0; j < (variable.noOfBytes ?? 0); j++) {
                    if (baseOffset + j < rxArray.length) {
                      unsignedValue |=
                          rxArray[baseOffset + j] <<
                          ((variable.noOfBytes! - 1 - j) * 8);
                    }
                  }

                  if (variable.isBitcoded == true) {
                    int shift =
                        (variable.noOfBytes! * 8 -
                        variable.noofBits! -
                        variable.startBit! +
                        1);
                    int mask = (1 << (variable.noofBits ?? 0)) - 1;
                    unsignedValue = (unsignedValue >> shift) & mask;
                  }

                  num value =
                      (variable.readParameterIndex ==
                              ReadParameterIndex.UDS_2S_COMPLIMENT &&
                          variable.offset == 1)
                      ? unsignedValue * (variable.resolution ?? 1.0)
                      : unsignedValue * (variable.resolution ?? 1.0) +
                            (variable.offset ?? 0.0);
                  dataValue = value.toStringAsFixed(3);
                  break;

                case "ASCII":
                  num end = baseOffset + (variable.noOfBytes ?? 0);
                  if (end <= rxArray.length) {
                    Uint8List temp = rxArray.sublist(baseOffset, end as int?);
                    dataValue = latin1.decode(
                      temp,
                      //allowInvalid: true,
                    ); // ✅ keep all zeros
                  }
                  break;

                case "BCD":
                case "HEX":
                  num end = baseOffset + (variable.noOfBytes ?? 0);
                  if (end <= rxArray.length) {
                    Uint8List temp = rxArray.sublist(baseOffset, end as int?);
                    dataValue = bytesToHex(temp); // ✅ keep all zeros
                  }
                  break;

                case "ENUMRATED":
                  int value = 0;
                  for (int j = 0; j < (variable.noOfBytes ?? 0); j++) {
                    value |=
                        rxArray[baseOffset + j] <<
                        ((variable.noOfBytes! - 1 - j) * 8);
                  }
                  dataValue = value.toString();
                  if (variable.messages != null) {
                    for (var msg in variable.messages!) {
                      if (int.tryParse(msg.code ?? '') == value)
                        dataValue = msg.message ?? '';
                    }
                  }
                  break;

                case "ENUMRATED_HEX":
                  num end = baseOffset + (variable.noOfBytes ?? 0);
                  if (end <= rxArray.length) {
                    Uint8List temp = rxArray.sublist(baseOffset, end as int?);
                    String hexVal = bytesToHex(temp);
                    dataValue = hexVal; // ✅ keep zeros
                    if (variable.messages != null) {
                      for (var msg in variable.messages!) {
                        if (msg.code == hexVal) dataValue = msg.message ?? '';
                      }
                    }
                  }
                  break;

                case "IQA":
                  List<int> lookup = [
                    65,
                    66,
                    67,
                    68,
                    69,
                    70,
                    71,
                    72,
                    73,
                    75,
                    76,
                    77,
                    78,
                    79,
                    80,
                    82,
                    83,
                    84,
                    85,
                    86,
                    87,
                    88,
                    89,
                    90,
                    49,
                    50,
                    51,
                    52,
                    53,
                    54,
                    55,
                    56,
                  ];

                  if (baseOffset + 8 <= rxArray.length) {
                    Uint8List rxData = rxArray.sublist(
                      baseOffset,
                      baseOffset + 8,
                    );
                    List<int> y = [
                      (rxData[0] & 0xF8) >> 3,
                      ((rxData[0] & 0x07) << 8 | (rxData[1] & 0xC0)) >> 6,
                      (rxData[1] & 0x3E) >> 1,
                      ((rxData[1] & 0x01) << 8 | (rxData[2] & 0xF0)) >> 4,
                      ((rxData[2] & 0x0F) << 8 | (rxData[3] & 0x80)) >> 7,
                      (rxData[3] & 0x7C) >> 2,
                      (rxData[4] & 0xF8) >> 3,
                    ];
                    dataValue = String.fromCharCodes(y.map((e) => lookup[e]));
                  }
                  break;

                default:
                  dataValue = "UNSUPPORTED";
              }
            }

            variableResponses.add(
              ReadParameterVariableResponse(
                pidName: variable.pidName,
                pidNumber: variable.pidNumber,
                responseValue: dataValue,
              ),
            );
          }

          dataByteArray.add(
            ReadParameterResponse(
              pidId: pidItem.pidId,
              status: ecuStatus,
              pidName: pidItem.pid,
              dataArray: rxArray,
              variables: variableResponses,
            ),
          );
        } else {
          _populateErrorVariableResponse(dataByteArray, pidItem, ecuStatus);
        }
      } catch (e) {
        print("PARSE ERROR: $e");
        dataByteArray.add(
          ReadParameterResponse(
            status: "PARSE_ERR",
            pidName: pidItem.pid,
            pidId: pidItem.pidId,
          ),
        );
      }
    }

    return dataByteArray;
  }

  String bytesToHex(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('')
        .toUpperCase();
  }

  String hexToAscii(String hex) {
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i += 2) {
      buffer.write(
        String.fromCharCode(int.parse(hex.substring(i, i + 2), radix: 16)),
      );
    }
    return buffer.toString();
  }

  Future<List<ReadParameterResponseIvn>> ivnReadParameters(
    int noOFParameters,
    List<PIDFrameId> readParameterCollection,
  ) async {
    List<ReadParameterResponseIvn> databyteArray = [];

    try {
      for (var item in readParameterCollection) {
        String dataValue = "";

        // 1. Request the specific IVN Frame from the hardware
        // item.frameId maps to 'FramID' from your JSON
        var getivnframe = await _dongleComm.canIVNRxFrame(item.framID ?? "");

        if (getivnframe.ecuResponseStatus == "NOERROR") {
          Uint8List rxArray = Uint8List.fromList(
            getivnframe.actualFrameBytes ?? [],
          );

          // 2. Safely parse configuration from String to Numeric
          String pidType = (item.numType ?? "")
              .toUpperCase(); // e.g., SIGNED/UNSIGNED
          // ignore: unused_local_variable
          String msgType = (item.bitCoded == "1") ? "CONTINUOUS" : "NORMAL";

          int startByte = int.tryParse(item.startByte ?? "1") ?? 1;
          int noOfBytes = int.tryParse(item.byte ?? "0") ?? 0;
          double resolution = double.tryParse(item.resolution ?? "1.0") ?? 1.0;
          double offset = double.tryParse(item.offset ?? "0.0") ?? 0.0;
          bool isLittleEndian = (item.endian ?? "").toUpperCase().contains(
            "LITTLE",
          );

          // --- 3. HANDLE ENDIANNESS & BYTE EXTRACTION ---
          int startIdx = startByte - 1;
          if (startIdx + noOfBytes > rxArray.length) continue; // Safety check

          Uint8List pidBytes = rxArray.sublist(startIdx, startIdx + noOfBytes);

          if (isLittleEndian) {
            pidBytes = Uint8List.fromList(pidBytes.reversed.toList());
          }

          // --- 4. DECODE LOGIC ---
          // We use 'unsignedIntValue' as the base for math
          int unsignedIntValue = 0;
          for (int l = 0; l < noOfBytes; l++) {
            unsignedIntValue |= (pidBytes[l] << ((noOfBytes - 1 - l) * 8));
          }

          // Bit-coded masking
          if (item.bitCoded == "1") {
            int sBit = int.tryParse(item.startBit ?? "0") ?? 0;
            int nBits = int.tryParse(item.noOfBits ?? "0") ?? 0;

            if (noOfBytes == 1) {
              int mask = 0;
              for (int x = 0; x < nBits; x++) {
                mask |= (1 << (8 - (sBit + x)));
              }
              unsignedIntValue =
                  (unsignedIntValue & mask) >> (8 - sBit - nBits + 1);
            } else {
              int mask = (pow(2, nBits).toInt() - 1);
              unsignedIntValue =
                  (unsignedIntValue >> (noOfBytes * 8 - nBits - sBit + 1)) &
                  mask;
            }
          }

          // Handle Signal Type (Signed vs Unsigned)
          if (pidType == "SIGNED" || item.numType == "SIGNED") {
            int signedValue = _toSigned(unsignedIntValue, noOfBytes);
            dataValue = ((signedValue * resolution) + offset).toString();
          } else if (item.unit == "ASCII") {
            dataValue = String.fromCharCodes(
              pidBytes,
            ).replaceAll("\x00", "").trim();
          } else {
            // Default Continuous
            dataValue = ((unsignedIntValue * resolution) + offset).toString();
          }

          // Enumerated mapping (if frameOfPidMessage exists)
          if (item.frameOfPidMessage != null &&
              item.frameOfPidMessage!.isNotEmpty) {
            for (var msg in item.frameOfPidMessage!) {
              if (int.tryParse(msg.code ?? "") == unsignedIntValue) {
                dataValue = msg.message ?? dataValue;
                break;
              }
            }
          }

          databyteArray.add(
            ReadParameterResponseIvn(
              pidName: item.pidDescription,
              responseValue: dataValue,
              status: "NO_ERROR",
              unit: item.unit,
            ),
          );
        } else {
          databyteArray.add(
            ReadParameterResponseIvn(
              pidName: item.pidDescription,
              responseValue: "ERR",
              status: getivnframe.ecuResponseStatus,
              unit: "",
            ),
          );
        }
      }
    } catch (e) {
      print("Parsing Error: $e");
    }
    return databyteArray;
  }

  /// Helper for 2's complement conversion
  int _toSigned(int value, int byteCount) {
    int bits = byteCount * 8;
    int max = pow(2, bits).toInt();
    int limit = pow(2, bits - 1).toInt();
    return (value >= limit) ? value - max : value;
  }

  Future<List<WriteParameterResponse>?> writeParameters1(
    int noOfParameters,

    WriteParameterIndex writeParameterIndex,
    List<WriteParameterPID> writeParameterCollection,
  ) async {
    try {
      List<WriteParameterResponse> resultList = [];

      for (var pidItem in writeParameterCollection) {
        int diagnosticsMode = 0x00;
        int getSeedIndex = 0x00;
        // Convert enum to string for logic checking
        String indexStr = writeParameterIndex.toString();

        // 1. Session and Security Index Mapping
        if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK090A) {
          diagnosticsMode = 0x03;
          getSeedIndex = 0x09;
        } else if (writeParameterIndex ==
                WriteParameterIndex.UDS_DS1003_SK0102 ||
            writeParameterIndex == WriteParameterIndex.UDS_SK0102_DS1003) {
          diagnosticsMode = 0x03;
          getSeedIndex = 0x01;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0B0C) {
          diagnosticsMode = 0x03;
          getSeedIndex = 0x0B;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0304) {
          diagnosticsMode = 0x03;
          getSeedIndex = 0x03;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0506) {
          diagnosticsMode = 0x03;
          getSeedIndex = 0x05;
        } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003) {
          diagnosticsMode = 0x03;
        }

        // Initialize Response (Make sure ResponseArrayStatus class exists)
        var response = ResponseArrayStatus();
        Uint8List txFrame = Uint8List(2);

        int indexSK = indexStr.indexOf("SK");
        int indexDS = indexStr.indexOf("DS1");

        // 2. Security Access & Session Control Sequence
        if (indexStr.contains("NA")) {
          response.ecuResponseStatus = "NOERROR";
        } else if (indexSK < 0) {
          txFrame[0] = 0x10;
          txFrame[1] = diagnosticsMode;
          response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
        } else if (indexSK >= 0 && indexSK < indexDS) {
          // Security first
          // Pass the enum object directly, providing a default enum value if null
          response = await sendSeedKey(
            getSeedIndex,
            pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values[0],
          );
          if (response.ecuResponseStatus == "NOERROR") {
            txFrame[0] = 0x10;
            txFrame[1] = diagnosticsMode;
            response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
          }
        } else {
          // Session first
          txFrame[0] = 0x10;
          txFrame[1] = diagnosticsMode;
          response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
          if (response.ecuResponseStatus == "NOERROR") {
            // Pass the enum object directly, providing a default enum value if null
            response = await sendSeedKey(
              getSeedIndex,
              pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values[0],
            );
          }
        }

        // 3. Write Data By Identifier (Service 0x2E)
        if (response.ecuResponseStatus == "NOERROR" ||
            indexStr.contains("NA")) {
          // Ensure writePid is not null
          String pidHex = pidItem.writePid ?? "";
          Uint8List writeParaPID = Uint8List.fromList(hex.decode(pidHex));
          int totalBytes = pidItem.totalBytes ?? 0;

          // Frame: [Service 2E] + [PID Bytes] + [Data Bytes]
          Uint8List writeFrame = Uint8List(
            1 + writeParaPID.length + totalBytes,
          );
          writeFrame[0] = 0x2E;
          writeFrame.setRange(1, 1 + writeParaPID.length, writeParaPID);

          if (pidItem.variantList != null) {
            for (int k = 0; k < pidItem.variantList!.length; k++) {
              var variant = pidItem.variantList![k];

              if (variant.datatype == "IQA" && pidItem.writeInput != null) {
                const String iqaLookup = "ABCDEFGHIKLMNOPRSTUVWXYZ12345678";
                Uint8List iqaY = Uint8List(7);
                Uint8List iqaX = Uint8List(8);

                for (int i = 0; i < 7; i++) {
                  int charToMatch = pidItem.writeInput![(7 * k) + i];
                  int lookupIndex = iqaLookup.indexOf(
                    String.fromCharCode(charToMatch).toUpperCase(),
                  );
                  iqaY[i] = (lookupIndex != -1) ? lookupIndex : 0;
                }

                int temp =
                    ((iqaY[0] & 0x1F) << 27) |
                    ((iqaY[1] & 0x1F) << 22) |
                    ((iqaY[2] & 0x1F) << 17) |
                    ((iqaY[3] & 0x1F) << 12) |
                    ((iqaY[4] & 0x1F) << 7) |
                    ((iqaY[5] & 0x1F) << 2);

                iqaX[0] = (temp >> 24) & 0xFF;
                iqaX[1] = (temp >> 16) & 0xFF;
                iqaX[2] = (temp >> 8) & 0xFF;
                iqaX[3] = temp & 0xFF;
                iqaX[4] = (iqaY[6] << 3) & 0xFF;

                int startPos =
                    1 + writeParaPID.length + (variant.startByte ?? 0);
                writeFrame.setRange(startPos, startPos + 8, iqaX);
              } else if (pidItem.writeInput != null) {
                int startPos =
                    1 + writeParaPID.length + (variant.startByte ?? 0);
                writeFrame.setRange(
                  startPos,
                  startPos + pidItem.writeInput!.length,
                  pidItem.writeInput!,
                );
              }
            }
          }

          response = await _dongleComm.can2xTxRx(
            writeFrame.length,
            hex.encode(writeFrame),
          );

          resultList.add(
            WriteParameterResponse(
              status: response.ecuResponseStatus,
              dataArray: response.actualDataBytes,
              pidName: pidItem.pidName,
              pidNumber: pidItem.writeParaNo,
              responseValue: response.ecuResponseStatus,
            ),
          );
        } else {
          resultList.add(
            WriteParameterResponse(
              status: response.ecuResponseStatus,
              pidName: pidItem.pidName,
              pidNumber: pidItem.writeParaNo,
              responseValue: response.ecuResponseStatus,
            ),
          );
        }
      }
      return resultList;
    } catch (e) {
      print("Error in writeParameters: $e");
      return null;
    }
  }

  Future<List<WriteParameterResponse>?> writeParameters(
    int noOfParameters,
    WriteParameterIndex writeParameterIndex,
    List<WriteParameterPID> writeParameterCollection,
  ) async {
    try {
      print(
        "🔹 writeParameters() started. Handling ${writeParameterCollection.length} PIDs",
      );
      List<WriteParameterResponse> resultList = [];

      for (var pidItem in writeParameterCollection) {
        print("\n➡ Processing: ${pidItem.pidName}");

        // 1. Session and Seed Mapping
        int diagnosticsMode = 0x03;
        int getSeedIndex = 0x00;
        String indexStr = writeParameterIndex.toString();

        if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK090A) {
          getSeedIndex = 0x09;
        } else if (writeParameterIndex ==
                WriteParameterIndex.UDS_DS1003_SK0102 ||
            writeParameterIndex == WriteParameterIndex.UDS_SK0102_DS1003) {
          getSeedIndex = 0x01;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0B0C) {
          getSeedIndex = 0x0B;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0304) {
          getSeedIndex = 0x03;
        } else if (writeParameterIndex ==
            WriteParameterIndex.UDS_DS1003_SK0506) {
          getSeedIndex = 0x05;
        }

        var response = ResponseArrayStatus();
        int indexSK = indexStr.indexOf("SK");
        int indexDS = indexStr.indexOf("DS1");

        // 2. Security Access & Session Control Sequence
        if (indexStr.contains("NA")) {
          response.ecuResponseStatus = "NOERROR";
        } else if (indexSK < 0) {
          response = await _dongleComm.can2xTxRx(
            2,
            hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
          );
        } else if (indexSK >= 0 && indexSK < indexDS) {
          response = await sendSeedKey(
            getSeedIndex,
            pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values.first,
          );
          if (response.ecuResponseStatus == "NOERROR") {
            response = await _dongleComm.can2xTxRx(
              2,
              hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
            );
          }
        } else {
          response = await _dongleComm.can2xTxRx(
            2,
            hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
          );
          if (response.ecuResponseStatus == "NOERROR") {
            response = await sendSeedKey(
              getSeedIndex,
              pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values.first,
            );
          }
        }

        // 3. Data Write Execution (Service 0x2E)
        if (response.ecuResponseStatus == "NOERROR" ||
            indexStr.contains("NA")) {
          if (pidItem.writePid == null) continue;

          Uint8List writeParaPID = Uint8List.fromList(
            hex.decode(pidItem.writePid!),
          );
          int totalBytes = pidItem.totalBytes ?? 0;

          // Structure: [0x2E] + [PID] + [DATA]
          Uint8List writeFrame = Uint8List(
            1 + writeParaPID.length + totalBytes,
          );
          writeFrame[0] = 0x2E;
          writeFrame.setRange(1, 1 + writeParaPID.length, writeParaPID);

          if (pidItem.writeInput != null) {
            int dataStartIndex = 1 + writeParaPID.length;
            int bytesToCopy = pidItem.writeInput!.length > totalBytes
                ? totalBytes
                : pidItem.writeInput!.length;
            writeFrame.setRange(
              dataStartIndex,
              dataStartIndex + bytesToCopy,
              pidItem.writeInput!,
            );
          }

          print("  🔹 Transmitting Write Frame: ${hex.encode(writeFrame)}");

          // 4. Initial Write Request
          response = await _dongleComm.can2xTxRx(
            writeFrame.length,
            hex.encode(writeFrame),
          );

          // 5. THE FIX: Handle NRC 0x78 (Response Pending)
          // ECU returns 7F 2E 78 when writing to NVM (VIN/Flash).
          int retryCount = 0;
          while (response.actualDataBytes != null &&
              response.actualDataBytes!.length >= 3 &&
              response.actualDataBytes![0] == 0x7F &&
              response.actualDataBytes![2] == 0x78 &&
              retryCount < 10) {
            print(
              "  ⏳ ECU Busy (NRC 78). Waiting 500ms... Attempt ${retryCount + 1}",
            );
            await Future.delayed(const Duration(milliseconds: 500));

            // Re-check response (Asking dongle for next buffer)
            response = await _dongleComm.can2xTxRx(
              writeFrame.length,
              hex.encode(writeFrame),
            );
            retryCount++;
          }

          // 6. BUFFER SCANNING: Verify Success SID 0x6E
          // If the buffer contains 0x6E (Positive Response SID), it's a success
          if (response.actualDataBytes != null &&
              response.actualDataBytes!.contains(0x6E)) {
            response.ecuResponseStatus = "NOERROR";
            print("  ✅ Write Success Verified (0x6E found)");
          }

          resultList.add(
            WriteParameterResponse(
              status: response.ecuResponseStatus,
              dataArray: response.actualDataBytes,
              pidName: pidItem.pidName,
              pidNumber: pidItem.writeParaNo,
              responseValue: response.ecuResponseStatus,
            ),
          );
        } else {
          print("  ❌ Preamble failed: ${response.ecuResponseStatus}");
          resultList.add(
            WriteParameterResponse(
              status: response.ecuResponseStatus,
              pidName: pidItem.pidName,
              pidNumber: pidItem.writeParaNo,
              responseValue: response.ecuResponseStatus,
            ),
          );
        }
      }
      return resultList;
    } catch (e) {
      print("❌ writeParameters Error: $e");
      return null;
    }
  }

  Future<WriteParameterResponse> actuatorTestWriteParameters(
    WriteParameterIndex writeParameterIndex,
    SEEDKEYINDEXTYPE seedKeyIndex,
    List<Uint8List> actuatorCmd,
  ) async {
    WriteParameterResponse writeParameterResp = WriteParameterResponse();

    try {
      int diagnosticsMode = 0x00;
      int getSeedIndex = 0x00;
      String indexStr = writeParameterIndex.toString();

      // 1. Mapping Session and Seed/Key Indices
      if (writeParameterIndex == WriteParameterIndex.UDS) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK090A) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x09;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0102 ||
          writeParameterIndex == WriteParameterIndex.UDS_SK0102_DS1003) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0B0C) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x0B;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0304) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x03;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0506) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x05;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003) {
        diagnosticsMode = 0x03;
      }

      ResponseArrayStatus response = ResponseArrayStatus();
      Uint8List txFrame = Uint8List(2);

      int indexSK = indexStr.indexOf("SK");
      int indexDS = indexStr.indexOf("DS1");

      // 2. Logic for Security Access and Diagnostic Session order
      if (indexStr.contains("NA")) {
        // Logic for NA: usually means no preamble required
        response.ecuResponseStatus = "NOERROR";
      } else if (indexSK < 0) {
        // Just Diagnostic Session
        txFrame[0] = 0x10;
        txFrame[1] = diagnosticsMode;
        response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
      } else if (indexSK >= 0 && indexSK < indexDS) {
        // SeedKey First, then Session
        response = await sendSeedKey(
          getSeedIndex,
          seedKeyIndex,
        ); // Correct: passes the Enum
        if (response.ecuResponseStatus == "NOERROR") {
          txFrame[0] = 0x10;
          txFrame[1] = diagnosticsMode;
          response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
        }
      } else {
        // Session First, then SeedKey
        txFrame[0] = 0x10;
        txFrame[1] = diagnosticsMode;
        response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
        if (response.ecuResponseStatus == "NOERROR") {
          response = await sendSeedKey(
            getSeedIndex,
            seedKeyIndex,
          ); // Correct: passes the Enum
        }
      }

      // 3. Actuator Command Execution (Service 0x2F / IO Control)
      if (response.ecuResponseStatus == "NOERROR") {
        for (var item in actuatorCmd) {
          // Send actual actuator control bytes
          response = await _dongleComm.can2xTxRx(item.length, hex.encode(item));

          writeParameterResp = WriteParameterResponse(
            status: response.ecuResponseStatus,
            dataArray: response.actualDataBytes,
            responseValue: response.ecuResponseStatus,
          );
        }
      } else {
        // Handle preamble failure
        writeParameterResp = WriteParameterResponse(
          status: response.ecuResponseStatus,
          dataArray: response.actualDataBytes,
          responseValue: response.ecuResponseStatus,
        );
      }
    } catch (e) {
      // Handle or log exception
      print("Error in Actuator Test: $e");
    }

    return writeParameterResp;
  }

  ECUCalculateSeedkey calculateSeedkey = ECUCalculateSeedkey();

  Future<ResponseArrayStatus> sendSeedKey(
    int getSeedIndex,
    SEEDKEYINDEXTYPE seedKeyIndex,
  ) async {
    ResponseArrayStatus response = ResponseArrayStatus();
    Uint8List txFrame = Uint8List(2);
    int frameLength = 2;

    /* 1. Send get seed command to ECU (0x27) */
    txFrame[0] = 0x27;
    txFrame[1] = getSeedIndex;

    response = await _dongleComm.can2xTxRx(
      frameLength,
      byteArrayToHexString(txFrame),
    );
    String? status = response.ecuResponseStatus;

    /* 2. Handle Required Time Delay loop */
    while (status == "ECUERROR REQUIREDTIMEDELAYNOTEXPIRED") {
      // In Flutter/Dart, use Future.delayed instead of Thread.Sleep
      await Future.delayed(const Duration(milliseconds: 300));
      response = await _dongleComm.can2xTxRx(
        frameLength,
        byteArrayToHexString(txFrame),
      );
      status = response.ecuResponseStatus;
    }

    if (status == "NOERROR") {
      Uint8List? rxArray = response.actualDataBytes;
      if (rxArray != null && rxArray.length >= 2) {
        // Extract seed array (skipping SID and Sub-function)
        Uint8List seedArray = rxArray.sublist(2);

        /* 3. Calculate the Key */
        // Note: We use the local _calculateSeedKey instance
        final Map<String, dynamic> result = _calculateSeedKey.calculateSeedKey(
          seedKeyIndex,
          seedArray.length,
          seedArray,
        );

        // Extract values from the returned Map
        int numKeyBytes = result["numKeyBytes"] ?? 0;
        Uint8List actualKey = result["key"] ?? Uint8List(0);

        if (status == "NOERROR" && numKeyBytes > 0) {
          /* 4. Prepare Send Key Frame: [0x27, SubFunc+1, Key...] */
          Uint8List newTxFrame = Uint8List(numKeyBytes + 2);
          newTxFrame[0] = 0x27;
          newTxFrame[1] = (getSeedIndex + 1) & 0xFF;

          // Copy calculated key into the frame
          newTxFrame.setRange(2, 2 + numKeyBytes, actualKey);

          /* 5. Send calculated key to ECU */
          response = await _dongleComm.can2xTxRx(
            newTxFrame.length,
            byteArrayToHexString(newTxFrame),
          );
        }
      }
    }
    return response;
  }

  // Global or Class-level variables to track state
  bool testCondition = false;
  bool stopTimer = true;

  Future<ResponseArrayStatus> iorTestParameters1({
    required SEEDKEYINDEXTYPE seedKeyIndex1,
    required WriteParameterIndex writeParameterIndex,
    required String startCommand,
    required String requestCommand,
    required String stopCommand,
    required bool inputTestCondition,
    required int bitPosition,
    required String activeCommand,
    required String completeCommand,
    required String failCommand,
    required bool isStop,
    required int timeBase,
  }) async {
    print("-------START IOR TEST METHOD-------");
    ResponseArrayStatus responseArrayStatus = ResponseArrayStatus();

    if (!isStop) {
      print("-------Entered-------");
      testCondition = true;
      int diagnosticsMode = 0x00;
      int getSeedIndex = 0x00;

      // 1. Session and Seed Index Mapping
      if (writeParameterIndex == WriteParameterIndex.UDS) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK090A) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x09;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0102) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0B0C) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x0B;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0304) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x03;
      } else if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK0506) {
        diagnosticsMode = 0x03;
        getSeedIndex = 0x05;
      }

      // 2. Start Diagnostic Session
      Uint8List txFrame = Uint8List(2);
      txFrame[0] = 0x10;
      txFrame[1] = diagnosticsMode;

      print("-------Send the parameter ID to the ECU-------");
      responseArrayStatus = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));

      if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
        // 3. Security Access (Request Seed)
        txFrame[0] = 0x27;
        txFrame[1] = getSeedIndex;
        print("-------Send get seed command to ECU-------");
        responseArrayStatus = await _dongleComm.can2xTxRx(
          2,
          hex.encode(txFrame),
        );

        if (responseArrayStatus.ecuResponseStatus ==
            "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
          await Future.delayed(const Duration(milliseconds: 11000));
          responseArrayStatus = await _dongleComm.can2xTxRx(
            2,
            hex.encode(txFrame),
          );
        }

        if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
          // 4. Send Security Key
          responseArrayStatus = await sendSeedKey(getSeedIndex, seedKeyIndex1);

          if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
            print("-------START COMMAND SENDING-------");
            responseArrayStatus = await _dongleComm.can2xTxRx(
              startCommand.length ~/ 2,
              startCommand,
            );

            if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
              // 5. Timer Logic (Async Countdown)
              if (timeBase > 0) {
                stopTimer = true;
                testCondition = true;

                int localTimeBase = timeBase;
                Timer.periodic(const Duration(seconds: 1), (timer) async {
                  localTimeBase -= 1;
                  print("Count : $localTimeBase");

                  if (localTimeBase < 1 && testCondition) {
                    print("Condition True : $localTimeBase");
                    stopTimer = testCondition = false;
                    timer.cancel();
                    print("-------STOP COMMAND SENDING-------");
                    await _dongleComm.can2xTxRx(
                      stopCommand.length ~/ 2,
                      stopCommand,
                    );
                  }

                  if (!stopTimer) timer.cancel();
                });
              }

              // 6. Polling Loop (Request Command)
              while (testCondition) {
                responseArrayStatus = await _dongleComm.can2xTxRx(
                  requestCommand.length ~/ 2,
                  requestCommand,
                );

                if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
                  Uint8List rxData = responseArrayStatus.actualDataBytes!;
                  int activeByte = rxData[bitPosition - 1];

                  int activeVal = int.parse(activeCommand, radix: 16);
                  int completeVal = int.parse(completeCommand, radix: 16);
                  int failVal = int.parse(failCommand, radix: 16);

                  if (activeByte != activeVal) {
                    testCondition = false;
                    if (activeByte == completeVal) {
                      responseArrayStatus.ecuResponseStatus = "Test Completed";
                    } else if (activeByte == failVal) {
                      responseArrayStatus.ecuResponseStatus = "Test Aborted";
                    }
                    testCondition = stopTimer = false;
                  }
                } else {
                  testCondition = stopTimer = false;
                }
                // Add a small delay to the while loop to prevent CPU pinning
                await Future.delayed(const Duration(milliseconds: 100));
              }
            }
          }
        }
      }
    } else {
      // 7. Manual Stop Logic
      stopTimer = testCondition = false;
      print("-------STOP COMMAND SENDING------- Stop");
      responseArrayStatus = await _dongleComm.can2xTxRx(
        stopCommand.length ~/ 2,
        stopCommand,
      );
      if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
        responseArrayStatus.ecuResponseStatus = "Test Stopped";
      }
    }

    return responseArrayStatus;
  }

  Future<ResponseArrayStatus> iorTestParameters({
    required SEEDKEYINDEXTYPE seedKeyIndex1,
    required WriteParameterIndex writeParameterIndex,
    required String startCommand,
    required String requestCommand,
    required String stopCommand,
    required bool testConditionParam,
    required int bitPosition,
    required List<String> activeCommand,
    required String completeCommand,
    required String failCommand,
    required bool isStop,
    required int timeBase,
  }) async {
    print("-------START IOR TEST METHOD-------");
    ResponseArrayStatus responseArrayStatus = ResponseArrayStatus();
    print("-------Entered-------");

    // Set test condition flag
    testCondition = true;

    // 1. Map session & seed index
    int diagnosticsMode = 0x00;
    int getSeedIndex = 0x00;

    switch (writeParameterIndex) {
      case WriteParameterIndex.UDS:
      case WriteParameterIndex.UDS_DS1003_SK0102:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
        break;
      case WriteParameterIndex.UDS_DS1003_SK090A:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x09;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0B0C:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x0B;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0304:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x03;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0506:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x05;
        break;
      case WriteParameterIndex.UDS_SK0102_DS1003:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WriteParameterIndex.UDS_DS1003:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    // 2. Send Diagnostic Session Command (0x10)
    Uint8List txFrame = Uint8List.fromList([0x10, diagnosticsMode]);
    print("-------Send diagnostic session command to ECU-------");
    responseArrayStatus = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));

    if (responseArrayStatus.ecuResponseStatus != "NOERROR")
      return responseArrayStatus;

    // 3. Request Seed (0x27)
    txFrame = Uint8List.fromList([0x27, getSeedIndex]);
    print("-------Request seed from ECU-------");
    responseArrayStatus = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));

    // Handle NRC 0x37 (required time delay)
    if (responseArrayStatus.ecuResponseStatus ==
        "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
      print("-------Waiting 11 seconds for NRC 0x37-------");
      await Future.delayed(const Duration(milliseconds: 11000));
      responseArrayStatus = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
    }

    if (responseArrayStatus.ecuResponseStatus != "NOERROR")
      return responseArrayStatus;

    // 4. Calculate Security Key
    Uint8List rxData = responseArrayStatus.actualDataBytes!;
    List<int> seedArray = rxData.sublist(2); // skip first 2 bytes

    final seedKeyResult = _calculateSeedKey.calculateSeedKey(
      seedKeyIndex1,
      seedArray.length,
      Uint8List.fromList(seedArray),
    );

    int numKeyBytes = seedKeyResult['numKeyBytes'] as int;
    List<int> keyList = seedKeyResult['key'] as List<int>;
    Uint8List actualKey = Uint8List.fromList(keyList);

    // 5. Send Key to ECU (0x27 sub-function)
    Uint8List keyTxFrame = Uint8List(numKeyBytes + 2);
    keyTxFrame[0] = 0x27;
    keyTxFrame[1] = getSeedIndex + 1; // sub-function for send key
    keyTxFrame.setRange(2, 2 + numKeyBytes, actualKey);

    responseArrayStatus = await _dongleComm.can2xTxRx(
      keyTxFrame.length,
      hex.encode(keyTxFrame),
    );

    if (responseArrayStatus.ecuResponseStatus != "NOERROR")
      return responseArrayStatus;

    // 6. Start the Routine (0x31)
    print("-------Start Routine Command-------");
    responseArrayStatus = await _dongleComm.can2xTxRx(
      startCommand.length ~/ 2,
      startCommand,
    );

    return responseArrayStatus;
  }

  bool activeCon = false;

  Future<ResponseArrayStatus> iorTestParameters2({
    SEEDKEYINDEXTYPE? seedKeyIndex1,
    WriteParameterIndex? writeParameterIndex,
    String? startCommand,
    String? requestCommand,
    String? stopCommand,
    bool? inputTestCondition,
    int? bitPosition,
    List<String>? activeCommands,
    String? completeCommand,
    String? failCommand,
    bool? isStop,
    int? timeBase,
    bool? isTimebase,
  }) async {
    print("-------START IOR TEST METHOD-------");

    ResponseArrayStatus responseArrayStatus = ResponseArrayStatus();

    bool stop = isStop ?? false;
    bool timebaseEnabled = isTimebase ?? false;
    int tb = timeBase ?? 0;

    if (!stop) {
      // TIMER LOGIC
      if (timebaseEnabled && tb > 0) {
        stopTimer = true;
        testCondition = true;
        int localTimeCounter = tb;

        Timer.periodic(const Duration(seconds: 1), (timer) async {
          localTimeCounter--;

          print("Count : $localTimeCounter");

          if (localTimeCounter < 1 && testCondition) {
            stopTimer = false;
            testCondition = false;
            timer.cancel();

            print("-------STOP COMMAND SENDING-------");

            var stopResult = await _dongleComm.can2xTxRx(
              (stopCommand!.length ~/ 2),
              stopCommand,
            );

            if (stopResult.ecuResponseStatus == "NOERROR") {
              print("Test stopped via Timer");
            }
          }

          if (!stopTimer) timer.cancel();
        });
      } else {
        testCondition = true;
      }

      // POLLING LOOP
      while (testCondition) {
        responseArrayStatus = await _dongleComm.can2xTxRx(
          (requestCommand!.length ~/ 2),
          requestCommand,
        );

        if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
          Uint8List rxBytes = responseArrayStatus.actualDataBytes!;
          int currentStatusByte = rxBytes[(bitPosition ?? 1) - 1];

          int completeByteVal = int.parse(completeCommand!, radix: 16);

          activeCon = false;

          for (var activeHex in (activeCommands ?? [])) {
            int activeByteVal = int.parse(activeHex, radix: 16);

            if (currentStatusByte == activeByteVal) {
              activeCon = true;
            }

            print(
              "Compare Byte = $currentStatusByte - $completeByteVal - $activeByteVal",
            );
          }

          if (!activeCon) {
            testCondition = false;
            stopTimer = false;

            if (currentStatusByte == completeByteVal) {
              responseArrayStatus.ecuResponseStatus = "Test Completed";
            } else if (currentStatusByte ==
                int.parse(failCommand!, radix: 16)) {
              responseArrayStatus.ecuResponseStatus = "Test Aborted";
            }
          }
        } else {
          testCondition = false;
          stopTimer = false;
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      stopTimer = false;
      testCondition = false;

      print("-------STOP COMMAND SENDING------- Stop");

      responseArrayStatus = await _dongleComm.can2xTxRx(
        (stopCommand!.length ~/ 2),
        stopCommand,
      );

      if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
        responseArrayStatus.ecuResponseStatus = "Test Stopped";
      }
    }

    return responseArrayStatus;
  }

  Future<ResponseArrayStatus> startIdIOR(
    SEEDKEYINDEXTYPE seedKeyIndex1,
    WriteParameterIndex writeParameterIndex,
    String startCommand,
  ) async {
    print("-------START IOR TEST METHOD-------");
    print("-------Entered-------");

    // In Flutter, these state flags are usually part of a controller or provider
    testCondition = true;

    int diagnosticsMode = 0x00;
    int getSeedIndex = 0x00;

    // 1. Session and Seed Index Mapping
    switch (writeParameterIndex) {
      case WriteParameterIndex.UDS:
      case WriteParameterIndex.UDS_DS1003_SK0102:
      case WriteParameterIndex.UDS_SK0102_DS1003:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x01;
        break;
      case WriteParameterIndex.UDS_DS1003_SK090A:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x09;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0B0C:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x0B;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0304:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x03;
        break;
      case WriteParameterIndex.UDS_DS1003_SK0506:
        diagnosticsMode = 0x03;
        getSeedIndex = 0x05;
        break;
      case WriteParameterIndex.UDS_DS1003:
        diagnosticsMode = 0x03;
        break;
      // ignore: unreachable_switch_default
      default:
        break;
    }

    ResponseArrayStatus response = ResponseArrayStatus();
    Uint8List txFrame = Uint8List(2);

    String enumString = writeParameterIndex.name;
    int indexSK = enumString.indexOf("SK");
    int indexDS = enumString.indexOf("DS1");

    // 2. Logic Flow for Session Control and Security Access
    if (enumString == "NA") {
      // Do nothing
    } else if (indexSK < 0) {
      // Session only
      txFrame[0] = 0x10;
      txFrame[1] = diagnosticsMode;
      response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
    } else if (indexSK >= 0 && indexSK < indexDS) {
      // Security first, then Session
      response = await sendSeedKey(getSeedIndex, seedKeyIndex1);
      if (response.ecuResponseStatus == "NOERROR") {
        txFrame[0] = 0x10;
        txFrame[1] = diagnosticsMode;
        response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
      }
    } else {
      // Session first, then Security
      txFrame[0] = 0x10;
      txFrame[1] = diagnosticsMode;
      response = await _dongleComm.can2xTxRx(2, hex.encode(txFrame));
      if (response.ecuResponseStatus == "NOERROR") {
        response = await sendSeedKey(getSeedIndex, seedKeyIndex1);
      }
    }

    // 3. Final Command Sending (Routine Control 0x31)
    if (response.ecuResponseStatus == "NOERROR") {
      print("-------START COMMAND SENDING-------");
      // length / 2 assumes startCommand is a Hex String
      response = await _dongleComm.can2xTxRx(
        startCommand.length ~/ 2,
        startCommand,
      );
    }

    return response;
  }

  /// Requests the current status of the IOR test
  Future<ResponseArrayStatus> requestIdIOR(String requestCommand) async {
    print("-------START IOR TEST METHOD-------");

    // Assuming dongleComm.CAN_TxRx takes (int length, String payload)
    // ~/ is integer division in Dart
    ResponseArrayStatus responseArrayStatus = await _dongleComm.can2xTxRx(
      requestCommand.length ~/ 2,
      requestCommand,
    );

    return responseArrayStatus;
  }

  /// Stops the IOR test and resets control flags on failure
  Future<ResponseArrayStatus> stopIdIOR(String stopCommand) async {
    print("-------STOP IOR TEST METHOD-------");
    print("STOP COMMAND SENDING : $stopCommand");

    ResponseArrayStatus responseArrayStatus = await _dongleComm.can2xTxRx(
      stopCommand.length ~/ 2,
      stopCommand,
    );

    if (responseArrayStatus.ecuResponseStatus == "NOERROR") {
      // Success logic can be placed here if needed
    } else {
      // Resetting global/class-level flags used for polling
      testCondition = false;
      stopTimer = false;
    }

    return responseArrayStatus;
  }

  Future<String?> startEcuUnlocking(
    String txFrame,
    String txFrequency,
    String txTotalTime,
  ) async {
    try {
      // 1. Prepare parameters
      int frameLen = txFrame.length ~/ 2;
      int frequencyMs = int.tryParse(txFrequency) ?? 100;
      int totalTimeMs = int.tryParse(txTotalTime) ?? 5000;

      // Stopwatch to track total duration
      Stopwatch stopwatch = Stopwatch()..start();

      // Completer allows us to return the function only after the timer finishes
      Completer<String> completer = Completer<String>();

      // 2. Start the Periodic Timer
      Timer.periodic(Duration(milliseconds: frequencyMs), (timer) async {
        if (stopwatch.elapsedMilliseconds < totalTimeMs) {
          // Send the frame asynchronously
          try {
            // Assuming _dongleComm.CAN_TxRx is your communication method
            var response = await _dongleComm.can2xTxRx(frameLen, txFrame);
            print(
              "Sent frame: $txFrame, Response: ${response.ecuResponseStatus}",
            );
          } catch (e) {
            print("Transmission Error: $e");
          }
        } else {
          // 3. Cleanup and finish
          stopwatch.stop();
          timer.cancel();
          completer.complete("FINISHED"); // Or any status mapping you prefer
        }
      });

      return await completer.future;
    } catch (ex) {
      print("EcuUnlocking Exception: $ex");
      return null;
    }
  }

  // Use 'int' in Dart as it handles 64-bit integers (replaces uint/long)
  int totalBytesToBeFlashed = 0;
  int realTimeBytesFlashed = 0;
  bool _bulkTransferCompleteLogged = false;

  /// Calculates the current progress as a decimal (0.0 to 1.0)
  Future<double> getRuntimeFlashPercent() async {
    if (totalBytesToBeFlashed == 0) return 0.0;

    // In Dart, int / double automatically returns a double
    double runtimeFlashPercent = realTimeBytesFlashed / totalBytesToBeFlashed;
    return runtimeFlashPercent;
  }

  /// Resets the flashing counters
  Future<void> resetPercentage() async {
    totalBytesToBeFlashed = 0;
    realTimeBytesFlashed = 0;
  }

  //   // Equivalent to List<LoopModel> loopModelList = new List<LoopModel>();
  List<LoopModel> loopModelList = [];

  // ── flashInterpreter with seed-key lock release callback ────────
  // onBulkDataStart: called the moment "sendbulkdata" first runs.
  // wifi_plugin uses this to release _seedKeyLock EARLY so the
  // next ECU can run its seed key while this ECU does bulk transfer.
  Future<String?> flashInterpreter(
    FlashConfig flashConfigData,
    int noOfSectors,
    List<FlashingMatrix> sectorData,
    String interpreterFile, {
    void Function()? onBulkDataStart,
  }) async {
    realTimeBytesFlashed = 0;
    totalBytesToBeFlashed = 0;
    _bulkTransferCompleteLogged = false;

    ResponseArrayStatus? reprogrammingResponse = ResponseArrayStatus();
    List<LoopModel> loopModelList = [];

    try {
      List<String> lineData = interpreterFile.split('\n');
      for (int i = 0; i < noOfSectors; i++) {
        int start = int.parse(sectorData[i.clamp(0, sectorData.length - 1)].jsonStartAddress!, radix: 16);
        int end = int.parse(sectorData[i.clamp(0, sectorData.length - 1)].jsonEndAddress!, radix: 16);

        int sectorNumBytes = end - start + 1;

        totalBytesToBeFlashed += sectorNumBytes;

        // ⚠️ Same as your C# (but logically this should be outside loop)
        realTimeBytesFlashed = 0;
      }

      Uint8List seedKey = Uint8List(0);
      int currSectorIndex = 0;
      bool skipKey = false;
      int loopInit = 0;
      bool isLoopPresent = false;

      for (int i = 0; i < lineData.length; i++) {
        String line = lineData[i].replaceAll('\r', '').trim();
        if (line.isEmpty || line.startsWith("//")) continue;

        if (skipKey) {
          skipKey = false;
          continue;
        }

        String command = line.split(':')[0];
        String info = line.contains(':') ? line.split(':')[1] : "";
        print('📜 [seq line $i] command="$command" @ ${DateTime.now()}');

        // ================= SEND COMMAND HANDLER =================
        if ([
          "send",
          "sendroutine",
          "sendroutinekwp",
          "sendignore",
        ].contains(command)) {
          List<String> splitData = info.split('+');
          BytesBuilder txFrameBuilder = BytesBuilder();

          for (var item in splitData) {
            if (!item.contains("<")) {
              // Direct hex string
              txFrameBuilder.add(hex.decode(item.trim()));
            } else {
              // Placeholder logic: <reference, length>
              int endIndex = item.indexOf('>');
              String bracketString = item.substring(1, endIndex);
              var parts = bracketString.split(',');
              String reference = parts[0];

              bool isCopyMSB = false;
              int copyLength;

              if (parts[1].contains('-')) {
                isCopyMSB = true;
                copyLength = int.parse(parts[1].substring(1), radix: 16);
              } else {
                copyLength = int.parse(parts[1], radix: 16);
              }

              Uint8List copyArray = Uint8List(0);

              // Handle References
              if (reference.contains("key")) {
                copyArray = seedKey;
              } else if (reference.contains("json_strt_addr") ||
                  reference.contains("ecu_memmap_strt_addr")) {
                int index = reference.contains("[i]")
                    ? loopModelList.last.i!
                    : int.tryParse(
                            RegExp(r'\d+').firstMatch(reference)?.group(0) ??
                                '0',
                          ) ??
                          0;

                // SAFETY: clamp index to valid sectorData range
                final safeIndex1 = index.clamp(0, sectorData.length - 1);
                currSectorIndex = safeIndex1;
                String addr = reference.contains("json_strt_addr")
                    ? sectorData[safeIndex1].jsonStartAddress ?? "0"
                    : sectorData[safeIndex1].ecuMemMapStartAddress ?? "0";

                copyArray = Uint8List.fromList(
                  hex.decode(addr.padLeft(copyLength * 2, '0')),
                );
              } else if (reference.contains("json_end_addr") ||
                  reference.contains("ecu_memmap_end_addr")) {
                int index = reference.contains("[i]")
                    ? loopModelList.last.i!
                    : int.tryParse(
                            RegExp(r'\d+').firstMatch(reference)?.group(0) ??
                                '0',
                          ) ??
                          0;

                // SAFETY: clamp index to valid sectorData range
                final safeIndex2 = index.clamp(0, sectorData.length - 1);
                currSectorIndex = safeIndex2;
                String addr = reference.contains("json_end_addr")
                    ? sectorData[safeIndex2].jsonEndAddress ?? "0"
                    : sectorData[safeIndex2].ecuMemMapEndAddress ?? "0";

                copyArray = Uint8List.fromList(
                  hex.decode(addr.padLeft(copyLength * 2, '0')),
                );
              } else if (reference.contains("json_sector_len") ||
                  reference.contains("ecu_memmap_len")) {
                int index = reference.contains("[i]")
                    ? loopModelList.last.i!
                    : int.tryParse(
                            RegExp(r'\d+').firstMatch(reference)?.group(0) ??
                                '0',
                          ) ??
                          0;

                currSectorIndex = index;
                int start = int.parse(
                  reference.contains("json_sector_len")
                      ? sectorData[index.clamp(0, sectorData.length - 1)].jsonStartAddress!
                      : sectorData[index.clamp(0, sectorData.length - 1)].ecuMemMapStartAddress!,
                  radix: 16,
                );
                int end = int.parse(
                  reference.contains("json_sector_len")
                      ? sectorData[index.clamp(0, sectorData.length - 1)].jsonEndAddress!
                      : sectorData[index.clamp(0, sectorData.length - 1)].ecuMemMapEndAddress!,
                  radix: 16,
                );
                int len = end - start + 1;

                copyArray = Uint8List.fromList(
                  hex.decode(
                    len.toRadixString(16).padLeft(copyLength * 2, '0'),
                  ),
                );
              } else if (reference.contains("json_checksum")) {
                int index = reference.contains("[i]")
                    ? loopModelList.last.i!
                    : int.tryParse(
                            RegExp(r'\d+').firstMatch(reference)?.group(0) ??
                                '0',
                          ) ??
                          0;

                currSectorIndex = index;
                copyArray = Uint8List.fromList(
                  hex.decode(
                    (sectorData[index.clamp(0, sectorData.length - 1)].jsonCheckSum ?? "0").padLeft(
                      copyLength * 2,
                      '0',
                    ),
                  ),
                );
              } else if (reference == "i") {
                copyArray = Uint8List.fromList([
                  (loopModelList.last.i ?? 0) + loopInit,
                ]);
              }

              // MSB/LSB Slicing logic
              if (!isCopyMSB && copyArray.length > copyLength) {
                copyArray = copyArray.sublist(copyArray.length - copyLength);
              }

              // Resize/Pad to fit copyLength exactly
              Uint8List finalPart = Uint8List(copyLength);
              for (int k = 0; k < copyArray.length && k < copyLength; k++) {
                finalPart[k] = copyArray[k];
              }
              txFrameBuilder.add(finalPart);
            }
          }

          Uint8List txFrame = txFrameBuilder.toBytes();
          print("Sending Command: ${hex.encode(txFrame)}");

          var sendResp = await _dongleComm.can2xTxRx(
            txFrame.length,
            hex.encode(txFrame),
          );

          if (command != "sendignore") {
            reprogrammingResponse = sendResp;
          }

          // Handle Security Delay
          while (reprogrammingResponse?.ecuResponseStatus ==
              "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
            await Future.delayed(const Duration(milliseconds: 300));
            reprogrammingResponse = await _dongleComm.can2xTxRx(
              txFrame.length,
              hex.encode(txFrame),
            );
          }

          // Error check
          if (reprogrammingResponse?.ecuResponseStatus != "NOERROR" &&
              command != "sendignore") {
            print(
              "--------- reprogrammingResponse ERROR ------------: ${reprogrammingResponse?.ecuResponseStatus}",
            );
            return reprogrammingResponse?.ecuResponseStatus ?? "ERROR";
          }
          if (command == "sendroutine") {
            // Construct routine request command
            String routineReqCommand =
                "3103" + splitData[0].trim().substring(4);

            bool isRoutineLoop = true;
            while (isRoutineLoop) {
              // Wait 500ms between each command send
              await Future.delayed(Duration(milliseconds: 500));

              print("Sending Command $routineReqCommand");

              var reprogrammingResponse = await _dongleComm.can2xTxRx(
                routineReqCommand.length ~/ 2, // length in bytes
                routineReqCommand, // sending as hex string
              );

              if (reprogrammingResponse.ecuResponseStatus != "NOERROR") {
                print(
                  "--------- reprogrammingResponse ERROR: ${reprogrammingResponse.ecuResponseStatus}",
                );
                print(
                  "--------- reprogrammingResponse LOOP END: ${reprogrammingResponse.ecuResponseStatus}",
                );
                isRoutineLoop = false;
                return reprogrammingResponse.ecuResponseStatus;
              }
              // Check ECU ActualDataBytes[4] status
              else if (reprogrammingResponse.actualDataBytes![4] == 0x02) {
                isRoutineLoop = false;
              } else if (reprogrammingResponse.actualDataBytes![4] == 0x01) {
                isRoutineLoop = false;
                // Optional: handle "Routine Test Aborted"
                // return "Routine Test Aborted";
              } else if (reprogrammingResponse.actualDataBytes![4] == 0x04) {
                isRoutineLoop = false;
              }
            }
          }
          // if (command == "sendroutine") {
          //   String routineReqCommand =
          //       "3103${splitData[0].trim().substring(4)}";
          //   bool isRoutineLoop = true;
          //   while (isRoutineLoop) {
          //     await Future.delayed(Duration(milliseconds: 50));
          //     print("Sending Command $routineReqCommand");
          //     reprogrammingResponse = await _dongleComm.can2xTxRx(
          //       routineReqCommand.length ~/ 2,
          //       routineReqCommand,
          //     );
          //     if (reprogrammingResponse.ecuResponseStatus != "NOERROR") {
          //       print(
          //         "--------- reprogrammingResponse ERROR------------== ${reprogrammingResponse.ecuResponseStatus}",
          //       );
          //       print(
          //         "---------reprogrammingResponse LOOP END------------== ${reprogrammingResponse.ecuResponseStatus}",
          //       );
          //       isRoutineLoop = false;
          //       return reprogrammingResponse.ecuResponseStatus;
          //     } else if (reprogrammingResponse.actualDataBytes![4] == 0x02) {
          //       isRoutineLoop = false;
          //     } else if (reprogrammingResponse.actualDataBytes![4] == 0x01) {
          //       isRoutineLoop = false;
          //     } else if (reprogrammingResponse.actualDataBytes![4] == 0x04) {
          //       isRoutineLoop = false;
          //     }
          //   }
          // }
          // ================= ROUTINE CONTROL (KWP) =================
          else if (command == "sendroutinekwp") {
            String routineReqCommand = "33${splitData[0].substring(2, 4)}";
            bool isRoutineLoop = true;

            while (isRoutineLoop) {
              await Future.delayed(const Duration(milliseconds: 50));
              reprogrammingResponse = await _dongleComm.can2xTxRx(
                routineReqCommand.length ~/ 2,
                routineReqCommand,
              );

              // If not a negative response (0x7F)
              if (reprogrammingResponse.actualDataBytes?[0] != 0x7F) {
                isRoutineLoop = false;
              }
            }
          }
        }
        // ================= SEED / KEY =================
        // else if (command == "function" &&
        //         info.contains("CalculateKeyFromSeed")) {
        //       // Extract info inside brackets, e.g., [BOSCH_BS6_PROD, 4]
        //       String sqrBktInfo = info.substring(
        //         info.indexOf('[') + 1,
        //         info.indexOf(']'),
        //       );
        //       List<String> bktParts = sqrBktInfo.split(',');
        //       String enumName = bktParts[0].trim().replaceAll('-', '_');
        //       int seedLength = int.tryParse(bktParts[1].trim()) ?? 0;
        //       // Map the string from the file to your Dart Enum
        //       flashConfigData.seedKeyIndex = SEEDKEYINDEXTYPE.values.firstWhere(
        //         (e) => e.toString().split('.').last == enumName,
        //         orElse: () => SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD,
        //       );
        //       Uint8List seedArray = Uint8List(seedLength);
        //       List<int> actualData = reprogrammingResponse?.actualDataBytes ?? [];
        //       // UDS Seed Response is [0x67, SubFunc, Seed0, Seed1...]
        //       // The actual seed starts at index 2.
        //       if (actualData.length >= (seedLength + 2)) {
        //         seedArray = Uint8List.fromList(
        //           actualData.sublist(2, 2 + seedLength),
        //         );
        //         print("📋 Seed Received: ${byteArrayToHexString(seedArray)}");
        //       } else {
        //         return "ERROR_INVALID_SEED_LENGTH";
        //       }
        //       // If seed is all zeros, ECU might already be unlocked
        //       if (seedArray.every((b) => b == 0)) {
        //         print("ℹ️ Seed is all zeros, skipping key transmission.");
        //         skipKey = true;
        //       } else {
        //         // Call the calculation class (Returns Map<String, dynamic>)
        //         // ensure _calculateSeedKey is initialized in your constructor
        //         Map<String, dynamic> result = _calculateSeedKey.calculateSeedKey(
        //           flashConfigData.seedKeyIndex!,
        //           seedArray.length,
        //           seedArray,
        //         );
        //         if (result.containsKey('key') && result['numKeyBytes'] > 0) {
        //           seedKey = Uint8List.fromList(result['key']);
        //           print("🔑 Key Generated: ${byteArrayToHexString(seedKey)}");
        //         } else {
        //           print("❌ Seed-Key Calculation Failed");
        //           return "ERROR_KEY_CALCULATION_FAILED";
        //         }
        //       }
        //     }
        else if (command == "function") {
          if (info.contains("CalculateKeyFromSeed")) {
            String seedkeynumbytes = "";

            // 1. Extract content inside [ ... ]
            int start = info.indexOf('[');
            int end = info.indexOf(']');
            if (start == -1 || end == -1) return "ERROR_PARSING_INFO";

            String sqrBktInfo = info.substring(start + 1, end);

            if (sqrBktInfo.contains(',')) {
              List<String> parts = sqrBktInfo.split(',');
              String enumName = parts[0].trim().replaceAll('-', '_');

              // Safety: Use firstWhere with orElse to prevent "No element" error
              flashConfigData.seedKeyIndex = SEEDKEYINDEXTYPE.values.firstWhere(
                (e) => e.toString().split('.').last == enumName,
                orElse: () => SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD,
              );
              seedkeynumbytes = parts[1].trim();
            } else {
              seedkeynumbytes = sqrBktInfo.trim();
            }

            // 2. Determine seed length (Handle both Hex "08" and Decimal "8")
            int seedLength = int.tryParse(seedkeynumbytes, radix: 16) ?? 0;
            if (seedLength == 0)
              seedLength = int.tryParse(seedkeynumbytes) ?? 0;

            Uint8List seedArray = Uint8List(seedLength);

            // 3. Extract Seed from ECU Response
            List<int> actualData = reprogrammingResponse?.actualDataBytes ?? [];

            if (actualData.length >= 2) {
              // Correctly extract only the seed portion
              int availableBytes = actualData.length - 2;
              int bytesToCopy = availableBytes < seedLength
                  ? availableBytes
                  : seedLength;

              for (int i = 0; i < bytesToCopy; i++) {
                seedArray[i] = actualData[i + 2];
              }
            }

            print(
              "-------seed array = ${byteArrayToHexString(seedArray)}-------",
            );

            if (seedArray.every((x) => x == 0)) {
              skipKey = true;
              print("-------seed is zeros, skipping security-------");
            } else {
              calculateSeedkey = ECUCalculateSeedkey();
              print(
                "-------calculating key for index: ${flashConfigData.seedKeyIndex}-------",
              );

              // 4. Call calculation
              Map<String, dynamic> result = calculateSeedkey.calculateSeedKey(
                flashConfigData.seedKeyIndex!,
                seedArray.length,
                seedArray,
              );

              // 5. CRITICAL SAFETY CHECK: Prevent the RangeError
              if (result.containsKey('key') && result['key'] != null) {
                Uint8List tempKey = result['key'] is Uint8List
                    ? result['key']
                    : Uint8List.fromList(List<int>.from(result['key']));

                if (tempKey.isNotEmpty) {
                  // Success! Assign the generated key
                  seedKey = tempKey;
                  print(
                    "-------get key response = ${byteArrayToHexString(seedKey)}-------",
                  );
                } else {
                  print("❌ Calculation returned empty key buffer");
                  return "ERROR_CALCULATION_EMPTY";
                }
              } else {
                print("❌ Seed-Key Calculation Failed internally");
                return "ERROR_KEY_CALCULATION_FAILED";
              }
            }
          }
        }
        // ================= LOOP =================
        else if (command == "repeatstart") {
          isLoopPresent = true;
          List<String> splitData = info.split(',');

          // Determine the max iterations (either a fixed number or the total sectors)
          int maxIndex = splitData[3].trim() == "noofsectors"
              ? noOfSectors
              : int.parse(splitData[3].trim());

          // Parse the loop initialization offset
          loopInit = int.tryParse(splitData[2].trim()) ?? 0;

          // Add a new loop state to our stack
          loopModelList.add(
            LoopModel(
              i: 0,
              loopId: int.parse(splitData[0].trim()),
              maxIndex: maxIndex,
              loopLocation: i, // Store current line index to jump back to
            ),
          );
        } else if (command == "repeatend") {
          if (loopModelList.isNotEmpty) {
            // Increment the counter of the current (innermost) loop
            loopModelList.last.i = (loopModelList.last.i ?? 0) + 1;

            // Check if loop has reached completion
            if (loopModelList.last.i == loopModelList.last.maxIndex) {
              loopModelList.removeLast();
              // Update global loop presence flag
              isLoopPresent = loopModelList.isNotEmpty;
            } else {
              // Jump back to the 'repeatstart' line index
              // Subtracting 1 because the main loop's i++ will trigger next
              i = loopModelList.last.loopLocation!;
            }
          }
        }
        // ================= BULK DATA TRANSFER (Service 0x36) =================
        // else if (command == "sendbulkdata") {
        //   // 1️⃣ Parse sector info
        //   List<String> splitInfo = info.split(',');
        //   int blkSeqCnt = int.parse(splitInfo[1]);
        //   int ind2 = info.indexOf(',', info.indexOf(',') + 1);
        //   String transferInfo = info.substring(ind2 + 1);
        //   List<String> transferSplitData = transferInfo.split('+');
        //   // 2️⃣ Fixed frame size = 2000
        //   const int sectorFrameTransferLen = 2000;
        //   // 3️⃣ Preprocess template
        //   final List<Uint8List> templateFixedParts = [];
        //   final List<String> partTypes = [];
        //   final List<int> partLengths = [];
        //   final ByteData tempBD = ByteData(4);
        //   for (var item in transferSplitData) {
        //     String trimmed = item.trim();
        //     if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
        //       partTypes.add('fixed');
        //       templateFixedParts.add(Uint8List.fromList(hex.decode(trimmed)));
        //       partLengths.add(0);
        //     } else if (trimmed.contains("bsc")) {
        //       partTypes.add('bsc');
        //       templateFixedParts.add(Uint8List(0));
        //       partLengths.add(1);
        //     } else if (trimmed.contains("json_sectordata")) {
        //       partTypes.add('data');
        //       templateFixedParts.add(Uint8List(0));
        //       partLengths.add(0);
        //     } else if (trimmed.contains("json_strt_addr") ||
        //         trimmed.contains("sectordatasent")) {
        //       int len = int.parse(
        //         trimmed.substring(
        //           trimmed.indexOf(',') + 1,
        //           trimmed.indexOf('>'),
        //         ),
        //         radix: 16,
        //       );
        //       partTypes.add(
        //         trimmed.contains("json_strt_addr") ? 'addr' : 'len',
        //       );
        //       templateFixedParts.add(Uint8List(0));
        //       partLengths.add(len);
        //     }
        //   }
        //   // 4️⃣ Sector data & addresses
        //   int index = isLoopPresent ? loopModelList.last.i! : currSectorIndex;
        //   Uint8List sectorDataArray = Uint8List.fromList(
        //     hex.decode(sectorData[index].jsonData!),
        //   );
        //   int startAddr = int.parse(
        //     sectorData[index].jsonStartAddress!,
        //     radix: 16,
        //   );
        //   int sectorNumBytes =
        //       int.parse(sectorData[index].jsonEndAddress!, radix: 16) -
        //       startAddr +
        //       1;
        //   // 5️⃣ Reusable buffer
        //   final Uint8List reuseBuffer = Uint8List(sectorFrameTransferLen + 16);
        //   int offset = 0;
        //   // 6️⃣ Bulk transfer loop
        //   while (offset < sectorNumBytes) {
        //     // Always try to send 2000 bytes, last frame may be smaller
        //     int chunkLen = (sectorNumBytes - offset) < sectorFrameTransferLen
        //         ? (sectorNumBytes - offset)
        //         : sectorFrameTransferLen;
        //     int bufferPtr = 0;
        //     for (int i = 0; i < partTypes.length; i++) {
        //       String type = partTypes[i];
        //       if (type == 'fixed') {
        //         reuseBuffer.setRange(
        //           bufferPtr,
        //           bufferPtr + templateFixedParts[i].length,
        //           templateFixedParts[i],
        //         );
        //         bufferPtr += templateFixedParts[i].length;
        //       } else if (type == 'bsc') {
        //         reuseBuffer[bufferPtr++] = blkSeqCnt & 0xFF;
        //       } else if (type == 'data') {
        //         reuseBuffer.setRange(
        //           bufferPtr,
        //           bufferPtr + chunkLen,
        //           sectorDataArray,
        //           offset,
        //         );
        //         bufferPtr += chunkLen;
        //       } else if (type == 'addr' || type == 'len') {
        //         int val = (type == 'addr') ? startAddr : chunkLen;
        //         int len = partLengths[i];
        //         tempBD.setUint32(0, val, Endian.big);
        //         reuseBuffer.setRange(
        //           bufferPtr,
        //           bufferPtr + len,
        //           tempBD.buffer.asUint8List(0, len),
        //         );
        //         bufferPtr += len;
        //       }
        //     }
        //     // 7️⃣ Send frame
        //     final frameToSend = reuseBuffer.sublist(0, bufferPtr);
        //     int retry = 0;
        //     ResponseArrayStatus response;
        //     while (retry < 3) {
        //       response = await _dongleComm.can2xTxRx(
        //         frameToSend.length,
        //         hex.encode(frameToSend),
        //       );
        //       if (response.ecuResponseStatus == "NOERROR") break;
        //       retry++;
        //       await Future.delayed(const Duration(milliseconds: 50));
        //     }
        //     // 8️⃣ Update counters
        //     offset += chunkLen;
        //     startAddr += chunkLen;
        //     blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
        //     realTimeBytesFlashed += chunkLen;
        //   }
        //   print(
        //     "✅ Sector bulk transfer complete: $sectorNumBytes bytes flashed",
        //   );
        // }
        else if (command == "sendbulkdata") {
          // 🔓 RELEASE SEED KEY LOCK — bulk data starts here
          // Other ECU can now start its seed key sequence
          if (onBulkDataStart != null) {
            onBulkDataStart();
            onBulkDataStart = null; // call only once
          }
          List<String> splitInfo = info.split(',');
          int blkSeqCnt = int.parse(splitInfo[1]);
          int ind2 = info.indexOf(',', info.indexOf(',') + 1);
          String transferInfo = info.substring(ind2 + 1);
          List<String> transferSplitData = transferInfo.split('+');

          int sectorFrameTransferLen = 2000;

          int index = isLoopPresent ? loopModelList.last.i! : currSectorIndex;
          Uint8List sectorDataArray = Uint8List.fromList(
            hex.decode(sectorData[index.clamp(0, sectorData.length - 1)].jsonData!),
          );
          int sectorStartAddr = int.parse(
            sectorData[index.clamp(0, sectorData.length - 1)].jsonStartAddress!,
            radix: 16,
          );
          int sectorNumBytes =
              int.parse(sectorData[index.clamp(0, sectorData.length - 1)].jsonEndAddress!, radix: 16) -
              sectorStartAddr +
              1;
          // SAFETY: clamp sectorNumBytes to actual data array length
          if (sectorNumBytes > sectorDataArray.length) {
            sectorNumBytes = sectorDataArray.length;
          }

          int offset = 0;
          while (offset < sectorNumBytes) {
            int chunkLen = (sectorNumBytes - offset) < sectorFrameTransferLen
                ? (sectorNumBytes - offset)
                : sectorFrameTransferLen;

            // 🔥 Skip all-0xFF blocks — ECU rejects blank (erased) data blocks
            // .NET does the same — only send blocks with actual firmware data
            final chunk = sectorDataArray.sublist(offset, offset + chunkLen);
            final allFF = chunk.every((b) => b == 0xFF);
            if (allFF) {
              print('⚡ Skipping all-0xFF block at offset $offset (blank sector)');
              offset += chunkLen;
              sectorStartAddr += chunkLen;       // ECU address pointer still moves
              realTimeBytesFlashed += chunkLen;  // progress still counts
              // 🔥 FIX: Do NOT increment blkSeqCnt here!
              // ECU never receives this block, so its internal counter
              // does not advance. Incrementing here caused a mismatch
              // with the next real block sent -> WRONGBLOCKSEQCOUNTER.
              continue;
            }

            BytesBuilder frameBuilder = BytesBuilder(copy: false);
            for (var item in transferSplitData) {
              String trimmed = item.trim();

              if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
                frameBuilder.add(hex.decode(trimmed));
              } else if (trimmed.contains("bsc")) {
                frameBuilder.addByte(blkSeqCnt & 0xFF);
              } else if (trimmed.contains("json_sectordata")) {
                // Slice the firmware data
                frameBuilder.add(
                  sectorDataArray.sublist(offset, offset + chunkLen),
                );
              } else if (trimmed.contains("json_strt_addr")) {
                int copyLength = int.parse(
                  trimmed.substring(
                    trimmed.indexOf(',') + 1,
                    trimmed.indexOf('>'),
                  ),
                  radix: 16,
                );
                ByteData bd = ByteData(4)..setUint32(0, sectorStartAddr);
                Uint8List addrBytes = bd.buffer.asUint8List();
                frameBuilder.add(
                  addrBytes.sublist(addrBytes.length - copyLength),
                );
              } else if (trimmed.contains("sectordatasent")) {
                int copyLength = int.parse(
                  trimmed.substring(
                    trimmed.indexOf(',') + 1,
                    trimmed.indexOf('>'),
                  ),
                  radix: 16,
                );
                ByteData bd = ByteData(4)..setUint32(0, chunkLen);
                Uint8List lenBytes = bd.buffer.asUint8List();
                frameBuilder.add(
                  lenBytes.sublist(lenBytes.length - copyLength),
                );
              }
            }

            Uint8List finalFrame = frameBuilder.toBytes();

            // 🔥 YIELD POINT — critical for parallel flash on separate CAN buses
            // Without this, two ECUs' CRC16/hex-encode CPU work (synchronous)
            // can monopolize the single Dart event loop back-to-back, starving
            // the other ECU's socket reads long enough to trigger NRC 0x78
            // (ECU Busy) storms and apparent "freezing" even though each ECU
            // has its own separate physical CAN bus and dongle.
            await Future.delayed(Duration.zero);

            var response = await _dongleComm.can2xTxRx(
              finalFrame.length,
              hex.encode(finalFrame),
            );

            if (response.ecuResponseStatus != "NOERROR")
              return response.ecuResponseStatus;

            // Correct pointer updates
            offset += chunkLen;
            sectorStartAddr += chunkLen; // Move the ECU address pointer forward
            realTimeBytesFlashed += chunkLen;
            blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
            if (realTimeBytesFlashed >= totalBytesToBeFlashed && !_bulkTransferCompleteLogged) {
              _bulkTransferCompleteLogged = true;
              print('🏁🏁🏁 BULK DATA TRANSFER COMPLETE (100% of firmware bytes sent) '
                    '@ ${DateTime.now()} — entering post-transfer verification phase '
                    '(checksum/routine-control/reset commands). Any failure from '
                    'this point on is a VERIFICATION failure, not a data-transfer failure.');
            }
          }
        }
        //         else if (command == "sendbulkdata") {
        //   List<String> splitInfo = info.split(',');
        //   int blkSeqCnt = int.parse(splitInfo[1]);
        //   int ind1 = info.indexOf(',');
        //   int ind2 = info.indexOf(',', ind1 + 1);
        //   String transferInfo = info.substring(ind2 + 1);
        //   List<String> transferSplitData = transferInfo.split('+');
        //   // Override or force the frame length to 2000 bytes
        //   int sectorFrameTransferLen = 2000;
        //   int index = isLoopPresent ? loopModelList.last.i! : currSectorIndex;
        //   Uint8List sectorDataArray = Uint8List.fromList(
        //     hex.decode(sectorData[index].jsonData!),
        //   );
        //   int sectorStartAddr = int.parse(
        //     sectorData[index].jsonStartAddress!,
        //     radix: 16,
        //   );
        //   int sectorNumBytes =
        //       int.parse(sectorData[index].jsonEndAddress!, radix: 16) -
        //       sectorStartAddr +
        //       1;
        //   int offset = 0;
        //   while (offset < sectorNumBytes) {
        //     try {
        //       // This correctly calculates if the remaining data is less than 2000
        //       int chunkLen = (sectorNumBytes - offset) < sectorFrameTransferLen
        //           ? (sectorNumBytes - offset)
        //           : sectorFrameTransferLen;
        //       BytesBuilder frameBuilder = BytesBuilder(copy: false);
        //       for (var item in transferSplitData) {
        //         String trimmed = item.trim();
        //         if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
        //           frameBuilder.add(hex.decode(trimmed));
        //         }
        //         else if (trimmed.contains("bsc")) {
        //           frameBuilder.addByte(blkSeqCnt & 0xFF);
        //         }
        //         else if (trimmed.contains("json_sectordata")) {
        //           // ✅ SLICING: Takes exactly 'chunkLen' (max 2000) from the offset
        //           frameBuilder.add(
        //             sectorDataArray.sublist(offset, offset + chunkLen),
        //           );
        //         }
        //         else if (trimmed.contains("json_strt_addr")) {
        //           int endIndex = trimmed.indexOf('>');
        //           String bracketString = trimmed.substring(1, endIndex);
        //           int copyLength = int.parse(bracketString.split(',')[1], radix: 16);
        //           ByteData bd = ByteData(4)..setUint32(0, sectorStartAddr);
        //           Uint8List addrBytes = bd.buffer.asUint8List();
        //           if (addrBytes.length > copyLength) {
        //             addrBytes = addrBytes.sublist(addrBytes.length - copyLength);
        //           }
        //           frameBuilder.add(addrBytes);
        //           // ✅ ADDRESS UPDATE: Move the pointer forward by the chunk we just sent
        //           sectorStartAddr += chunkLen;
        //         }
        //         else if (trimmed.contains("sectordatasent")) {
        //           int endIndex = trimmed.indexOf('>');
        //           String bracketString = trimmed.substring(1, endIndex);
        //           int copyLength = int.parse(bracketString.split(',')[1], radix: 16);
        //           ByteData bd = ByteData(4)..setUint32(0, chunkLen);
        //           Uint8List lenBytes = bd.buffer.asUint8List();
        //           if (lenBytes.length > copyLength) {
        //             lenBytes = lenBytes.sublist(lenBytes.length - copyLength);
        //           }
        //           frameBuilder.add(lenBytes);
        //         }
        //       }
        //       Uint8List finalFrame = frameBuilder.toBytes();
        //       // Send to hardware
        //       var response = await _dongleComm.can2xTxRx(
        //         finalFrame.length,
        //         hex.encode(finalFrame),
        //       );
        //       if (response.ecuResponseStatus != "NOERROR") {
        //         return response.ecuResponseStatus;
        //       }
        //       // ✅ COUNTER UPDATES
        //       offset += chunkLen;
        //       realTimeBytesFlashed += chunkLen;
        //       blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
        //     } catch (e) {
        //       return "exception";
        //     }
        //   }
        // }
        // else if (command == "sendbulkdata") {
        //   List<String> splitInfo = info.split(',');
        //   int blkSeqCnt = int.parse(splitInfo[1]);
        //   // Extract transfer template after second comma
        //   int ind1 = info.indexOf(',');
        //   int ind2 = info.indexOf(',', ind1 + 1);
        //   String transferInfo = info.substring(ind2 + 1);
        //   List<String> transferSplitData = transferInfo.split('+');
        //   // Find json_sectordata to get frame length
        //   String jsonSectorDataPart = transferSplitData.firstWhere(
        //     (x) => x.contains("json_sectordata"),
        //   );
        //   String sqrBktInfo = jsonSectorDataPart
        //       .substring(
        //         jsonSectorDataPart.indexOf('[') + 1,
        //         jsonSectorDataPart.indexOf(']'),
        //       )
        //       .trim();
        //   int sectorFrameTransferLen = sqrBktInfo.contains(',')
        //       ? int.parse(sqrBktInfo.split(',')[1].trim(), radix: 16)
        //       : int.parse(sqrBktInfo, radix: 16);
        //   int index = isLoopPresent ? loopModelList.last.i! : currSectorIndex;
        //   Uint8List sectorDataArray = Uint8List.fromList(
        //     hex.decode(sectorData[index].jsonData!),
        //   );
        //   int sectorStartAddr = int.parse(
        //     sectorData[index].jsonStartAddress!,
        //     radix: 16,
        //   );
        //   int sectorNumBytes =
        //       int.parse(sectorData[index].jsonEndAddress!, radix: 16) -
        //       sectorStartAddr +
        //       1;
        //   int offset = 0;
        //   while (offset < sectorNumBytes) {
        //     try {
        //       int chunkLen = (sectorNumBytes - offset) < sectorFrameTransferLen
        //           ? (sectorNumBytes - offset)
        //           : sectorFrameTransferLen;
        //       // --- Build frame ---
        //       BytesBuilder frameBuilder = BytesBuilder(copy: false);
        //       for (var item in transferSplitData) {
        //         String trimmed = item.trim();
        //         // 1️⃣ Fixed Hex bytes
        //         if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
        //           frameBuilder.add(hex.decode(trimmed));
        //         }
        //         // 2️⃣ Block Sequence Counter
        //         else if (trimmed.contains("bsc")) {
        //           frameBuilder.addByte(blkSeqCnt & 0xFF);
        //         }
        //         // 3️⃣ Firmware data
        //         else if (trimmed.contains("json_sectordata")) {
        //           frameBuilder.add(
        //             sectorDataArray.sublist(offset, offset + chunkLen),
        //           );
        //         }
        //         // 4️⃣ Current Address
        //         else if (trimmed.contains("json_strt_addr")) {
        //           int endIndex = trimmed.indexOf('>');
        //           String bracketString = trimmed.substring(1, endIndex);
        //           int copyLength = int.parse(
        //             bracketString.split(',')[1],
        //             radix: 16,
        //           );
        //           ByteData bd = ByteData(4)..setUint32(0, sectorStartAddr);
        //           Uint8List addrBytes = bd.buffer.asUint8List();
        //           if (addrBytes.length > copyLength) {
        //             addrBytes = addrBytes.sublist(
        //               addrBytes.length - copyLength,
        //             );
        //           }
        //           frameBuilder.add(addrBytes);
        //           // Increment address by full transfer length (like C#)
        //           sectorStartAddr += sectorFrameTransferLen;
        //         }
        //         // 5️⃣ Bytes sent in this frame
        //         else if (trimmed.contains("sectordatasent")) {
        //           int endIndex = trimmed.indexOf('>');
        //           String bracketString = trimmed.substring(1, endIndex);
        //           int copyLength = int.parse(
        //             bracketString.split(',')[1],
        //             radix: 16,
        //           );
        //           ByteData bd = ByteData(4)..setUint32(0, chunkLen);
        //           Uint8List lenBytes = bd.buffer.asUint8List();
        //           if (lenBytes.length > copyLength) {
        //             lenBytes = lenBytes.sublist(lenBytes.length - copyLength);
        //           }
        //           frameBuilder.add(lenBytes);
        //         }
        //       }
        //       Uint8List finalFrame = frameBuilder.toBytes();
        //       // --- Send via Dongle ---
        //       var response = await _dongleComm.can2xTxRx(
        //         finalFrame.length,
        //         hex.encode(finalFrame),
        //       );
        //       if (response.ecuResponseStatus != "NOERROR") {
        //         print("🛑 BULK ERROR: ${response.ecuResponseStatus}");
        //         return response.ecuResponseStatus;
        //       }
        //       // Increment counters
        //       offset += chunkLen;
        //       realTimeBytesFlashed += chunkLen;
        //       blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
        //       print(
        //         "🚀 Block $blkSeqCnt sent. Total: $offset / $sectorNumBytes",
        //       );
        //     } catch (e) {
        //       print("❌ Bulk Exception: $e");
        //       return "exception";
        //     }
        //   }
        // }
        //       else if (command == "sendbulkdata") {
        //   List<String> splitInfo = info.split(',');
        //   int seqvarInitValue = int.parse(splitInfo[1]);
        //   // Extract the transfer template (everything after the second comma)
        //   int ind1 = info.indexOf(',');
        //   int ind2 = info.indexOf(',', ind1 + 1);
        //   String transferInfo = info.substring(ind2 + 1);
        //   // Parse json_sectordata frame length
        //   String jsonSectorDataPart = transferInfo
        //       .split('+')
        //       .firstWhere((x) => x.contains("json_sectordata"));
        //   String sqrBktInfo = jsonSectorDataPart.substring(
        //     jsonSectorDataPart.indexOf('[') + 1,
        //     jsonSectorDataPart.indexOf(']'),
        //   );
        //   int sectorFrameTransferLen = sqrBktInfo.contains(',')
        //       ? int.parse(sqrBktInfo.split(',')[1].trim(), radix: 16)
        //       : int.parse(sqrBktInfo.trim(), radix: 16);
        //   int blkSeqCnt = seqvarInitValue;
        //   int index = isLoopPresent ? loopModelList.last.i! : currSectorIndex;
        //   // Prepare sector data once
        //   Uint8List sectorDataArray = Uint8List.fromList(hex.decode(sectorData[index].jsonData!));
        //   int sectorNumBytes = int.parse(sectorData[index].jsonEndAddress!, radix: 16) -
        //       int.parse(sectorData[index].jsonStartAddress!, radix: 16) +
        //       1;
        //   int startAddr = int.parse(sectorData[index].jsonStartAddress!, radix: 16);
        //   // Pre-split transfer template once
        //   List<String> transferSplitData = transferInfo.split('+');
        //   // Precompute fixed hex bytes
        //   List<Uint8List?> fixedHexBytes = transferSplitData.map((item) {
        //     String trimmed = item.trim();
        //     return RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)
        //         ? Uint8List.fromList(hex.decode(trimmed))
        //         : null;
        //   }).toList();
        //   // Reusable ByteData buffer for addresses/lengths
        //   ByteData tempBuffer = ByteData(4);
        //   int j = 0;
        //   while (j < sectorNumBytes) {
        //     try {
        //       int currentTransferLen = (sectorNumBytes - j) < sectorFrameTransferLen
        //           ? (sectorNumBytes - j)
        //           : sectorFrameTransferLen;
        //       BytesBuilder nTxFrameBuilder = BytesBuilder();
        //       for (int k = 0; k < transferSplitData.length; k++) {
        //         String item = transferSplitData[k].trim();
        //         if (fixedHexBytes[k] != null) {
        //           nTxFrameBuilder.add(fixedHexBytes[k]!);
        //         } else if (item.contains("bsc")) {
        //           nTxFrameBuilder.addByte(blkSeqCnt & 0xFF);
        //         } else if (item.contains("json_sectordata")) {
        //           // Use view instead of sublist to avoid copy
        //           nTxFrameBuilder.add(sectorDataArray.buffer.asUint8List(j, currentTransferLen));
        //         } else if (item.contains("json_strt_addr")) {
        //           int endIndex = item.indexOf('>');
        //           String bracketString = item.substring(1, endIndex);
        //           int copyLength = int.parse(bracketString.split(',')[1], radix: 16);
        //           tempBuffer.setUint32(0, startAddr);
        //           Uint8List addrBytes = tempBuffer.buffer.asUint8List();
        //           if (addrBytes.length > copyLength) {
        //             addrBytes = addrBytes.sublist(addrBytes.length - copyLength);
        //           }
        //           nTxFrameBuilder.add(addrBytes);
        //           startAddr += sectorFrameTransferLen;
        //         } else if (item.contains("sectordatasent")) {
        //           int endIndex = item.indexOf('>');
        //           String bracketString = item.substring(1, endIndex);
        //           int copyLength = int.parse(bracketString.split(',')[1], radix: 16);
        //           tempBuffer.setUint32(0, currentTransferLen);
        //           Uint8List lenBytes = tempBuffer.buffer.asUint8List();
        //           if (lenBytes.length > copyLength) {
        //             lenBytes = lenBytes.sublist(lenBytes.length - copyLength);
        //           }
        //           nTxFrameBuilder.add(lenBytes);
        //         }
        //       }
        //       // Increment global offset
        //       j += currentTransferLen;
        //       Uint8List finalFrame = nTxFrameBuilder.toBytes();
        //       // Send via Dongle
        //       var bulkTransferResponse = await _dongleComm.can2xTxRx(
        //         finalFrame.length,
        //         hex.encode(finalFrame),
        //       );
        //       blkSeqCnt = (blkSeqCnt + 1) & 0xFF; // wrap-around 0x00-0xFF
        //       if (bulkTransferResponse.ecuResponseStatus != "NOERROR") {
        //         return bulkTransferResponse.ecuResponseStatus ?? "ERROR";
        //       }
        //       // Update progress (optional)
        //       realTimeBytesFlashed += currentTransferLen;
        //     } catch (e) {
        //       print("ELMZ: Exception == $e");
        //       return "exception";
        //     }
        //   }
        // }
        // ================= SLEEP / PROTOCOL =================
        else if (command == "sleep") {
          await Future.delayed(Duration(milliseconds: int.parse(info)));
        } else if (command == "protocol") {
          await _dongleComm.dongleSetProtocol(int.parse(info));
        } else if (command == "txid") {
          await _dongleComm.canSetTxHeader(info);
        } else if (command == "rxid") {
          await _dongleComm.canSetRxHeaderMask(info);
        } else if (command == "startpadding") {
          await _dongleComm.canStartPadding(info);
        } else if (command == "stoppadding") {
          await _dongleComm.canStopPadding();
        } else if (command == "setstmin") {
          await _dongleComm.canSetP1Min(info.trim());
        } else if (command == "setP2Max") {
          await _dongleComm.canSetP2Max(info.trim());
        } else if (command == "startTP") {
          await _dongleComm.canStartTP();
        } else if (command == "stopTP") {
          await _dongleComm.canStopTP();
        }
      }
    } catch (e, stackTrace) {
      print("❌ FLASH ERROR: $e");
      print("📍 STACKTRACE: $stackTrace");
      return "exception";
    }

    return reprogrammingResponse?.ecuResponseStatus ?? "FINISHED";
  }

  /// Converts an int value to a [byteLength]-long big-endian Uint8List
  Uint8List intToBytes(int value, int byteLength) {
    Uint8List bytes = Uint8List(byteLength);
    for (int i = 0; i < byteLength; i++) {
      bytes[byteLength - 1 - i] = (value >> (8 * i)) & 0xFF;
    }
    return bytes;
  }

  List<int> intToBytesBigEndian(int value, int length) {
    Uint8List result = Uint8List(length);
    for (int i = length - 1; i >= 0; i--) {
      result[i] = value & 0xFF;
      value >>= 8;
    }
    return result.toList();
  }

  Uint8List hexStringToBytes(String hex) {
    hex = hex.replaceAll(' ', '').replaceAll('0x', '');
    if (hex.length % 2 != 0) hex = '0$hex';
    return Uint8List.fromList(
      List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  Future<ResponseArrayStatus?> setDataData(String command) async {
    // Dart uses ~/ for integer division (equivalent to C# length / 2)
    int frameLength = command.length ~/ 2;

    // Await the response from the dongle communication
    var pidResponse = await _dongleComm.can2xTxRx(frameLength, command);

    return pidResponse;
  }

  Future<List<ReadParameterResponse>> setRoutineValue(
    int noOfParameters,
    List<ReadParameterPID> readParameterCollection,
    Uint8List actualResponse,
  ) async {
    List<ReadParameterResponse> databyteArray = [];
    // ignore: unused_local_variable
    int index = 0;

    for (int i = 0; i < readParameterCollection.length; i++) {
      var pidItem = readParameterCollection[i];
      int frameLength = 0; // Matching your C# logic
      String dataValue = "";

      // dev.log("--- START LOOP PID NAME: ${pidItem.pid} ---");

      // Mocking the response as per your C# code
      var pidResponse = ResponseArrayStatus(
        ecuResponseStatus: "NOERROR",
        actualDataBytes: actualResponse,
      );

      try {
        if (pidResponse.ecuResponseStatus == "NOERROR") {
          var rxArray = pidResponse.actualDataBytes;
          double floatPidValue = 0;
          Uint8List outputLiveParaArray = Uint8List(0);

          List<ReadParameterVariableResponse> variableResponses = [];

          for (int k = 0; k < pidItem.variables!.length; k++) {
            var currentVar = pidItem.variables![k];
            // dev.log("--- START LOOP VARIABLE NAME: ${currentVar.pidName} ---");

            if (currentVar.datatype == "CONTINUOUS") {
              int unsignedPidIntValue = 0;

              for (int j = 0; j < (currentVar.noOfBytes ?? 0); j++) {
                index++;
                // Calculate index: StartByte + offset(5) + frameLen - 1 + j
                int byteIdx =
                    (currentVar.startByte ?? 0) + 5 + frameLength - 1 + j;

                if (byteIdx < rxArray!.length) {
                  int shift = ((currentVar.noOfBytes ?? 1) - 1 - j) * 8;
                  unsignedPidIntValue |= (rxArray[byteIdx] << shift);
                }
              }

              // Bit-coded logic
              if (currentVar.isBitcoded == true) {
                int noOfBytes = currentVar.noOfBytes ?? 1;
                int noOfBits = currentVar.noofBits ?? 1;
                int startBit = currentVar.startBit ?? 1;

                int mask = (pow(2, noOfBits).toInt()) - 1;
                int shiftAmount = (noOfBytes * 8) - noOfBits - startBit + 1;
                unsignedPidIntValue =
                    (unsignedPidIntValue >> shiftAmount) & mask;
              }

              // Scaling / Resolution
              if (currentVar.readParameterIndex == "UDS_2S_COMPLIMENT" &&
                  currentVar.offset == 1) {
                floatPidValue =
                    unsignedPidIntValue * (currentVar.resolution ?? 1.0);
              } else {
                floatPidValue =
                    (unsignedPidIntValue * (currentVar.resolution ?? 1.0)) +
                    (currentVar.offset ?? 0);
              }

              dataValue = floatPidValue.toStringAsFixed(3);
            } else if (currentVar.datatype == "ASCII") {
              int start = (currentVar.startByte ?? 0) + 5 + frameLength - 1;
              int len = currentVar.noOfBytes ?? 0;

              if (start + len <= rxArray!.length) {
                var subList = rxArray.sublist(start, start + len);
                dataValue = String.fromCharCodes(
                  subList,
                ).replaceAll('\u0000', '');
              }
            } else if (currentVar.datatype == "BCD" ||
                currentVar.datatype == "HEX") {
              int start = (currentVar.startByte ?? 0) + 5 + frameLength - 1;
              int len = currentVar.noOfBytes ?? 0;

              if (start + len <= rxArray!.length) {
                var subList = rxArray.sublist(start, start + len);
                // Convert bytes to Hex string
                dataValue = subList
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join('')
                    .toUpperCase();
              }
            }

            variableResponses.add(
              ReadParameterVariableResponse(
                pidName: currentVar.pidName,
                pidNumber: currentVar.pidNumber,
                responseValue: dataValue,
              ),
            );
          }

          databyteArray.add(
            ReadParameterResponse(
              pidId: pidItem.pidId,
              status: pidResponse.ecuResponseStatus,
              dataArray: outputLiveParaArray,
              variables: variableResponses,
            ),
          );
        }
      } catch (e) {
        //dev.log("Error in SetRoutineValue: $e");
        databyteArray.add(
          ReadParameterResponse(status: e.toString(), pidId: pidItem.pidId),
        );
      }
    }
    return databyteArray;
  }
}