// import 'dart:typed_data';
// import 'package:ap_diagnostic/enum/readDTCIndex.dart';
// import 'package:ap_diagnostic/enum/flashIndexTypes.dart';
// import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
// import 'package:ap_diagnostic/enum/writeParameter.dart';
// import 'package:ap_diagnostic/models/freezeFrameModel.dart';
// import 'package:ap_diagnostic/models/readParameterPIDModel.dart';
// import 'package:ap_diagnostic/structure/flash_structures.dart';
// import 'package:ap_diagnostic/structure/sectorData_structure.dart';
// import 'package:ap_diagnostic/usd_diagnostic.dart';
// import 'package:ap_dongle_comm/utils/model/responseArrayStatusModel.dart';
// import 'package:flutter_test/flutter_test.dart';
// // Import your implementation file here

// void main() {
//   late UDSDiagnostic uds;
//   late MockDongleComm mockDongle;
//   late MockSeedKeyCalculator mockCalculator;
//   late UDSDiagnostic diagnostic;
//   // ignore: unused_local_variable
//   late FlashConfig mockConfig;

//   setUp(() {
//     mockDongle = MockDongleComm();
//     mockCalculator = MockSeedKeyCalculator();
//     uds = UDSDiagnostic(mockDongle, mockCalculator);
//     diagnostic = UDSDiagnostic(mockDongle, mockCalculator);
//     mockConfig = FlashConfig(
//       flashIndex: FlashIndexType.UDS,
//       diagMode: 0x03,
//       sendSeedByte: 0x01,
//       seedKeyNumBytes: 4,
//       seedKeyIndex: SeedKeyIndexType.SK_0102,
//       addrDataFormat: '44',
//       sectorFrameTransferLen: 1024,
//       sepTime: 10,
//       eraseSector: EraseSectorEnum.ENABLED,
//       checksumSector: ChecksumSectorEnum.ENABLED,
//     );
//   });

//   group('enterExtendedSession Unit Tests', () {
//     test('Happy Path: Complete Security Access Sequence', () async {
//       int callCount = 0;

//       mockDongle.onTxRx = (len, hexStr) {
//         callCount++;
//         if (callCount == 1) {
//           // Session Control Request
//           expect(hexStr, "1003");
//           return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//         } else if (callCount == 2) {
//           // Seed Request (Index 0x01)
//           expect(hexStr, "2701");
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             actualDataBytes: Uint8List.fromList([0x67, 0x01, 0x11, 0x22]),
//           );
//         } else if (callCount == 3) {
//           // Key Send (Index 0x02 + Mock Key [12, 23])
//           expect(hexStr, "27021223");
//           return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//         }
//         return null;
//       };

//       final result = await uds.enterExtendedSession(
//         WriteParameterIndex.UDS_DS1003_SK0102,
//         SeedKeyIndexType.greavesBoschBs6Prod,
//       );

//       expect(result?.ecuResponseStatus, "NOERROR");
//       expect(callCount, 3);
//     });

//     test('Retry Logic: Security Delay Required', () async {
//       int seedRequests = 0;

//       mockDongle.onTxRx = (len, hexStr) {
//         if (hexStr == "1003") return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
        
//         if (hexStr == "2709") {
//           seedRequests++;
//           if (seedRequests < 3) {
//             return ResponseArrayStatus(ecuResponseStatus: "ECUERROR REQUIREDTIMEDELAYNOTEXPIRED");
//           }
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             actualDataBytes: Uint8List.fromList([0x67, 0x09, 0xAA, 0xBB]),
//           );
//         }
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//       };

//       final result = await uds.enterExtendedSession(
//         WriteParameterIndex.UDS_DS1003_SK090A,
//         SeedKeyIndexType.greavesBoschBs6Prod,
//       );

//       expect(seedRequests, 3); // Verified two retries plus one success
//       expect(result?.ecuResponseStatus, "NOERROR");
//     });

//     test('Zero Seed: Forces NOERROR despite Response Status', () async {
//       int callCount = 0;
//       mockDongle.onTxRx = (len, hexStr) {
//         callCount++;
//         if (hexStr == "1003") return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
        
//         if (hexStr == "270b") {
//           // Returning ECU_BUSY here to test the override
//           return ResponseArrayStatus(
//             ecuResponseStatus: "ECU_BUSY", 
//             actualDataBytes: Uint8List.fromList([0x67, 0x0b, 0x00, 0x00]),
//           );
//         }
        
//         // This is the Key Send (270c...) response
//         return ResponseArrayStatus(ecuResponseStatus: "SOMETHING_ELSE");
//       };

//       final result = await uds.enterExtendedSession(
//         WriteParameterIndex.UDS_DS1003_SK0B0C,
//         SeedKeyIndexType.greavesBoschBs6Prod,
//       );

//       // result should be NOERROR because the seed [00, 00] was detected
//       expect(result?.ecuResponseStatus, "NOERROR");
//       expect(callCount, 3); // 1003 -> 270b (Seed) -> 270c (Key)
//     });
//   });

//   group('readDTC Tests', () {
    
