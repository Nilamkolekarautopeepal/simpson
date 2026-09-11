// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:simpson/modals/all.models.dart';
// import 'package:simpson/modals/flashingMatrix_model.dart';
// //import 'package:simpson/modals/flashingMatrix_model.dart';

// class GetJson {
//   Future<String> convertToJson(
//     Uint8List streamBytes,
//     List<EcuMapFile> ecuMapFiles,
//     String checksumAlgo,
//   ) async {
//     try {
//       final hex2json = Hex2JSON();

//       // Convert bytes → string → lines
//       final content = utf8.decode(streamBytes);
//       final lines = LineSplitter.split(content);

//       int counter = 0;
//       String data = "";

//       for (final ln in lines) {
//         counter++;

//         if (ln.trim().isNotEmpty) {
//           final input = hex2json.hex2json(ln); // returns String
//           data = input;
//         }
//       }

//       print("File has $counter lines.");
//       print("APDATA = $data");

//       hex2json.endFile();

//       final flashJson = await hex2json.createJSON(ecuMapFiles, checksumAlgo);

//       return flashJson;
//     } catch (e) {
//       return "";
//     }
//   }
// }

// class Hex2JSON {
//   String filetype = "";
//   String tag = "HEX2JSON";

//   int expectedStrtAddr = 0;

//   // Arrays → List<int>
//   List<int> sectorStrtAddr = List.filled(40, 0);
//   int sectorIndex = 0;

//   int lineStrtAddr = 0;
//   int lineStrtAddrHS = 0x00000000;

//   bool firstLine = true;

//   int defaultEcuAddressing = 4; // 4 byte addressing
//   int sectorDataIndex = 0;
//   int actualDataLength = 0;

//   List<int> sectorLen = List.filled(20, 0);

//   String returnStatus = "NOERROR";

//   // 2D byte array → List<List<int>>
//   List<List<int>> inputFileDataArray =
//       List.generate(20, (_) => List.filled(2000 * 10000, 0));

//   late Crc16 cr;

//   int fileStartAddr = 0x00000000;

//   String projectName = "";
//   String returnstatus = "";

//   List<ReturnJsonDataANDPath> returnJson = [];

//   List<int>? ecuStartAddress;
//   List<int>? ecuEndAddress;
//   List<int>? ecuMemMapNumSectors;

//   List<int>? jsonStartAddress;
//   List<int>? jsonEndAddress;

//   // ✅ Constructor
//   Hex2JSON() {
//     cr = Crc16(Crc16Mode.ccittKermit);
//   }

//   String hex2json(String lineBytes) {
//     try {
//       final firstChar = lineBytes[0];

//       // Detect file type
//       if (firstChar == 'S') {
//         filetype = "SREC";
//       } else if (firstChar == ':') {
//         filetype = "HEX";
//       } else {
//         return "INVALIDFILETYPE";
//       }

//       switch (filetype) {
//         case "HEX":
//           {
//             final line = lineBytes.split('');
//             final actualData = lineBytes.replaceFirst(':', '');
//             final hxArray = hexStringToByteArray(actualData);

//             if (line[0] == ':') {
//               final lineHexArray = hxArray;

//               final lineLen = lineHexArray[0];
//               final lineType = lineHexArray[3];

//               if (lineType == 0x00) {
//                 // DATA LINE
//                 lineStrtAddr = (lineStrtAddrHS +
//                     ((lineHexArray[1] << 8) + lineHexArray[2]));

//                 if (firstLine) {
//                   expectedStrtAddr = lineStrtAddr;
//                   firstLine = false;
//                   sectorStrtAddr[sectorIndex] = lineStrtAddr;
//                 }

//                 if (expectedStrtAddr != lineStrtAddr) {
//                   sectorLen[sectorIndex] = sectorDataIndex;
//                   sectorDataIndex = 0;
//                   sectorStrtAddr[++sectorIndex] = lineStrtAddr;
//                 }

//                 for (int i = 0; i < lineLen; i++) {
//                   try {
//                     inputFileDataArray[sectorIndex][sectorDataIndex + i] =
//                         lineHexArray[4 + i];
//                   } catch (_) {}
//                 }

//                 sectorDataIndex += lineLen;
//                 expectedStrtAddr = (lineStrtAddr + lineLen);
//               } else if (lineType == 0x04) {
//                 // 4-byte addressing
//                 lineStrtAddrHS =
//                     ((lineHexArray[4] << 24) + (lineHexArray[5] << 16));
//                 defaultEcuAddressing = 4;
//               } else if (lineType == 0x03) {
//                 lineStrtAddrHS = ((lineHexArray[5] << 16) +
//                     (lineHexArray[6] << 8) +
//                     lineHexArray[7]);
//                 defaultEcuAddressing = 3;
//                 sectorDataIndex = 0;
//                 sectorStrtAddr[sectorIndex++] = lineStrtAddr;
//                 expectedStrtAddr = lineStrtAddrHS;
//               } else if (lineType == 0x02) {
//                 lineStrtAddrHS = ((lineHexArray[4] << 8) + (lineHexArray[5]));
//                 defaultEcuAddressing = 2;
//                 sectorDataIndex = 0;
//                 sectorStrtAddr[sectorIndex++] = lineStrtAddr;
//                 expectedStrtAddr = lineStrtAddrHS;
//               } else if (lineType == 0x01) {
//                 return returnStatus; // End of file
//               }
//             } else {
//               returnstatus = "CORRUPTEDHEXFILE";
//               return returnstatus;
//             }
//           }
//           break;

//         case "SREC":
//           {
//             final line = lineBytes.split('');

//             if (line[0] == 'S') {
//               final lineType = line[1];
//               final actualData = lineBytes.substring(2);
//               final lineHexArray = hexStringToByteArray(actualData);

//               final lineLen = lineHexArray[0];
//               int lineStrtAddrLocal = 0;

//               if (lineType == '1') {
//                 lineStrtAddrLocal = ((lineHexArray[1] << 8) + lineHexArray[2]);

//                 if (firstLine) {
//                   expectedStrtAddr = lineStrtAddrLocal;
//                   firstLine = false;
//                   sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
//                 }

//                 if (expectedStrtAddr != lineStrtAddrLocal) {
//                   sectorLen[sectorIndex] = sectorDataIndex;
//                   sectorDataIndex = 0;
//                   sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
//                 }

//                 for (int i = 0; i < lineLen - 3; i++) {
//                   inputFileDataArray[sectorIndex][sectorDataIndex + i] =
//                       lineHexArray[3 + i];
//                 }

//                 sectorDataIndex += (lineLen - 3);
//                 defaultEcuAddressing = 2;
//                 expectedStrtAddr = (lineStrtAddrLocal + lineLen - 3);
//               } else if (lineType == '2') {
//                 lineStrtAddrLocal = ((lineHexArray[1] << 16) +
//                     (lineHexArray[2] << 8) +
//                     lineHexArray[3]);

//                 if (firstLine) {
//                   expectedStrtAddr = lineStrtAddrLocal;
//                   firstLine = false;
//                   sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
//                 }

//                 if (expectedStrtAddr != lineStrtAddrLocal) {
//                   sectorLen[sectorIndex] = sectorDataIndex;
//                   sectorDataIndex = 0;
//                   sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
//                 }

//                 for (int i = 0; i < lineLen - 4; i++) {
//                   inputFileDataArray[sectorIndex][sectorDataIndex + i] =
//                       lineHexArray[4 + i];
//                 }

//                 sectorDataIndex += (lineLen - 4);
//                 defaultEcuAddressing = 3;
//                 expectedStrtAddr = (lineStrtAddrLocal + lineLen - 4);
//               } else if (lineType == '3') {
//                 lineStrtAddrLocal = ((lineHexArray[1] << 24) +
//                     (lineHexArray[2] << 16) +
//                     (lineHexArray[3] << 8) +
//                     lineHexArray[4]);

//                 if (firstLine) {
//                   expectedStrtAddr = lineStrtAddrLocal;
//                   firstLine = false;
//                   sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
//                 }

//                 if (expectedStrtAddr != lineStrtAddrLocal) {
//                   sectorLen[sectorIndex] = sectorDataIndex;
//                   sectorDataIndex = 0;
//                   sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
//                 }

