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
  InjectorCharectorization? injectorCharectorization;
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
        injectorCharectorization: injectorCharectorizationValues
            .map[json["injector_charectorization"]]!,
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
        "injector_charectorization":
            injectorCharectorizationValues.reverse[injectorCharectorization],
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

enum InjectorCharectorization { ACTIVE }

final injectorCharectorizationValues =
    EnumValues({"ACTIVE": InjectorCharectorization.ACTIVE});

class SubmodelModelecu {
  int? id;
  Ecu? ecu;
  List<Dataset>? datasets;
  List<Dataset>? pidDatasets;
  List<dynamic>? ivnDtcDatasets;
  List<dynamic>? ivnPidDatasets;
  FlashFile? flashFile;
  FiringSequence? firingSequence;
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
        firingSequence: firingSequenceValues.map[json["firing_sequence"]]!,
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
        "firing_sequence": firingSequenceValues.reverse[firingSequence],
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
  SequenceFileNameEnum? name;
  int? priority;
  TxHeader? txHeader;
  RxHeader? rxHeader;
  dynamic readWritePidByAddr;
  Channel? channel;
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
        name: sequenceFileNameEnumValues.map[json["name"]]!,
        priority: json["priority"],
        txHeader: txHeaderValues.map[json["tx_header"]]!,
        rxHeader: rxHeaderValues.map[json["rx_header"]]!,
        readWritePidByAddr: json["read_write_pid_by_addr"],
        channel: channelValues.map[json["channel"]]!,
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
        "name": sequenceFileNameEnumValues.reverse[name],
        "priority": priority,
        "tx_header": txHeaderValues.reverse[txHeader],
        "rx_header": rxHeaderValues.reverse[rxHeader],
        "read_write_pid_by_addr": readWritePidByAddr,
        "channel": channelValues.reverse[channel],
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

enum Channel { CHANNEL_0 }

final channelValues = EnumValues({"CHANNEL-0": Channel.CHANNEL_0});

class FnIndex {
  Value? value;

  FnIndex({
    this.value,
  });

  factory FnIndex.fromJson(Map<String, dynamic> json) => FnIndex(
        value: valueValues.map[json["value"]]!,
      );

  Map<String, dynamic> toJson() => {
        "value": valueValues.reverse[value],
      };
}

enum Value {
  SIMPSON_MD1_CC878_SECURITY,
  SIMPSON_MDCS162_SECURITY,
  UDS,
  UDS_3_BYTE_DTC,
  UDS_4_BYTES,
  UDS_DS1003_SK0102
}

final valueValues = EnumValues({
  "SIMPSON_MD1CC878_SECURITY": Value.SIMPSON_MD1_CC878_SECURITY,
  "SIMPSON_MDCS162_SECURITY": Value.SIMPSON_MDCS162_SECURITY,
  "UDS": Value.UDS,
  "UDS_3BYTE_DTC": Value.UDS_3_BYTE_DTC,
  "UDS_4BYTES": Value.UDS_4_BYTES,
  "UDS_DS1003_SK0102": Value.UDS_DS1003_SK0102
});

enum SequenceFileNameEnum { MD1_CC878, MD1_CS162 }

final sequenceFileNameEnumValues = EnumValues({
  "MD1CC878": SequenceFileNameEnum.MD1_CC878,
  "MD1CS162": SequenceFileNameEnum.MD1_CS162
});

class Protocol {
  ProtocolName? name;
  dynamic elm;
  String? autopeepal;

  Protocol({
    this.name,
    this.elm,
    this.autopeepal,
  });

  factory Protocol.fromJson(Map<String, dynamic> json) => Protocol(
        name: protocolNameValues.map[json["name"]]!,
        elm: json["elm"],
        autopeepal: json["autopeepal"],
      );

  Map<String, dynamic> toJson() => {
        "name": protocolNameValues.reverse[name],
        "elm": elm,
        "autopeepal": autopeepal,
      };
}

enum ProtocolName { ISO15765_1_MB_11_BIT_CAN }

final protocolNameValues = EnumValues(
    {"ISO15765_1MB_11BIT_CAN": ProtocolName.ISO15765_1_MB_11_BIT_CAN});

enum RxHeader { THE_07_E8 }

final rxHeaderValues = EnumValues({"07E8": RxHeader.THE_07_E8});

enum TxHeader { THE_07_E0 }

final txHeaderValues = EnumValues({"07E0": TxHeader.THE_07_E0});

enum FiringSequence { THE_123, THE_1342 }

final firingSequenceValues = EnumValues(
    {"1,2,3": FiringSequence.THE_123, "1,3,4,2": FiringSequence.THE_1342});

class FlashFile {
  int? id;
  SequenceFileNameEnum? sequenceFileName;
  String? sequenceFile;
  List<FileElement>? file;
  Protocol? protocol;
  TxHeader? txHeader;
  RxHeader? rxHeader;
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
  List<dynamic>? ecuMapFile;

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
        sequenceFileName:
            sequenceFileNameEnumValues.map[json["sequence_file_name"]]!,
        sequenceFile: json["sequence_file"],
        file: json["file"] == null
            ? []
            : List<FileElement>.from(
                json["file"]!.map((x) => FileElement.fromJson(x))),
        protocol: json["protocol"] == null
            ? null
            : Protocol.fromJson(json["protocol"]),
        txHeader: txHeaderValues.map[json["tx_header"]]!,
        rxHeader: rxHeaderValues.map[json["rx_header"]]!,
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
            : List<dynamic>.from(json["ecu_map_file"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sequence_file_name":
            sequenceFileNameEnumValues.reverse[sequenceFileName],
        "sequence_file": sequenceFile,
        "file": file == null
            ? []
            : List<dynamic>.from(file!.map((x) => x.toJson())),
        "protocol": protocol?.toJson(),
        "tx_header": txHeaderValues.reverse[txHeader],
        "rx_header": rxHeaderValues.reverse[rxHeader],
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
            : List<dynamic>.from(ecuMapFile!.map((x) => x)),
      };
}

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

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