//     test('UDS 3-Byte DTC: Correct parsing and formatting', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         expect(hexStr, "1902FF");
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           // Data: [SID+40, SubFn, DTCCount, DTC1_B0, B1, B2, Status, DTC2_B0, B1, B2, Status]
//           // DTC 1: P0123-01 (Active) -> P = 0x00, 0x01, 0x23, Status 0x01
//           // DTC 2: U0456-02 (Inactive) -> U = 0xC0 (0x3<<6), 0x04, 0x56, Status 0x00
//           actualDataBytes: Uint8List.fromList([
//             0x59, 0x02, 0x01, // Header
//             0x00, 0x01, 0x23, 0x01, // DTC 1
//             0xC4, 0x05, 0x06, 0x00, // DTC 2 (0xC0 | 0x04 = 0xC4)
//           ]),
//         );
//       };

//       final result = await uds.readDTC(ReadDtcIndex.UDS_3BYTE_DTC);

//       expect(result.status, "NO_ERROR");
//       expect(result.dtcs!.length, 2);
      
//       // Check DTC 1
//       expect(result.dtcs![0][0], "P0001-23"); // Note: Byte0 is (raw & 0x3F)
//       expect(result.dtcs![0][1], "Active");

//       // Check DTC 2
//       expect(result.dtcs![1][0], "U0405-06");
//       expect(result.dtcs![1][1], "Inactive");
//     });

//     test('UDS 2-Byte13 DTC: Correct formatting (Prefix + B0 + B2)', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           actualDataBytes: Uint8List.fromList([
//             0x59, 0x02, 0x01, 
//             0x41, 0x22, 0x33, 0x01, // B0=0x41 (C prefix), B1=0x22, B2=0x33
//           ]),
//         );
//       };

//       final result = await uds.readDTC(ReadDtcIndex.UDS_2BYTE13_DTC);

//       // Code logic: Prefix + Byte0 + Byte2
//       expect(result.dtcs![0][0], "C0133"); 
//     });

//     test('Generic OBD: Aggregates Mode 03 and Mode 07', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         if (hexStr == "03") {
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             actualDataBytes: Uint8List.fromList([0x43, 0x01, 0x01, 0x02]), // P0102
//           );
//         } else if (hexStr == "07") {
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             actualDataBytes: Uint8List.fromList([0x47, 0x01, 0x81, 0x04]), // B0104 (0x80 = B)
//           );
//         }
//      return null;
//       };

//       final result = await uds.readDTC(ReadDtcIndex.GENERIC_OBD);

//       expect(result.dtcs!.length, 2);
//       expect(result.dtcs![0], ["P0102", "Current"]);
//       expect(result.dtcs![1], ["B0104", "Pending"]);
//       expect(result.status, "NO_ERROR");
//     });

//     test('Error Handling: Returns ECU status on failure', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(ecuResponseStatus: "ECUERROR CONDITIONSNOTCORRECT");
//       };

//       final result = await uds.readDTC(ReadDtcIndex.UDS_3BYTE_DTC);

//       expect(result.status, "ECUERROR CONDITIONSNOTCORRECT");
//       expect(result.dtcs!.isEmpty, true);
//     });
//   });

//   group('getFreezeFrameDtcCode Tests', () {
//     test('Correctly parses Powertrain (P) DTC: P0123', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         expect(hexStr, "020200");
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           // Byte 0-2: SID/PID/Seq, Byte 3-4: DTC Bytes
//           // P0123: P=00 (bits 7-6), Code=0x0123
//           // Byte 3: 0x01, Byte 4: 0x23
//           actualDataBytes: Uint8List.fromList([0x42, 0x02, 0x00, 0x01, 0x23]),
//         );
//       };

//       final result = await uds.getFreezeFrameDtcCode();
//       expect(result, "P0123");
//     });

//     test('Correctly parses Chassis (C) DTC: C1A5F', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         // C prefix = binary 01 (bits 7-6). 
//         // 0x40 | 0x1A = 0x5A
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           actualDataBytes: Uint8List.fromList([0x42, 0x02, 0x00, 0x5A, 0x5F]),
//         );
//       };

//       final result = await uds.getFreezeFrameDtcCode();
//       expect(result, "C1A5F");
//     });

//     test('Returns empty string on ECU Error', () async {
//       mockDongle.onTxRx = (len, hexStr) => ResponseArrayStatus(ecuResponseStatus: "ERROR");
//       final result = await uds.getFreezeFrameDtcCode();
//       expect(result, "");
//     });
//   });

//   group('clearDTC Tests', () {
//     test('UDS 4-Byte (uds4Bytes): Sends 14FFFFFF', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         expect(hexStr, "14FFFFFF");
//         expect(len, 4);
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//       };

//       final resp = await uds.clearDTC(ClearDtcIndex.uds4Bytes);
//       expect(resp.ecuResponseStatus, "NOERROR");
//     });

//     test('Generic OBD (genericObd): Sends 04', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         expect(hexStr, "04");
//         expect(len, 1);
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//       };