//                 for (int i = 0; i < lineLen - 5; i++) {
//                   inputFileDataArray[sectorIndex][sectorDataIndex + i] =
//                       lineHexArray[5 + i];
//                 }

//                 sectorDataIndex += (lineLen - 5);
//                 defaultEcuAddressing = 4;
//                 expectedStrtAddr = (lineStrtAddrLocal + lineLen - 5);
//               }
//             } else {
//               returnstatus = "CORRUPTEDSRECFILE";
//               return returnstatus;
//             }
//           }
//           break;
//       }

//       return returnStatus;
//     } catch (e) {
//       return "ERROR";
//     }
//   }

//   void endFile() {
//     sectorLen[sectorIndex++] = sectorDataIndex;
//   }

//   // Future<String> createJSON(
//   //     List<EcuMapFile>? ecuMapFiles, String checksumAlgo) async {
//   //   String returnJson = '';

//   //   try {
//   //     int count = 0;
//   //     int i = 0;
//   //     jsonStartAddress = List.filled(20, 0);
//   //     jsonEndAddress = List.filled(20, 0);
//   //     ecuStartAddress = List.filled(20, 0);
//   //     ecuEndAddress = List.filled(20, 0);

//   //     if (ecuMapFiles != null && ecuMapFiles.isNotEmpty) {
//   //       count = ecuMapFiles.length;
//   //       ecuStartAddress = List.filled(count, 0);
//   //       ecuEndAddress = List.filled(count, 0);

//   //       for (var item in ecuMapFiles) {
//   //         ecuStartAddress![i] = item.startAddr!;
//   //         ecuEndAddress![i] = item.endAddr!;
//   //         i++;
//   //       }
//   //     } else {
//   //       for (i = 0; i < sectorLen.length; i++) {
//   //         if (i + 1 >= sectorLen.length || sectorLen[i + 1] == 0) {
//   //           count = i + 1;
//   //           break;
//   //         }
//   //       }

//   //       ecuStartAddress = List.filled(count, 0);
//   //       ecuEndAddress = List.filled(count, 0);

//   //       for (i = 0; i < count; i++) {
//   //         ecuStartAddress![i] = sectorStrtAddr[i];
//   //         ecuEndAddress![i] = sectorStrtAddr[i] + sectorLen[i];
//   //       }
//   //     }

//   //     if (filetype == "HEX") {
//   //       returnJson = await createJsonByEcuMemMap(
//   //           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
//   //     } else if (filetype == "SREC") {
//   //       returnJson = await srecCreateJsonByEcuMemMap(
//   //           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
//   //     }

//   //     return returnJson;
//   //   } catch (e) {
//   //     return returnJson;
//   //   }
//   // }

//   Future<String> createJSON(
//     List<EcuMapFile>? ecuMapFiles, String checksumAlgo) async {
//   String returnJson = '';

//   try {
//     int count = 0;
//     int i = 0;
//     jsonStartAddress = List.filled(20, 0);
//     jsonEndAddress = List.filled(20, 0);
//     ecuStartAddress = List.filled(20, 0);
//     ecuEndAddress = List.filled(20, 0);

//     if (ecuMapFiles != null && ecuMapFiles.isNotEmpty) {
//       print('✅ [Hex2JSON] Using ${ecuMapFiles.length} EcuMapFile entries from API');
//       count = ecuMapFiles.length;
//       ecuStartAddress = List.filled(count, 0);
//       ecuEndAddress = List.filled(count, 0);

//       for (var item in ecuMapFiles) {
//         ecuStartAddress![i] = item.startAddr!;
//         ecuEndAddress![i] = item.endAddr!;
//         print('✅ [Hex2JSON]   sector[$i] start=0x${item.startAddr?.toRadixString(16).toUpperCase()} '
//             'end=0x${item.endAddr?.toRadixString(16).toUpperCase()}');
//         i++;
//       }
//     } else {
//       // ⚠️ FALLBACK PATH — no EcuMapFile data from the API for this
//       // ECU/variant. Deriving sector addresses purely from what the
//       // firmware file itself embeds. This is NOT guaranteed to match the
//       // valid memory ranges the ECU will actually accept — those live in
//       // the sequence file's "EcuMapFile:<start_address,...>" declarations,
//       // which this fallback has no way to cross-check against.
//       print('⚠️ [Hex2JSON] No EcuMapFile data from API — falling back to '
//           'firmware-embedded addresses. This can produce an address the ECU '
//           'rejects with ECUERROR_REQUESTOUTOFRANGE if the firmware\'s own '
//           'address records don\'t match the sequence file\'s declared '
//           'valid ranges.');

//       for (i = 0; i < sectorLen.length; i++) {
//         if (i + 1 >= sectorLen.length || sectorLen[i + 1] == 0) {
//           count = i + 1;
//           break;
//         }
//       }

//       ecuStartAddress = List.filled(count, 0);
//       ecuEndAddress = List.filled(count, 0);

//       for (i = 0; i < count; i++) {
//         ecuStartAddress![i] = sectorStrtAddr[i];
//         ecuEndAddress![i] = sectorStrtAddr[i] + sectorLen[i];
//         print('⚠️ [Hex2JSON]   fallback sector[$i] start=0x${sectorStrtAddr[i].toRadixString(16).toUpperCase()} '
//             'end=0x${ecuEndAddress![i].toRadixString(16).toUpperCase()} '
//             '(from firmware file, NOT from API)');
//       }
//     }

//     if (filetype == "HEX") {
//       returnJson = await createJsonByEcuMemMap(
//           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
//     } else if (filetype == "SREC") {
//       returnJson = await srecCreateJsonByEcuMemMap(
//           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
//     }

//     return returnJson;
//   } catch (e) {
//     print('❌ [Hex2JSON] createJSON exception: $e');
//     return returnJson;
//   }
// }

//   Future<String> createJsonByEcuMemMap(
//     int ecuMemMapNumSectors,
//     List<int> ecuStartAddress,
//     List<int> ecuEndAddress,
//     String checksumAlgo,
//   ) async {
//     try {
//       List<FlashingMatrix> flashingMatrixCollection = [];
//       FlashingMatrixData flashingMatrixData = FlashingMatrixData();

//       int noOfJsonSectors = 0;

//       // 🔹 LOOP 1
//       for (int i = 0; i < ecuMemMapNumSectors; i++) {
//         for (int j = 0; j < sectorIndex; j++) {
//           String stringData = "";

//           if ((ecuStartAddress[i] >= sectorStrtAddr[j]) &&
//               ((sectorStrtAddr[j] + sectorLen[j]) > ecuStartAddress[i])) {
//             jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

//             jsonEndAddress![i] =
//                 _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

//             int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

//             int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

//             // ✅ Extract bytes safely
//             List<int> bytesCollection =
//                 inputFileDataArray[j].sublist(offset, offset + number);

//             stringData = byteArrayToString(bytesCollection);

//             int checksum = 0;
//             int checksum32 = 0;

//             if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
//               checksum = cr.computeChecksumBytesKTM(bytesCollection);
//             } else if (checksumAlgo == "JAMCRC32") {
//               checksum32 = cr.computeJamCRC(bytesCollection);
//             } else {
//               for (var b in bytesCollection) {
//                 checksum += b;
//               }
//             }

//             flashingMatrixCollection.add(FlashingMatrix(
//               jsonEndAddress:
//                   jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonStartAddress:
//                   jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonCheckSum: checksumAlgo == "JAMCRC32"
//                   ? checksum32.toRadixString(16)
//                   : checksum.toRadixString(16),
//               ecuMemMapStartAddress:
//                   ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
//               ecuMemMapEndAddress:
//                   ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
//               jsonData: stringData,
//             ));

//             noOfJsonSectors++;
//             break;
//           }
//         }

//         flashingMatrixData.noOfSectors = ecuMemMapNumSectors;
//         flashingMatrixData.sectorData = flashingMatrixCollection;
//       }

//       // 🔹 LOOP 2 (same logic, reversed condition)
//       for (int j = 0; j < sectorIndex; j++) {
//         for (int i = 0; i < ecuMemMapNumSectors; i++) {
//           String stringData = "";

