class AllModel {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  AllModel({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory AllModel.fromJson(Map<String, dynamic> json) => AllModel(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: json["results"] == null
            ? []
            : List<Result>.from(
                json["results"]!.map((x) => Result.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class Result {
  int? id;
  int? oem;
  String? name;
  dynamic voltage;
  String? modelFile;
  List<SubModel>? subModels;

  Result({
    this.id,
    this.oem,
    this.name,
    this.voltage,
    this.modelFile,
    this.subModels,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        oem: json["oem"],
        name: json["name"],
        voltage: json["voltage"],
        modelFile: json["model_file"],
        subModels: json["sub_models"] == null
            ? []
            : List<SubModel>.from(
                json["sub_models"]!.map((x) => SubModel.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "oem": oem,
        "name": name,
        "voltage": voltage,
        "model_file": modelFile,
        "sub_models": subModels == null
            ? []
            : List<dynamic>.from(subModels!.map((x) => x.toJson())),
      };
}

class SubModel {
  int? id;
  String? name;
  dynamic segment;
  String? modelYear;
  dynamic subModelFile;
  // Was a closed enum with only "ACTIVE" — kept as String so any status
  // the API returns (e.g. "INACTIVE", "PENDING") doesn't crash parsing.
  String? injectorCharectorization;
  String? password;
  List<dynamic>? runTimeLicenses;
  bool? isActive;
  List<SubmodelModelecu>? submodelModelecu;

  SubModel({
    this.id,
    this.name,
    this.segment,
    this.modelYear,
    this.subModelFile,
    this.injectorCharectorization,
    this.password,
    this.runTimeLicenses,
    this.isActive,
    this.submodelModelecu,
  });

  factory SubModel.fromJson(Map<String, dynamic> json) => SubModel(
        id: json["id"],
        name: json["name"],
        segment: json["segment"],
        modelYear: json["model_year"],
        subModelFile: json["sub_model_file"],
        injectorCharectorization: json["injector_charectorization"],
        password: json["password"],
        runTimeLicenses: json["run_time_licenses"] == null
            ? []
            : List<dynamic>.from(json["run_time_licenses"]!.map((x) => x)),
        isActive: json["is_active"],
        submodelModelecu: json["submodel_modelecu"] == null
            ? []
            : List<SubmodelModelecu>.from(json["submodel_modelecu"]!
                .map((x) => SubmodelModelecu.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "segment": segment,
        "model_year": modelYear,
        "sub_model_file": subModelFile,
        "injector_charectorization": injectorCharectorization,
        "password": password,
        "run_time_licenses": runTimeLicenses == null
            ? []
            : List<dynamic>.from(runTimeLicenses!.map((x) => x)),
        "is_active": isActive,
        "submodel_modelecu": submodelModelecu == null
            ? []
            : List<dynamic>.from(submodelModelecu!.map((x) => x.toJson())),
      };
}

class SubmodelModelecu {
  int? id;
  Ecu? ecu;
  List<Dataset>? datasets;
  List<Dataset>? pidDatasets;
  List<dynamic>? ivnDtcDatasets;
  List<dynamic>? ivnPidDatasets;
  FlashFile? flashFile;
  // Was a closed enum with only "1,2,3"/"1,3,4,2" — any other injector
  // count/order (5-cyl, 6-cyl, different order) would crash parsing.
  String? firingSequence;
  int? noOfInjectors;
  List<String>? routineTest;

  SubmodelModelecu({
    this.id,
    this.ecu,
    this.datasets,
    this.pidDatasets,
    this.ivnDtcDatasets,
    this.ivnPidDatasets,
    this.flashFile,
    this.firingSequence,
    this.noOfInjectors,
    this.routineTest,
  });

  factory SubmodelModelecu.fromJson(Map<String, dynamic> json) =>
      SubmodelModelecu(
        id: json["id"],
        ecu: json["ecu"] == null ? null : Ecu.fromJson(json["ecu"]),
        datasets: json["datasets"] == null
            ? []
            : List<Dataset>.from(
                json["datasets"]!.map((x) => Dataset.fromJson(x))),
        pidDatasets: json["pid_datasets"] == null
            ? []
            : List<Dataset>.from(
                json["pid_datasets"]!.map((x) => Dataset.fromJson(x))),
        ivnDtcDatasets: json["ivn_dtc_datasets"] == null
            ? []
            : List<dynamic>.from(json["ivn_dtc_datasets"]!.map((x) => x)),
        ivnPidDatasets: json["ivn_pid_datasets"] == null
            ? []
            : List<dynamic>.from(json["ivn_pid_datasets"]!.map((x) => x)),
        flashFile: json["flash_file"] == null
            ? null
            : FlashFile.fromJson(json["flash_file"]),
        firingSequence: json["firing_sequence"],
        noOfInjectors: json["no_of_injectors"],
        routineTest: json["routine_test"] == null
            ? []
            : List<String>.from(json["routine_test"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "ecu": ecu?.toJson(),
        "datasets": datasets == null
            ? []
            : List<dynamic>.from(datasets!.map((x) => x.toJson())),
        "pid_datasets": pidDatasets == null
            ? []
            : List<dynamic>.from(pidDatasets!.map((x) => x.toJson())),
        "ivn_dtc_datasets": ivnDtcDatasets == null
            ? []
            : List<dynamic>.from(ivnDtcDatasets!.map((x) => x)),
        "ivn_pid_datasets": ivnPidDatasets == null
            ? []
            : List<dynamic>.from(ivnPidDatasets!.map((x) => x)),
        "flash_file": flashFile?.toJson(),
        "firing_sequence": firingSequence,
        "no_of_injectors": noOfInjectors,
        "routine_test": routineTest == null
            ? []
            : List<dynamic>.from(routineTest!.map((x) => x)),
      };
}

class Dataset {
  int? id;
  String? code;

  Dataset({
    this.id,
    this.code,
  });

  factory Dataset.fromJson(Map<String, dynamic> json) => Dataset(
        id: json["id"],
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
      };
}

class Ecu {
  int? id;
  // Was a closed enum with only MD1CC878/MD1CS162 — any new ECU model name
  // from the API would crash parsing. Free text, matches real-world usage.
  String? name;
  int? priority;
  // Was closed enums keyed to literal "07E0"/"07E8" — these are exactly the
  // fields your dllFunctions code (setDongleProperties, canSetTxHeader, etc.)
  // needs as raw hex strings. Any new ECU with a different header would have
  // crashed parsing before reaching your flashing code at all.
  String? txHeader;
  String? rxHeader;
  dynamic readWritePidByAddr;
  // Was a closed enum with only "CHANNEL-0" — any other channel string
  // would crash parsing.
  String? channel;
  Protocol? protocol;
  FnIndex? readDtcFnIndex;
  FnIndex? clearDtcFnIndex;
  FnIndex? readDataFnIndex;
  FnIndex? writeDataFnIndex;
  FnIndex? seedkeyalgoFnIndex;
  int? ffSet;
  FnIndex? iorTestFnIndex;

  Ecu({
    this.id,
    this.name,
    this.priority,
    this.txHeader,
    this.rxHeader,
    this.readWritePidByAddr,
    this.channel,
    this.protocol,
    this.readDtcFnIndex,
    this.clearDtcFnIndex,
    this.readDataFnIndex,
    this.writeDataFnIndex,
    this.seedkeyalgoFnIndex,
    this.ffSet,
    this.iorTestFnIndex,
  });

  factory Ecu.fromJson(Map<String, dynamic> json) => Ecu(
        id: json["id"],
        name: json["name"],
        priority: json["priority"],
        txHeader: json["tx_header"],
        rxHeader: json["rx_header"],
        readWritePidByAddr: json["read_write_pid_by_addr"],
        channel: json["channel"],
        protocol: json["protocol"] == null
            ? null
            : Protocol.fromJson(json["protocol"]),
        readDtcFnIndex: json["read_dtc_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["read_dtc_fn_index"]),
        clearDtcFnIndex: json["clear_dtc_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["clear_dtc_fn_index"]),
        readDataFnIndex: json["read_data_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["read_data_fn_index"]),
        writeDataFnIndex: json["write_data_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["write_data_fn_index"]),
        seedkeyalgoFnIndex: json["seedkeyalgo_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["seedkeyalgo_fn_index"]),
        ffSet: json["ff_set"],
        iorTestFnIndex: json["ior_test_fn_index"] == null
            ? null
            : FnIndex.fromJson(json["ior_test_fn_index"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "priority": priority,
        "tx_header": txHeader,
        "rx_header": rxHeader,
        "read_write_pid_by_addr": readWritePidByAddr,
        "channel": channel,
        "protocol": protocol?.toJson(),
        "read_dtc_fn_index": readDtcFnIndex?.toJson(),
        "clear_dtc_fn_index": clearDtcFnIndex?.toJson(),
        "read_data_fn_index": readDataFnIndex?.toJson(),
        "write_data_fn_index": writeDataFnIndex?.toJson(),
        "seedkeyalgo_fn_index": seedkeyalgoFnIndex?.toJson(),
        "ff_set": ffSet,
        "ior_test_fn_index": iorTestFnIndex?.toJson(),
      };
}

class FnIndex {
  // Was a closed enum (Value) requiring every seed-key/UDS function name to
  // be pre-registered here. New security algorithms or function indexes
  // from the API would otherwise crash parsing before you could even see
  // what value came back.
  String? value;

  FnIndex({
    this.value,
  });

  factory FnIndex.fromJson(Map<String, dynamic> json) => FnIndex(
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "value": value,
      };
}

class Protocol {
  // Was a closed enum with only ISO15765_1MB_11BIT_CAN — this is exactly
  // the field setDongleProperties1() uses for Protocol.values.firstWhere(),
  // so it needs to be a plain String to match against Protocol (comm-layer
  // enum) by name, and to not crash on any new protocol the API adds.
  String? name;
  dynamic elm;
  String? autopeepal;

  Protocol({
    this.name,
    this.elm,
    this.autopeepal,
  });

  factory Protocol.fromJson(Map<String, dynamic> json) => Protocol(
        name: json["name"],
        elm: json["elm"],
        autopeepal: json["autopeepal"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "elm": elm,
        "autopeepal": autopeepal,
      };
}

// class FlashFile {
//   int? id;
//   String? sequenceFileName;
//   String? sequenceFile;
//   List<FileElement>? file;
//   Protocol? protocol;
//   String? txHeader;
//   String? rxHeader;
//   dynamic flashDiagnosticMode;
//   dynamic flashSeedKeyLength;
//   dynamic flashAddressDataFormat;
//   dynamic flashEraseType;
//   dynamic flashFraseByte;
//   dynamic flashNaxBlkseqcntr;
//   dynamic flashsepTime;
//   dynamic flashCheckSumType;
//   dynamic flashStatus;
//   String? sectorframetransferlen;
//   String? sendseedbyte;
//   List<dynamic>? ecuMapFile;

//   FlashFile({
//     this.id,
//     this.sequenceFileName,
//     this.sequenceFile,
//     this.file,
//     this.protocol,
//     this.txHeader,
//     this.rxHeader,
//     this.flashDiagnosticMode,
//     this.flashSeedKeyLength,
//     this.flashAddressDataFormat,
//     this.flashEraseType,
//     this.flashFraseByte,
//     this.flashNaxBlkseqcntr,
//     this.flashsepTime,
//     this.flashCheckSumType,
//     this.flashStatus,
//     this.sectorframetransferlen,
//     this.sendseedbyte,
//     this.ecuMapFile,
//   });

//   factory FlashFile.fromJson(Map<String, dynamic> json) => FlashFile(
//         id: json["id"],
//         sequenceFileName: json["sequence_file_name"]?.toString(),
//         sequenceFile: json["sequence_file"],
//         file: json["file"] == null
//             ? []
//             : List<FileElement>.from(
//                 json["file"]!.map((x) => FileElement.fromJson(x))),
//         protocol: json["protocol"] == null
//             ? null
//             : Protocol.fromJson(json["protocol"]),
//         txHeader: json["tx_header"],
//         rxHeader: json["rx_header"],
//         flashDiagnosticMode: json["flash_diagnostic_mode"],
//         flashSeedKeyLength: json["flash_seed_key_length"],
//         flashAddressDataFormat: json["flash_address_data_format"],
//         flashEraseType: json["flash_erase_type"],
//         flashFraseByte: json["flash_frase_byte"],
//         flashNaxBlkseqcntr: json["flash_nax_blkseqcntr"],
//         flashsepTime: json["flashsep_time"],
//         flashCheckSumType: json["flash_check_sum_type"],
//         flashStatus: json["flash_status"],
//         sectorframetransferlen: json["sectorframetransferlen"],
//         sendseedbyte: json["sendseedbyte"],
//         ecuMapFile: json["ecu_map_file"] == null
//             ? []
//             : List<dynamic>.from(json["ecu_map_file"]!.map((x) => x)),
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "sequence_file_name": sequenceFileName,
//         "sequence_file": sequenceFile,
//         "file": file == null
//             ? []
//             : List<dynamic>.from(file!.map((x) => x.toJson())),
//         "protocol": protocol?.toJson(),
//         "tx_header": txHeader,
//         "rx_header": rxHeader,
//         "flash_diagnostic_mode": flashDiagnosticMode,
//         "flash_seed_key_length": flashSeedKeyLength,
//         "flash_address_data_format": flashAddressDataFormat,
//         "flash_erase_type": flashEraseType,
//         "flash_frase_byte": flashFraseByte,
//         "flash_nax_blkseqcntr": flashNaxBlkseqcntr,
//         "flashsep_time": flashsepTime,
//         "flash_check_sum_type": flashCheckSumType,
//         "flash_status": flashStatus,
//         "sectorframetransferlen": sectorframetransferlen,
//         "sendseedbyte": sendseedbyte,
//         "ecu_map_file": ecuMapFile == null
//             ? []
//             : List<dynamic>.from(ecuMapFile!.map((x) => x)),
//       };
// }

class FileElement {
  int? id;
  int? sequenceFileName;
  String? swPartNo;
  String? dataFileName;
  String? dataFile;
  String? hexSrecFile;

  FileElement({
    this.id,
    this.sequenceFileName,
    this.swPartNo,
    this.dataFileName,
    this.dataFile,
    this.hexSrecFile,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
        id: json["id"],
        sequenceFileName: json["sequence_file_name"],
        swPartNo: json["sw_part_no"],
        dataFileName: json["data_file_name"],
        dataFile: json["data_file"],
        hexSrecFile: json["hex_srec_file"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sequence_file_name": sequenceFileName,
        "sw_part_no": swPartNo,
        "data_file_name": dataFileName,
        "data_file": dataFile,
        "hex_srec_file": hexSrecFile,
      };
}

/// Represents one flashable memory-address sector for an ECU, as returned
/// directly by the API under flash_file.ecu_map_file / ecu2.ecu_map_file.
class EcuMapFile {
  int? id;
  String? startAddress;
  int? startAddr;
  String? endAddress;
  int? endAddr;
  String? sectorName;
  int? priority;

  EcuMapFile({
    this.id,
    this.startAddress,
    this.startAddr,
    this.endAddress,
    this.endAddr,
    this.sectorName,
    this.priority,
  });

  factory EcuMapFile.fromJson(Map<String, dynamic> json) {
    final String? startAddressStr = json["start_address"];
    final String? endAddressStr = json["end_address"];

    // 🔧 FIX: derive startAddr/endAddr from the hex string fields
    // (start_address/end_address) instead of trusting the API's separate
    // start_addr/end_addr numeric fields directly. Those two numeric
    // fields have been observed to diverge from the hex string for at
    // least one variant — e.g. start_address="08FD8000" (correct, matches
    // the flash sequence file) while start_addr held a completely
    // different value (~0x0060C000), causing RequestDownload (UDS 0x34)
    // to target the wrong ECU memory range and fail with
    // ECUERROR_REQUESTOUTOFRANGE (NRC 0x31). Parsing from the hex string
    // ourselves removes the dependency on that second field being kept
    // in sync on the backend.
    int? parsedStartAddr = startAddressStr != null
        ? int.tryParse(startAddressStr, radix: 16)
        : null;
    int? parsedEndAddr = endAddressStr != null
        ? int.tryParse(endAddressStr, radix: 16)
        : null;

    // If parsing the hex string failed for some reason (null/malformed),
    // fall back to whatever the API's numeric field provided rather than
    // silently producing a null address.
    parsedStartAddr ??= json["start_addr"];
    parsedEndAddr ??= json["end_addr"];

    return EcuMapFile(
      id: json["id"],
      startAddress: startAddressStr,
      startAddr: parsedStartAddr,
      endAddress: endAddressStr,
      endAddr: parsedEndAddr,
      sectorName: json["sector_name"],
      priority: json["priority"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "start_address": startAddress,
        "start_addr": startAddr,
        "end_address": endAddress,
        "end_addr": endAddr,
        "sector_name": sectorName,
        "priority": priority,
      };
}

class FlashFile {
  int? id;
  String? sequenceFileName;
  String? sequenceFile;
  List<FileElement>? file;
  Protocol? protocol;
  String? txHeader;
  String? rxHeader;
  dynamic flashDiagnosticMode;
  dynamic flashSeedKeyLength;
  dynamic flashAddressDataFormat;
  dynamic flashEraseType;
  dynamic flashFraseByte;
  dynamic flashNaxBlkseqcntr;
  dynamic flashsepTime;
  dynamic flashCheckSumType;
  dynamic flashStatus;
  String? sectorframetransferlen;
  String? sendseedbyte;
  // Was List<dynamic> — now properly typed against the real API shape,
  // matching EcuMapFile.fromJson above (id/start_addr/end_addr/sector_name/priority).
  List<EcuMapFile>? ecuMapFile;

  FlashFile({
    this.id,
    this.sequenceFileName,
    this.sequenceFile,
    this.file,
    this.protocol,
    this.txHeader,
    this.rxHeader,
    this.flashDiagnosticMode,
    this.flashSeedKeyLength,
    this.flashAddressDataFormat,
    this.flashEraseType,
    this.flashFraseByte,
    this.flashNaxBlkseqcntr,
    this.flashsepTime,
    this.flashCheckSumType,
    this.flashStatus,
    this.sectorframetransferlen,
    this.sendseedbyte,
    this.ecuMapFile,
  });

  factory FlashFile.fromJson(Map<String, dynamic> json) => FlashFile(
        id: json["id"],
        sequenceFileName: json["sequence_file_name"]?.toString(),
        sequenceFile: json["sequence_file"],
        file: json["file"] == null
            ? []
            : List<FileElement>.from(
                json["file"]!.map((x) => FileElement.fromJson(x))),
        protocol: json["protocol"] == null
            ? null
            : Protocol.fromJson(json["protocol"]),
        txHeader: json["tx_header"],
        rxHeader: json["rx_header"],
        flashDiagnosticMode: json["flash_diagnostic_mode"],
        flashSeedKeyLength: json["flash_seed_key_length"],
        flashAddressDataFormat: json["flash_address_data_format"],
        flashEraseType: json["flash_erase_type"],
        flashFraseByte: json["flash_frase_byte"],
        flashNaxBlkseqcntr: json["flash_nax_blkseqcntr"],
        flashsepTime: json["flashsep_time"],
        flashCheckSumType: json["flash_check_sum_type"],
        flashStatus: json["flash_status"],
        sectorframetransferlen: json["sectorframetransferlen"],
        sendseedbyte: json["sendseedbyte"],
        ecuMapFile: json["ecu_map_file"] == null
            ? []
            : List<EcuMapFile>.from(
                json["ecu_map_file"]!.map((x) => EcuMapFile.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sequence_file_name": sequenceFileName,
        "sequence_file": sequenceFile,
        "file": file == null
            ? []
            : List<dynamic>.from(file!.map((x) => x.toJson())),
        "protocol": protocol?.toJson(),
        "tx_header": txHeader,
        "rx_header": rxHeader,
        "flash_diagnostic_mode": flashDiagnosticMode,
        "flash_seed_key_length": flashSeedKeyLength,
        "flash_address_data_format": flashAddressDataFormat,
        "flash_erase_type": flashEraseType,
        "flash_frase_byte": flashFraseByte,
        "flash_nax_blkseqcntr": flashNaxBlkseqcntr,
        "flashsep_time": flashsepTime,
        "flash_check_sum_type": flashCheckSumType,
        "flash_status": flashStatus,
        "sectorframetransferlen": sectorframetransferlen,
        "sendseedbyte": sendseedbyte,
        "ecu_map_file": ecuMapFile == null
            ? []
            : List<dynamic>.from(ecuMapFile!.map((x) => x.toJson())),
      };
}