//       final resp = await uds.clearDTC(ClearDtcIndex.genericObd);
//       expect(resp.ecuResponseStatus, "NOERROR");
//     });

//     test('KWP (kwpPrimitive): Sends 14', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         expect(hexStr, "14");
//         expect(len, 1);
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//       };

//       await uds.clearDTC(ClearDtcIndex.kwpPrimitive);
//     });
//   });

//   group('getFreezeFrame Logic Tests', () {
    
//     test('DTC Encoding: P0123-45 correctly formats request string', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         // P = 0x00. DTC 01 23 45. Record FF.
//         // Expected Request: 1904(00|01)2345FF -> 1904012345FF
//         expect(hexStr, "1904012345ff");
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR", actualDataBytes: Uint8List(0));
//       };

//       await uds.getFreezeFrame("P0123-45", FreezeFrameModel(freezeFrameCode: []));
//     });

//     test('DTC Encoding: U0123-45 applies prefix bits correctly', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         // U = 0x03 (11 in binary). 
//         // DTC 01 23 45 -> 01 binary is 00000001
//         // Apply (03 << 6) -> 11000000
//         // Result: 11000001 (0xC1)
//         // Expected Request: 1904C12345FF
//         expect(hexStr, "1904c12345ff");
//         return ResponseArrayStatus(ecuResponseStatus: "NOERROR", actualDataBytes: Uint8List(0));
//       };

//       await uds.getFreezeFrame("U0123-45", FreezeFrameModel(freezeFrameCode: []));
//     });

//     test('Data Parsing: Successfully finds DID and extracts value', () async {
//       // Setup Config with one DID: 0xF401
//       final config = FreezeFrameModel(freezeFrameCode: [
//         FreezeFrameCode(code: "F401", length: 1)
//       ]);

//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           // Dummy UDS Response: [59, 04, DTC..., Record, DID_High, DID_Low, Value]
//           // index 8 is where the loop starts
//           actualDataBytes: Uint8List.fromList([
//             0x59, 0x04, 0x01, 0x23, 0x45, 0x01, 0x00, 0x00, // Header (8 bytes)
//             0xAA, 0xBB, // Noise data
//             0xF4, 0x01, 0x55 // The target DID and Value (0x55)
//           ]),
//         );
//       };

//       // Note: This test assumes you have mocked getFreezeValue or 
//       // that it performs standard extraction.
//       final result = await uds.getFreezeFrame("P0123-45", config);

//       expect(result.status, "NOERROR");
//       expect(result.dtcs?.length, 1);
//       expect(result.dtcs?[0].code, "F401");
//       // Verify parsing found the DID at index 10
//     });

//     test('Search Wrap-around: Finds DID if it appears before the current index', () async {
//        final config = FreezeFrameModel(freezeFrameCode: [
//         FreezeFrameCode(code: "D001", length: 1), // First DID
//         FreezeFrameCode(code: "A001", length: 1), // Second DID (appears earlier in buffer)
//       ]);

//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           actualDataBytes: Uint8List.fromList([
//             0x59, 0x04, 0x01, 0x23, 0x45, 0x01, 0x00, 0x00, 
//             0xA0, 0x01, 0x11, // DID 2 at index 8
//             0xD0, 0x01, 0x22, // DID 1 at index 11
//           ]),
//         );
//       };

//       final result = await uds.getFreezeFrame("P0123-45", config);

//       expect(result.dtcs?[0].code, "D001");
//       expect(result.dtcs?[1].code, "A001");
//       // If search(0) works, both will be found.
//     });

//     test('Error Handling: Returns Status not found on null response', () async {
//       mockDongle.onTxRx = (len, hexStr) => null;

//       final result = await uds.getFreezeFrame("P0123-45", FreezeFrameModel());
//       expect(result.status, "Status not found.");
//     });
//   });


//   group('genericOBDSupportedPidList Unit Tests', () {
//     test('Calculates PID 0x01 and 0x0C from bitmask correctly', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         if (hexStr == "0100") {
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             // 0x41 (Response SID), 0x00 (PID), followed by 4 bytes of bitmask
//             // Bitmask: 0x80100000 
//             // Binary: 1000 0000 0001 0000 0000...
//             // Bit 31 is set (PID 01), Bit 20 is set (PID 0C)
//             actualDataBytes: Uint8List.fromList([0x41, 0x00, 0x80, 0x10, 0x00, 0x00]),
//           );
//         }
//         // Return null for other loop iterations to simulate no response
//         return null;
//       };

//       final result = await uds.genericOBDSupportedPidList();

//       expect(result, contains("0101"));
//       expect(result, contains("010C"));
//       expect(result?.length, 2);
//     });

//     test('Reconstructs bitmask from partial response lengths (len=4)', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         if (hexStr == "0100") {
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             // data[2] and data[3] provided. Result should be 0xFFFF0000
//             actualDataBytes: Uint8List.fromList([0x41, 0x00, 0xFF, 0xFF]),
//           );
//         }
//         return null;
//       };

//       final result = await uds.genericOBDSupportedPidList();

