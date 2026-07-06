import 'package:ap_diagnostic/enum/flashIndexTypes.dart';
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/structure/sectorData_structure.dart';

/// Maps to APDiagnostic.Structures.flashconfig
class FlashConfig {
  FlashIndexType? flashIndex;
  int? diagMode;
  int? sendSeedByte;
  int? seedKeyNumBytes;
  SEEDKEYINDEXTYPE? seedKeyIndex;
  String? addrDataFormat;
  int? sectorFrameTransferLen;
  int? sepTime;
  EraseSectorEnum? eraseSector;
  ChecksumSectorEnum? checksumSector;
  String? flashStatus;

  FlashConfig({
     this.flashIndex,
     this.diagMode,
     this.sendSeedByte,
     this.seedKeyNumBytes,
     this.seedKeyIndex,
     this.addrDataFormat,
     this.sectorFrameTransferLen,
     this.sepTime,
     this.eraseSector,
     this.checksumSector,
    this.flashStatus,
  });
}

