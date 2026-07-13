import 'dart:typed_data';
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ecu_seedkey/security_access_unblocker.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/ripemd160.dart';

class ECUCalculateSeedkey {
  Map<String, dynamic> calculateSeedKey(
    SEEDKEYINDEXTYPE seedKeyIndex,
    int numSeedBytes,
    List<int> seed,
  ) {
    try {
      Uint8List key = Uint8List(0);
      int numKeyBytes = 0;

      // --- Algorithms based on seedKeyIndex ---
      switch (seedKeyIndex) {
        case SEEDKEYINDEXTYPE.SIMPSON_MDCS162_SECURITY:
        case SEEDKEYINDEXTYPE.SIMPSON_MD1CC878_SECURITY:
        case SEEDKEYINDEXTYPE.RE_SEEDKEY_EPM44:
        case SEEDKEYINDEXTYPE.BAJAJ_EMS_SECURITY:
        case SEEDKEYINDEXTYPE.BAJAJ_M17_SECURITY:
        case SEEDKEYINDEXTYPE.KOEL_AUTO_BS4:
        case SEEDKEYINDEXTYPE.Sanitas_BOSCH_BS6_PROD:
        case SEEDKEYINDEXTYPE.KOEL_CPCB4_MID_HP_ECU:
        case SEEDKEYINDEXTYPE.KOEL_CPCB4_HIGH_HP_ECU:
        case SEEDKEYINDEXTYPE.KOEL_CPCB4_LOW_HP_ECU:
        case SEEDKEYINDEXTYPE.KOEL_BOSCH_BS6:
        case SEEDKEYINDEXTYPE.SML_BOSCH_BS6_PROD:
        case SEEDKEYINDEXTYPE.FLASH_KOEL_BOSCH_F6_CPCB4:
        case SEEDKEYINDEXTYPE.GREAVES_LIGIER_BOSCH_PV:
        case SEEDKEYINDEXTYPE.GREAVES_POWER_BOSCH_CPCB4:
        case SEEDKEYINDEXTYPE.TATA_CPCB4_SEC:
          List<int> keyByte = getHash(seed, seedKeyIndex.name);
          key = Uint8List.fromList(keyByte.sublist(0, 8));
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.GREAVES_LIGIER_DELPHI:
          seed = seed.reversed.toList();
          int seedVal = _bytesToUint32(seed);
          int keyVal = SecurityAccessUnlocker().computeUnlockKey(seedVal);
          key = Uint8List.fromList([
            (keyVal >> 24) & 0xFF,
            (keyVal >> 16) & 0xFF,
            (keyVal >> 8) & 0xFF,
            keyVal & 0xFF,
          ]);
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.GREAVES_LIGIER_DASHBOARD:
          seed = seed.reversed.toList();
          int seedVal = _bytesToUint32(seed);
          int mask = 133;
          int keyVal = getDashboardKey(seedVal, mask);
          key = Uint8List.fromList([
            (keyVal >> 24) & 0xFF,
            (keyVal >> 16) & 0xFF,
            (keyVal >> 8) & 0xFF,
            keyVal & 0xFF,
          ]);
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.RE_SEEDKEY:
        case SEEDKEYINDEXTYPE.RE_SEEDKEY_M4C:
          int seedVal = _bytesToUint32(seed);
          key = Uint8List.fromList(getREKey(seedVal, 0x3DFA2EAE7835BC4F) ?? []);
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.RE_SEEDKEY_M4A:
          int seedVal = _bytesToUint32(seed);
          if (seedVal == 0xFFFFFFFF) {
            key = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
          } else {
            key = Uint8List.fromList(
              getREKey(seedVal, 0xD5785A2DB93831AD) ?? [],
            );
          }
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.RE_SEEDKEY_MONNALISA:
          seed = seed.reversed.toList();
          int reSeed = _bytesToUint32(seed);
          key = Uint8List.fromList(generateKeyForMonalisa(reSeed, 0x8A4B7251));
          numKeyBytes = key.length;
          break;

        case SEEDKEYINDEXTYPE.BAJAJ_TFT_SECURITY:
          key = Uint8List.fromList(calKeyForTFT(seed));
          numKeyBytes = key.length;
          break;
        // Inside your switch (seedKeyIndex) statement:
        case SEEDKEYINDEXTYPE.GREAVES_BOSCH_BS6_PROD:
          // 1. Convert seed bytes to a 32-bit unsigned integer
          // .NET: (UInt32)seed[3] + (seed[2]<<8) + (seed[1]<<16) + (seed[0]<<24)
          int longseed =
              ((seed[0] << 24) | (seed[1] << 16) | (seed[2] << 8) | seed[3]) &
              0xFFFFFFFF;

          int mask2 = 0xEDC17789;
          int numshift = (longseed & 0x000F0000) >> 16;
          int dir = (longseed & 0x00000008) >> 3;

          for (int ct = 0; ct < numshift; ct++) {
            // Check condition (longseed & 0x07 != 5)
            if ((longseed & 0x00000007) != 5) {
              if (dir != 0x00) {
                // Circular Right Shift (32-bit)
                longseed =
                    ((longseed >> 1) & 0x7FFFFFFF) |
                    ((longseed << 31) & 0xFFFFFFFF);
              } else {
                // Circular Left Shift (32-bit)
                longseed =
                    ((longseed << 1) & 0xFFFFFFFF) |
                    ((longseed >> 31) & 0x00000001);
              }
            } else {
              break;
            }
          }

          // 2. Final XOR with mask
          int dKeyU32 = (longseed ^ mask2) & 0xFFFFFFFF;

          // 3. Convert back to bytes (Big Endian)
          key = Uint8List(4);
          key[0] = (dKeyU32 >> 24) & 0xFF;
          key[1] = (dKeyU32 >> 16) & 0xFF;
          key[2] = (dKeyU32 >> 8) & 0xFF;
          key[3] = dKeyU32 & 0xFF;

          numKeyBytes = 4;
          break;

        default:
          key = Uint8List(0);
          numKeyBytes = 0;
          break;
      }

      // --- Debug Logs ---
      print("✅ Seed: ${byteArrayToString(Uint8List.fromList(seed))}");
      print("✅ Generated Key: ${byteArrayToString(key)}");

      return {
        "status": key.isEmpty ? -1 : 0,
        "key": key,
        "numKeyBytes": numKeyBytes,
      };
    } catch (e) {
      print("❌ Error in calculateSeedKey: $e");
      return {"status": -1, "key": Uint8List(0), "numKeyBytes": 0};
    }
  }

