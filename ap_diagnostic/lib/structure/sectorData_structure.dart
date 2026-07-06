import 'dart:typed_data';

/// Maps to APDiagnostic.Structures.sectordata
class SectorData {
  int startAddress;
  int noOfBytes;
  Uint8List byteArray;
  int sectorChecksum;

  SectorData({
    required this.startAddress,
    required this.noOfBytes,
    required this.byteArray,
    required this.sectorChecksum,
  });
}

enum EraseSectorEnum {
  none,
  eraseAllAtOnce,
  eraseBySector,
  eraseAllAtOnceWoAddr, ENABLED,
}

enum ChecksumSectorEnum {
  none,
  compare2ByteSimpleAddBySector,
  compareCrc16CcittBySector,
  computeBySector,
  noChecksumBySector,
  compareBySector,
  noChecksum,
  compareBySectorWoAddrCrcCcitt16, ENABLED,
}