//           if ((sectorStrtAddr[j] > ecuStartAddress[i]) &&
//               ((sectorStrtAddr[j] + sectorLen[j]) < ecuEndAddress[i])) {
//             jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

//             jsonEndAddress![i] =
//                 _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

//             int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

//             int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

//             List<int> bytesCollection =
//                 inputFileDataArray[j].sublist(offset, offset + number);

//             stringData = byteArrayToString(bytesCollection);

//             int checksum = 0;
//             int checksum32 = 0;

//             if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
//               checksum = cr.computeChecksumBytesKTM(bytesCollection);
//             } else if (checksumAlgo == "JAMCRC32") {
//               checksum32 = cr.computeJamCRC(bytesCollection);
//             } else {
//               for (var b in bytesCollection) {
//                 checksum += b;
//               }
//             }

//             flashingMatrixCollection.add(FlashingMatrix(
//               jsonEndAddress:
//                   jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonStartAddress:
//                   jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonCheckSum: checksumAlgo == "JAMCRC32"
//                   ? checksum32.toRadixString(16)
//                   : checksum.toRadixString(16),
//               ecuMemMapStartAddress:
//                   ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
//               ecuMemMapEndAddress:
//                   ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
//               jsonData: stringData,
//             ));

//             noOfJsonSectors++;
//             break;
//           }
//         }

//         flashingMatrixData.noOfSectors = ecuMemMapNumSectors;
//         flashingMatrixData.sectorData = flashingMatrixCollection;
//       }

//       // ✅ Final count
//       flashingMatrixData.noOfSectors = noOfJsonSectors;

//       // ✅ Convert to JSON
//       final jsonMatrix = jsonEncode(flashingMatrixData.toJson());

//       return jsonMatrix;
//     } catch (e) {
//       return "";
//     }
//   }

//   Future<String> srecCreateJsonByEcuMemMap(
//     int ecuMemMapNumSectors,
//     List<int> ecuStartAddress,
//     List<int> ecuEndAddress,
//     String checksumAlgo,
//   ) async {
//     try {
//       returnJson = [];

//       List<FlashingMatrix> flashingMatrixCollection = [];
//       SRECFlashingMatrixData srecFlashingMatrixData = SRECFlashingMatrixData();

//       int noOfJsonSectors = 0;

//       // 🔹 LOOP 1
//       for (int i = 0; i < ecuMemMapNumSectors; i++) {
//         for (int j = 0; j < sectorIndex; j++) {
//           String stringData = "";

//           if ((ecuStartAddress[i] >= sectorStrtAddr[j]) &&
//               ((sectorStrtAddr[j] + sectorLen[j]) > ecuStartAddress[i])) {
//             jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

//             jsonEndAddress![i] =
//                 _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

//             int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

//             int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

//             // ✅ SAFE extraction
//             List<int> bytesCollection =
//                 inputFileDataArray[j].sublist(offset, offset + number);

//             stringData = byteArrayToString(bytesCollection);

//             int checksum = 0;
//             int checksum32 = 0;

//             if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
//               checksum = cr.computeChecksumBytesKTM(bytesCollection);
//             } else if (checksumAlgo == "JAMCRC32") {
//               checksum32 = cr.computeJamCRC(bytesCollection);
//             } else {
//               for (var b in bytesCollection) {
//                 checksum += b;
//               }
//             }

//             flashingMatrixCollection.add(FlashingMatrix(
//               jsonEndAddress:
//                   jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonStartAddress:
//                   jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonCheckSum: checksumAlgo == "JAMCRC32"
//                   ? checksum32.toRadixString(16)
//                   : checksum.toRadixString(16),
//               ecuMemMapStartAddress:
//                   ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
//               ecuMemMapEndAddress:
//                   ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
//               jsonData: stringData,
//             ));

//             noOfJsonSectors++;
//             break;
//           }
//         }

//         srecFlashingMatrixData.noOfSectors = ecuMemMapNumSectors;
//         srecFlashingMatrixData.fileStartAddr =
//             fileStartAddr.toRadixString(16).padLeft(4, '0');
//         srecFlashingMatrixData.sectorData = flashingMatrixCollection;
//       }

//       // 🔹 LOOP 2
//       for (int j = 0; j < sectorIndex; j++) {
//         for (int i = 0; i < ecuMemMapNumSectors; i++) {
//           String stringData = "";

//           if ((sectorStrtAddr[j] > ecuStartAddress[i]) &&
//               ((sectorStrtAddr[j] + sectorLen[j]) < ecuEndAddress[i])) {
//             jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

//             jsonEndAddress![i] =
//                 _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

//             int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

//             int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

//             List<int> bytesCollection =
//                 inputFileDataArray[j].sublist(offset, offset + number);

//             stringData = byteArrayToString(bytesCollection);

//             int checksum = 0;
//             int checksum32 = 0;

//             if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
//               checksum = cr.computeChecksumBytesKTM(bytesCollection);
//             } else if (checksumAlgo == "JAMCRC32") {
//               checksum32 = cr.computeJamCRC(bytesCollection);
//             } else {
//               for (var b in bytesCollection) {
//                 checksum += b;
//               }
//             }

//             flashingMatrixCollection.add(FlashingMatrix(
//               jsonEndAddress:
//                   jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonStartAddress:
//                   jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
//               jsonCheckSum: checksumAlgo == "JAMCRC32"
//                   ? checksum32.toRadixString(16)
//                   : checksum.toRadixString(16),
//               ecuMemMapStartAddress:
//                   ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
//               ecuMemMapEndAddress:
//                   ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
//               jsonData: stringData,
//             ));

//             noOfJsonSectors++;
//             break;
//           }
//         }

//         srecFlashingMatrixData.noOfSectors = ecuMemMapNumSectors;
//         srecFlashingMatrixData.fileStartAddr =
//             fileStartAddr.toRadixString(16).padLeft(4, '0');
//         srecFlashingMatrixData.sectorData = flashingMatrixCollection;
//       }

//       // ✅ Final values
//       srecFlashingMatrixData.noOfSectors = noOfJsonSectors;
//       srecFlashingMatrixData.fileStartAddr =
//           fileStartAddr.toRadixString(16).padLeft(4, '0');

//       final jsonMatrix = jsonEncode(srecFlashingMatrixData.toJson());

//       return jsonMatrix;
//     } catch (e) {
//       return "";
//     }
//   }

//   String byteArrayToString(List<int> bytes) {
//     return bytes
//         .map((b) => b.toRadixString(16).padLeft(2, '0'))
//         .join()
//         .toUpperCase();
//   }

//   List<int> hexStringToByteArray(String hex) {
//     hex = hex.replaceAll(" ", "");

//     // If odd length, prepend 0
//     if (hex.length % 2 != 0) {
//       hex = "0$hex";
//     }

//     List<int> bytes = [];

//     for (int i = 0; i < hex.length; i += 2) {
//       String byteString = hex.substring(i, i + 2);
//       bytes.add(int.parse(byteString, radix: 16));
//     }

//     return bytes;
//   }

//   int _max(int a, int b) => a > b ? a : b;
//   int _min(int a, int b) => a < b ? a : b;
// }

// class ReturnJsonDataANDPath {
//   String? jsonPath;
//   String? jsonData;

//   ReturnJsonDataANDPath({this.jsonPath, this.jsonData});

//   // Optional: JSON serialization/deserialization
//   factory ReturnJsonDataANDPath.fromJson(Map<String, dynamic> json) {
//     return ReturnJsonDataANDPath(
//       jsonPath: json['JsonPath'] as String?,
//       jsonData: json['JsonData'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'JsonPath': jsonPath,
//       'JsonData': jsonData,
//     };
//   }
// }

// enum Crc16Mode { standard, ccittKermit }

// class Crc16 {
//   final List<int> table = List<int>.filled(256, 0);

//   Crc16(Crc16Mode mode) {
//     _initTable(mode);
//   }

