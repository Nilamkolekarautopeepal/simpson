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
        case WriteParameterIndex.UDS_DS1002_SK0102:
          // TODO: Handle this case.
          throw UnimplementedError();
        case WriteParameterIndex.UDS_DS1040_SK0708:
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

  // Future<ReadDtcResponseModel> readDTC(ReadDtcIndex dtcIndex) async {
  //   String status = '';
  //   String returnStatus = '';
  //   List<List<String>>? dtcArray;

  //   try {
  //     if (dtcIndex == ReadDtcIndex.KWP_2BYTE_DTC ||
  //         dtcIndex == ReadDtcIndex.UDS_2BYTE12_DTC ||
  //         dtcIndex == ReadDtcIndex.UDS_2BYTE13_DTC ||
  //         dtcIndex == ReadDtcIndex.UDS_3BYTE_DTC) {
  //       int frameLength = 3;
  //       final responseBytes = await _dongleComm.can2xTxRx(
  //         frameLength,
  //         '1902FF',
  //       );
  //       status = responseBytes.ecuResponseStatus ?? '';
  //       final actualData = responseBytes.actualDataBytes;
  //       returnStatus = '';

  //       if (status == 'NOERROR') {
  //         returnStatus = 'NO_ERROR';
  //         final rxSize = actualData!.length;
  //         final rxArray = actualData;
  //         int dtcStartByteIndex = 3;
  //         // 59 02 FF DTCHB DTCMB1 DTCLB1 DTCSTS1 DTCHB2 DTCMB2 DTCLB2 DTCSTS2 ..... DTCHBn DTCMBn DTCLBn DTCSTSn
  //         final noOfDtc = (rxSize - 3) ~/ 4;
  //         dtcArray = List.generate(noOfDtc, (_) => List.filled(2, ''));

  //         int i = 0;
  //         while (i < noOfDtc) {
  //           final dtcTypeBits = (rxArray[dtcStartByteIndex] & 0xC0) >> 6;
  //           String dtcType = '';
  //           if (dtcTypeBits == 0x00) {
  //             dtcType = 'P';
  //           } else if (dtcTypeBits == 0x01) {
  //             dtcType = 'C';
  //           } else if (dtcTypeBits == 0x02) {
  //             dtcType = 'B';
  //           } else if (dtcTypeBits == 0x03) {
  //             dtcType = 'U';
  //           }

  //           final value = rxArray[dtcStartByteIndex + 3] & 0x01;
  //           switch (value) {
  //             case 0x00:
  //               dtcArray[i][1] = 'Inactive';
  //               break;
  //             case 0x01:
  //               dtcArray[i][1] = 'Active';
  //               break;
  //           }

  //           switch (dtcIndex) {
  //             case ReadDtcIndex.UDS_3BYTE_DTC:
  //               dtcArray[i][0] =
  //                   '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}-${rxArray[dtcStartByteIndex + 2].toRadixString(16).padLeft(2, '0')}';
  //               break;
  //             case ReadDtcIndex.UDS_2BYTE12_DTC:
  //               dtcArray[i][0] =
  //                   '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}';
  //               break;
  //             case ReadDtcIndex.UDS_2BYTE13_DTC:
  //               dtcArray[i][0] =
  //                   '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 2].toRadixString(16).padLeft(2, '0')}';
  //               break;
  //             case ReadDtcIndex.KWP_2BYTE_DTC:
  //               dtcArray[i][0] =
  //                   '$dtcType${(rxArray[dtcStartByteIndex] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray[dtcStartByteIndex + 1].toRadixString(16).padLeft(2, '0')}';
  //               break;
  //             default:
  //               dtcArray[i][0] = '';
  //           }

  //           dtcStartByteIndex += 4;
  //           i++;
  //         }
  //       } else {
  //         returnStatus = status;
  //       }
  //     } else if (dtcIndex == ReadDtcIndex.GENERIC_OBD) {
  //       int frameLength = 1;
  //       final responseBytes03 = await _dongleComm.can2xTxRx(frameLength, '03');
  //       status = responseBytes03.ecuResponseStatus ?? '';
  //       final actualData03 = responseBytes03.actualDataBytes;

  //       if (status == 'NOERROR') {
  //         final rxArray03 = actualData03!;
  //         frameLength = 1;
  //         final responseBytes07 = await _dongleComm.can2xTxRx(
  //           frameLength,
  //           '07',
  //         );
  //         status = responseBytes07.ecuResponseStatus ?? '';
  //         final actualData07 = responseBytes07.actualDataBytes;
  //         returnStatus = '';

  //         if (status == 'NOERROR') {
  //           returnStatus = 'NO_ERROR';
  //           final rxArray07 = actualData07!;
  //           // All DTCs    - 43 LEN DTCHB DTCLB1 DTCHB2 DTCLB2  ..... DTCHBn DTCLBn
  //           // Pending DTCs - 47 LEN DTCHB DTCLB1 DTCHB2 DTCLB2  ..... DTCHBn DTCLBn
  //           final noOfDtc03 = rxArray03[1];
  //           final noOfDtc07 = rxArray07[1];

  //           dtcArray = List.generate(
  //             noOfDtc03 + noOfDtc07,
  //             (_) => List.filled(2, ''),
  //           );

  //           int i = 0;
  //           for (i = 0; i < noOfDtc03; i++) {
  //             final dtcTypeBits = (rxArray03[i * 2 + 2] & 0xC0) >> 6;
  //             String dtcType = '';
  //             if (dtcTypeBits == 0x00) {
  //               dtcType = 'P';
  //             } else if (dtcTypeBits == 0x01) {
  //               dtcType = 'C';
  //             } else if (dtcTypeBits == 0x02) {
  //               dtcType = 'B';
  //             } else if (dtcTypeBits == 0x03) {
  //               dtcType = 'U';
  //             }
  //             dtcArray[i][0] =
  //                 '$dtcType${(rxArray03[i * 2 + 2] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray03[i * 2 + 3].toRadixString(16).padLeft(2, '0')}';
  //             dtcArray[i][1] = 'Current';
  //           }

  //           for (int j = 0; j < noOfDtc07; j++) {
  //             final dtcTypeBits = (rxArray07[j * 2 + 2] & 0xC0) >> 6;
  //             String dtcType = '';
  //             if (dtcTypeBits == 0x00) {
  //               dtcType = 'P';
  //             } else if (dtcTypeBits == 0x01) {
  //               dtcType = 'C';
  //             } else if (dtcTypeBits == 0x02) {
  //               dtcType = 'B';
  //             } else if (dtcTypeBits == 0x03) {
  //               dtcType = 'U';
  //             }
  //             dtcArray[i + j][0] =
  //                 '$dtcType${(rxArray07[j * 2 + 2] & 0x3F).toRadixString(16).padLeft(2, '0')}${rxArray07[j * 2 + 3].toRadixString(16).padLeft(2, '0')}';
  //             dtcArray[i + j][1] = 'Pending';
  //           }
  //         } else {
  //           returnStatus = status;
  //         }
  //       } else {
  //         returnStatus = status;
  //       }
  //     }

  //     return ReadDtcResponseModel(dtcs: dtcArray, status: returnStatus);
  //   } catch (e) {
  //     return ReadDtcResponseModel(dtcs: null, status: e.toString());
  //   }
  // }

  Future<ReadDtcResponseModel> readDTC(ReadDtcIndex dtcIndex) async {
    String status = '';
    String returnStatus = '';
    List<List<String>>? dtcArray;

    try {
      if (dtcIndex == ReadDtcIndex.KWP_2BYTE_DTC ||
          dtcIndex == ReadDtcIndex.UDS_2BYTE12_DTC ||
          dtcIndex == ReadDtcIndex.UDS_2BYTE13_DTC ||
          dtcIndex == ReadDtcIndex.UDS_3BYTE_DTC) {
        int frameLength = 3;
        final responseBytes = await _dongleComm.can2xTxRx(
          frameLength,
          '1902AF',
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

            final value = rxArray[dtcStartByteIndex + 3] & 0x01;
            String dtcStatus = (value == 0x00) ? 'Inactive' : 'Active';

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
                  dataValue = value == value.roundToDouble()
                      ? value.toInt().toString()
                      : value
                            .toStringAsFixed(3)
                            .replaceFirst(RegExp(r'0+$'), '')
                            .replaceFirst(RegExp(r'\.$'), '');
                  break;

                // case "ASCII":
                //   num end = baseOffset + (variable.noOfBytes ?? 0);
                //   if (end <= rxArray.length) {
                //     Uint8List temp = rxArray.sublist(baseOffset, end as int?);
                //     dataValue = latin1.decode(
                //       temp,
                //       //allowInvalid: true,
                //     ); // ✅ keep all zeros
                //   }
                //   break;
                case "ASCII":
                  {
                    num end = baseOffset + (variable.noOfBytes ?? 0);
                    if (end <= rxArray.length) {
                      Uint8List temp = rxArray.sublist(baseOffset, end as int?);
                      dataValue = latin1
                          .decode(temp)
                          .replaceAll('\u0000', '')
                          .replaceAll(' ', '')
                          .trim();
                    }
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

  // Future<List<WriteParameterResponse>?> writeParameters(
  //   int noOfParameters,
  //   WriteParameterIndex writeParameterIndex,
  //   List<WriteParameterPID> writeParameterCollection,
  // ) async {
  //   try {
  //     print(
  //       "🔹 writeParameters() started. Handling ${writeParameterCollection.length} PIDs",
  //     );
  //     List<WriteParameterResponse> resultList = [];

  //     for (var pidItem in writeParameterCollection) {
  //       print("\n➡ Processing: ${pidItem.pidName}");

  //       // 1. Session and Seed Mapping
  //       int diagnosticsMode = 0x03;
  //       int getSeedIndex = 0x00;
  //       String indexStr = writeParameterIndex.toString();

  //       if (writeParameterIndex == WriteParameterIndex.UDS_DS1003_SK090A) {
  //         getSeedIndex = 0x09;
  //       } else if (writeParameterIndex ==
  //               WriteParameterIndex.UDS_DS1003_SK0102 ||
  //           writeParameterIndex == WriteParameterIndex.UDS_SK0102_DS1003) {
  //         getSeedIndex = 0x01;
  //       } else if (writeParameterIndex ==
  //           WriteParameterIndex.UDS_DS1003_SK0B0C) {
  //         getSeedIndex = 0x0B;
  //       } else if (writeParameterIndex ==
  //           WriteParameterIndex.UDS_DS1003_SK0304) {
  //         getSeedIndex = 0x03;
  //       } else if (writeParameterIndex ==
  //           WriteParameterIndex.UDS_DS1003_SK0506) {
  //         getSeedIndex = 0x05;
  //       }

  //       var response = ResponseArrayStatus();
  //       int indexSK = indexStr.indexOf("SK");
  //       int indexDS = indexStr.indexOf("DS1");

  //       // 2. Security Access & Session Control Sequence
  //       if (indexStr.contains("NA")) {
  //         response.ecuResponseStatus = "NOERROR";
  //       } else if (indexSK < 0) {
  //         response = await _dongleComm.can2xTxRx(
  //           2,
  //           hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
  //         );
  //       } else if (indexSK >= 0 && indexSK < indexDS) {
  //         response = await sendSeedKey(
  //           getSeedIndex,
  //           pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values.first,
  //         );
  //         if (response.ecuResponseStatus == "NOERROR") {
  //           response = await _dongleComm.can2xTxRx(
  //             2,
  //             hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
  //           );
  //         }
  //       } else {
  //         response = await _dongleComm.can2xTxRx(
  //           2,
  //           hex.encode(Uint8List.fromList([0x10, diagnosticsMode])),
  //         );
  //         if (response.ecuResponseStatus == "NOERROR") {
  //           response = await sendSeedKey(
  //             getSeedIndex,
  //             pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values.first,
  //           );
  //         }
  //       }

  //       // 3. Data Write Execution (Service 0x2E)
  //       if (response.ecuResponseStatus == "NOERROR" ||
  //           indexStr.contains("NA")) {
  //         if (pidItem.writePid == null) continue;

  //         Uint8List writeParaPID = Uint8List.fromList(
  //           hex.decode(pidItem.writePid!),
  //         );
  //         int totalBytes = pidItem.totalBytes ?? 0;

  //         // Structure: [0x2E] + [PID] + [DATA]
  //         Uint8List writeFrame = Uint8List(
  //           1 + writeParaPID.length + totalBytes,
  //         );
  //         writeFrame[0] = 0x2E;
  //         writeFrame.setRange(1, 1 + writeParaPID.length, writeParaPID);

  //         if (pidItem.writeInput != null) {
  //           int dataStartIndex = 1 + writeParaPID.length;
  //           int bytesToCopy = pidItem.writeInput!.length > totalBytes
  //               ? totalBytes
  //               : pidItem.writeInput!.length;
  //           writeFrame.setRange(
  //             dataStartIndex,
  //             dataStartIndex + bytesToCopy,
  //             pidItem.writeInput!,
  //           );
  //         }

  //         print("  🔹 Transmitting Write Frame: ${hex.encode(writeFrame)}");

  //         // 4. Initial Write Request
  //         response = await _dongleComm.can2xTxRx(
  //           writeFrame.length,
  //           hex.encode(writeFrame),
  //         );

  //         // 5. THE FIX: Handle NRC 0x78 (Response Pending)
  //         // ECU returns 7F 2E 78 when writing to NVM (VIN/Flash).
  //         int retryCount = 0;
  //         while (response.actualDataBytes != null &&
  //             response.actualDataBytes!.length >= 3 &&
  //             response.actualDataBytes![0] == 0x7F &&
  //             response.actualDataBytes![2] == 0x78 &&
  //             retryCount < 10) {
  //           print(
  //             "  ⏳ ECU Busy (NRC 78). Waiting 500ms... Attempt ${retryCount + 1}",
  //           );
  //           await Future.delayed(const Duration(milliseconds: 500));

  //           // Re-check response (Asking dongle for next buffer)
  //           response = await _dongleComm.can2xTxRx(
  //             writeFrame.length,
  //             hex.encode(writeFrame),
  //           );
  //           retryCount++;
  //         }

  //         // 6. BUFFER SCANNING: Verify Success SID 0x6E
  //         // If the buffer contains 0x6E (Positive Response SID), it's a success
  //         if (response.actualDataBytes != null &&
  //             response.actualDataBytes!.contains(0x6E)) {
  //           response.ecuResponseStatus = "NOERROR";
  //           print("  ✅ Write Success Verified (0x6E found)");
  //         }

  //         resultList.add(
  //           WriteParameterResponse(
  //             status: response.ecuResponseStatus,
  //             dataArray: response.actualDataBytes,
  //             pidName: pidItem.pidName,
  //             pidNumber: pidItem.writeParaNo,
  //             responseValue: response.ecuResponseStatus,
  //           ),
  //         );
  //       } else {
  //         print("  ❌ Preamble failed: ${response.ecuResponseStatus}");
  //         resultList.add(
  //           WriteParameterResponse(
  //             status: response.ecuResponseStatus,
  //             pidName: pidItem.pidName,
  //             pidNumber: pidItem.writeParaNo,
  //             responseValue: response.ecuResponseStatus,
  //           ),
  //         );
  //       }
  //     }
  //     return resultList;
  //   } catch (e) {
  //     print("❌ writeParameters Error: $e");
  //     return null;
  //   }
  // }

  Future<List<WriteParameterResponse>?> writeParameters(
    int noOfParameters,
    WriteParameterIndex writeParameterIndex,
    List<WriteParameterPID> writeParameterCollection,
  ) async {
    try {
      // _dongleComm?.saveLog("------Start Write Pid Process------\n");

      List<WriteParameterResponse> responseList = [];

      for (var pidItem in writeParameterCollection) {
        int diagnosticsMode = 0x03;
        int getSeedIndex = 0x01;

        // ── Seed Index Mapping ─────────────────────────────
        switch (writeParameterIndex) {
          case WriteParameterIndex.UDS_DS1003_SK090A:
            getSeedIndex = 0x09;
            break;
          case WriteParameterIndex.UDS_DS1003_SK0102:
            getSeedIndex = 0x01;
            break;
          case WriteParameterIndex.UDS_DS1003_SK0B0C:
            getSeedIndex = 0x0B;
            break;
          case WriteParameterIndex.UDS_DS1003_SK0304:
            getSeedIndex = 0x03;
            break;
          case WriteParameterIndex.UDS_DS1003_SK0506:
            getSeedIndex = 0x05;
            break;
          default:
            getSeedIndex = 0x01;
        }

        print("🔑 PID: ${pidItem.writePid} Seed: $getSeedIndex");

        // ── STEP 1: Session ─────────────────────────────
        var sessionResp = await _dongleComm.can2xTxRx(
          2,
          byteArrayToString(Uint8List.fromList([0x10, diagnosticsMode])),
        );

        if (sessionResp.ecuResponseStatus != "NOERROR") {
          responseList.add(
            WriteParameterResponse(
              status: sessionResp.ecuResponseStatus,
              pidNumber: pidItem.writeParaNo,
              responseValue: "SESSION_FAILED",
            ),
          );
          continue;
        }

        // ── STEP 2: Seed Request ─────────────────────────
        var seedResp = await _dongleComm.can2xTxRx(
          2,
          byteArrayToHexString(Uint8List.fromList([0x27, getSeedIndex])),
        );

        if (seedResp.ecuResponseStatus != "NOERROR" ||
            seedResp.actualDataBytes == null ||
            seedResp.actualDataBytes!.length <= 2) {
          responseList.add(
            WriteParameterResponse(
              status: seedResp.ecuResponseStatus,
              pidNumber: pidItem.writeParaNo,
              responseValue: "SEED_FAILED",
            ),
          );
          continue;
        }

        Uint8List seedArray = seedResp.actualDataBytes!.sublist(2);
        // List<int> keyBuffer = [];

        // // ── STEP 3: Key Calculation ───────────────────────
        // await calculateSeedkey!.calculateSeedKey(
        //   pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values[0],
        //   seedArray.length,
        //   keyBuffer,
        // );

        // if (keyBuffer.isEmpty) {
        //   responseList.add(
        //     WriteParameterResponse(
        //       status: "KEY_CALC_FAILED",
        //       pidNumber: pidItem.writeParaNo,
        //     ),
        //   );
        //   continue;
        // }

        // ── STEP 3: Key Calculation ───────────────────────
        final seedKeyResult = calculateSeedkey.calculateSeedKey(
          pidItem.seedKeyIndex ?? SEEDKEYINDEXTYPE.values[0],
          seedArray.length,
          seedArray, // pass the real seed, not keyBuffer
        );

        final List<int> keyBuffer = List<int>.from(
          seedKeyResult['key'] as List<int>,
        );

        if (keyBuffer.isEmpty) {
          responseList.add(
            WriteParameterResponse(
              status: "KEY_CALC_FAILED",
              pidNumber: pidItem.writeParaNo,
            ),
          );
          continue;
        }

        // ── STEP 4: Key Send ──────────────────────────────
        Uint8List keyFrame = Uint8List(2 + keyBuffer.length);
        keyFrame[0] = 0x27;
        keyFrame[1] = getSeedIndex + 1;
        keyFrame.setRange(2, 2 + keyBuffer.length, keyBuffer);

        var keyResp = await _dongleComm.can2xTxRx(
          keyFrame.length,
          byteArrayToHexString(keyFrame),
        );

        if (keyResp.ecuResponseStatus != "NOERROR") {
          responseList.add(
            WriteParameterResponse(
              status: "SECURITY_DENIED",
              pidNumber: pidItem.writeParaNo,
            ),
          );
          continue;
        }

        // ── STEP 5: WRITE FRAME BUILD (FIXED CORE ISSUE) ─────

        Uint8List pidBytes = hexStringToByteArray(pidItem.writePid ?? "");

        int dataSize = pidItem.totalBytes ?? 0;

        int frameSize = 1 + pidBytes.length + dataSize;

        Uint8List writeFrame = Uint8List(frameSize);

        writeFrame[0] = 0x2E;

        // PID placement
        writeFrame.setRange(1, 1 + pidBytes.length, pidBytes);

        int baseOffset = 1 + pidBytes.length;

        // ── SAFE DATA INSERTION ───────────────────────────
        if (pidItem.writeInput != null && pidItem.writeInput!.isNotEmpty) {
          int end =
              baseOffset +
              (pidItem.startByte ?? 0) +
              pidItem.writeInput!.length;

          if (end <= writeFrame.length) {
            writeFrame.setRange(
              baseOffset + (pidItem.startByte ?? 0),
              baseOffset +
                  (pidItem.startByte ?? 0) +
                  pidItem.writeInput!.length,
              pidItem.writeInput!,
            );
          } else {
            print("❌ WRITE INPUT OVERFLOW - skipping");
          }
        }

        // ── IQA PACKING SAFE ──────────────────────────────
        for (int k = 0; k < (pidItem.variantList?.length ?? 0); k++) {
          // if (pidItem.variantList![k].datatype == "IQA") {
          if ((pidItem.variantList![k].datatype ?? '').contains('IQA')) {
            _packIQAData(pidItem, writeFrame, pidBytes.length, k);
          }
        }

        print("🔧 FINAL FRAME: ${byteArrayToHexString(writeFrame)}");

        // ── STEP 6: WRITE TO ECU ──────────────────────────
        var writeResp = await _dongleComm.can2xTxRx(
          writeFrame.length,
          byteArrayToHexString(writeFrame),
        );

        responseList.add(
          WriteParameterResponse(
            status: writeResp.ecuResponseStatus,
            dataArray: writeResp.actualDataBytes,
            pidName: pidItem.pidName,
            pidNumber: pidItem.writeParaNo,
            responseValue: writeResp.ecuResponseStatus,
          ),
        );
      }

      return responseList;
    } catch (ex) {
      print("❌ WriteParameters Exception: $ex");
      return null;
    }
  }

  Uint8List hexStringToByteArray(String hexString) {
    hexString = hexString.replaceAll(' ', '');

    if (hexString.length.isOdd) {
      throw FormatException('Invalid hex string length');
    }

    return Uint8List.fromList(
      List.generate(
        hexString.length ~/ 2,
        (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  /// Helper for IQA packing bit-manipulation
  // void _packIQAData(
  //   WriteParameterPID pidItem,
  //   Uint8List writeFrame,
  //   int pidOffset,
  //   int k,
  // ) {
  //   const String iqaLookup = "ABCDEFGHIKLMNOPTRSTUVWXYZ12345678";
  //   List<int> iqaY = List.filled(7, 0);

  //   // Find indices in lookup table
  //   for (int i = 0; i < 7; i++) {
  //     String charToFind = String.fromCharCode(
  //       pidItem.writeInput![i],
  //     ).toUpperCase();
  //     iqaY[i] = iqaLookup.indexOf(charToFind);
  //   }

  //   // Pack 5-bit values into 32-bit temp
  //   int temp =
  //       ((iqaY[0] & 0x1F) << 27) |
  //       ((iqaY[1] & 0x1F) << 22) |
  //       ((iqaY[2] & 0x1F) << 17) |
  //       ((iqaY[3] & 0x1F) << 12) |
  //       ((iqaY[4] & 0x1F) << 7) |
  //       ((iqaY[5] & 0x1F) << 2);

  //   Uint8List iqaPacked = Uint8List(8);
  //   iqaPacked[0] = (temp & 0xFF000000) >> 24;
  //   iqaPacked[1] = (temp & 0x00FF0000) >> 16;
  //   iqaPacked[2] = (temp & 0x0000FF00) >> 8;
  //   iqaPacked[3] = (temp & 0x000000FF);
  //   iqaPacked[4] = (iqaY[6] << 3);

  //   int startPos = 1 + pidOffset + (pidItem.variantList![k].startByte ?? 0);
  //   writeFrame.setRange(startPos, startPos + 8, iqaPacked);
  // }

  void _packIQAData(
    WriteParameterPID pidItem,
    Uint8List writeFrame,
    int pidOffset,
    int k,
  ) {
    const String iqaLookup =
        "ABCDEFGHIKLMNOPRSTUVWXYZ12345678"; // fixed: 32 chars
    List<int> iqaY = List.filled(7, 0);

    final variant = pidItem.variantList![k];
    final int srcOffset =
        (variant.startByte ?? 1) -
        1; // 0-based offset for THIS cylinder's 7 chars

    for (int i = 0; i < 7; i++) {
      final ch = String.fromCharCode(
        pidItem.writeInput![srcOffset + i],
      ).toUpperCase();
      final idx = iqaLookup.indexOf(ch);
      iqaY[i] = idx >= 0 ? idx : 0;
    }

    int temp =
        ((iqaY[0] & 0x1F) << 27) |
        ((iqaY[1] & 0x1F) << 22) |
        ((iqaY[2] & 0x1F) << 17) |
        ((iqaY[3] & 0x1F) << 12) |
        ((iqaY[4] & 0x1F) << 7) |
        ((iqaY[5] & 0x1F) << 2);

    Uint8List iqaPacked = Uint8List(8);
    iqaPacked[0] = (temp >> 24) & 0xFF;
    iqaPacked[1] = (temp >> 16) & 0xFF;
    iqaPacked[2] = (temp >> 8) & 0xFF;
    iqaPacked[3] = temp & 0xFF;
    iqaPacked[4] = (iqaY[6] << 3) & 0xFF;

    int startPos =
        1 + pidOffset + srcOffset; // fixed: 0-based, not raw startByte
    writeFrame.setRange(startPos, startPos + 8, iqaPacked);
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
      case WriteParameterIndex.UDS_DS1002_SK0102:
        // TODO: Handle this case.
        throw UnimplementedError();
      case WriteParameterIndex.UDS_DS1040_SK0708:
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

  // // Use 'int' in Dart as it handles 64-bit integers (replaces uint/long)
  // int totalBytesToBeFlashed = 0;
  // int realTimeBytesFlashed = 0;

  // Future<double> getRuntimeFlashPercent() async {
  //   if (totalBytesToBeFlashed == 0) return 0.0;

  //   // In Dart, int / double automatically returns a double
  //   double runtimeFlashPercent = realTimeBytesFlashed / totalBytesToBeFlashed;
  //   return runtimeFlashPercent;
  // }

  // /// Resets the flashing counters
  // Future<void> resetPercentage() async {
  //   totalBytesToBeFlashed = 0;
  //   realTimeBytesFlashed = 0;
  // }

  // //   // Equivalent to List<LoopModel> loopModelList = new List<LoopModel>();
  // List<LoopModel> loopModelList = [];

  // Future<String?> flashInterpreter(
  //   FlashConfig flashConfigData,
  //   int noofsectors,
  //   List<FlashingMatrix> sectordata,
  //   String interpreterFile,
  // ) async {
  //   ResponseArrayStatus reprogrammingResponse = ResponseArrayStatus();

  //   try {
  //     // _dongleComm!.saveLog("------Start Flashing------\n");

  //     // ── ENTRY DIAGNOSTICS ─────────────────────────────────────────────────
  //     print("🚀 flashInterpreter START");
  //     print("📋 noofsectors: $noofsectors");
  //     print("📋 sectordata count: ${sectordata.length}");
  //     print("📋 interpreterFile length: ${interpreterFile.length}");
  //     print(
  //       "📋 interpreterFile preview: ${interpreterFile.length > 300 ? interpreterFile.substring(0, 300) : interpreterFile}",
  //     );

  //     if (interpreterFile.isEmpty) {
  //       print("❌ interpreterFile is EMPTY — cannot flash");
  //       return "ERROR : interpreter file is empty";
  //     }
  //     if (noofsectors == 0 || sectordata.isEmpty) {
  //       print(
  //         "❌ No sector data — noofsectors=$noofsectors sectordata=${sectordata.length}",
  //       );
  //       return "ERROR : no sector data";
  //     }

  //     List<String> lineData = interpreterFile.split('\n');
  //     print("📋 Total interpreter lines: ${lineData.length}");

  //     // ── TOTAL BYTES CALCULATION ───────────────────────────────────────────
  //     totalBytesToBeFlashed = 0;
  //     for (int i = 0; i < noofsectors; i++) {
  //       Uint8List sectorDataArray = hexStringToBytes(
  //         sectordata[i].jsonData ?? "",
  //       );
  //       int sectorNumBytes = sectorDataArray.length;
  //       totalBytesToBeFlashed += sectorNumBytes;
  //       realTimeBytesFlashed = 0;
  //       print(
  //         "📦 Sector[$i] jsonData length (bytes): $sectorNumBytes | startAddr: ${sectordata[i].jsonStartAddress} | endAddr: ${sectordata[i].jsonEndAddress}",
  //       );
  //     }
  //     print("📦 totalBytesToBeFlashed: $totalBytesToBeFlashed");

  //     Uint8List seedKey = Uint8List(0);
  //     int currSectorIndex = 0;
  //     bool isLoopPresent = false;
  //     int loopInit = 0;
  //     bool skipKey = false;

  //     // ── INTERPRETER LOOP ──────────────────────────────────────────────────
  //     for (int i = 0; i < lineData.length; i++) {
  //       String formattedLine = lineData[i].replaceAll('\r', '').trim();

  //       if (formattedLine.isEmpty || formattedLine.startsWith("//")) {
  //         continue;
  //       } else if (skipKey) {
  //         print("⏭ Skipping line (skipKey=true): $formattedLine");
  //         skipKey = false;
  //         continue;
  //       }

  //       List<String> parts = formattedLine.split(':');
  //       String command = parts[0];
  //       String info = parts.length > 1 ? parts[1] : "";

  //       print("🔄 Line[$i] command='$command' info='$info'");

  //       if (command == "send" ||
  //           command == "sendroutine" ||
  //           command == "sendignore" ||
  //           command == "sendroutineignore") {
  //         List<String> splitData = info.split('+');
  //         List<int> txFrameList = [];

  //         for (var item in splitData) {
  //           if (!item.contains("<")) {
  //             txFrameList.addAll(hexStringToBytes(item));
  //           } else {
  //             int endIndex = item.indexOf('>');
  //             String bracketString = item.substring(1, endIndex);
  //             List<String> bParts = bracketString.split(',');
  //             String reference = bParts[0];
  //             int copyLength = int.parse(bParts[1]);
  //             print("   🔧 reference='$reference' copyLength=$copyLength");

  //             Uint8List copyArray = Uint8List(0);

  //             if (reference.contains("key")) {
  //               copyArray = seedKey;
  //               print("   🔑 key bytes: ${bytesToHex(seedKey)}");
  //             } else if (reference.contains("json_strt_addr") ||
  //                 reference.contains("ecu_memmap_strt_addr")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String addrHex = reference.contains("json_strt_addr")
  //                   ? (sectordata[index].jsonStartAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     )
  //                   : (sectordata[index].ecuMemMapStartAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     );
  //               copyArray = hexStringToBytes(addrHex);
  //               print("   📍 start_addr[$index]: $addrHex");
  //             } else if (reference.contains("json_end_addr") ||
  //                 reference.contains("ecu_memmap_end_addr")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String addrHex = reference.contains("json_end_addr")
  //                   ? (sectordata[index].jsonEndAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     )
  //                   : (sectordata[index].ecuMemMapEndAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     );
  //               copyArray = hexStringToBytes(addrHex);
  //               print("   📍 end_addr[$index]: $addrHex");
  //             } else if (reference.contains("json_checksum")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String checkSumHex = (sectordata[index].jsonCheckSum ?? "")
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(checkSumHex);
  //               print("   🔢 checksum[$index]: $checkSumHex");
  //             } else if (reference.contains("json_sector_len") ||
  //                 reference.contains("ecu_memmap_len")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               int sectorNumBytes;
  //               if (reference.contains("json_sector_len")) {
  //                 sectorNumBytes =
  //                     int.parse(sectordata[index].jsonEndAddress!, radix: 16) -
  //                     int.parse(
  //                       sectordata[index].jsonStartAddress!,
  //                       radix: 16,
  //                     ) +
  //                     1;
  //               } else {
  //                 sectorNumBytes =
  //                     int.parse(
  //                       sectordata[index].ecuMemMapEndAddress!,
  //                       radix: 16,
  //                     ) -
  //                     int.parse(
  //                       sectordata[index].ecuMemMapStartAddress!,
  //                       radix: 16,
  //                     ) +
  //                     1;
  //               }
  //               String hexLen = sectorNumBytes
  //                   .toRadixString(16)
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(hexLen);
  //               print(
  //                 "   📏 sector_len[$index]: $sectorNumBytes bytes → $hexLen",
  //               );
  //             } else if (reference.contains("calculate_sector_len")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               int sectorNumBytes = (sectordata[index].jsonData!.length ~/ 2);
  //               String hexLen = sectorNumBytes
  //                   .toRadixString(16)
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(hexLen);
  //               print(
  //                 "   📏 calc_sector_len[$index]: $sectorNumBytes bytes → $hexLen",
  //               );
  //             } else if (reference.contains("i")) {
  //               copyArray = Uint8List.fromList([
  //                 loopModelList.last.i! + loopInit,
  //               ]);
  //               print(
  //                 "   🔢 loop i value: ${loopModelList.last.i! + loopInit}",
  //               );
  //             } else {
  //               print(
  //                 "   ⚠️ Unknown reference: '$reference' — copyArray will be empty",
  //               );
  //             }

  //             Uint8List finalBuffer = Uint8List(copyLength);
  //             int actualToCopy = copyArray.length > copyLength
  //                 ? copyLength
  //                 : copyArray.length;
  //             finalBuffer.setRange(0, actualToCopy, copyArray);
  //             txFrameList.addAll(finalBuffer);
  //           }
  //         }

  //         Uint8List txFrame = Uint8List.fromList(txFrameList);
  //         print(
  //           "📤 send[$command]: ${bytesToHex(txFrame)} (${txFrame.length} bytes)",
  //         );

  //         var sendResp = await _dongleComm.can2xTxRx(
  //           txFrame.length,
  //           bytesToHex(txFrame),
  //         );
  //         print("📥 send response: '${sendResp.ecuResponseStatus}'");

  //         if (command != "sendignore") {
  //           reprogrammingResponse = sendResp;
  //         }

  //         while (reprogrammingResponse.ecuResponseStatus ==
  //             "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
  //           print("⏳ RequiredTimeDelay — retrying in 300ms...");
  //           //  await Future.delayed(const Duration(milliseconds: 300));
  //           reprogrammingResponse = await _dongleComm.can2xTxRx(
  //             txFrame.length,
  //             bytesToHex(txFrame),
  //           );
  //           print(
  //             "📥 retry response: '${reprogrammingResponse.ecuResponseStatus}'",
  //           );
  //         }

  //         if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
  //             command != "sendignore") {
  //           print("❌ send ERROR: '${reprogrammingResponse.ecuResponseStatus}'");
  //           return reprogrammingResponse.ecuResponseStatus;
  //         }

  //         if (command == "sendroutine" || command == "sendroutineignore") {
  //           String routineReqCommand =
  //               "3103" + splitData[0].trim().substring(4);
  //           print("🔁 sendroutine polling: $routineReqCommand");
  //           bool isRoutineLoop = true;
  //           while (isRoutineLoop) {
  //             // await Future.delayed(const Duration(milliseconds: 500));
  //             var routineResp = await _dongleComm.can2xTxRx(
  //               routineReqCommand.length ~/ 2,
  //               routineReqCommand,
  //             );
  //             print(
  //               "📥 routine response: '${routineResp.ecuResponseStatus}' data: ${routineResp.actualDataBytes != null ? bytesToHex(routineResp.actualDataBytes!) : 'null'}",
  //             );

  //             if (command != "sendroutineignore") {
  //               reprogrammingResponse = routineResp;
  //             }

  //             if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
  //                 command != "sendroutineignore") {
  //               print(
  //                 "❌ routine ERROR: '${reprogrammingResponse.ecuResponseStatus}'",
  //               );
  //               isRoutineLoop = false;
  //               return reprogrammingResponse.ecuResponseStatus;
  //             } else if (routineResp.ecuResponseStatus != "NOERROR" &&
  //                 command == "sendroutineignore") {
  //               isRoutineLoop = false;
  //             } else {
  //               int statusByte = reprogrammingResponse.actualDataBytes![4];
  //               print(
  //                 "   routine statusByte[4]: 0x${statusByte.toRadixString(16).padLeft(2, '0')}",
  //               );
  //               if (statusByte == 0x02 ||
  //                   statusByte == 0x01 ||
  //                   statusByte == 0x04) {
  //                 print("   ✅ routine complete");
  //                 isRoutineLoop = false;
  //               }
  //             }
  //           }
  //         }
  //       } else if (command == "sleep") {
  //         int ms = int.parse(info);
  //         print("💤 sleep ${ms}ms");
  //         await Future.delayed(Duration(milliseconds: ms));
  //       } else if (command == "function") {
  //         if (info.contains("CalculateKeyFromSeed")) {
  //           String seedkeynumbytes = "";

  //           // 1. Extract content inside [ ... ]
  //           int start = info.indexOf('[');
  //           int end = info.indexOf(']');
  //           if (start == -1 || end == -1) return "ERROR_PARSING_INFO";

  //           String sqrBktInfo = info.substring(start + 1, end);

  //           if (sqrBktInfo.contains(',')) {
  //             List<String> parts = sqrBktInfo.split(',');
  //             String enumName = parts[0].trim().replaceAll('-', '_');

  //             // Safety: Use firstWhere with orElse to prevent "No element" error
  //             flashConfigData.seedKeyIndex = SEEDKEYINDEXTYPE.values.firstWhere(
  //               (e) => e.toString().split('.').last == enumName,
  //               orElse: () => SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD,
  //             );
  //             seedkeynumbytes = parts[1].trim();
  //           } else {
  //             seedkeynumbytes = sqrBktInfo.trim();
  //           }

  //           // 2. Determine seed length (Handle both Hex "08" and Decimal "8")
  //           int seedLength = int.tryParse(seedkeynumbytes, radix: 16) ?? 0;
  //           if (seedLength == 0)
  //             seedLength = int.tryParse(seedkeynumbytes) ?? 0;

  //           Uint8List seedArray = Uint8List(seedLength);

  //           // 3. Extract Seed from ECU Response
  //           List<int> actualData = reprogrammingResponse.actualDataBytes ?? [];

  //           if (actualData.length >= 2) {
  //             // Correctly extract only the seed portion
  //             int availableBytes = actualData.length - 2;
  //             int bytesToCopy = availableBytes < seedLength
  //                 ? availableBytes
  //                 : seedLength;

  //             for (int i = 0; i < bytesToCopy; i++) {
  //               seedArray[i] = actualData[i + 2];
  //             }
  //           }

  //           print(
  //             "-------seed array = ${byteArrayToHexString(seedArray)}-------",
  //           );

  //           if (seedArray.every((x) => x == 0)) {
  //             skipKey = true;
  //             print("-------seed is zeros, skipping security-------");
  //           } else {
  //             calculateSeedkey = ECUCalculateSeedkey();

  //             // 4. Call calculation
  //             Map<String, dynamic> result = calculateSeedkey.calculateSeedKey(
  //               flashConfigData.seedKeyIndex!,
  //               seedArray.length,
  //               seedArray,
  //             );

  //             // 5. CRITICAL SAFETY CHECK: Prevent the RangeError
  //             if (result.containsKey('key') && result['key'] != null) {
  //               Uint8List tempKey = result['key'] is Uint8List
  //                   ? result['key']
  //                   : Uint8List.fromList(List<int>.from(result['key']));

  //               if (tempKey.isNotEmpty) {
  //                 // Success! Assign the generated key
  //                 seedKey = tempKey;
  //                 print(
  //                   "-------get key response = ${byteArrayToHexString(seedKey)}-------",
  //                 );
  //               } else {
  //                 print("❌ Calculation returned empty key buffer");
  //                 return "ERROR_CALCULATION_EMPTY";
  //               }
  //             } else {
  //               print("❌ Seed-Key Calculation Failed internally");
  //               return "ERROR_KEY_CALCULATION_FAILED";
  //             }
  //           }
  //         }
  //       } else if (command == "repeatstart") {
  //         isLoopPresent = true;
  //         List<String> sData = info.split(',');
  //         int maxIdx = sData[3] == "noofsectors"
  //             ? noofsectors
  //             : int.parse(sData[3]);
  //         loopInit = int.parse(sData[2]);
  //         loopModelList.add(
  //           LoopModel(
  //             i: 0,
  //             loopId: int.parse(sData[0]),
  //             maxIndex: maxIdx,
  //             loopLocation: i,
  //           ),
  //         );
  //         print(
  //           "🔁 repeatstart — loopId=${sData[0]} maxIdx=$maxIdx loopInit=$loopInit",
  //         );
  //       } else if (command == "repeatend") {
  //         loopModelList.last.i = (loopModelList.last.i ?? 0) + 1;
  //         print(
  //           "🔁 repeatend — i=${loopModelList.last.i} / maxIndex=${loopModelList.last.maxIndex}",
  //         );
  //         if (loopModelList.last.i == loopModelList.last.maxIndex) {
  //           print("✅ Loop complete — removing from stack");
  //           loopModelList.removeLast();
  //         } else {
  //           i = loopModelList.last.loopLocation ?? 0;
  //           print("↩️ Loop back to line $i");
  //         }
  //       }
  //       //else if (command == "sendbulkdata") {
  //       //   List<String> sInfo = info.split(',');
  //       //   int seqVarInitValue = int.parse(sInfo[1]);
  //       //   String transferInfo = sInfo[2];
  //       //   // --- RESOLVED PARSING LOGIC ---
  //       //   int startBracket = info.indexOf('[') + 1;
  //       //   int endBracket = info.indexOf(']');
  //       //   String sqrBktInfo = info.substring(startBracket, endBracket);
  //       //   // Split by comma and take the last element to ensure we get the value
  //       //   // regardless of whether the format is [ffd] or [prefix, ffd]
  //       //   List<String> bktParts = sqrBktInfo.split(',');
  //       //   int sectorFrameTransferLen = int.parse(
  //       //     bktParts.last.trim(),
  //       //     radix: 16,
  //       //   );
  //       //   // ------------------------------
  //       //   int blkSeqCnt = seqVarInitValue;
  //       //   int index = isLoopPresent
  //       //       ? loopModelList.last.i ?? 0
  //       //       : currSectorIndex;
  //       //   print(
  //       //     "📦 sendbulkdata — sectorIndex=$index seqVarInitValue=$seqVarInitValue sectorFrameTransferLen=$sectorFrameTransferLen",
  //       //   );
  //       //   Uint8List sectorDataArray = hexStringToBytes(
  //       //     sectordata[index].jsonData ?? "",
  //       //   );
  //       //   int sectorNumBytes = sectorDataArray.length;
  //       //   print("📦 sectorDataArray length: $sectorNumBytes bytes");
  //       //   for (int j = 0; j < sectorNumBytes;) {
  //       //     try {
  //       //       int currentTransferLen =
  //       //           (sectorNumBytes - j) < sectorFrameTransferLen
  //       //           ? (sectorNumBytes - j)
  //       //           : sectorFrameTransferLen;
  //       //       List<String> tSplitData = transferInfo.split('+');
  //       //       List<int> nTxFrameList = [];
  //       //       for (var item in tSplitData) {
  //       //         String trimmedItem = item.trim();
  //       //         if (RegExp(r'^\d+$').hasMatch(trimmedItem)) {
  //       //           nTxFrameList.addAll(hexStringToBytes(trimmedItem));
  //       //         } else if (trimmedItem.contains("bsc")) {
  //       //           nTxFrameList.add(blkSeqCnt & 0xFF);
  //       //         } else if (trimmedItem.contains("json_sectordata")) {
  //       //           nTxFrameList.addAll(
  //       //             sectorDataArray.sublist(j, j + currentTransferLen),
  //       //           );
  //       //         }
  //       //       }
  //       //       j += currentTransferLen;
  //       //       Uint8List nTxFrame = Uint8List.fromList(nTxFrameList);
  //       //       print(
  //       //         "📤 bulk[blk=$blkSeqCnt j=$j/${sectorNumBytes}]: ${nTxFrame.length} bytes",
  //       //       );
  //       //       var bulkResp = await _dongleComm.can2xTxRx(
  //       //         nTxFrame.length,
  //       //         byteArrayToHexString(nTxFrame),
  //       //       );
  //       //       print("📥 bulk response: '${bulkResp.ecuResponseStatus}'");
  //       //       blkSeqCnt++;
  //       //       if (bulkResp.ecuResponseStatus != "NOERROR") {
  //       //         print("❌ bulk ERROR: '${bulkResp.ecuResponseStatus}'");
  //       //         return bulkResp.ecuResponseStatus;
  //       //       }
  //       //       realTimeBytesFlashed += currentTransferLen;
  //       //     } catch (e) {
  //       //       print("❌ bulk exception: $e");
  //       //       return e.toString();
  //       //     }
  //       //   }
  //       //   print(
  //       //     "✅ sendbulkdata complete — totalFlashed so far: $realTimeBytesFlashed",
  //       //   );
  //       // }
  //       else if (command == "sendbulkdata") {
  //         List<String> sInfo = info.split(',');
  //         int seqVarInitValue = int.parse(sInfo[1]);
  //         String transferInfo = sInfo[2];

  //         int startBracket = info.indexOf('[');
  //         int endBracket = info.indexOf(']');
  //         if (startBracket == -1 || endBracket == -1) {
  //           throw FormatException("Missing brackets");
  //         }

  //         String sqrBktInfo = info.substring(startBracket + 1, endBracket);
  //         int sectorFrameTransferLen = int.parse(
  //           sqrBktInfo.split(',').last.trim(),
  //           radix: 16,
  //         );

  //         int blkSeqCnt = seqVarInitValue;
  //         int index = isLoopPresent
  //             ? (loopModelList.last.i ?? 0)
  //             : currSectorIndex;

  //         Uint8List sectorDataArray = hexStringToBytes(
  //           sectordata[index].jsonData ?? "",
  //         );
  //         int sectorNumBytes = sectorDataArray.length;

  //         // Build the frame layout ONCE — static hex bytes + placeholder slots for
  //         // bsc (block sequence counter) and the variable-length data chunk.
  //         final List<String> tSplitData = transferInfo.split('+');
  //         final RegExp hexRe = RegExp(r'^[0-9a-fA-F]+$');

  //         final List<int> layout = [];
  //         int bscPos = -1;
  //         int dataPos = -1;

  //         for (final raw in tSplitData) {
  //           final trimmed = raw.trim();
  //           if (hexRe.hasMatch(trimmed)) {
  //             layout.addAll(hexStringToBytes(trimmed));
  //           } else if (trimmed.contains("bsc")) {
  //             bscPos = layout.length;
  //             layout.add(0);
  //           } else if (trimmed.contains("json_sectordata")) {
  //             dataPos = layout.length;
  //           }
  //         }

  //         // One reusable buffer sized for the largest possible frame.
  //         final int maxFrameLen = layout.length + sectorFrameTransferLen;
  //         final Uint8List frameBuf = Uint8List(maxFrameLen);

  //         print("📦 Starting bulk transfer...");
  //         Stopwatch sw = Stopwatch()..start();

  //         for (int j = 0; j < sectorNumBytes;) {
  //           try {
  //             final int currentTransferLen =
  //                 (sectorNumBytes - j) < sectorFrameTransferLen
  //                 ? (sectorNumBytes - j)
  //                 : sectorFrameTransferLen;

  //             frameBuf.setRange(0, layout.length, layout);
  //             if (bscPos != -1) frameBuf[bscPos] = blkSeqCnt & 0xFF;

  //             int frameLen = layout.length;
  //             if (dataPos != -1) {
  //               frameBuf.setRange(
  //                 dataPos,
  //                 dataPos + currentTransferLen,
  //                 sectorDataArray,
  //                 j,
  //               );
  //               frameLen = layout.length + currentTransferLen;
  //             }

  //             j += currentTransferLen;
  //             final Uint8List nTxFrame = Uint8List.sublistView(
  //               frameBuf,
  //               0,
  //               frameLen,
  //             );

  //             var bulkResp = await _dongleComm.can2xTxRx(
  //               nTxFrame.length,
  //               byteArrayToHexString(nTxFrame),
  //             );

  //             if (bulkResp.ecuResponseStatus != "NOERROR") {
  //               print("❌ Error at byte $j: ${bulkResp.ecuResponseStatus}");
  //               return bulkResp.ecuResponseStatus;
  //             }

  //             blkSeqCnt++;
  //             realTimeBytesFlashed += currentTransferLen;
  //           } catch (e) {
  //             print("❌ bulk exception: $e");
  //             return e.toString();
  //           }
  //         }

  //         sw.stop();
  //         print("✅ Bulk transfer finished in ${sw.elapsed.inSeconds} seconds");
  //       } else if (command == "txid") {
  //         print("🔧 txid: $info");
  //         await _dongleComm.canSetTxHeader(info);
  //       } else if (command == "rxid") {
  //         print("🔧 rxid: $info");
  //         await _dongleComm.canSetRxHeaderMask(info);
  //       } else if (command == "startpadding") {
  //         print("🔧 startpadding: $info");
  //         await _dongleComm.canStartPadding(info);
  //       } else if (command == "stoppadding") {
  //         print("🔧 stoppadding");
  //         await _dongleComm.canStopPadding();
  //       } else if (command == "setstmin") {
  //         print("🔧 setstmin: $info");
  //         await _dongleComm.canSetP1Min(info.trim());
  //       } else if (command == "setP2Max") {
  //         print("🔧 setP2Max: $info");
  //         await _dongleComm.canSetP2Max(info.trim());
  //       } else if (command == "stopTP") {
  //         print("🔧 stopTP");
  //         await _dongleComm.canStopTP();
  //       } else if (command == "startTP") {
  //         print("🔧 startTP");
  //         await _dongleComm.canStartTP();
  //       } else {
  //         print("⚠️ Unknown command '$command' — skipping");
  //       }
  //     }

  //     print(
  //       "🏁 flashInterpreter END — final status: '${reprogrammingResponse.ecuResponseStatus}'",
  //     );
  //   } catch (ex, stack) {
  //     print("❌ flashInterpreter EXCEPTION: $ex");
  //     print("❌ StackTrace: $stack");
  //     return ex.toString();
  //   }

  //   return reprogrammingResponse.ecuResponseStatus;
  // }

  // Use 'int' in Dart as it handles 64-bit integers (replaces uint/long)
  int totalBytesToBeFlashed = 0;
  int realTimeBytesFlashed = 0;

  Future<double> getRuntimeFlashPercent() async {
    if (totalBytesToBeFlashed == 0) return 0.0;
    double runtimeFlashPercent = realTimeBytesFlashed / totalBytesToBeFlashed;
    return runtimeFlashPercent;
  }

  /// Resets the flashing counters
  Future<void> resetPercentage() async {
    totalBytesToBeFlashed = 0;
    realTimeBytesFlashed = 0;
  }

  List<LoopModel> loopModelList = [];
  Future<String?> flashInterpreter(
    FlashConfig flashconfigData,
    int noofsectors,
    List<FlashingMatrix> sectordata,
    String interpreterFile,
  ) async {
    ResponseArrayStatus reprogrammingResponse = ResponseArrayStatus();

    try {
      //_dongleComm!.saveLog("------Start Flashing------\n");

      // ── ENTRY DIAGNOSTICS ─────────────────────────────────────────────────
      print("🚀 flashInterpreter START");
      print("📋 noofsectors: $noofsectors");
      print("📋 sectordata count: ${sectordata.length}");
      print("📋 interpreterFile length: ${interpreterFile.length}");
      print(
        "📋 interpreterFile preview: ${interpreterFile.length > 300 ? interpreterFile.substring(0, 300) : interpreterFile}",
      );

      if (interpreterFile.isEmpty) {
        print("❌ interpreterFile is EMPTY — cannot flash");
        return "ERROR : interpreter file is empty";
      }
      if (noofsectors == 0 || sectordata.isEmpty) {
        print(
          "❌ No sector data — noofsectors=$noofsectors sectordata=${sectordata.length}",
        );
        return "ERROR : no sector data";
      }

      List<String> lineData = interpreterFile.split('\n');
      print("📋 Total interpreter lines: ${lineData.length}");

      // ── TOTAL BYTES CALCULATION ───────────────────────────────────────────
      totalBytesToBeFlashed = 0;
      realTimeBytesFlashed = 0;
      for (int i = 0; i < noofsectors; i++) {
        Uint8List sectorDataArray = hexStringToByteArray(
          sectordata[i].jsonData ?? "",
        );
        int sectorNumBytes = sectorDataArray.length;
        totalBytesToBeFlashed += sectorNumBytes;
        print(
          "📦 Sector[$i] jsonData length (bytes): $sectorNumBytes | startAddr: ${sectordata[i].jsonStartAddress} | endAddr: ${sectordata[i].jsonEndAddress}",
        );
      }
      print("📦 totalBytesToBeFlashed: $totalBytesToBeFlashed");

      Uint8List seedKey = Uint8List(0);
      int currSectorIndex = 0;
      bool isLoopPresent = false;
      int loopInit = 0;
      bool skipKey = false;

      // ── INTERPRETER LOOP ──────────────────────────────────────────────────
      for (int i = 0; i < lineData.length; i++) {
        String formattedLine = lineData[i].replaceAll('\r', '').trim();

        if (formattedLine.isEmpty || formattedLine.startsWith("//")) {
          continue;
        } else if (skipKey) {
          print("⏭ Skipping line (skipKey=true): $formattedLine");
          skipKey = false;
          continue;
        }

        List<String> parts = formattedLine.split(':');
        String command = parts[0];
        String info = parts.length > 1 ? parts[1] : "";

        print("🔄 Line[$i] command='$command' info='$info'");

        // ── send / sendroutine / sendignore / sendroutineignore ──────────
        if (command == "send" ||
            command == "sendroutine" ||
            command == "sendignore" ||
            command == "sendroutineignore") {
          List<String> splitData = info.split('+');
          List<int> txFrameList = [];

          for (var item in splitData) {
            if (!item.contains("<")) {
              txFrameList.addAll(hexStringToByteArray(item));
            } else {
              int endIndex = item.indexOf('>');
              String bracketString = item.substring(1, endIndex);
              List<String> bParts = bracketString.split(',');
              String reference = bParts[0];
              int copyLength = int.parse(bParts[1]);
              print("   🔧 reference='$reference' copyLength=$copyLength");

              Uint8List copyArray = Uint8List(0);

              if (reference.contains("key")) {
                copyArray = seedKey;
                print("   🔑 key bytes: ${byteArrayToHexString(seedKey)}");
              } else if (reference.contains("json_strt_addr") ||
                  reference.contains("ecu_memmap_strt_addr")) {
                int index;
                if (reference.contains("[i]")) {
                  index = loopModelList.last.i ?? 0;
                } else {
                  String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
                  index = int.parse(match);
                  currSectorIndex = index;
                }
                String addrHex = reference.contains("json_strt_addr")
                    ? (sectordata[index].jsonStartAddress ?? "").padLeft(
                        copyLength * 2,
                        '0',
                      )
                    : (sectordata[index].ecuMemMapStartAddress ?? "").padLeft(
                        copyLength * 2,
                        '0',
                      );
                copyArray = hexStringToByteArray(addrHex);
                print("   📍 start_addr[$index]: $addrHex");
              } else if (reference.contains("json_end_addr") ||
                  reference.contains("ecu_memmap_end_addr")) {
                int index;
                if (reference.contains("[i]")) {
                  index = loopModelList.last.i ?? 0;
                } else {
                  String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
                  index = int.parse(match);
                  currSectorIndex = index;
                }
                String addrHex = reference.contains("json_end_addr")
                    ? (sectordata[index].jsonEndAddress ?? "").padLeft(
                        copyLength * 2,
                        '0',
                      )
                    : (sectordata[index].ecuMemMapEndAddress ?? "").padLeft(
                        copyLength * 2,
                        '0',
                      );
                copyArray = hexStringToByteArray(addrHex);
                print("   📍 end_addr[$index]: $addrHex");
              } else if (reference.contains("json_checksum")) {
                int index;
                if (reference.contains("[i]")) {
                  index = loopModelList.last.i ?? 0;
                } else {
                  String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
                  index = int.parse(match);
                  currSectorIndex = index;
                }
                String checkSumHex = (sectordata[index].jsonCheckSum ?? "")
                    .padLeft(copyLength * 2, '0');
                copyArray = hexStringToByteArray(checkSumHex);
                print("   🔢 checksum[$index]: $checkSumHex");
              } else if (reference.contains("json_sector_len") ||
                  reference.contains("ecu_memmap_len")) {
                int index;
                if (reference.contains("[i]")) {
                  index = loopModelList.last.i ?? 0;
                } else {
                  String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
                  index = int.parse(match);
                  currSectorIndex = index;
                }
                int sectorNumBytes;
                if (reference.contains("json_sector_len")) {
                  sectorNumBytes =
                      int.parse(sectordata[index].jsonEndAddress!, radix: 16) -
                      int.parse(
                        sectordata[index].jsonStartAddress!,
                        radix: 16,
                      ) +
                      1;
                } else {
                  sectorNumBytes =
                      int.parse(
                        sectordata[index].ecuMemMapEndAddress!,
                        radix: 16,
                      ) -
                      int.parse(
                        sectordata[index].ecuMemMapStartAddress!,
                        radix: 16,
                      ) +
                      1;
                }
                String hexLen = sectorNumBytes
                    .toRadixString(16)
                    .padLeft(copyLength * 2, '0');
                copyArray = hexStringToByteArray(hexLen);
                print(
                  "   📏 sector_len[$index]: $sectorNumBytes bytes → $hexLen",
                );
              } else if (reference.contains("calculate_sector_len")) {
                int index;
                if (reference.contains("[i]")) {
                  index = loopModelList.last.i ?? 0;
                } else {
                  String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
                  index = int.parse(match);
                  currSectorIndex = index;
                }
                int sectorNumBytes = (sectordata[index].jsonData!.length ~/ 2);
                String hexLen = sectorNumBytes
                    .toRadixString(16)
                    .padLeft(copyLength * 2, '0');
                copyArray = hexStringToByteArray(hexLen);
                print(
                  "   📏 calc_sector_len[$index]: $sectorNumBytes bytes → $hexLen",
                );
              } else if (reference.contains("i")) {
                copyArray = Uint8List.fromList([
                  loopModelList.last.i! + loopInit,
                ]);
                print(
                  "   🔢 loop i value: ${loopModelList.last.i! + loopInit}",
                );
              } else {
                print(
                  "   ⚠️ Unknown reference: '$reference' — copyArray will be empty",
                );
              }

              Uint8List finalBuffer = Uint8List(copyLength);
              int actualToCopy = copyArray.length > copyLength
                  ? copyLength
                  : copyArray.length;
              finalBuffer.setRange(0, actualToCopy, copyArray);
              txFrameList.addAll(finalBuffer);
            }
          }

          Uint8List txFrame = Uint8List.fromList(txFrameList);
          print(
            "📤 send[$command]: ${byteArrayToHexString(txFrame)} (${txFrame.length} bytes)",
          );

          var sendResp = await _dongleComm!.can2xTxRx(
            txFrame.length,
            byteArrayToHexString(txFrame),
          );
          print("📥 send response: '${sendResp.ecuResponseStatus}'");

          if (command != "sendignore") {
            reprogrammingResponse = sendResp;
          }

          while (reprogrammingResponse.ecuResponseStatus ==
              "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
            print("⏳ RequiredTimeDelay — retrying in 300ms...");
          //  await Future.delayed(const Duration(milliseconds: 300));
            reprogrammingResponse = await _dongleComm!.can2xTxRx(
              txFrame.length,
              byteArrayToHexString(txFrame),
            );
            print(
              "📥 retry response: '${reprogrammingResponse.ecuResponseStatus}'",
            );
          }

          if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
              command != "sendignore") {
            print("❌ send ERROR: '${reprogrammingResponse.ecuResponseStatus}'");
            return reprogrammingResponse.ecuResponseStatus;
          }

          if (command == "sendroutine" || command == "sendroutineignore") {
            String routineReqCommand =
                "3103" + splitData[0].trim().substring(4);
            print("🔁 sendroutine polling: $routineReqCommand");
            bool isRoutineLoop = true;
            while (isRoutineLoop) {
             // await Future.delayed(const Duration(milliseconds: 500));
              var routineResp = await _dongleComm!.can2xTxRx(
                routineReqCommand.length ~/ 2,
                routineReqCommand,
              );
              print(
                "📥 routine response: '${routineResp.ecuResponseStatus}' data: ${routineResp.actualDataBytes != null ? byteArrayToHexString(routineResp.actualDataBytes!) : 'null'}",
              );

              if (command != "sendroutineignore") {
                reprogrammingResponse = routineResp;
              }

              if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
                  command != "sendroutineignore") {
                print(
                  "❌ routine ERROR: '${reprogrammingResponse.ecuResponseStatus}'",
                );
                isRoutineLoop = false;
                return reprogrammingResponse.ecuResponseStatus;
              } else if (routineResp.ecuResponseStatus != "NOERROR" &&
                  command == "sendroutineignore") {
                isRoutineLoop = false;
              } else {
                int statusByte = reprogrammingResponse.actualDataBytes![4];
                print(
                  "   routine statusByte[4]: 0x${statusByte.toRadixString(16).padLeft(2, '0')}",
                );
                if (statusByte == 0x02 ||
                    statusByte == 0x01 ||
                    statusByte == 0x04) {
                  print("   ✅ routine complete");
                  isRoutineLoop = false;
                }
              }
            }
          }
        }

        // ── sleep ──────────────────────────────────────────────────────
        else if (command == "sleep") {
          int ms = int.parse(info);
          print("💤 sleep ${ms}ms");
          await Future.delayed(Duration(milliseconds: ms));
        }

        // ── function (seed/key calc) ──────────────────────────────────
        else if (command == "function") {
          if (info.contains("CalculateKeyFromSeed")) {
            String seedkeynumbytes = "";

            int start = info.indexOf('[');
            int end = info.indexOf(']');
            if (start == -1 || end == -1) return "ERROR_PARSING_INFO";

            String sqrBktInfo = info.substring(start + 1, end);

            if (sqrBktInfo.contains(',')) {
              List<String> partsX = sqrBktInfo.split(',');
              String enumName = partsX[0].trim().replaceAll('-', '_');

              flashconfigData.seedKeyIndex = SEEDKEYINDEXTYPE.values.firstWhere(
                (e) => e.toString().split('.').last == enumName,
                orElse: () => SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD,
              );
              seedkeynumbytes = partsX[1].trim();
            } else {
              seedkeynumbytes = sqrBktInfo.trim();
            }

            int seedLength = int.tryParse(seedkeynumbytes, radix: 16) ?? 0;
            if (seedLength == 0) {
              seedLength = int.tryParse(seedkeynumbytes) ?? 0;
            }

            Uint8List seedArray = Uint8List(seedLength);

            List<int> actualData = reprogrammingResponse.actualDataBytes ?? [];

            if (actualData.length >= 2) {
              int availableBytes = actualData.length - 2;
              int bytesToCopy = availableBytes < seedLength
                  ? availableBytes
                  : seedLength;

              for (int k = 0; k < bytesToCopy; k++) {
                seedArray[k] = actualData[k + 2];
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

              Map<String, dynamic> result = calculateSeedkey.calculateSeedKey(
                flashconfigData.seedKeyIndex!,
                seedArray.length,
                seedArray,
              );

              if (result.containsKey('key') && result['key'] != null) {
                Uint8List tempKey = result['key'] is Uint8List
                    ? result['key']
                    : Uint8List.fromList(List<int>.from(result['key']));

                if (tempKey.isNotEmpty) {
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

        // ── repeatstart / repeatend ────────────────────────────────────
        else if (command == "repeatstart") {
          isLoopPresent = true;
          List<String> sData = info.split(',');
          int maxIdx = sData[3] == "noofsectors"
              ? noofsectors
              : int.parse(sData[3]);
          loopInit = int.parse(sData[2]);
          loopModelList.add(
            LoopModel(
              i: 0,
              loopId: int.parse(sData[0]),
              maxIndex: maxIdx,
              loopLocation: i,
            ),
          );
          print(
            "🔁 repeatstart — loopId=${sData[0]} maxIdx=$maxIdx loopInit=$loopInit",
          );
        } else if (command == "repeatend") {
          loopModelList.last.i = (loopModelList.last.i ?? 0) + 1;
          print(
            "🔁 repeatend — i=${loopModelList.last.i} / maxIndex=${loopModelList.last.maxIndex}",
          );
          if (loopModelList.last.i == loopModelList.last.maxIndex) {
            print("✅ Loop complete — removing from stack");
            loopModelList.removeLast();
          } else {
            i = loopModelList.last.loopLocation ?? 0;
            print("↩️ Loop back to line $i");
          }
        }

        // ── sendbulkdata (SINGLE block — no dead duplicate) ─────────────
        else if (command == "sendbulkdata") {
          List<String> sInfo = info.split(',');
          int blkSeqCnt = int.parse(sInfo[1]);
          String transferInfo = sInfo[2];

          int startBracket = info.indexOf('[');
          int endBracket = info.indexOf(']');
          if (startBracket == -1 || endBracket == -1) {
            throw FormatException("Missing brackets");
          }

          String sqrBktInfo = info.substring(startBracket + 1, endBracket);
          int sectorFrameTransferLen = int.parse(
            sqrBktInfo.split(',').last.trim(),
            radix: 16,
          );

          int index = isLoopPresent
              ? (loopModelList.last.i ?? 0)
              : currSectorIndex;

          print(
            "📦 sendbulkdata — sectorIndex=$index blkSeqCnt=$blkSeqCnt sectorFrameTransferLen=$sectorFrameTransferLen",
          );

          Uint8List sectorDataArray = hexStringToByteArray(
            sectordata[index].jsonData ?? "",
          );
          int sectorNumBytes = sectorDataArray.length;
          print("📦 sectorDataArray length: $sectorNumBytes bytes");

          List<String> tSplitData = transferInfo.split('+');
          final RegExp hexRe = RegExp(r'^[0-9a-fA-F]+$');

          bool needsDynamicAddr = tSplitData.any(
            (t) => t.trim().contains("json_strt_addr") ||
                t.trim().contains("sectordatasent"),
          );

          Stopwatch sw = Stopwatch()..start();

          if (!needsDynamicAddr) {
     
            final List<int> layout = [];
            int bscPos = -1;
            int dataPos = -1;

            for (final raw in tSplitData) {
              final trimmed = raw.trim();
              if (trimmed.contains("bsc")) {
                bscPos = layout.length;
                layout.add(0);
              } else if (trimmed.contains("json_sectordata")) {
                dataPos = layout.length;
              } else if (hexRe.hasMatch(trimmed)) {
                layout.addAll(hexStringToByteArray(trimmed));
              }
            }

            final int maxFrameLen = layout.length + sectorFrameTransferLen;
            final Uint8List frameBuf = Uint8List(maxFrameLen);

            for (int j = 0; j < sectorNumBytes;) {
              try {
                final int currentTransferLen =
                    (sectorNumBytes - j) < sectorFrameTransferLen
                    ? (sectorNumBytes - j)
                    : sectorFrameTransferLen;

                frameBuf.setRange(0, layout.length, layout);
                if (bscPos != -1) frameBuf[bscPos] = blkSeqCnt & 0xFF;

                int frameLen = layout.length;
                if (dataPos != -1) {
                  frameBuf.setRange(
                    dataPos,
                    dataPos + currentTransferLen,
                    sectorDataArray,
                    j,
                  );
                  frameLen = layout.length + currentTransferLen;
                }

                j += currentTransferLen;
                final Uint8List nTxFrame = Uint8List.sublistView(
                  frameBuf,
                  0,
                  frameLen,
                );

                var bulkResp = await _dongleComm!.can2xTxRx(
                  nTxFrame.length,
                  byteArrayToHexString(nTxFrame),
                );

                if (bulkResp.ecuResponseStatus != "NOERROR") {
                  print("❌ bulk ERROR at byte $j: ${bulkResp.ecuResponseStatus}");
                  return bulkResp.ecuResponseStatus;
                }

                blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
                // Update EVERY frame, not batched — this is just an int
                // add, it costs nothing, and it's what keeps the progress
                // bar from freezing then jumping between UI polls.
                realTimeBytesFlashed += currentTransferLen;
              } catch (e) {
                print("❌ bulk exception: $e");
                return e.toString();
              }
            }
          } else {
            // ---- GENERAL PATH: template needs a per-frame-varying
            // value (address or sent-length) — rebuild each frame. ----
            int startAddr = int.parse(
              sectordata[index].jsonStartAddress!,
              radix: 16,
            );

            for (int j = 0; j < sectorNumBytes;) {
              try {
                final int currentTransferLen =
                    (sectorNumBytes - j) < sectorFrameTransferLen
                    ? (sectorNumBytes - j)
                    : sectorFrameTransferLen;

                List<int> nTxFrameList = [];

                for (final raw in tSplitData) {
                  final trimmed = raw.trim();

                  if (trimmed.contains("bsc")) {
                    nTxFrameList.add(blkSeqCnt & 0xFF);
                  } else if (trimmed.contains("json_sectordata")) {
                    nTxFrameList.addAll(
                      sectorDataArray.sublist(j, j + currentTransferLen),
                    );
                  } else if (trimmed.contains("json_strt_addr")) {
                    int endIdx = trimmed.indexOf('>');
                    String bracketStr = trimmed.substring(1, endIdx);
                    int copyLength = int.parse(
                      bracketStr.split(',')[1].trim(),
                      radix: 16,
                    );

                    Uint8List addrBig = (ByteData(4)
                          ..setUint32(0, startAddr, Endian.big))
                        .buffer
                        .asUint8List();

                    Uint8List trimmedAddr = addrBig.length > copyLength
                        ? addrBig.sublist(addrBig.length - copyLength)
                        : addrBig;

                    nTxFrameList.addAll(trimmedAddr);
                    startAddr += sectorFrameTransferLen;
                  } else if (trimmed.contains("sectordatasent")) {
                    int endIdx = trimmed.indexOf('>');
                    String bracketStr = trimmed.substring(1, endIdx);
                    int copyLength = int.parse(
                      bracketStr.split(',')[1].trim(),
                      radix: 16,
                    );

                    Uint8List lenBig = (ByteData(4)
                          ..setUint32(0, currentTransferLen, Endian.big))
                        .buffer
                        .asUint8List();

                    Uint8List trimmedLen = lenBig.length > copyLength
                        ? lenBig.sublist(lenBig.length - copyLength)
                        : lenBig;

                    nTxFrameList.addAll(trimmedLen);
                  } else if (hexRe.hasMatch(trimmed) &&
                      !trimmed.contains('<')) {
                    nTxFrameList.addAll(hexStringToByteArray(trimmed));
                  }
                }

                j += currentTransferLen;
                Uint8List nTxFrame = Uint8List.fromList(nTxFrameList);

                var bulkResp = await _dongleComm!.can2xTxRx(
                  nTxFrame.length,
                  byteArrayToHexString(nTxFrame),
                );

                if (bulkResp.ecuResponseStatus != "NOERROR") {
                  print("❌ bulk ERROR at byte $j: ${bulkResp.ecuResponseStatus}");
                  return bulkResp.ecuResponseStatus;
                }

                blkSeqCnt = (blkSeqCnt + 1) & 0xFF;
                realTimeBytesFlashed += currentTransferLen;
              } catch (e) {
                print("❌ bulk exception: $e");
                return e.toString();
              }
            }
          }

          sw.stop();
          print(
            "✅ sendbulkdata complete in ${sw.elapsed.inSeconds}s — totalFlashed so far: $realTimeBytesFlashed",
          );
        }

        // ── dongle config commands ────────────────────────────────────
        else if (command == "txid") {
          print("🔧 txid: $info");
          await _dongleComm!.canSetTxHeader(info);
        } else if (command == "rxid") {
          print("🔧 rxid: $info");
          await _dongleComm!.canSetRxHeaderMask(info);
        } else if (command == "startpadding") {
          print("🔧 startpadding: $info");
          await _dongleComm!.canStartPadding(info);
        } else if (command == "stoppadding") {
          print("🔧 stoppadding");
          await _dongleComm!.canStopPadding();
        } else if (command == "setstmin") {
          print("🔧 setstmin: $info");
          await _dongleComm!.canSetP1Min(info.trim());
        } else if (command == "setP2Max") {
          print("🔧 setP2Max: $info");
          await _dongleComm!.canSetP2Max(info.trim());
        } else if (command == "stopTP") {
          print("🔧 stopTP");
          await _dongleComm!.canStopTP();
        } else if (command == "startTP") {
          print("🔧 startTP");
          await _dongleComm!.canStartTP();
        } else {
          print("⚠️ Unknown command '$command' — skipping");
        }
      }

      print(
        "🏁 flashInterpreter END — final status: '${reprogrammingResponse.ecuResponseStatus}'",
      );
    } catch (ex, stack) {
      print("❌ flashInterpreter EXCEPTION: $ex");
      print("❌ StackTrace: $stack");
      return ex.toString();
    }

    return reprogrammingResponse.ecuResponseStatus;
  }

  // Future<String?> flashInterpreter(
  //   FlashConfig flashConfigData,
  //   int noofsectors,
  //   List<FlashingMatrix> sectordata,
  //   String interpreterFile,
  // ) async {
  //   ResponseArrayStatus reprogrammingResponse = ResponseArrayStatus();

  //   try {
  //     print("🚀 flashInterpreter START");
  //     print("📋 noofsectors: $noofsectors");
  //     print("📋 sectordata count: ${sectordata.length}");
  //     print("📋 interpreterFile length: ${interpreterFile.length}");

  //     if (interpreterFile.isEmpty) {
  //       print("❌ interpreterFile is EMPTY — cannot flash");
  //       return "ERROR : interpreter file is empty";
  //     }
  //     if (noofsectors == 0 || sectordata.isEmpty) {
  //       print(
  //         "❌ No sector data — noofsectors=$noofsectors sectordata=${sectordata.length}",
  //       );
  //       return "ERROR : no sector data";
  //     }

  //     List<String> lineData = interpreterFile.split('\n');
  //     print("📋 Total interpreter lines: ${lineData.length}");

  //     // ── TOTAL BYTES CALCULATION ───────────────────────────────────────────
  //     totalBytesToBeFlashed = 0;
  //     realTimeBytesFlashed = 0;
  //     for (int i = 0; i < noofsectors; i++) {
  //       Uint8List sectorDataArray = hexStringToBytes(
  //         sectordata[i].jsonData ?? "",
  //       );
  //       int sectorNumBytes = sectorDataArray.length;
  //       totalBytesToBeFlashed += sectorNumBytes;
  //       print(
  //         "📦 Sector[$i] jsonData length (bytes): $sectorNumBytes | startAddr: ${sectordata[i].jsonStartAddress} | endAddr: ${sectordata[i].jsonEndAddress}",
  //       );
  //     }
  //     print("📦 totalBytesToBeFlashed: $totalBytesToBeFlashed");

  //     Uint8List seedKey = Uint8List(0);
  //     int currSectorIndex = 0;
  //     bool isLoopPresent = false;
  //     int loopInit = 0;
  //     bool skipKey = false;

  //     // ── INTERPRETER LOOP ──────────────────────────────────────────────────
  //     for (int i = 0; i < lineData.length; i++) {
  //       String formattedLine = lineData[i].replaceAll('\r', '').trim();

  //       if (formattedLine.isEmpty || formattedLine.startsWith("//")) {
  //         continue;
  //       } else if (skipKey) {
  //         print("⏭ Skipping line (skipKey=true): $formattedLine");
  //         skipKey = false;
  //         continue;
  //       }

  //       List<String> parts = formattedLine.split(':');
  //       String command = parts[0];
  //       String info = parts.length > 1 ? parts[1] : "";

  //       print("🔄 Line[$i] command='$command' info='$info'");

  //       // ── send / sendroutine / sendignore / sendroutineignore ──────────
  //       if (command == "send" ||
  //           command == "sendroutine" ||
  //           command == "sendignore" ||
  //           command == "sendroutineignore") {
  //         List<String> splitData = info.split('+');
  //         List<int> txFrameList = [];

  //         for (var item in splitData) {
  //           if (!item.contains("<")) {
  //             txFrameList.addAll(hexStringToBytes(item));
  //           } else {
  //             int endIndex = item.indexOf('>');
  //             String bracketString = item.substring(1, endIndex);
  //             List<String> bParts = bracketString.split(',');
  //             String reference = bParts[0];
  //             int copyLength = int.parse(bParts[1]);
  //             print("   🔧 reference='$reference' copyLength=$copyLength");

  //             Uint8List copyArray = Uint8List(0);

  //             if (reference.contains("key")) {
  //               copyArray = seedKey;
  //               print("   🔑 key bytes: ${bytesToHex(seedKey)}");
  //             } else if (reference.contains("json_strt_addr") ||
  //                 reference.contains("ecu_memmap_strt_addr")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String addrHex = reference.contains("json_strt_addr")
  //                   ? (sectordata[index].jsonStartAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     )
  //                   : (sectordata[index].ecuMemMapStartAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     );
  //               copyArray = hexStringToBytes(addrHex);
  //               print("   📍 start_addr[$index]: $addrHex");
  //             } else if (reference.contains("json_end_addr") ||
  //                 reference.contains("ecu_memmap_end_addr")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String addrHex = reference.contains("json_end_addr")
  //                   ? (sectordata[index].jsonEndAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     )
  //                   : (sectordata[index].ecuMemMapEndAddress ?? "").padLeft(
  //                       copyLength * 2,
  //                       '0',
  //                     );
  //               copyArray = hexStringToBytes(addrHex);
  //               print("   📍 end_addr[$index]: $addrHex");
  //             } else if (reference.contains("json_checksum")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               String checkSumHex = (sectordata[index].jsonCheckSum ?? "")
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(checkSumHex);
  //               print("   🔢 checksum[$index]: $checkSumHex");
  //             } else if (reference.contains("json_sector_len") ||
  //                 reference.contains("ecu_memmap_len")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               int sectorNumBytes;
  //               if (reference.contains("json_sector_len")) {
  //                 sectorNumBytes =
  //                     int.parse(sectordata[index].jsonEndAddress!, radix: 16) -
  //                     int.parse(
  //                       sectordata[index].jsonStartAddress!,
  //                       radix: 16,
  //                     ) +
  //                     1;
  //               } else {
  //                 sectorNumBytes =
  //                     int.parse(
  //                       sectordata[index].ecuMemMapEndAddress!,
  //                       radix: 16,
  //                     ) -
  //                     int.parse(
  //                       sectordata[index].ecuMemMapStartAddress!,
  //                       radix: 16,
  //                     ) +
  //                     1;
  //               }
  //               String hexLen = sectorNumBytes
  //                   .toRadixString(16)
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(hexLen);
  //               print(
  //                 "   📏 sector_len[$index]: $sectorNumBytes bytes → $hexLen",
  //               );
  //             } else if (reference.contains("calculate_sector_len")) {
  //               int index;
  //               if (reference.contains("[i]")) {
  //                 index = loopModelList.last.i ?? 0;
  //               } else {
  //                 String match = RegExp(r'\d+').stringMatch(reference) ?? "0";
  //                 index = int.parse(match);
  //                 currSectorIndex = index;
  //               }
  //               int sectorNumBytes = (sectordata[index].jsonData!.length ~/ 2);
  //               String hexLen = sectorNumBytes
  //                   .toRadixString(16)
  //                   .padLeft(copyLength * 2, '0');
  //               copyArray = hexStringToBytes(hexLen);
  //               print(
  //                 "   📏 calc_sector_len[$index]: $sectorNumBytes bytes → $hexLen",
  //               );
  //             } else if (reference.contains("i")) {
  //               copyArray = Uint8List.fromList([
  //                 loopModelList.last.i! + loopInit,
  //               ]);
  //               print(
  //                 "   🔢 loop i value: ${loopModelList.last.i! + loopInit}",
  //               );
  //             } else {
  //               print(
  //                 "   ⚠️ Unknown reference: '$reference' — copyArray will be empty",
  //               );
  //             }

  //             Uint8List finalBuffer = Uint8List(copyLength);
  //             int actualToCopy = copyArray.length > copyLength
  //                 ? copyLength
  //                 : copyArray.length;
  //             finalBuffer.setRange(0, actualToCopy, copyArray);
  //             txFrameList.addAll(finalBuffer);
  //           }
  //         }

  //         Uint8List txFrame = Uint8List.fromList(txFrameList);
  //         print(
  //           "📤 send[$command]: ${bytesToHex(txFrame)} (${txFrame.length} bytes)",
  //         );

  //         var sendResp = await _dongleComm.can2xTxRx(
  //           txFrame.length,
  //           bytesToHex(txFrame),
  //         );
  //         print("📥 send response: '${sendResp.ecuResponseStatus}'");

  //         if (command != "sendignore") {
  //           reprogrammingResponse = sendResp;
  //         }

  //         while (reprogrammingResponse.ecuResponseStatus ==
  //             "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED") {
  //           print("⏳ RequiredTimeDelay — retrying in 300ms...");
  //           //await Future.delayed(const Duration(milliseconds: 300));
  //           reprogrammingResponse = await _dongleComm.can2xTxRx(
  //             txFrame.length,
  //             bytesToHex(txFrame),
  //           );
  //           print(
  //             "📥 retry response: '${reprogrammingResponse.ecuResponseStatus}'",
  //           );
  //         }

  //         if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
  //             command != "sendignore") {
  //           print("❌ send ERROR: '${reprogrammingResponse.ecuResponseStatus}'");
  //           return reprogrammingResponse.ecuResponseStatus;
  //         }

  //         if (command == "sendroutine" || command == "sendroutineignore") {
  //           String routineReqCommand =
  //               "3103" + splitData[0].trim().substring(4);
  //           print("🔁 sendroutine polling: $routineReqCommand");
  //           bool isRoutineLoop = true;
  //           while (isRoutineLoop) {
  //             var routineResp = await _dongleComm.can2xTxRx(
  //               routineReqCommand.length ~/ 2,
  //               routineReqCommand,
  //             );
  //             print(
  //               "📥 routine response: '${routineResp.ecuResponseStatus}' data: ${routineResp.actualDataBytes != null ? bytesToHex(routineResp.actualDataBytes!) : 'null'}",
  //             );

  //             if (command != "sendroutineignore") {
  //               reprogrammingResponse = routineResp;
  //             }

  //             if (reprogrammingResponse.ecuResponseStatus != "NOERROR" &&
  //                 command != "sendroutineignore") {
  //               print(
  //                 "❌ routine ERROR: '${reprogrammingResponse.ecuResponseStatus}'",
  //               );
  //               isRoutineLoop = false;
  //               return reprogrammingResponse.ecuResponseStatus;
  //             } else if (routineResp.ecuResponseStatus != "NOERROR" &&
  //                 command == "sendroutineignore") {
  //               isRoutineLoop = false;
  //             } else {
  //               int statusByte = reprogrammingResponse.actualDataBytes![4];
  //               print(
  //                 "   routine statusByte[4]: 0x${statusByte.toRadixString(16).padLeft(2, '0')}",
  //               );
  //               if (statusByte == 0x02 ||
  //                   statusByte == 0x01 ||
  //                   statusByte == 0x04) {
  //                 print("   ✅ routine complete");
  //                 isRoutineLoop = false;
  //               }
  //             }
  //           }
  //         }
  //       }

  //       // ── sleep ──────────────────────────────────────────────────────
  //       else if (command == "sleep") {
  //         int ms = int.parse(info);
  //         print("💤 sleep ${ms}ms");
  //         await Future.delayed(Duration(milliseconds: ms));
  //       }

  //       // ── function (seed/key calc) ──────────────────────────────────
  //       else if (command == "function") {
  //         if (info.contains("CalculateKeyFromSeed")) {
  //           String seedkeynumbytes = "";

  //           int start = info.indexOf('[');
  //           int end = info.indexOf(']');
  //           if (start == -1 || end == -1) return "ERROR_PARSING_INFO";

  //           String sqrBktInfo = info.substring(start + 1, end);

  //           if (sqrBktInfo.contains(',')) {
  //             List<String> partsX = sqrBktInfo.split(',');
  //             String enumName = partsX[0].trim().replaceAll('-', '_');

  //             flashConfigData.seedKeyIndex = SEEDKEYINDEXTYPE.values.firstWhere(
  //               (e) => e.toString().split('.').last == enumName,
  //               orElse: () => SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD,
  //             );
  //             seedkeynumbytes = partsX[1].trim();
  //           } else {
  //             seedkeynumbytes = sqrBktInfo.trim();
  //           }

  //           int seedLength = int.tryParse(seedkeynumbytes, radix: 16) ?? 0;
  //           if (seedLength == 0) {
  //             seedLength = int.tryParse(seedkeynumbytes) ?? 0;
  //           }

  //           Uint8List seedArray = Uint8List(seedLength);

  //           List<int> actualData = reprogrammingResponse.actualDataBytes ?? [];

  //           if (actualData.length >= 2) {
  //             int availableBytes = actualData.length - 2;
  //             int bytesToCopy = availableBytes < seedLength
  //                 ? availableBytes
  //                 : seedLength;

  //             for (int k = 0; k < bytesToCopy; k++) {
  //               seedArray[k] = actualData[k + 2];
  //             }
  //           }

  //           print(
  //             "-------seed array = ${byteArrayToHexString(seedArray)}-------",
  //           );

  //           if (seedArray.every((x) => x == 0)) {
  //             skipKey = true;
  //             print("-------seed is zeros, skipping security-------");
  //           } else {
  //             calculateSeedkey = ECUCalculateSeedkey();

  //             Map<String, dynamic> result = calculateSeedkey.calculateSeedKey(
  //               flashConfigData.seedKeyIndex!,
  //               seedArray.length,
  //               seedArray,
  //             );

  //             if (result.containsKey('key') && result['key'] != null) {
  //               Uint8List tempKey = result['key'] is Uint8List
  //                   ? result['key']
  //                   : Uint8List.fromList(List<int>.from(result['key']));

  //               if (tempKey.isNotEmpty) {
  //                 seedKey = tempKey;
  //                 print(
  //                   "-------get key response = ${byteArrayToHexString(seedKey)}-------",
  //                 );
  //               } else {
  //                 print("❌ Calculation returned empty key buffer");
  //                 return "ERROR_CALCULATION_EMPTY";
  //               }
  //             } else {
  //               print("❌ Seed-Key Calculation Failed internally");
  //               return "ERROR_KEY_CALCULATION_FAILED";
  //             }
  //           }
  //         }
  //       }

  //       // ── repeatstart / repeatend ────────────────────────────────────
  //       else if (command == "repeatstart") {
  //         isLoopPresent = true;
  //         List<String> sData = info.split(',');
  //         int maxIdx = sData[3] == "noofsectors"
  //             ? noofsectors
  //             : int.parse(sData[3]);
  //         loopInit = int.parse(sData[2]);
  //         loopModelList.add(
  //           LoopModel(
  //             i: 0,
  //             loopId: int.parse(sData[0]),
  //             maxIndex: maxIdx,
  //             loopLocation: i,
  //           ),
  //         );
  //         print(
  //           "🔁 repeatstart — loopId=${sData[0]} maxIdx=$maxIdx loopInit=$loopInit",
  //         );
  //       } else if (command == "repeatend") {
  //         loopModelList.last.i = (loopModelList.last.i ?? 0) + 1;
  //         print(
  //           "🔁 repeatend — i=${loopModelList.last.i} / maxIndex=${loopModelList.last.maxIndex}",
  //         );
  //         if (loopModelList.last.i == loopModelList.last.maxIndex) {
  //           print("✅ Loop complete — removing from stack");
  //           loopModelList.removeLast();
  //         } else {
  //           i = loopModelList.last.loopLocation ?? 0;
  //           print("↩️ Loop back to line $i");
  //         }
  //       }

  //       // ── sendbulkdata ────────────────────────────────────────────────
  //       else if (command == "sendbulkdata") {
  //         List<String> sInfo = info.split(',');
  //         int seqVarInitValue = int.parse(sInfo[1]);
  //         String transferInfo = sInfo[2];

  //         int startBracket = info.indexOf('[');
  //         int endBracket = info.indexOf(']');
  //         if (startBracket == -1 || endBracket == -1) {
  //           throw FormatException("Missing brackets");
  //         }

  //         String sqrBktInfo = info.substring(startBracket + 1, endBracket);
  //         int sectorFrameTransferLen = int.parse(
  //           sqrBktInfo.split(',').last.trim(),
  //           radix: 16,
  //         );

  //         int blkSeqCnt = seqVarInitValue;
  //         int index = isLoopPresent
  //             ? (loopModelList.last.i ?? 0)
  //             : currSectorIndex;

  //         Uint8List sectorDataArray = hexStringToBytes(
  //           sectordata[index].jsonData ?? "",
  //         );
  //         int sectorNumBytes = sectorDataArray.length;

  //         List<String> tSplitData = transferInfo.split('+');
  //         final RegExp hexRe = RegExp(r'^[0-9a-fA-F]+$');

  //         bool needsDynamicAddr = tSplitData.any(
  //           (t) => t.trim().contains("json_strt_addr") ||
  //               t.trim().contains("sectordatasent"),
  //         );

  //         print(
  //           "📦 Starting bulk transfer... (dynamic-addr mode: $needsDynamicAddr)",
  //         );
  //         Stopwatch sw = Stopwatch()..start();

  //         if (!needsDynamicAddr) {
  //           // ---- FAST PATH: static layout, reused buffer ----
  //           final List<int> layout = [];
  //           int bscPos = -1;
  //           int dataPos = -1;

  //           for (final raw in tSplitData) {
  //             final trimmed = raw.trim();
  //             if (trimmed.contains("bsc")) {
  //               bscPos = layout.length;
  //               layout.add(0);
  //             } else if (trimmed.contains("json_sectordata")) {
  //               dataPos = layout.length;
  //             } else if (hexRe.hasMatch(trimmed)) {
  //               layout.addAll(hexStringToBytes(trimmed));
  //             }
  //           }

  //           final int maxFrameLen = layout.length + sectorFrameTransferLen;
  //           final Uint8List frameBuf = Uint8List(maxFrameLen);

  //           for (int j = 0; j < sectorNumBytes;) {
  //             try {
  //               final int currentTransferLen =
  //                   (sectorNumBytes - j) < sectorFrameTransferLen
  //                   ? (sectorNumBytes - j)
  //                   : sectorFrameTransferLen;

  //               frameBuf.setRange(0, layout.length, layout);
  //               if (bscPos != -1) frameBuf[bscPos] = blkSeqCnt & 0xFF;

  //               int frameLen = layout.length;
  //               if (dataPos != -1) {
  //                 frameBuf.setRange(
  //                   dataPos,
  //                   dataPos + currentTransferLen,
  //                   sectorDataArray,
  //                   j,
  //                 );
  //                 frameLen = layout.length + currentTransferLen;
  //               }

  //               j += currentTransferLen;
  //               final Uint8List nTxFrame = Uint8List.sublistView(
  //                 frameBuf,
  //                 0,
  //                 frameLen,
  //               );

  //               var bulkResp = await _dongleComm.can2xTxRx(
  //                 nTxFrame.length,
  //                 byteArrayToHexString(nTxFrame),
  //               );

  //               if (bulkResp.ecuResponseStatus != "NOERROR") {
  //                 print("❌ Error at byte $j: ${bulkResp.ecuResponseStatus}");
  //                 return bulkResp.ecuResponseStatus;
  //               }

  //               blkSeqCnt++;
  //               realTimeBytesFlashed += currentTransferLen;
  //             } catch (e) {
  //               print("❌ bulk exception: $e");
  //               return e.toString();
  //             }
  //           }
  //         } else {
  //           // ---- GENERAL PATH: rebuild frame each iteration (matches C#) ----
  //           int startAddr = int.parse(
  //             sectordata[index].jsonStartAddress!,
  //             radix: 16,
  //           );

  //           for (int j = 0; j < sectorNumBytes;) {
  //             try {
  //               final int currentTransferLen =
  //                   (sectorNumBytes - j) < sectorFrameTransferLen
  //                   ? (sectorNumBytes - j)
  //                   : sectorFrameTransferLen;

  //               List<int> nTxFrameList = [];

  //               for (final raw in tSplitData) {
  //                 final trimmed = raw.trim();

  //                 if (trimmed.contains("bsc")) {
  //                   nTxFrameList.add(blkSeqCnt & 0xFF);
  //                 } else if (trimmed.contains("json_sectordata")) {
  //                   nTxFrameList.addAll(
  //                     sectorDataArray.sublist(j, j + currentTransferLen),
  //                   );
  //                 } else if (trimmed.contains("json_strt_addr")) {
  //                   int endIdx = trimmed.indexOf('>');
  //                   String bracketStr = trimmed.substring(1, endIdx);
  //                   int copyLength = int.parse(
  //                     bracketStr.split(',')[1].trim(),
  //                     radix: 16,
  //                   );

  //                   Uint8List addrBig = (ByteData(4)
  //                         ..setUint32(0, startAddr, Endian.big))
  //                       .buffer
  //                       .asUint8List();

  //                   Uint8List trimmedAddr = addrBig.length > copyLength
  //                       ? addrBig.sublist(addrBig.length - copyLength)
  //                       : addrBig;

  //                   nTxFrameList.addAll(trimmedAddr);
  //                   startAddr += sectorFrameTransferLen;
  //                 } else if (trimmed.contains("sectordatasent")) {
  //                   int endIdx = trimmed.indexOf('>');
  //                   String bracketStr = trimmed.substring(1, endIdx);
  //                   int copyLength = int.parse(
  //                     bracketStr.split(',')[1].trim(),
  //                     radix: 16,
  //                   );

  //                   Uint8List lenBig = (ByteData(4)
  //                         ..setUint32(0, currentTransferLen, Endian.big))
  //                       .buffer
  //                       .asUint8List();

  //                   Uint8List trimmedLen = lenBig.length > copyLength
  //                       ? lenBig.sublist(lenBig.length - copyLength)
  //                       : lenBig;

  //                   nTxFrameList.addAll(trimmedLen);
  //                 } else if (hexRe.hasMatch(trimmed) &&
  //                     !trimmed.contains('<')) {
  //                   nTxFrameList.addAll(hexStringToBytes(trimmed));
  //                 }
  //               }

  //               j += currentTransferLen;
  //               Uint8List nTxFrame = Uint8List.fromList(nTxFrameList);

  //               var bulkResp = await _dongleComm.can2xTxRx(
  //                 nTxFrame.length,
  //                 byteArrayToHexString(nTxFrame),
  //               );

  //               if (bulkResp.ecuResponseStatus != "NOERROR") {
  //                 print("❌ Error at byte $j: ${bulkResp.ecuResponseStatus}");
  //                 return bulkResp.ecuResponseStatus;
  //               }

  //               blkSeqCnt++;
  //               realTimeBytesFlashed += currentTransferLen;
  //             } catch (e) {
  //               print("❌ bulk exception: $e");
  //               return e.toString();
  //             }
  //           }
  //         }

  //         sw.stop();
  //         print("✅ Bulk transfer finished in ${sw.elapsed.inSeconds} seconds");
  //       }

  //       // ── dongle config commands ────────────────────────────────────
  //       else if (command == "txid") {
  //         print("🔧 txid: $info");
  //         await _dongleComm.canSetTxHeader(info);
  //       } else if (command == "rxid") {
  //         print("🔧 rxid: $info");
  //         await _dongleComm.canSetRxHeaderMask(info);
  //       } else if (command == "startpadding") {
  //         print("🔧 startpadding: $info");
  //         await _dongleComm.canStartPadding(info);
  //       } else if (command == "stoppadding") {
  //         print("🔧 stoppadding");
  //         await _dongleComm.canStopPadding();
  //       } else if (command == "setstmin") {
  //         print("🔧 setstmin: $info");
  //         await _dongleComm.canSetP1Min(info.trim());
  //       } else if (command == "setP2Max") {
  //         print("🔧 setP2Max: $info");
  //         await _dongleComm.canSetP2Max(info.trim());
  //       } else if (command == "stopTP") {
  //         print("🔧 stopTP");
  //         await _dongleComm.canStopTP();
  //       } else if (command == "startTP") {
  //         print("🔧 startTP");
  //         await _dongleComm.canStartTP();
  //       } else {
  //         print("⚠️ Unknown command '$command' — skipping");
  //       }
  //     }

  //     print(
  //       "🏁 flashInterpreter END — final status: '${reprogrammingResponse.ecuResponseStatus}'",
  //     );
  //   } catch (ex, stack) {
  //     print("❌ flashInterpreter EXCEPTION: $ex");
  //     print("❌ StackTrace: $stack");
  //     return ex.toString();
  //   }

  //   return reprogrammingResponse.ecuResponseStatus;
  // }

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

  String byteArrayToString(List<int> bytes) {
    final buffer = StringBuffer();

    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
    }

    return buffer.toString();
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