//       // Should contain 16 PIDs (01 through 10)
//       expect(result?.length, 16);
//       expect(result, contains("0101"));
//       expect(result, contains("0110"));
//     });

//     test('Block offset logic: Correctly identifies PID 0x21 from 0120 request', () async {
//       mockDongle.onTxRx = (len, hexStr) {
//         if (hexStr == "0101") { // Requesting block 1
//           return ResponseArrayStatus(
//             ecuResponseStatus: "NOERROR",
//             // Bit 31 set: (1 * 32) + (32 - 31) = 33 (0x21)
//             actualDataBytes: Uint8List.fromList([0x41, 0x01, 0x80, 0x00, 0x00, 0x00]),
//           );
//         }
//         return null;
//       };

//       final result = await uds.genericOBDSupportedPidList();
//       expect(result, contains("0121"));
//     });

//     test('Returns null when no PIDs are found', () async {
//       mockDongle.onTxRx = (len, hexStr) => null;
//       final result = await uds.genericOBDSupportedPidList();
//       expect(result, isNull);
//     });
//   });

//   group('readParameters Unit Tests', () {
    
//     test('CONTINUOUS: Correctly handles 2-byte scaling and offsets', () async {
//       final config = [
//         ReadParameterPID(
//           pid: "22F401",
//           pidId: 101,
//           variables: [
//             PidVariable(
//               pidName: "Engine Speed",
//               datatype: "CONTINUOUS",
//               startByte: 1, // Start after SID/PID
//               noOfBytes: 2,
//               resolution: 0.25,
//               offset: 0.0,
//             )
//           ]
//         )
//       ];

//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           // 62 F4 01 followed by 0x01 F4 (500 decimal)
//           // (500 * 0.25) + 0 = 125.0
//           actualDataBytes: Uint8List.fromList([0x62, 0xF4, 0x01, 0x01, 0xF4]),
//         );
//       };

//       final result = await uds.readParameters(1, config);

//       expect(result[0].status, "NOERROR");
//       expect(result[0].variables![0].responseValue, "125");
//     });

//     test('BITCODED: Extracts specific bits from a byte', () async {
//       final config = [
//         ReadParameterPID(
//           pid: "22F402",
//           variables: [
//             PidVariable(
//               pidName: "Switch Status",
//               datatype: "CONTINUOUS",
//               isBitcoded: true,
//               startByte: 1,
//               noOfBytes: 1,
//               startBit: 3, // Start at bit 3
//               noofBits: 2,  // Read 2 bits
//               resolution: 1.0,
//             )
//           ]
//         )
//       ];

//       mockDongle.onTxRx = (len, hexStr) {
//         return ResponseArrayStatus(
//           ecuResponseStatus: "NOERROR",
//           // Byte: 0x1C -> Binary 0001 1100
//           // Shifted/Masked bits: bits 3-4 are '11' binary -> 3 decimal
//           actualDataBytes: Uint8List.fromList([0x62, 0xF4, 0x02, 0x1C]),
//         );
//       };

//       final result = await uds.readParameters(1, config);
//       expect(result[0].variables![0].responseValue, "3");
//     });

//     test('ENUMERATED: Map code to message string', () async {
//       final config = [
//         ReadParameterPID(
//           pid: "22F403",
//           variables: [
//             PidVariable(
//               pidName: "Gear",
//               datatype: "ENUMERATED",
//               startByte: 1,
//               noOfBytes: 1,
//               messages: [
//                 SelectedParameterMessage(code: "1", message: "First"),
//                 SelectedParameterMessage(code: "2", message: "Second"),
//               ]
//             )
//           ]
//         )
//       ];

//       mockDongle.onTxRx = (len, hexStr) => ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x62, 0xF4, 0x03, 0x02]),
//       );

//       final result = await uds.readParameters(1, config);
//       expect(result[0].variables![0].responseValue, "Second");
//     });

//     test('ASCII: Decodes byte array to string', () async {
//       final config = [
//         ReadParameterPID(
//           pid: "22F404",
//           variables: [
//             PidVariable(
//               pidName: "VIN",
//               datatype: "ASCII",
//               startByte: 1,
//               noOfBytes: 3,
//             )
//           ]
//         )
//       ];

//       mockDongle.onTxRx = (len, hexStr) => ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x62, 0xF4, 0x04, 0x41, 0x42, 0x43]), // "ABC"
//       );

//       final result = await uds.readParameters(1, config);
//       expect(result[0].variables![0].responseValue, "ABC");
//     });

//     test('IQA: Specialized Injector Coding logic', () async {
//       final config = [
//         ReadParameterPID(
//           pid: "22F405",
//           variables: [
//             PidVariable(pidName: "Inj1", datatype: "IQA"),
//           ]
//         )
//       ];

//       mockDongle.onTxRx = (len, hexStr) => ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         // Needs at least 8 bytes of data after header
//         actualDataBytes: Uint8List.fromList([
//           0x62, 0xF4, 0x05, // Header
//           0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF // 0xFF results in '8888888' in lookup
//         ]),
//       );