  // Helper: convert 4 bytes to uint32
  int _bytesToUint32(List<int> bytes) {
    return ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) &
        0xFFFFFFFF;
  }

  // Converts Uint8List to hex string for debugging
  String byteArrayToString(Uint8List ba) {
    return ba.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> getHash(List<int> seed, String seedKey) {
    List<int> sSeed = List.filled(16, 0);

    switch (seedKey) {
      case "BAJAJ_EMS_SECURITY":
        sSeed = hexStringToByteArray("01AC6BD69ECDF74CBC172AB7F9D3CEA7");
        break;

      case "BAJAJ_M17_SECURITY":
        sSeed = hexStringToByteArray("6BBECD8B95518DEA1320C0218203603E");
        break;

      case "KOEL_AUTO_BS4":
        sSeed = hexStringToByteArray("15FBED0C4AFCF8770385D4475BFB9F35");
        break;

      case "Sanitas_BOSCH_BS6_PROD":
        sSeed = hexStringToByteArray("F633E29B600729855EEB398C199BBE88");
        break;

      case "KOEL_CPCB4_MID_HP_ECU":
        sSeed = hexStringToByteArray("15FBED0C4AFCF8770385D4475BFB9F35");
        break;

      case "KOEL_CPCB4_HIGH_HP_ECU":
        sSeed = hexStringToByteArray("8CD11C59ED4425798E05E04133EB2903");
        break;

      case "KOEL_CPCB4_LOW_HP_ECU":
        sSeed = hexStringToByteArray("1D61F1BCB3E83A7284E8BF2981DE7ED7");
        break;

      case "KOEL_BOSCH_BS6":
        sSeed = hexStringToByteArray("15FBED0C4AFCF8770385D4475BFB9F35");
        break;

      case "SML_BOSCH_BS6_PROD":
        sSeed = hexStringToByteArray("F633E29B600729855EEB398C199BBE88");
        break;

      case "FLASH_KOEL_BOSCH_F6_CPCB4":
        sSeed = hexStringToByteArray("1D61F1BCB3E83A7284E8BF2981DE7ED7");
        break;

      case "SIMPSON_MDCS162_SECURITY":
        sSeed = hexStringToByteArray("81C6EBEC28BFC4A625374737664D4042");
        break;

      case "SIMPSON_MD1CC878_SECURITY":
        sSeed = hexStringToByteArray("5C4062143A40C9B05C7E7F04DB2C6777");
        break;

      case "RE_SEEDKEY_EPM44":
        sSeed = hexStringToByteArray("13A120A0FE9EC178ADEB179F9E5CC130");
        break;

      case "GREAVES_LIGIER_BOSCH_PV":
        sSeed = hexStringToByteArray("48BEF1BBDE5D87F7DD5C85C40427C4F7");
        break;

      case "GREAVES_POWER_BOSCH_CPCB4":
        sSeed = hexStringToByteArray("064189772684358995E10278A4450F8B");
        break;

      case "TATA_CPCB4_SEC":
        sSeed = hexStringToByteArray("F61A207E7331B90B029C0DF626B12161");
        break;
    }

    List<int> combined = [...sSeed, ...seed];

    // Debug: show exactly what secret+seed we are hashing
    print(
      '🔑 getHash[$seedKey]: '
      'secret=${sSeed.map((b) => b.toRadixString(16).padLeft(2, "0")).join()} '
      'seed=${seed.map((b) => b.toRadixString(16).padLeft(2, "0")).join()} '
      'combined=${combined.length}bytes',
    );

    var digest = RIPEMD160Digest();
    Uint8List output = Uint8List(digest.digestSize);

    digest.update(Uint8List.fromList(combined), 0, combined.length);
    digest.doFinal(output, 0);

    return output;
  }

  List<int> hexStringToByteArray(String hex) {
    List<int> result = [];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  List<int> encrypt(
    String clearText,
    String secretKey,
    String keyFormat,
    String initVector,
  ) {
    try {
      List<int> byteKey;

      if (keyFormat == "STRING") {
        var keyBytes = Uint8List.fromList(
          secretKey.padRight(16, '\x00').codeUnits,
        );

        if (keyBytes.length > 16) {
          byteKey = keyBytes.sublist(0, 16);
        } else {
          byteKey = keyBytes;
        }
      } else {
        byteKey = hexStringToByteArray(secretKey);
      }

      List<int> byteIV = hexStringToByteArray(initVector);
      List<int> byteText = hexStringToByteArray(clearText);

      final cipher = PaddedBlockCipher("AES/CBC/PKCS7");

      cipher.init(
        true,
        PaddedBlockCipherParameters(
          ParametersWithIV(
            KeyParameter(Uint8List.fromList(byteKey)),
            Uint8List.fromList(byteIV),
          ),
          null,
        ),
      );

      Uint8List encrypted = cipher.process(Uint8List.fromList(byteText));

      if (encrypted.length >= 16) {
        encrypted = encrypted.sublist(0, 16);
      }

      return encrypted;
    } catch (e) {
      return [0, 0, 0];
    }
  }

  List<int> calculateKeyUsingAes128(
    List<int> data,
    List<int> key,
    List<int> iv,
  ) {
    try {
      // Zero padding manually
      int blockSize = 16;
      int padding = blockSize - (data.length % blockSize);

      if (padding != blockSize) {
        data = [...data, ...List.filled(padding, 0)];
      }

      final cipher = CBCBlockCipher(AESEngine());

      cipher.init(
        true, // encryption
        ParametersWithIV(
          KeyParameter(Uint8List.fromList(key)),
          Uint8List.fromList(iv),
        ),
      );

      Uint8List input = Uint8List.fromList(data);
      Uint8List output = Uint8List(input.length);

      for (int offset = 0; offset < input.length; offset += blockSize) {
        cipher.processBlock(input, offset, output, offset);
      }

      return output;
    } catch (e) {
      return [];
    }
  }

  List<int> performCryptography(List<int> data, BlockCipher cipher) {
    try {
      int blockSize = cipher.blockSize;

      Uint8List input = Uint8List.fromList(data);
      Uint8List output = Uint8List(input.length);

      for (int offset = 0; offset < input.length; offset += blockSize) {
        cipher.processBlock(input, offset, output, offset);
      }

      return output;
    } catch (e) {
      return [];
    }
  }

  int getDashboardKey(int seed, int mask) {
    int key = 0;

    if (seed < 858953459) {
      key = ((seed % 5) * seed) + (mask % 7);
    } else {
      if (seed <= 1715986918) {
        key = ((seed % 3) * seed) + (mask % 17);
      } else {
        if (seed <= 2576850387) {
          key = seed + (seed % (mask + 11));
        } else {
          if (seed <= 3434973735) {
            key = ((seed % 27) * mask) + seed + 7;
          } else {
            key = mask * ((seed % 227) + 1);
          }
        }
      }
    }

    // ensure 32-bit unsigned result
    return key & 0xFFFFFFFF;
  }

  List<int> calculateKeyForABS(List<int> actualSeed) {
    const int DELTA = 0x9E3779B9;

    int y, calcKey, hiddenSeed, sum, rounds, len;
    List<int> seed = List.filled(2, 0);
    List<int> constKey = List.filled(4, 0);

    int p, e;

    len = 2;
    rounds = 6 + (52 ~/ len);
    sum = 0;
    hiddenSeed = 0x544F4D49;

    // reverse seed like C#
    actualSeed = actualSeed.reversed.toList();

    seed[0] = bytesToUint32(actualSeed, 0);
    seed[1] = hiddenSeed;

    constKey[0] = 0xB5A01EF2;
    constKey[1] = 0x53ACD2F9;
    constKey[2] = 0x2340E321;
    constKey[3] = 0x63F9DB10;

    calcKey = seed[len - 1];

    do {
      sum = (sum + DELTA) & 0xFFFFFFFF;
      e = (sum >> 2) & 3;

      for (p = 0; p < (len - 1); p++) {
        y = seed[p + 1];
        seed[p] = (seed[p] + mx(calcKey, y, sum, p, e, constKey)) & 0xFFFFFFFF;
        calcKey = seed[p];
      }

      y = seed[0];
      seed[len - 1] =
          (seed[len - 1] + mx(calcKey, y, sum, len - 1, e, constKey)) &
          0xFFFFFFFF;

      calcKey = seed[len - 1];
    } while (--rounds != 0);

    List<int> key = uint32ToBytes(calcKey);
    return key.reversed.toList();
  }

  int mx(int calcKey, int y, int sum, int p, int e, List<int> constKey) {
    return ((((calcKey >> 5) ^ (y << 2)) +
            (((y >> 3) ^ (calcKey << 4)) ^ (sum ^ y)) +
            (constKey[(p & 3) ^ e] ^ calcKey)) &
        0xFFFFFFFF);
  }

  int bytesToUint32(List<int> bytes, int offset) {
    return ((bytes[offset] << 24) |
            (bytes[offset + 1] << 16) |
            (bytes[offset + 2] << 8) |
            bytes[offset + 3]) &
        0xFFFFFFFF;
  }

  List<int> uint32ToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  List<int> calKeyForTFT(List<int> seed) {
    const int constant1 = 0x5FD63801;
    const int constant2 = 0x6179CC5D;
    const int constant3 = 0xBCAA1E23;

    // Reverse seed like C#
    seed = seed.reversed.toList();

    int seedVal = bytesToUint32(seed, 0);

    int key = (seedVal + constant1) & 0xFFFFFFFF;
    key = (key ^ constant2) & 0xFFFFFFFF;
    key = (key - constant3) & 0xFFFFFFFF;

    List<int> keyArray = uint32ToBytes(key);

    return keyArray.reversed.toList();
  }

  // List<int>? getREKey(int s, int ek) {
  //   try {
  //     int revS = reverseBits32(s);
  //     int notS = (~s) & 0xFFFFFFFF;
  //     int rotL14S = ((s << 14) | (s >> (32 - 14))) & 0xFFFFFFFF;
  //     int rotR10S = ((s >> 10) | (s << (32 - 10))) & 0xFFFFFFFF;
  //     int revRotR10S = reverseBits32(rotR10S);

  //     int notRotL13EK =
  //         (~(((ek << 13) | (ek >> (64 - 13))) & 0xFFFFFFFFFFFFFFFF)) &
  //         0xFFFFFFFFFFFFFFFF;
  //     int rotL31EK = ((ek << 31) | (ek >> (64 - 31))) & 0xFFFFFFFFFFFFFFFF;
  //     int notEK = (~ek) & 0xFFFFFFFFFFFFFFFF;

  //     int revEK = reverseBits64(ek);

  //     // Build concatenated hex string B
  //     String b =
  //         s.toRadixString(16).padLeft(8, '0') +
  //         ek.toRadixString(16).padLeft(16, '0') +
  //         revS.toRadixString(16).padLeft(8, '0') +
  //         notEK.toRadixString(16).padLeft(16, '0') +
  //         rotL14S.toRadixString(16).padLeft(8, '0') +
  //         revEK.toRadixString(16).padLeft(16, '0') +
  //         notS.toRadixString(16).padLeft(8, '0') +
  //         rotL31EK.toRadixString(16).padLeft(16, '0') +
  //         s.toRadixString(16).padLeft(8, '0') +
  //         notRotL13EK.toRadixString(16).padLeft(16, '0') +
  //         revRotR10S.toRadixString(16).padLeft(8, '0');

  //     // Convert hex to byte array
  //     List<int> bArray = hexStringToBytes(b).reversed.toList();

  //     // Compute RIPEMD160
  //     RIPEMD160Digest ripemd = RIPEMD160Digest();
  //     ripemd.update(bArray as Uint8List, 0, bArray.length);
  //     Uint8List d = Uint8List(ripemd.digestSize);
  //     ripemd.doFinal(d, 0);

  //     List<int> revD = d.reversed.toList();

  //     // Convert revD to binary string
  //     String revDBin = revD
  //         .map((b) => b.toRadixString(2).padLeft(8, '0'))
  //         .join();
  //     String dBin = revDBin.split('').reversed.join();

  //     // Extract bits for key
  //     List<int> positions = [
  //       19,
  //       74,
  //       59,
  //       78,
  //       0,
  //       26,
  //       89,
  //       77,
  //       144,
  //       107,
  //       47,
  //       134,
  //       61,
  //       88,
  //       58,
  //       135,
  //       121,
  //       95,
  //       29,
  //       158,
  //       81,
  //       54,
  //       70,
  //       115,
  //       46,
  //       3,
  //       44,
  //       123,
  //       39,
  //       157,
  //       30,
  //       90,
  //     ];

  //     String revKString = positions.map((i) => dBin[i]).join();
  //     String keyString = revKString.split('').reversed.join();

  //     int k = int.parse(keyString, radix: 2);

  //     List<int> kBytes = uint32ToBytes(k).reversed.toList();
  //     return kBytes;
  //   } catch (e) {
  //     return null;
  //   }
  // }
  List<int>? getREKey(int s, int ek) {
    try {
      final mask32 = BigInt.parse('FFFFFFFF', radix: 16);
      final mask64 = BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16);

      BigInt sBig = BigInt.from(s) & mask32;
      BigInt ekBig = BigInt.parse(
        ek.toRadixString(16).padLeft(16, '0'),
        radix: 16,
      );

      BigInt revS = BigInt.from(reverseBits32(s));
      BigInt notS = (~sBig) & mask32;
      BigInt notEK = (~ekBig) & mask64;
      String ekBinStr = ekBig.toRadixString(2).padLeft(64, '0');
      BigInt revEK = BigInt.parse(ekBinStr.split('').reversed.join(), radix: 2);
      BigInt rotL14S = ((sBig << 14) | (sBig >> (32 - 14))) & mask32;
      BigInt rotL31EK = ((ekBig << 31) | (ekBig >> (64 - 31))) & mask64;
      BigInt rotL13EK = ((ekBig << 13) | (ekBig >> (64 - 13))) & mask64;
      BigInt notRotL13EK = (~rotL13EK) & mask64;
      BigInt rotR10S = ((sBig >> 10) | (sBig << (32 - 10))) & mask32;
      BigInt revRotR10S = BigInt.from(reverseBits32(rotR10S.toInt()));

      String bHex =
          sBig.toRadixString(16).padLeft(8, '0') +
          ekBig.toRadixString(16).padLeft(16, '0') +
          revS.toRadixString(16).padLeft(8, '0') +
          notEK.toRadixString(16).padLeft(16, '0') +
          rotL14S.toRadixString(16).padLeft(8, '0') +
          revEK.toRadixString(16).padLeft(16, '0') +
          notS.toRadixString(16).padLeft(8, '0') +
          rotL31EK.toRadixString(16).padLeft(16, '0') +
          sBig.toRadixString(16).padLeft(8, '0') +
          notRotL13EK.toRadixString(16).padLeft(16, '0') +
          revRotR10S.toRadixString(16).padLeft(8, '0');

      List<int> bArray = hexStringToBytes(bHex).reversed.toList();

      RIPEMD160Digest ripemd = RIPEMD160Digest();
      ripemd.update(Uint8List.fromList(bArray), 0, bArray.length);
      Uint8List d = Uint8List(ripemd.digestSize);
      ripemd.doFinal(d, 0);

      List<int> revD = d.reversed.toList();
      String revDHex = revD
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      String revDBin = revDHex
          .split('')
          .map((c) => int.parse(c, radix: 16).toRadixString(2).padLeft(4, '0'))
          .join();
      String dBin = revDBin.split('').reversed.join();

      List<int> positions = [
        19,
        74,
        59,
        78,
        0,
        26,
        89,
        77,
        144,
        107,
        47,
        134,
        61,
        88,
        58,
        135,
        121,
        95,
        29,
        158,
        81,
        54,
        70,
        115,
        46,
        3,
        44,
        123,
        39,
        157,
        30,
        90,
      ];

      String keyBits = positions.map((i) => dBin[i]).join();
      keyBits = keyBits.split('').reversed.join();

      int k = int.parse(keyBits, radix: 2);
      return uint32ToBytes(k);
    } catch (e) {
      print("❌ getREKey error: $e");
      return null;
    }
  }

  int reverseBits32(int x) {
    int r = 0;
    for (int i = 0; i < 32; i++) {
      r |= ((x >> i) & 1) << (31 - i);
    }
    return r & 0xFFFFFFFF;
  }

  int reverseBits64(int x) {
    int r = 0;
    for (int i = 0; i < 64; i++) {
      r |= ((x >> i) & 1) << (63 - i);
    }
    return r & 0xFFFFFFFFFFFFFFFF;
  }

  List<int> hexStringToBytes(String hex) {
    hex = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    List<int> result = [];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  List<int> generateKeyForMonalisa(int seed, int mask) {
    int rotateLeft8(int value, int count) {
      return ((value << count) | (value >> (8 - count))) & 0xFF;
    }

    // --- Byte 1 ---
    int rotateVal1 = (seed & 0x00FF0000) >> 16;
    int rotateBy1 = mask & 0x07;
    int rotateResult1 = rotateLeft8(rotateVal1, rotateBy1);
    int nibbleVal1 = mask & 0x0F;
    if (nibbleVal1 >= 0x08) rotateResult1 = (~rotateResult1) & 0xFF;
    int xorWith1 = (mask & 0xFF000000) >> 24;
    int xorResult1 = rotateResult1 ^ xorWith1;

    // --- Byte 2 ---
    int rotateVal2 = seed & 0x000000FF;
    int rotateBy2 = (mask & 0x07000000) >> 24;
    int rotateResult2 = rotateLeft8(rotateVal2, rotateBy2);
    int nibbleVal2 = (mask & 0x0F000000) >> 24;
    if (nibbleVal2 >= 0x08) rotateResult2 = (~rotateResult2) & 0xFF;
    int xorWith2 = (mask & 0x00FF0000) >> 16;
    int xorResult2 = rotateResult2 ^ xorWith2;

    // --- Byte 3 ---
    int rotateVal3 = (seed & 0xFF000000) >> 24;
    int rotateBy3 = (mask & 0x0700) >> 8;
    int rotateResult3 = rotateLeft8(rotateVal3, rotateBy3);
    int nibbleVal3 = (mask & 0x0F00) >> 8;
    if (nibbleVal3 >= 0x08) rotateResult3 = (~rotateResult3) & 0xFF;
    int xorWith3 = (mask & 0xFF00) >> 8;
    int xorResult3 = rotateResult3 ^ xorWith3;

    // --- Byte 4 ---
    int rotateVal4 = (seed & 0xFF00) >> 8;
    int rotateBy4 = (mask & 0x070000) >> 16;
    int rotateResult4 = rotateLeft8(rotateVal4, rotateBy4);
    int nibbleVal4 = (mask & 0x0F0000) >> 16;
    if (nibbleVal4 >= 0x08) rotateResult4 = (~rotateResult4) & 0xFF;
    int xorWith4 = mask & 0xFF;
    int xorResult4 = rotateResult4 ^ xorWith4;

    // Combine bytes
    int key1 =
        ((xorResult1 << 24) |
            (xorResult2 << 16) |
            (xorResult3 << 8) |
            xorResult4) &
        0xFFFFFFFF;

    // Convert to byte array and reverse
    List<int> key = [
      (key1 >> 24) & 0xFF,
      (key1 >> 16) & 0xFF,
      (key1 >> 8) & 0xFF,
      key1 & 0xFF,
    ].reversed.toList();

    return key;
  }

  List<int> calculateSeedForVECV01(List<int> seedArray) {
    try {
      int P = 2869;
      int Q = 52143;
      int R = 3740;
      int S = 42301;

      int NX, LX;
      // Convert seed array to hex string then to integer
      String seedHex = seedArray
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      int MX = int.parse(seedHex, radix: 16);

      // 50 iterations
      for (int i = 1; i <= 50; i++) {
        NX = ((P * MX - Q) & 0xFFFF);
        MX = (NX ^ S) & 0xFFFF;
      }

      LX = (65536 - MX) & 0xFFFF;
      int key = ((LX ^ S) + R) & 0xFFFF;

      // Convert to 2-byte array (big endian)
      List<int> keyArray = [(key >> 8) & 0xFF, key & 0xFF];

      return keyArray;
    } catch (e) {
      return [];
    }
  }

  List<int> calculateSeedForAMTBS46(List<int> seedKey, String mode) {
    // Algorithm parameters
    List<int> para;
    if (mode == "SEEDKEY_AMT_BS46_PROG") {
      para = [0xC61E70E0, 0xAEECA97A, 0xA36F4397, 0xA5A23B39, 0x00000040];
    } else {
      para = [0x59F24A44, 0xFC5B578D, 0xF1DCEFAA, 0x3878149B, 0x00000040];
    }

    int v0 =
        ((seedKey[0] << 24) |
            (seedKey[1] << 16) |
            (seedKey[2] << 8) |
            seedKey[3]) &
        0xFFFFFFFF;
    int v1 =
        ((seedKey[4] << 24) |
            (seedKey[5] << 16) |
            (seedKey[6] << 8) |
            seedKey[7]) &
        0xFFFFFFFF;

    int sum = 0;
    int noOfRounds = para[4];

    for (int i = 0; i < noOfRounds; i++) {
      v0 =
          (v0 + ((((v1 << 4) & 0xFFFFFFFF) ^ (v1 >> 5)) + v1) ^
              (sum + para[sum & 3])) &
          0xFFFFFFFF;
      sum = (sum + 0x9E3779B9) & 0xFFFFFFFF;
      v1 =
          (v1 + ((((v0 << 4) & 0xFFFFFFFF) ^ (v0 >> 5)) + v0) ^
              (sum + para[(sum >> 11) & 3])) &
          0xFFFFFFFF;
    }

    // Write back v0 and v1 into seedKey array (big-endian)
    seedKey[0] = (v0 >> 24) & 0xFF;
    seedKey[1] = (v0 >> 16) & 0xFF;
    seedKey[2] = (v0 >> 8) & 0xFF;
    seedKey[3] = v0 & 0xFF;

    seedKey[4] = (v1 >> 24) & 0xFF;
    seedKey[5] = (v1 >> 16) & 0xFF;
    seedKey[6] = (v1 >> 8) & 0xFF;
    seedKey[7] = v1 & 0xFF;

    return seedKey;
  }

  List<int> seedKeyForAMTBS4(List<int> seedArray, String ecu) {
    int p1 = 0;
    int p2 = 0;

    if (ecu == "EBS") {
      p1 = 0x24669CC3;
      p2 = 0x98672EE1;
    } else {
      p1 = 0x2B61E547;
      p2 = 0x75EC6D43;
    }

    // Reverse seed array (big-endian)
    List<int> reversedSeed = List.from(seedArray.reversed);
    int seed =
        (reversedSeed[0] << 24) |
        (reversedSeed[1] << 16) |
        (reversedSeed[2] << 8) |
        reversedSeed[3];

    // High and Low words
    int KH1 = (seed >> 16) & 0xFFFF;
    int KL1 = seed & 0xFFFF;
    int KH2 = 0;
    int KL2 = 0;

    for (int i = 0; i < 5; i++) {
      KH2 = KH1 ^ (~KL1 & 0xFFFF);
      KL2 = ((((p1 >> 16) & 0xFFFF) * KL1 + (p1 & 0xFFFF)) & 0xFFFF) ^ KH1;
      KH1 = (KH2 >> 1) ^ ((p2 >> 16) & 0xFFFF);
      KL1 = KL2 ^ (p2 & 0xFFFF);
    }

    int key = ((KH2 << 16) | KL2) & 0xFFFFFFFF;

    // Convert to byte array (big-endian)
    List<int> keyArray = [
      (key >> 24) & 0xFF,
      (key >> 16) & 0xFF,
      (key >> 8) & 0xFF,
      key & 0xFF,
    ];

    return keyArray;
  }

  int rotateLeft(int rotateVal, int rotateBy) {
    // Ensure we only work with 8-bit values
    rotateVal &= 0xFF;
    rotateBy &= 0x07; // rotation for 8-bit, max 7

    int result =
        ((rotateVal << rotateBy) | (rotateVal >> (8 - rotateBy))) & 0xFF;
    return result;
  }

  String stringReverse(String s) {
    return s.split('').reversed.join('');
  }
}