//   void _initTable(Crc16Mode mode) {
//     const ushortMax = 0xFFFF;
//     for (int i = 0; i < 256; i++) {
//       int crc = i;
//       if (mode == Crc16Mode.standard) {
//         for (int j = 0; j < 8; j++) {
//           if ((crc & 1) != 0) {
//             crc = (crc >> 1) ^ 0xA001;
//           } else {
//             crc >>= 1;
//           }
//         }
//       } else if (mode == Crc16Mode.ccittKermit) {
//         for (int j = 0; j < 8; j++) {
//           if ((crc & 1) != 0) {
//             crc = (crc >> 1) ^ 0x8408;
//           } else {
//             crc >>= 1;
//           }
//         }
//       }
//       table[i] = crc & ushortMax;
//     }
//   }

//   int computeChecksum(List<int> bytes) {
//     int crc = 0;
//     for (var b in bytes) {
//       int index = (crc ^ b) & 0xFF;
//       crc = ((crc >> 8) ^ table[index]) & 0xFFFF;
//     }
//     return crc;
//   }

//   // int computeChecksumKTM(List<int> bytes) {
//   //   int crc = 0xFFFF;

//   //   // Example CRC table (replace with your actual crc_tabccitt values)
//   //   List<int> crcTabCcitt = List<int>.filled(256, 0);

//   //   for (int i = 0; i < bytes.length; i++) {
//   //     int byteVal = bytes[i] & 0xFF; // Ensure byte is 0-255
//   //     crc =
//   //         ((crc << 8) ^ crcTabCcitt[((crc >> 8) ^ byteVal) & 0xFFFF]) & 0xFFFF;
//   //   }

//   //   return crc;
//   // }

//   int computeChecksumKTM(List<int> bytes) {
//     int crc = 0xFFFF;

//     for (int i = 0; i < bytes.length; i++) {
//       int byteVal = bytes[i] & 0xFF;
//       crc = ((crc << 8) ^ crcTabCcitt[((crc >> 8) ^ byteVal) & 0xFFFF]) & 0xFFFF;
//     }

//     return crc;
// }

//   int computeJamCRC(List<int> data) {
//     int crc = 0xFFFFFFFF;
//     const int poly = 0xEDB88320; // reversed polynomial

//     for (int b in data) {
//       int temp = (crc ^ b) & 0xFF;

//       for (int i = 0; i < 8; i++) {
//         if ((temp & 1) != 0) {
//           temp = (temp >> 1) ^ poly;
//         } else {
//           temp >>= 1;
//         }
//       }

//       crc = (crc >> 8) ^ temp;
//     }

//     return crc; // No final XOR
//   }

//   int computeChecksumBytes(List<int> bytes) {
//     int crc = computeChecksum(bytes); // call your computeChecksum function
//     return crc & 0xFFFF; // ensure it's 16-bit like ushort
//   }

//   int computeChecksumBytesKTM(List<int> bytes) {
//     int crc =
//         computeChecksumKTM(bytes); // call your computeChecksumKTM function
//     return crc & 0xFFFF; // ensure 16-bit like ushort
//   }

//   // CCITT table
//   final List<int> crcTabCcitt = [
//     0x0000,
//     0x1021,
//     0x2042,
//     0x3063,
//     0x4084,
//     0x50A5,
//     0x60C6,
//     0x70E7,
//     0x8108,
//     0x9129,
//     0xA14A,
//     0xB16B,
//     0xC18C,
//     0xD1AD,
//     0xE1CE,
//     0xF1EF,
//     0x1231,
//     0x0210,
//     0x3273,
//     0x2252,
//     0x52B5,
//     0x4294,
//     0x72F7,
//     0x62D6,
//     0x9339,
//     0x8318,
//     0xB37B,
//     0xA35A,
//     0xD3BD,
//     0xC39C,
//     0xF3FF,
//     0xE3DE,
//     0x2462,
//     0x3443,
//     0x0420,
//     0x1401,
//     0x64E6,
//     0x74C7,
//     0x44A4,
//     0x5485,
//     0xA56A,
//     0xB54B,
//     0x8528,
//     0x9509,
//     0xE5EE,
//     0xF5CF,
//     0xC5AC,
//     0xD58D,
//     0x3653,
//     0x2672,
//     0x1611,
//     0x0630,
//     0x76D7,
//     0x66F6,
//     0x5695,
//     0x46B4,
//     0xB75B,
//     0xA77A,
//     0x9719,
//     0x8738,
//     0xF7DF,
//     0xE7FE,
//     0xD79D,
//     0xC7BC,
//     0x48C4,
//     0x58E5,
//     0x6886,
//     0x78A7,
//     0x0840,
//     0x1861,
//     0x2802,
//     0x3823,
//     0xC9CC,
//     0xD9ED,
//     0xE98E,
//     0xF9AF,
//     0x8948,
//     0x9969,
//     0xA90A,
//     0xB92B,
//     0x5AF5,
//     0x4AD4,
//     0x7AB7,
//     0x6A96,
//     0x1A71,
//     0x0A50,
//     0x3A33,
//     0x2A12,
//     0xDBFD,
//     0xCBDC,
//     0xFBBF,
//     0xEB9E,
//     0x9B79,
//     0x8B58,
//     0xBB3B,
//     0xAB1A,
//     0x6CA6,
//     0x7C87,
//     0x4CE4,
//     0x5CC5,
//     0x2C22,
//     0x3C03,
//     0x0C60,
//     0x1C41,
//     0xEDAE,
//     0xFD8F,
//     0xCDEC,
//     0xDDCD,
//     0xAD2A,
//     0xBD0B,
//     0x8D68,
//     0x9D49,
//     0x7E97,
//     0x6EB6,
//     0x5ED5,
//     0x4EF4,
//     0x3E13,
//     0x2E32,
//     0x1E51,
//     0x0E70,
//     0xFF9F,
//     0xEFBE,
//     0xDFDD,
//     0xCFFC,
//     0xBF1B,
//     0xAF3A,
//     0x9F59,
//     0x8F78,
//     0x9188,
//     0x81A9,
//     0xB1CA,
//     0xA1EB,
//     0xD10C,
//     0xC12D,
//     0xF14E,
//     0xE16F,
//     0x1080,
//     0x00A1,
//     0x30C2,
//     0x20E3,
//     0x5004,
//     0x4025,
//     0x7046,
//     0x6067,
//     0x83B9,
//     0x9398,
//     0xA3FB,
//     0xB3DA,
//     0xC33D,
//     0xD31C,
//     0xE37F,
//     0xF35E,
//     0x02B1,
//     0x1290,
//     0x22F3,
//     0x32D2,
//     0x4235,
//     0x5214,
//     0x6277,
//     0x7256,
//     0xB5EA,
//     0xA5CB,
//     0x95A8,
//     0x8589,
//     0xF56E,
//     0xE54F,
//     0xD52C,
//     0xC50D,
//     0x34E2,
//     0x24C3,
//     0x14A0,
//     0x0481,
//     0x7466,
//     0x6447,
//     0x5424,
//     0x4405,
//     0xA7DB,
//     0xB7FA,
//     0x8799,
//     0x97B8,
//     0xE75F,
//     0xF77E,
//     0xC71D,
//     0xD73C,
//     0x26D3,
//     0x36F2,
//     0x0691,
//     0x16B0,
//     0x6657,
//     0x7676,
//     0x4615,
//     0x5634,
//     0xD94C,
//     0xC96D,
//     0xF90E,
//     0xE92F,
//     0x99C8,
//     0x89E9,
//     0xB98A,
//     0xA9AB,
//     0x5844,
//     0x4865,
//     0x7806,
//     0x6827,
//     0x18C0,
//     0x08E1,
//     0x3882,
//     0x28A3,
//     0xCB7D,
//     0xDB5C,
//     0xEB3F,
//     0xFB1E,
//     0x8BF9,
//     0x9BD8,
//     0xABBB,
//     0xBB9A,
//     0x4A75,
//     0x5A54,
//     0x6A37,
//     0x7A16,
//     0x0AF1,
//     0x1AD0,
//     0x2AB3,
//     0x3A92,
//     0xFD2E,
//     0xED0F,
//     0xDD6C,
//     0xCD4D,
//     0xBDAA,
//     0xAD8B,
//     0x9DE8,
//     0x8DC9,
//     0x7C26,
//     0x6C07,
//     0x5C64,
//     0x4C45,
//     0x3CA2,
//     0x2C83,
//     0x1CE0,
//     0x0CC1,
//     0xEF1F,
//     0xFF3E,
//     0xCF5D,
//     0xDF7C,
//     0xAF9B,
//     0xBFBA,
//     0x8FD9,
//     0x9FF8,
//     0x6E17,
//     0x7E36,
//     0x4E55,
//     0x5E74,
//     0x2E93,
//     0x3EB2,
//     0x0ED1,
//     0x1EF0
//   ];
// }
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:simpson/modals/all.models.dart';
import 'package:simpson/modals/flashingMatrix_model.dart';
//import 'package:simpson/modals/flashingMatrix_model.dart';