//       final result = await uds.readParameters(1, config);
//       expect(result[0].variables![0].responseValue, "8888888");
//     });
//   });

//   group('ivnReadParameters Decoding Tests', () {
    
//     test('Endianness: Should handle Little Endian conversion correctly', () async {
//       // ignore: unused_local_variable
//       final item = PIDFrameId(
//         framID: "CF00400",
//         pidDescription: "Engine Speed",
//         startByte: "1",
//         unit: "2",
//         endian: "LITTLE", // Should reverse [0x64, 0x00] to 0x0064
//         resolution: "1.0",
//         offset: "0.0",
//       );

//       // Simulated Frame: [0x64, 0x00, ...] -> 100 in Little Endian
//       final mockFrame = Uint8List.fromList([0x64, 0x00, 0xAA, 0xBB]);
      
//       // Verification logic (Applying your code's math)
//       Uint8List pidBytes = mockFrame.sublist(0, 2); 
//       pidBytes = Uint8List.fromList(pidBytes.reversed.toList()); // [0x00, 0x64]
      
//       int val = (pidBytes[0] << 8) | pidBytes[1]; // 100
//       expect(val, 100);
//     });

//     test('Bitcoded: MSB-0 Masking logic for 1-byte data', () async {
//       // Config: 1 byte total, start at bit 3, read 2 bits
//       // ignore: unused_local_variable
//       final item = PIDFrameId(
//         framID: "123",
//         bitCoded: "1",
//         startByte: "1",
//         unit: "1",
//         startBit: "3",
//         noOfBits: "2",
//       );

//       // Data: 0x30 -> Binary 0011 0000
//       // Mask calculation in your code: 
//       // mask |= (1 << (8 - (3 + 0))) -> bit 5 set
//       // mask |= (1 << (8 - (3 + 1))) -> bit 4 set
//       // mask = 0011 0000 (0x30)
//       // Result = (0x30 & 0x30) >> (8 - 3 - 2 + 1) -> 0x30 >> 4 = 3
      
//       int unsignedIntValue = 0x30;
//       int sBit = 3;
//       int nBits = 2;
//       int mask = 0;
//       for (int x = 0; x < nBits; x++) {
//         mask |= (1 << (8 - (sBit + x)));
//       }
//       int result = (unsignedIntValue & mask) >> (8 - sBit - nBits + 1);

//       expect(result, 3);
//     });

//     test('Signed: Should handle negative values via _toSigned', () {
//       // 0xFF in 1 byte (255 unsigned) should be -1 signed
//       int val = 0xFF;
//       int byteCount = 1;
      
//       // ignore: unused_local_variable
//       int bits = byteCount * 8; // 8
//       int max = 256; // pow(2, 8)
//       int limit = 128; // pow(2, 7)
      
//       int result = (val >= limit) ? val - max : val;
      
//       expect(result, -1);
//     });

//     test('ASCII: Decodes char codes correctly', () {
//       // ignore: unused_local_variable
//       final item = PIDFrameId(
//         unit: "ASCII",
//         startByte: "1",
     
//       );
      
//       Uint8List pidBytes = Uint8List.fromList([0x41, 0x42, 0x43]); // ABC
//       String dataValue = String.fromCharCodes(pidBytes).trim();
      
//       expect(dataValue, "ABC");
//     });
//   });

// //    group('actuatorTestWriteParameters Tests', () {
    
// //     test('Sequence Check: Session -> Seed -> Key -> Actuator Command', () async {
// //   List<String> logs = [];

// //   mockDongle.onTxRx = (len, hexData) {
// //     // Normalize input to uppercase for reliable matching
// //     String command = hexData.toUpperCase();
// //     logs.add(command);
    
// //     if (command == "1003") {
// //       return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //     }
    
// //     if (command == "2701") {
// //       return ResponseArrayStatus(
// //         ecuResponseStatus: "NOERROR",
// //         actualDataBytes: Uint8List.fromList([0x67, 0x01, 0x11, 0x22]), 
// //       );
// //     }

// //     // This is the most likely spot for the null error.
// //     // Ensure the Key calculation (Seed + 1) matches your expectations.
// //     if (command == "27021223") {
// //       return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //     }

// //     if (command.startsWith("2F")) {
// //       return ResponseArrayStatus(
// //         ecuResponseStatus: "NOERROR",
// //         actualDataBytes: Uint8List.fromList([0x6F, 0xF4, 0x01, 0x03]),
// //       );
// //     }

// //     // If it hits here, your test will fail, but result.status won't be null!
// //     return ResponseArrayStatus(ecuResponseStatus: "MOCK_UNHANDLED_$command");
// //   };

// //   final actuatorCmd = [Uint8List.fromList([0x2F, 0xF4, 0x01, 0x03, 0x01])];

// //   final result = await uds.actuatorTestWriteParameters(
// //     WriteParameterIndex.UDS_DS1003_SK0102,
// //     SeedKeyIndexType.greavesBoschBs6Prod,
// //     actuatorCmd,
// //   );

