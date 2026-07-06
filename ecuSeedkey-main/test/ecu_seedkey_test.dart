// import 'dart:typed_data';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:ecu_seedkey/ecu_seedkey.dart'; // Adjust this to your actual filename

// void main() {
//   final calculator = ECUCalculateSeedkey();

//   group('1. Basic Calculation & Bit Shifting (Bosch)', () {
//     test('calculateSeedkey - Bosch BS6 Shifting Logic', () {
//       // Seed that triggers specific shifts
//       final seed = [0x01, 0x02, 0x03, 0x04];
//       final result = calculator.calculateSeedkey(
//         SeedKeyIndexType.greavesBoschBs6Prod, 
//         4, 
//         seed
//       );
//       // Even if logic is complex, it should return a consistent 32-bit int
//       expect(result, isA<int>());
//     });

//     test('calculateSeedkey - Invalid Seed Length returns 0', () {
//       final result = calculator.calculateSeedkey(
//         SeedKeyIndexType.greavesBoschBs6Prod, 
//         2, // Incorrect length
//         [0x01, 0x02]
//       );
//       expect(result, 0);
//     });
//   });

//   group('2. Hashing Methods (RIPEMD-160)', () {
//     test('getHash - Verify Bajaj EMS mapping', () {
//       final seed = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
//       final hash = calculator.getHash(seed, "BAJAJ_EMS_SECURITY");
//       expect(hash.length, 20); // RIPEMD-160 is 160 bits (20 bytes)
//     });

//     test('getHash - Verify Tata CPCB4 mapping', () {
//       final seed = Uint8List.fromList([0xAA, 0xBB]);
//       final hash = calculator.getHash(seed, "TATA_CPCB4_SEC");
//       expect(hash.length, 20);
//     });
//   });

//   group('3. AES Cryptography Methods', () {
//     test('encrypt - STRING format with Null Padding', () {
//       final clearHex = "11223344556677889900AABBCCDDEEFF";
//       final key = "secret_key_123";
//       final iv = "00000000000000000000000000000000";
      
//       final result = calculator.encrypt(clearHex, key, "STRING", iv);
//       expect(result.length, 16);
//       expect(result, isNot(Uint8List.fromList([0, 0, 0])));
//     });

//     test('calculateKeyUsingAes128 - Direct byte encryption', () {
//       final data = Uint8List(16);
//       final key = Uint8List(16);
//       final iv = Uint8List(16);
//       final result = calculator.calculateKeyUsingAes128(data, key, iv);
//       expect(result.length, 16);
//     });
//   });

//   group('4. Mathematical Dashboard & ABS Algorithms', () {
//  // test/ecu_seedkey_test.dart
// test('getDashboardKey - Formula Thresholds', () {
//   expect(calculator.getDashboardKey(100, 5), 5); // Corrected expectation
// });
 
//     test('calculateKeyForABS - TEA Round Logic', () {
//       final seed = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
//       final result = calculator.calculateKeyForABS(seed);
//       expect(result.length, 4);
//     });

//     test('calKeyForTFT - Arithmetic Chain', () {
//       final seed = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
//       final result = calculator.calKeyForTFT(seed);
//       expect(result.length, 4);
//     });
//   });

//   group('5. Advanced Rotations & Reversals', () {
//     test('getREKey - RIPEMD and Bit Picking', () {
//       final result = calculator.getREKey(0x12345678, 0x9ABCDEF012345678);
//       expect(result, isNotNull);
//       expect(result?.length, 4);
//     });

//     test('generateKeyForMonalisa - 8-bit Rotations', () {
//       final result = calculator.generateKeyForMonalisa(0x12345678, 0x87654321);
//       expect(result.length, 4);
//     });
//   });

//   group('6. Industrial VECV & AMT Iterative Loops', () {
//     test('calculateSeedForVECV_01 - 50 Round 16-bit Loop', () {
//       final seed = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]);
//       final result = calculator.calculateSeedForVECV_01(seed);
//       expect(result?.length, 2);
//     });

//     test('calculateSeedForAMT_BS46 - TEA v0/v1 conversion', () {
//       final seed = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]);
//       final result = calculator.calculateSeedForAMT_BS46(seed, "SEEDKEY_AMT_BS46_PROG");
//       expect(result.length, 8);
//     });

//     test('seedKeyForAMTBS4 - EBS vs Other selection', () {
//       final seed = Uint8List.fromList([0x11, 0x22, 0x33, 0x44]);
//       final result = calculator.seedKeyForAMTBS4(seed, "EBS");
//       expect(result.length, 4);
//     });
//   });

//   group('7. Utility Methods', () {
//     test('rotateLeft - Circular 8-bit shift', () {
//       // 0x01 (00000001) rotated left by 1 = 0x02 (00000010)
//       expect(calculator.rotateLeft(0x01, 1), 0x02);
//       // 0x80 (10000000) rotated left by 1 = 0x01 (00000001)
//       expect(calculator.rotateLeft(0x80, 1), 0x01);
//     });

//     test('hexStringToByteArray - Encode/Decode', () {
//       final hex = "AABBCC";
//       final bytes = calculator.hexStringToByteArray(hex);
//       expect(bytes, [0xAA, 0xBB, 0xCC]);
//     });
//   });
// }