/// Bundles convertToJson's 3 args into one object — compute() only
/// passes a single argument to its top-level function.
class HexToJsonArgs {
  final Uint8List streamBytes;
  final List<EcuMapFile> ecuMapFiles;
  final String checksumAlgo;

  HexToJsonArgs({
    required this.streamBytes,
    required this.ecuMapFiles,
    required this.checksumAlgo,
  });
}

/// Top-level (isolate-compatible) entry point for hex→JSON conversion.
/// PFS flashes multiple lanes' ECUs "in parallel," but each lane's hex
/// file can be several megabytes and this conversion is genuinely
/// CPU-bound — running it directly on the main isolate means every
/// lane's conversion serializes on the same single thread regardless
/// of how many lanes started flashing at once (the network/socket
/// side is truly parallel per-lane, but this step wasn't). Routing it
/// through `compute()` spawns a real background isolate per call, so
/// N lanes' conversions can actually run on N CPU cores at the same
/// time instead of queuing behind each other.
Future<String> convertHexToJsonIsolate(HexToJsonArgs args) {
  return GetJson().convertToJson(args.streamBytes, args.ecuMapFiles, args.checksumAlgo);
}

class GetJson {
  Future<String> convertToJson(
    Uint8List streamBytes,
    List<EcuMapFile> ecuMapFiles,
    String checksumAlgo,
  ) async {
    try {
      final hex2json = Hex2JSON();

      // Convert bytes → string → lines
      final content = utf8.decode(streamBytes);
      final lines = LineSplitter.split(content);

      int counter = 0;
      String data = "";

      for (final ln in lines) {
        counter++;

        if (ln.trim().isNotEmpty) {
          final input = hex2json.hex2json(ln); // returns String
          data = input;
        }
      }

      print("File has $counter lines.");
      print("APDATA = $data");

      hex2json.endFile();

      final flashJson = await hex2json.createJSON(ecuMapFiles, checksumAlgo);

      return flashJson;
    } catch (e) {
      return "";
    }
  }
}

class Hex2JSON {
  String filetype = "";
  String tag = "HEX2JSON";

  int expectedStrtAddr = 0;

  // Arrays → List<int>
  List<int> sectorStrtAddr = List.filled(40, 0);
  int sectorIndex = 0;

  int lineStrtAddr = 0;
  int lineStrtAddrHS = 0x00000000;

  bool firstLine = true;

  int defaultEcuAddressing = 4; // 4 byte addressing
  int sectorDataIndex = 0;
  int actualDataLength = 0;

  List<int> sectorLen = List.filled(20, 0);

  String returnStatus = "NOERROR";

  // 2D byte array → List<List<int>>
  List<List<int>> inputFileDataArray =
      List.generate(20, (_) => List.filled(2000 * 10000, 0));

  late Crc16 cr;

  int fileStartAddr = 0x00000000;

  String projectName = "";
  String returnstatus = "";

  List<ReturnJsonDataANDPath> returnJson = [];

  List<int>? ecuStartAddress;
  List<int>? ecuEndAddress;
  List<int>? ecuMemMapNumSectors;

  List<int>? jsonStartAddress;
  List<int>? jsonEndAddress;

  // ✅ Constructor
  Hex2JSON() {
    cr = Crc16(Crc16Mode.ccittKermit);
  }

  String hex2json(String lineBytes) {
    try {
      final firstChar = lineBytes[0];

      // Detect file type
      if (firstChar == 'S') {
        filetype = "SREC";
      } else if (firstChar == ':') {
        filetype = "HEX";
      } else {
        return "INVALIDFILETYPE";
      }

      switch (filetype) {
        case "HEX":
          {
            final line = lineBytes.split('');
            final actualData = lineBytes.replaceFirst(':', '');
            final hxArray = hexStringToByteArray(actualData);

            if (line[0] == ':') {
              final lineHexArray = hxArray;

              final lineLen = lineHexArray[0];
              final lineType = lineHexArray[3];

              if (lineType == 0x00) {
                // DATA LINE
                lineStrtAddr = (lineStrtAddrHS +
                    ((lineHexArray[1] << 8) + lineHexArray[2]));

                if (firstLine) {
                  expectedStrtAddr = lineStrtAddr;
                  firstLine = false;
                  sectorStrtAddr[sectorIndex] = lineStrtAddr;
                }

                if (expectedStrtAddr != lineStrtAddr) {
                  sectorLen[sectorIndex] = sectorDataIndex;
                  sectorDataIndex = 0;
                  sectorStrtAddr[++sectorIndex] = lineStrtAddr;
                }

                for (int i = 0; i < lineLen; i++) {
                  try {
                    inputFileDataArray[sectorIndex][sectorDataIndex + i] =
                        lineHexArray[4 + i];
                  } catch (_) {}
                }

                sectorDataIndex += lineLen;
                expectedStrtAddr = (lineStrtAddr + lineLen);
              } else if (lineType == 0x04) {
                // 4-byte addressing
                lineStrtAddrHS =
                    ((lineHexArray[4] << 24) + (lineHexArray[5] << 16));
                defaultEcuAddressing = 4;
              } else if (lineType == 0x03) {
                lineStrtAddrHS = ((lineHexArray[5] << 16) +
                    (lineHexArray[6] << 8) +
                    lineHexArray[7]);
                defaultEcuAddressing = 3;
                sectorDataIndex = 0;
                sectorStrtAddr[sectorIndex++] = lineStrtAddr;
                expectedStrtAddr = lineStrtAddrHS;
              } else if (lineType == 0x02) {
                lineStrtAddrHS = ((lineHexArray[4] << 8) + (lineHexArray[5]));
                defaultEcuAddressing = 2;
                sectorDataIndex = 0;
                sectorStrtAddr[sectorIndex++] = lineStrtAddr;
                expectedStrtAddr = lineStrtAddrHS;
              } else if (lineType == 0x01) {
                return returnStatus; // End of file
              }
            } else {
              returnstatus = "CORRUPTEDHEXFILE";
              return returnstatus;
            }
          }
          break;

        case "SREC":
          {
            final line = lineBytes.split('');

            if (line[0] == 'S') {
              final lineType = line[1];
              final actualData = lineBytes.substring(2);
              final lineHexArray = hexStringToByteArray(actualData);

              final lineLen = lineHexArray[0];
              int lineStrtAddrLocal = 0;

              if (lineType == '1') {
                lineStrtAddrLocal = ((lineHexArray[1] << 8) + lineHexArray[2]);

                if (firstLine) {
                  expectedStrtAddr = lineStrtAddrLocal;
                  firstLine = false;
                  sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
                }

                if (expectedStrtAddr != lineStrtAddrLocal) {
                  sectorLen[sectorIndex] = sectorDataIndex;
                  sectorDataIndex = 0;
                  sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
                }

                for (int i = 0; i < lineLen - 3; i++) {
                  inputFileDataArray[sectorIndex][sectorDataIndex + i] =
                      lineHexArray[3 + i];
                }

                sectorDataIndex += (lineLen - 3);
                defaultEcuAddressing = 2;
                expectedStrtAddr = (lineStrtAddrLocal + lineLen - 3);
              } else if (lineType == '2') {
                lineStrtAddrLocal = ((lineHexArray[1] << 16) +
                    (lineHexArray[2] << 8) +
                    lineHexArray[3]);

                if (firstLine) {
                  expectedStrtAddr = lineStrtAddrLocal;
                  firstLine = false;
                  sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
                }

                if (expectedStrtAddr != lineStrtAddrLocal) {
                  sectorLen[sectorIndex] = sectorDataIndex;
                  sectorDataIndex = 0;
                  sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
                }

                for (int i = 0; i < lineLen - 4; i++) {
                  inputFileDataArray[sectorIndex][sectorDataIndex + i] =
                      lineHexArray[4 + i];
                }

                sectorDataIndex += (lineLen - 4);
                defaultEcuAddressing = 3;
                expectedStrtAddr = (lineStrtAddrLocal + lineLen - 4);
              } else if (lineType == '3') {
                lineStrtAddrLocal = ((lineHexArray[1] << 24) +
                    (lineHexArray[2] << 16) +
                    (lineHexArray[3] << 8) +
                    lineHexArray[4]);

                if (firstLine) {
                  expectedStrtAddr = lineStrtAddrLocal;
                  firstLine = false;
                  sectorStrtAddr[sectorIndex] = lineStrtAddrLocal;
                }

                if (expectedStrtAddr != lineStrtAddrLocal) {
                  sectorLen[sectorIndex] = sectorDataIndex;
                  sectorDataIndex = 0;
                  sectorStrtAddr[++sectorIndex] = lineStrtAddrLocal;
                }

                for (int i = 0; i < lineLen - 5; i++) {
                  inputFileDataArray[sectorIndex][sectorDataIndex + i] =
                      lineHexArray[5 + i];
                }

                sectorDataIndex += (lineLen - 5);
                defaultEcuAddressing = 4;
                expectedStrtAddr = (lineStrtAddrLocal + lineLen - 5);
              }
            } else {
              returnstatus = "CORRUPTEDSRECFILE";
              return returnstatus;
            }
          }
          break;
      }

      return returnStatus;
    } catch (e) {
      return "ERROR";
    }
  }