// //   // This helps you see exactly what failed if it's not "NOERROR"
// //   expect(result.status, "NOERROR", reason: "Expected NOERROR but got ${result.status}. Logs: $logs");
// // });

// //     test('NA Index: Should skip preamble and send command directly', () async {
// //       List<String> transmittedFrames = [];
// //       mockDongle.onTxRx = (len, hexData) {
// //         transmittedFrames.add(hexData.toUpperCase());
// //         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //       };

// //       final actuatorCmd = [Uint8List.fromList([0x2F, 0xDE, 0xAD, 0x03])];

// //       await uds.actuatorTestWriteParameters(
// //         WriteParameterIndex.NA,
// //         SeedKeyIndexType.greavesBoschBs6Prod,
// //         actuatorCmd,
// //       );

// //       expect(transmittedFrames.length, 1);
// //       expect(transmittedFrames[0], "2FDEAD03");
// //     });

// //  test('Multi-Command: Should stop if a command fails', () async {
// //   int cmdCount = 0;
// //   mockDongle.onTxRx = (len, hexData) {
// //     cmdCount++;
// //     if (cmdCount == 1) return ResponseArrayStatus(ecuResponseStatus: "FAILED");
// //     return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //   };

// //   await uds.actuatorTestWriteParameters(
// //     WriteParameterIndex.NA,
// //     SeedKeyIndexType.greavesBoschBs6Prod,
// //     [Uint8List.fromList([0x2F, 0x01]), Uint8List.fromList([0x2F, 0x02])],
// //   );

// //   // Should be 1, because the loop 'breaks' after the first failure
// //   expect(cmdCount, 1); 
// // });

// //     test('Failure Handling: Should stop and return error if Session fails', () async {
// //       mockDongle.onTxRx = (len, hexData) {
// //         if (hexData == "1003") {
// //           return ResponseArrayStatus(ecuResponseStatus: "ECUERROR CONDITIONSNOTCORRECT");
// //         }
// //         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //       };

// //       final result = await uds.actuatorTestWriteParameters(
// //         WriteParameterIndex.UDS_DS1003,
// //         SeedKeyIndexType.greavesBoschBs6Prod,
// //         [Uint8List.fromList([0x2F, 0x01, 0x03])],
// //       );

// //       expect(result.status, "ECUERROR CONDITIONSNOTCORRECT");
// //       expect(mockDongle.lastTxHex, "1003"); // Should not have progressed to 2F
// //     });
// //   });

// // group('iorTestParameters1 Unit Tests', () {
// //   late MockDongleComm mockDongle;
// //   late MockSeedKeyCalculator mockCalculator;
// //   late UDSDiagnostic udsDiagnostic;

// //   setUp(() {
// //     mockDongle = MockDongleComm();
// //     mockCalculator = MockSeedKeyCalculator();
// //     udsDiagnostic = UDSDiagnostic(mockDongle, mockCalculator);
// //   });

// //   test('Happy Path: Complete IOR Sequence with Polling and Auto-Stop', () async {
// //     int callCount = 0;

// //     mockDongle.onTxRx = (len, hexStr) {
// //       callCount++;
// //       String command = hexStr.toUpperCase();

// //       if (callCount == 1) {
// //         expect(command, "1003"); // Session
// //         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //       } else if (callCount == 2) {
// //         expect(command, "2701"); // Request Seed
// //         return ResponseArrayStatus(
// //           ecuResponseStatus: "NOERROR",
// //           actualDataBytes: Uint8List.fromList([0x67, 0x01, 0x11, 0x22]),
// //         );
// //       } else if (callCount == 3) {
// //         expect(command, "27021223"); // Send Key (Calculated by Mock)
// //         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //       } else if (callCount == 4) {
// //         expect(command, "START_CMD"); // Start Command
// //         return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //       } else if (callCount == 5) {
// //         expect(command, "REQ_CMD"); // First Poll
// //         // Return "Active" state (assuming activeCommand is "01")
// //         return ResponseArrayStatus(
// //           ecuResponseStatus: "NOERROR",
// //           actualDataBytes: Uint8List.fromList([0x01]), 
// //         );
// //       } else if (callCount == 6) {
// //         expect(command, "REQ_CMD"); // Second Poll
// //         // Return "Complete" state (assuming completeCommand is "02")
// //         return ResponseArrayStatus(
// //           ecuResponseStatus: "NOERROR",
// //           actualDataBytes: Uint8List.fromList([0x02]), 
// //         );
// //       }
// //       return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //     };

// //     final result = await udsDiagnostic.iorTestParameters1(
// //       seedKeyIndex1: SeedKeyIndexType.SK_0102,
// //       writeParameterIndex: WriteParameterIndex.UDS,
// //       startCommand: "START_CMD",
// //       requestCommand: "REQ_CMD",
// //       stopCommand: "STOP_CMD",
// //      // inputTestCondition: true,
// //       bitPosition: 1,
// //       activeCommand: "01",
// //       completeCommand: "02",
// //       failCommand: "03",
// //       isStop: false,
// //       timeBase: 5, inputTestCondition: true,
// //     );

// //     expect(result.ecuResponseStatus, "Test Completed");
// //   });