  void endFile() {
    sectorLen[sectorIndex++] = sectorDataIndex;
  }

  // Future<String> createJSON(
  //     List<EcuMapFile>? ecuMapFiles, String checksumAlgo) async {
  //   String returnJson = '';

  //   try {
  //     int count = 0;
  //     int i = 0;
  //     jsonStartAddress = List.filled(20, 0);
  //     jsonEndAddress = List.filled(20, 0);
  //     ecuStartAddress = List.filled(20, 0);
  //     ecuEndAddress = List.filled(20, 0);

  //     if (ecuMapFiles != null && ecuMapFiles.isNotEmpty) {
  //       count = ecuMapFiles.length;
  //       ecuStartAddress = List.filled(count, 0);
  //       ecuEndAddress = List.filled(count, 0);

  //       for (var item in ecuMapFiles) {
  //         ecuStartAddress![i] = item.startAddr!;
  //         ecuEndAddress![i] = item.endAddr!;
  //         i++;
  //       }
  //     } else {
  //       for (i = 0; i < sectorLen.length; i++) {
  //         if (i + 1 >= sectorLen.length || sectorLen[i + 1] == 0) {
  //           count = i + 1;
  //           break;
  //         }
  //       }

  //       ecuStartAddress = List.filled(count, 0);
  //       ecuEndAddress = List.filled(count, 0);

  //       for (i = 0; i < count; i++) {
  //         ecuStartAddress![i] = sectorStrtAddr[i];
  //         ecuEndAddress![i] = sectorStrtAddr[i] + sectorLen[i];
  //       }
  //     }

  //     if (filetype == "HEX") {
  //       returnJson = await createJsonByEcuMemMap(
  //           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
  //     } else if (filetype == "SREC") {
  //       returnJson = await srecCreateJsonByEcuMemMap(
  //           count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
  //     }

  //     return returnJson;
  //   } catch (e) {
  //     return returnJson;
  //   }
  // }