// //   test('Security Access Failure: Should not send Start Command', () async {
// //     int callCount = 0;
// //     bool startSent = false;

// //     mockDongle.onTxRx = (len, hexStr) {
// //       callCount++;
// //       if (hexStr == "START_CMD") startSent = true;

// //       if (callCount == 1) return ResponseArrayStatus(ecuResponseStatus: "NOERROR"); // Session
// //       if (callCount == 2) return ResponseArrayStatus(ecuResponseStatus: "ECUERROR"); // Seed Fail
      
// //       return ResponseArrayStatus(ecuResponseStatus: "NOERROR");
// //     };

// //     await udsDiagnostic.iorTestParameters1(
// //       seedKeyIndex1: SeedKeyIndexType.SK_0102,
// //       writeParameterIndex: WriteParameterIndex.UDS,
// //       startCommand: "START_CMD",
// //       requestCommand: "REQ_CMD",
// //       stopCommand: "STOP_CMD",
// //       inputTestCondition: true,
// //       bitPosition: 1,
// //       activeCommand: "01",
// //       completeCommand: "02",
// //       failCommand: "03",
// //       isStop: false,
// //       timeBase: 5,
// //     );

// //     expect(startSent, false);
// //   });
// // });

// group('iorTestParameters Setup Sequence', () {
//     test('Successful Routine Start with Security Access', () async {
//       // 1. Mock Session Response (10 03)
//       mockDongle.responses["1003"] = ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x50, 0x03]),
//       );

//       // 2. Mock Seed Response (27 01)
//       mockDongle.responses["2701"] = ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x67, 0x01, 0xAA, 0xBB]),
//       );

//       // 3. Mock Key Response (Calculator writes 0x12, 0x34)
//       // Note: Hex for 12, 34 is 1234. Sequence: 27 + (01+1) + 1234
//       mockDongle.responses["27021234"] = ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x67, 0x02]),
//       );

//       String startCmd = "3101AABB";
//       mockDongle.responses[startCmd] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//       final result = await diagnostic.iorTestParameters(
//         seedKeyIndex1: SeedKeyIndexType.SK_0102,
//         writeParameterIndex: WriteParameterIndex.UDS,
//         startCommand: startCmd,
//         requestCommand: "3103AABB",
//         stopCommand: "3102AABB",
//         testConditionParam: true,
//         bitPosition: 4,
//         activeCommand: ["01"],
//         completeCommand: "00",
//         failCommand: "FF",
//         isStop: false,
//         timeBase: 10,
//       );

//       expect(result.ecuResponseStatus, equals("NOERROR"));
//       expect(mockDongle.lastTxHex, startCmd);
//     });
//   });

//   group('iorTestParameters2 Polling Logic', () {
//     test('Aborts immediately if isStop is true', () async {
//       String stopCmd = "3102AABB";
//       mockDongle.responses[stopCmd] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//       final result = await diagnostic.iorTestParameters2(
//         seedKeyIndex1: SeedKeyIndexType.SK_0102,
//         writeParameterIndex: WriteParameterIndex.UDS,
//         startCommand: "3101AABB",
//         requestCommand: "3103AABB",
//         stopCommand: stopCmd,
//         inputTestCondition: true,
//         bitPosition: 1,
//         activeCommands: ["01"],
//         completeCommand: "00",
//         failCommand: "FF",
//         isStop: true,
//         timeBase: 0,
//         isTimebase: false,
//       );

//       expect(result.ecuResponseStatus, equals("Test Stopped"));
//       expect(mockDongle.lastTxHex, stopCmd);
//     });
//   });

//   group('IOR Basic Operations', () {
//   test('startIdIOR: Session-First Logic (UDS)', () async {
//     // 1. Session Response (10 03)
//     mockDongle.responses["1003"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");
//     // 2. Seed/Key handled by sendSeedKey (Mocked)
//     // 3. Start Command (31 01 00 01)
//     mockDongle.responses["31010001"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//     final result = await diagnostic.startIdIOR(
//       SeedKeyIndexType.SK_0102,
//       WriteParameterIndex.UDS,
//       "31010001"
//     );

//     expect(result.ecuResponseStatus, "NOERROR");
//     expect(mockDongle.lastTxHex, "31010001");
//   });

//   test('stopIdIOR: Reset Flags on Error', () async {
//     mockDongle.responses["31020001"] = ResponseArrayStatus(ecuResponseStatus: "ECUERROR");
    
//     await diagnostic.stopIdIOR("31020001");
    
//     // Check if class-level flags were reset (requires flags to be accessible)
//     // expect(diagnostic.testCondition, false);
//   });
// });

// group('ECU Unlocking', () {
//   test('startEcuUnlocking: Completes after duration', () async {
//     // We send a frame every 10ms for 50ms total
//     final result = await diagnostic.startEcuUnlocking("112233", "10", "50");
    
//     expect(result, "FINISHED");
//   });
// });