  Future<String> createJSON(
    List<EcuMapFile>? ecuMapFiles, String checksumAlgo) async {
  String returnJson = '';

  try {
    int count = 0;
    int i = 0;
    jsonStartAddress = List.filled(20, 0);
    jsonEndAddress = List.filled(20, 0);
    ecuStartAddress = List.filled(20, 0);
    ecuEndAddress = List.filled(20, 0);

    if (ecuMapFiles != null && ecuMapFiles.isNotEmpty) {
      print('✅ [Hex2JSON] Using ${ecuMapFiles.length} EcuMapFile entries from API');
      count = ecuMapFiles.length;
      ecuStartAddress = List.filled(count, 0);
      ecuEndAddress = List.filled(count, 0);

      for (var item in ecuMapFiles) {
        ecuStartAddress![i] = item.startAddr!;
        ecuEndAddress![i] = item.endAddr!;
        print('✅ [Hex2JSON]   sector[$i] start=0x${item.startAddr?.toRadixString(16).toUpperCase()} '
            'end=0x${item.endAddr?.toRadixString(16).toUpperCase()}');
        i++;
      }
    } else {
      // ⚠️ FALLBACK PATH — no EcuMapFile data from the API for this
      // ECU/variant. Deriving sector addresses purely from what the
      // firmware file itself embeds. This is NOT guaranteed to match the
      // valid memory ranges the ECU will actually accept — those live in
      // the sequence file's "EcuMapFile:<start_address,...>" declarations,
      // which this fallback has no way to cross-check against.
      print('⚠️ [Hex2JSON] No EcuMapFile data from API — falling back to '
          'firmware-embedded addresses. This can produce an address the ECU '
          'rejects with ECUERROR_REQUESTOUTOFRANGE if the firmware\'s own '
          'address records don\'t match the sequence file\'s declared '
          'valid ranges.');

      for (i = 0; i < sectorLen.length; i++) {
        if (i + 1 >= sectorLen.length || sectorLen[i + 1] == 0) {
          count = i + 1;
          break;
        }
      }

      ecuStartAddress = List.filled(count, 0);
      ecuEndAddress = List.filled(count, 0);

      for (i = 0; i < count; i++) {
        ecuStartAddress![i] = sectorStrtAddr[i];
        ecuEndAddress![i] = sectorStrtAddr[i] + sectorLen[i];
        print('⚠️ [Hex2JSON]   fallback sector[$i] start=0x${sectorStrtAddr[i].toRadixString(16).toUpperCase()} '
            'end=0x${ecuEndAddress![i].toRadixString(16).toUpperCase()} '
            '(from firmware file, NOT from API)');
      }
    }

    if (filetype == "HEX") {
      returnJson = await createJsonByEcuMemMap(
          count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
    } else if (filetype == "SREC") {
      returnJson = await srecCreateJsonByEcuMemMap(
          count, ecuStartAddress!, ecuEndAddress!, checksumAlgo);
    }

    return returnJson;
  } catch (e) {
    print('❌ [Hex2JSON] createJSON exception: $e');
    return returnJson;
  }
}

  Future<String> createJsonByEcuMemMap(
    int ecuMemMapNumSectors,
    List<int> ecuStartAddress,
    List<int> ecuEndAddress,
    String checksumAlgo,
  ) async {
    try {
      List<FlashingMatrix> flashingMatrixCollection = [];
      FlashingMatrixData flashingMatrixData = FlashingMatrixData();

      int noOfJsonSectors = 0;

      // 🔹 LOOP 1
      for (int i = 0; i < ecuMemMapNumSectors; i++) {
        for (int j = 0; j < sectorIndex; j++) {
          String stringData = "";

          if ((ecuStartAddress[i] >= sectorStrtAddr[j]) &&
              ((sectorStrtAddr[j] + sectorLen[j]) > ecuStartAddress[i])) {
            jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

            jsonEndAddress![i] =
                _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

            int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

            int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

            // ✅ Extract bytes safely
            List<int> bytesCollection =
                inputFileDataArray[j].sublist(offset, offset + number);

            stringData = byteArrayToString(bytesCollection);

            int checksum = 0;
            int checksum32 = 0;

            if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
              checksum = cr.computeChecksumBytesKTM(bytesCollection);
            } else if (checksumAlgo == "JAMCRC32") {
              checksum32 = cr.computeJamCRC(bytesCollection);
            } else {
              for (var b in bytesCollection) {
                checksum += b;
              }
            }

            flashingMatrixCollection.add(FlashingMatrix(
              jsonEndAddress:
                  jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonStartAddress:
                  jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonCheckSum: checksumAlgo == "JAMCRC32"
                  ? checksum32.toRadixString(16)
                  : checksum.toRadixString(16),
              ecuMemMapStartAddress:
                  ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
              ecuMemMapEndAddress:
                  ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
              jsonData: stringData,
            ));

            noOfJsonSectors++;
            break;
          }
        }

        flashingMatrixData.noOfSectors = ecuMemMapNumSectors;
        flashingMatrixData.sectorData = flashingMatrixCollection;
      }

      // 🔹 LOOP 2 (same logic, reversed condition)
      for (int j = 0; j < sectorIndex; j++) {
        for (int i = 0; i < ecuMemMapNumSectors; i++) {
          String stringData = "";

          if ((sectorStrtAddr[j] > ecuStartAddress[i]) &&
              ((sectorStrtAddr[j] + sectorLen[j]) < ecuEndAddress[i])) {
            jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

            jsonEndAddress![i] =
                _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

            int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

            int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

            List<int> bytesCollection =
                inputFileDataArray[j].sublist(offset, offset + number);

            stringData = byteArrayToString(bytesCollection);

            int checksum = 0;
            int checksum32 = 0;

            if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
              checksum = cr.computeChecksumBytesKTM(bytesCollection);
            } else if (checksumAlgo == "JAMCRC32") {
              checksum32 = cr.computeJamCRC(bytesCollection);
            } else {
              for (var b in bytesCollection) {
                checksum += b;
              }
            }

            flashingMatrixCollection.add(FlashingMatrix(
              jsonEndAddress:
                  jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonStartAddress:
                  jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonCheckSum: checksumAlgo == "JAMCRC32"
                  ? checksum32.toRadixString(16)
                  : checksum.toRadixString(16),
              ecuMemMapStartAddress:
                  ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
              ecuMemMapEndAddress:
                  ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
              jsonData: stringData,
            ));

            noOfJsonSectors++;
            break;
          }
        }

        flashingMatrixData.noOfSectors = ecuMemMapNumSectors;
        flashingMatrixData.sectorData = flashingMatrixCollection;
      }

      // ✅ Final count
      flashingMatrixData.noOfSectors = noOfJsonSectors;

      // ✅ Convert to JSON
      final jsonMatrix = jsonEncode(flashingMatrixData.toJson());

      return jsonMatrix;
    } catch (e) {
      return "";
    }
  }

  Future<String> srecCreateJsonByEcuMemMap(
    int ecuMemMapNumSectors,
    List<int> ecuStartAddress,
    List<int> ecuEndAddress,
    String checksumAlgo,
  ) async {
    try {
      returnJson = [];

      List<FlashingMatrix> flashingMatrixCollection = [];
      SRECFlashingMatrixData srecFlashingMatrixData = SRECFlashingMatrixData();

      int noOfJsonSectors = 0;

      // 🔹 LOOP 1
      for (int i = 0; i < ecuMemMapNumSectors; i++) {
        for (int j = 0; j < sectorIndex; j++) {
          String stringData = "";

          if ((ecuStartAddress[i] >= sectorStrtAddr[j]) &&
              ((sectorStrtAddr[j] + sectorLen[j]) > ecuStartAddress[i])) {
            jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

            jsonEndAddress![i] =
                _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

            int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

            int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

            // ✅ SAFE extraction
            List<int> bytesCollection =
                inputFileDataArray[j].sublist(offset, offset + number);

            stringData = byteArrayToString(bytesCollection);

            int checksum = 0;
            int checksum32 = 0;

            if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
              checksum = cr.computeChecksumBytesKTM(bytesCollection);
            } else if (checksumAlgo == "JAMCRC32") {
              checksum32 = cr.computeJamCRC(bytesCollection);
            } else {
              for (var b in bytesCollection) {
                checksum += b;
              }
            }

            flashingMatrixCollection.add(FlashingMatrix(
              jsonEndAddress:
                  jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonStartAddress:
                  jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonCheckSum: checksumAlgo == "JAMCRC32"
                  ? checksum32.toRadixString(16)
                  : checksum.toRadixString(16),
              ecuMemMapStartAddress:
                  ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
              ecuMemMapEndAddress:
                  ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
              jsonData: stringData,
            ));

            noOfJsonSectors++;
            break;
          }
        }

        srecFlashingMatrixData.noOfSectors = ecuMemMapNumSectors;
        srecFlashingMatrixData.fileStartAddr =
            fileStartAddr.toRadixString(16).padLeft(4, '0');
        srecFlashingMatrixData.sectorData = flashingMatrixCollection;
      }

      // 🔹 LOOP 2
      for (int j = 0; j < sectorIndex; j++) {
        for (int i = 0; i < ecuMemMapNumSectors; i++) {
          String stringData = "";

          if ((sectorStrtAddr[j] > ecuStartAddress[i]) &&
              ((sectorStrtAddr[j] + sectorLen[j]) < ecuEndAddress[i])) {
            jsonStartAddress![i] = _max(ecuStartAddress[i], sectorStrtAddr[j]);

            jsonEndAddress![i] =
                _min(ecuEndAddress[i], (sectorStrtAddr[j] + sectorLen[j] - 1));

            int number = (jsonEndAddress![i] - jsonStartAddress![i] + 1);

            int offset = (jsonStartAddress![i] - sectorStrtAddr[j]);

            List<int> bytesCollection =
                inputFileDataArray[j].sublist(offset, offset + number);

            stringData = byteArrayToString(bytesCollection);

            int checksum = 0;
            int checksum32 = 0;

            if (checksumAlgo == "CCITT" || checksumAlgo == "KTM") {
              checksum = cr.computeChecksumBytesKTM(bytesCollection);
            } else if (checksumAlgo == "JAMCRC32") {
              checksum32 = cr.computeJamCRC(bytesCollection);
            } else {
              for (var b in bytesCollection) {
                checksum += b;
              }
            }

            flashingMatrixCollection.add(FlashingMatrix(
              jsonEndAddress:
                  jsonEndAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonStartAddress:
                  jsonStartAddress![i].toRadixString(16).padLeft(4, '0'),
              jsonCheckSum: checksumAlgo == "JAMCRC32"
                  ? checksum32.toRadixString(16)
                  : checksum.toRadixString(16),
              ecuMemMapStartAddress:
                  ecuStartAddress[i].toRadixString(16).padLeft(4, '0'),
              ecuMemMapEndAddress:
                  ecuEndAddress[i].toRadixString(16).padLeft(4, '0'),
              jsonData: stringData,
            ));

            noOfJsonSectors++;
            break;
          }
        }

        srecFlashingMatrixData.noOfSectors = ecuMemMapNumSectors;
        srecFlashingMatrixData.fileStartAddr =
            fileStartAddr.toRadixString(16).padLeft(4, '0');
        srecFlashingMatrixData.sectorData = flashingMatrixCollection;
      }

      // ✅ Final values
      srecFlashingMatrixData.noOfSectors = noOfJsonSectors;
      srecFlashingMatrixData.fileStartAddr =
          fileStartAddr.toRadixString(16).padLeft(4, '0');

      final jsonMatrix = jsonEncode(srecFlashingMatrixData.toJson());

      return jsonMatrix;
    } catch (e) {
      return "";
    }
  }

  String byteArrayToString(List<int> bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  List<int> hexStringToByteArray(String hex) {
    hex = hex.replaceAll(" ", "");

    // If odd length, prepend 0
    if (hex.length % 2 != 0) {
      hex = "0$hex";
    }

    List<int> bytes = [];

    for (int i = 0; i < hex.length; i += 2) {
      String byteString = hex.substring(i, i + 2);
      bytes.add(int.parse(byteString, radix: 16));
    }

    return bytes;
  }

  int _max(int a, int b) => a > b ? a : b;
  int _min(int a, int b) => a < b ? a : b;
}

class ReturnJsonDataANDPath {
  String? jsonPath;
  String? jsonData;

  ReturnJsonDataANDPath({this.jsonPath, this.jsonData});

  // Optional: JSON serialization/deserialization
  factory ReturnJsonDataANDPath.fromJson(Map<String, dynamic> json) {
    return ReturnJsonDataANDPath(
      jsonPath: json['JsonPath'] as String?,
      jsonData: json['JsonData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'JsonPath': jsonPath,
      'JsonData': jsonData,
    };
  }
}

enum Crc16Mode { standard, ccittKermit }

class Crc16 {
  final List<int> table = List<int>.filled(256, 0);

  Crc16(Crc16Mode mode) {
    _initTable(mode);
  }

  void _initTable(Crc16Mode mode) {
    const ushortMax = 0xFFFF;
    for (int i = 0; i < 256; i++) {
      int crc = i;
      if (mode == Crc16Mode.standard) {
        for (int j = 0; j < 8; j++) {
          if ((crc & 1) != 0) {
            crc = (crc >> 1) ^ 0xA001;
          } else {
            crc >>= 1;
          }
        }
      } else if (mode == Crc16Mode.ccittKermit) {
        for (int j = 0; j < 8; j++) {
          if ((crc & 1) != 0) {
            crc = (crc >> 1) ^ 0x8408;
          } else {
            crc >>= 1;
          }
        }
      }
      table[i] = crc & ushortMax;
    }
  }

  int computeChecksum(List<int> bytes) {
    int crc = 0;
    for (var b in bytes) {
      int index = (crc ^ b) & 0xFF;
      crc = ((crc >> 8) ^ table[index]) & 0xFFFF;
    }
    return crc;
  }

  int computeChecksumKTM(List<int> bytes) {
    int crc = 0xFFFF;

    // Example CRC table (replace with your actual crc_tabccitt values)
    List<int> crcTabCcitt = List<int>.filled(256, 0);

    for (int i = 0; i < bytes.length; i++) {
      int byteVal = bytes[i] & 0xFF; // Ensure byte is 0-255
      crc =
          ((crc << 8) ^ crcTabCcitt[((crc >> 8) ^ byteVal) & 0xFFFF]) & 0xFFFF;
    }

    return crc;
  }

  int computeJamCRC(List<int> data) {
    int crc = 0xFFFFFFFF;
    const int poly = 0xEDB88320; // reversed polynomial

    for (int b in data) {
      int temp = (crc ^ b) & 0xFF;

      for (int i = 0; i < 8; i++) {
        if ((temp & 1) != 0) {
          temp = (temp >> 1) ^ poly;
        } else {
          temp >>= 1;
        }
      }

      crc = (crc >> 8) ^ temp;
    }

    return crc; // No final XOR
  }

  int computeChecksumBytes(List<int> bytes) {
    int crc = computeChecksum(bytes); // call your computeChecksum function
    return crc & 0xFFFF; // ensure it's 16-bit like ushort
  }

  int computeChecksumBytesKTM(List<int> bytes) {
    int crc =
        computeChecksumKTM(bytes); // call your computeChecksumKTM function
    return crc & 0xFFFF; // ensure 16-bit like ushort
  }

  // CCITT table
  final List<int> crcTabCcitt = [
    0x0000,
    0x1021,
    0x2042,
    0x3063,
    0x4084,
    0x50A5,
    0x60C6,
    0x70E7,
    0x8108,
    0x9129,
    0xA14A,
    0xB16B,
    0xC18C,
    0xD1AD,
    0xE1CE,
    0xF1EF,
    0x1231,
    0x0210,
    0x3273,
    0x2252,
    0x52B5,
    0x4294,
    0x72F7,
    0x62D6,
    0x9339,
    0x8318,
    0xB37B,
    0xA35A,
    0xD3BD,
    0xC39C,
    0xF3FF,
    0xE3DE,
    0x2462,
    0x3443,
    0x0420,
    0x1401,
    0x64E6,
    0x74C7,
    0x44A4,
    0x5485,
    0xA56A,
    0xB54B,
    0x8528,
    0x9509,
    0xE5EE,
    0xF5CF,
    0xC5AC,
    0xD58D,
    0x3653,
    0x2672,
    0x1611,
    0x0630,
    0x76D7,
    0x66F6,
    0x5695,
    0x46B4,
    0xB75B,
    0xA77A,
    0x9719,
    0x8738,
    0xF7DF,
    0xE7FE,
    0xD79D,
    0xC7BC,
    0x48C4,
    0x58E5,
    0x6886,
    0x78A7,
    0x0840,
    0x1861,
    0x2802,
    0x3823,
    0xC9CC,
    0xD9ED,
    0xE98E,
    0xF9AF,
    0x8948,
    0x9969,
    0xA90A,
    0xB92B,
    0x5AF5,
    0x4AD4,
    0x7AB7,
    0x6A96,
    0x1A71,
    0x0A50,
    0x3A33,
    0x2A12,
    0xDBFD,
    0xCBDC,
    0xFBBF,
    0xEB9E,
    0x9B79,
    0x8B58,
    0xBB3B,
    0xAB1A,
    0x6CA6,
    0x7C87,
    0x4CE4,
    0x5CC5,
    0x2C22,
    0x3C03,
    0x0C60,
    0x1C41,
    0xEDAE,
    0xFD8F,
    0xCDEC,
    0xDDCD,
    0xAD2A,
    0xBD0B,
    0x8D68,
    0x9D49,
    0x7E97,
    0x6EB6,
    0x5ED5,
    0x4EF4,
    0x3E13,
    0x2E32,
    0x1E51,
    0x0E70,
    0xFF9F,
    0xEFBE,
    0xDFDD,
    0xCFFC,
    0xBF1B,
    0xAF3A,
    0x9F59,
    0x8F78,
    0x9188,
    0x81A9,
    0xB1CA,
    0xA1EB,
    0xD10C,
    0xC12D,
    0xF14E,
    0xE16F,
    0x1080,
    0x00A1,
    0x30C2,
    0x20E3,
    0x5004,
    0x4025,
    0x7046,
    0x6067,
    0x83B9,
    0x9398,
    0xA3FB,
    0xB3DA,
    0xC33D,
    0xD31C,
    0xE37F,
    0xF35E,
    0x02B1,
    0x1290,
    0x22F3,
    0x32D2,
    0x4235,
    0x5214,
    0x6277,
    0x7256,
    0xB5EA,
    0xA5CB,
    0x95A8,
    0x8589,
    0xF56E,
    0xE54F,
    0xD52C,
    0xC50D,
    0x34E2,
    0x24C3,
    0x14A0,
    0x0481,
    0x7466,
    0x6447,
    0x5424,
    0x4405,
    0xA7DB,
    0xB7FA,
    0x8799,
    0x97B8,
    0xE75F,
    0xF77E,
    0xC71D,
    0xD73C,
    0x26D3,
    0x36F2,
    0x0691,
    0x16B0,
    0x6657,
    0x7676,
    0x4615,
    0x5634,
    0xD94C,
    0xC96D,
    0xF90E,
    0xE92F,
    0x99C8,
    0x89E9,
    0xB98A,
    0xA9AB,
    0x5844,
    0x4865,
    0x7806,
    0x6827,
    0x18C0,
    0x08E1,
    0x3882,
    0x28A3,
    0xCB7D,
    0xDB5C,
    0xEB3F,
    0xFB1E,
    0x8BF9,
    0x9BD8,
    0xABBB,
    0xBB9A,
    0x4A75,
    0x5A54,
    0x6A37,
    0x7A16,
    0x0AF1,
    0x1AD0,
    0x2AB3,
    0x3A92,
    0xFD2E,
    0xED0F,
    0xDD6C,
    0xCD4D,
    0xBDAA,
    0xAD8B,
    0x9DE8,
    0x8DC9,
    0x7C26,
    0x6C07,
    0x5C64,
    0x4C45,
    0x3CA2,
    0x2C83,
    0x1CE0,
    0x0CC1,
    0xEF1F,
    0xFF3E,
    0xCF5D,
    0xDF7C,
    0xAF9B,
    0xBFBA,
    0x8FD9,
    0x9FF8,
    0x6E17,
    0x7E36,
    0x4E55,
    0x5E74,
    0x2E93,
    0x3EB2,
    0x0ED1,
    0x1EF0
  ];
}