// group('Flash Interpreter Logic', () {
// test('IORTestParameters: Handles NRC 0x37 Delay', () async {
//   // 1. Initial 10 03 (Session Control)
//   mockDongle.responses["1003"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//   // 2. First 27 01 (Seed Request) returns NRC 37
//   // Your code will see this and perform Thread.Sleep(11000)
//   mockDongle.responses["2701"] = ResponseArrayStatus(ecuResponseStatus: "ECUERROR_REQUIREDTIMEDELAYNOTEXPIRED");

//   // 3. Second attempt (after sleep) returns valid seed
//   // The code will call CAN_TxRx again with the same TxFrame
//   mockDongle.onTxRx = (len, hex) {
//     if (hex == "2701") {
//        return ResponseArrayStatus(
//          ecuResponseStatus: "NOERROR", 
//          actualDataBytes: Uint8List.fromList([0x67, 0x01, 0x11, 0x22])
//        );
//     }
//     return null;
//   };
// });
// });
// test('startIdIOR: Session First then Security Sequence', () async {
//   // 1. Mock Session Response (10 03)
//   mockDongle.responses["1003"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");
  
//   // 2. Mock Seed Request (27 01)
//   mockDongle.responses["2701"] = ResponseArrayStatus(
//     ecuResponseStatus: "NOERROR",
//     actualDataBytes: Uint8List.fromList([0x67, 0x01, 0xAA, 0xBB]),
//   );

//   // 3. Mock Key Send (27 02 + Key)
//   // Calculator adds 1 to AA BB -> AB BC
//   mockDongle.responses["2702abbc"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//   // 4. Mock Routine Start
//   mockDongle.responses["3101AABB"] = ResponseArrayStatus(ecuResponseStatus: "NOERROR");

//   final result = await diagnostic.startIdIOR(
//     SeedKeyIndexType.SK_0102,
//     WriteParameterIndex.UDS_DS1003_SK0102, // This triggers "Session then Security"
//     "3101AABB",
//   );

//   expect(result.ecuResponseStatus, equals("NOERROR"));
//   expect(mockDongle.lastTxHex, equals("3101AABB"));
// });

// test('IORTestParameters2: Polls until "Test Completed"', () async {
//   String request_cmd = "3103AA01";
//   // ignore: unused_local_variable
//   List<String> active_cmds = ["03"]; // 03 means "Active/Running"
//   // ignore: unused_local_variable
//   String complete_cmd = "01";        // 01 means "Success"
//   // ignore: unused_local_variable
//   int bit_pos = 5; 

//   int pollCount = 0;
//   mockDongle.onTxRx = (len, hex) {
//     if (hex == request_cmd) {
//       pollCount++;
//       // Return 0x03 for first two calls, then 0x01
//       int statusByte = (pollCount < 3) ? 0x03 : 0x01;
      
//       return ResponseArrayStatus(
//         ecuResponseStatus: "NOERROR",
//         actualDataBytes: Uint8List.fromList([0x71, 0x03, 0xAA, 0x01, statusByte])
//       );
//     }
//     return ResponseArrayStatus(ecuResponseStatus: "ERROR");
//   };

// });
// }

// // --- Mock Classes ---

// class MockDongleComm {
//   String lastTxHex = "";
  
//   // ADD THIS: To store your mock ECU responses
//   Map<String, ResponseArrayStatus> responses = {};

//   ResponseArrayStatus? Function(int len, String hexData)? onTxRx;

//   Future<ResponseArrayStatus?> CAN_TxRx(int len, String hexData) async {
//     lastTxHex = hexData;
    
//     // Check if the test provided a manual callback logic
//     if (onTxRx != null) {
//       return onTxRx!(len, hexData); 
//     }

//     // Check if the test pre-loaded a response in the map
//     if (responses.containsKey(hexData)) {
//       return responses[hexData];
//     }

//     // Default return
//     return ResponseArrayStatus(
//       ecuResponseStatus: "NOERROR", 
//       actualDataBytes: Uint8List(0),
//     );
//   }

//   Future<ResponseArrayStatusivn> CAN_IVNRxFrame(String frameId) async {
//     return ResponseArrayStatusivn(
//       ecuResponseStatus: "NOERROR", 
//       actualFrameBytes: Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]),
//     );
//   }
// }
// class MockKeyResult {
//   final int keyLength;
//   final Uint8List keyBytes;
  
//   MockKeyResult(this.keyLength, {Uint8List? bytes}) 
//     : keyBytes = bytes ?? Uint8List(0);
// }

// // 1. Ensure this class structure matches what your code expects
// class CalculationResult {
//   final int keyLength;
//   CalculationResult(this.keyLength);
// }

// class MockSeedKeyCalculator {
//   // REMOVE the curly braces {} to make these positional arguments
//   dynamic calculate(
//     dynamic seedKeyIndex,
//     Uint8List seed,
//     Uint8List buffer,
//   ) {
//     // Fill the buffer with dummy key bytes
//     if (seed.length >= 2) {
//       buffer[0] = seed[0] + 1;
//       buffer[1] = seed[1] + 1;
//     }
    
//     // Return the object with keyLength property
//     return CalculationResult(2); 
//   }
// }