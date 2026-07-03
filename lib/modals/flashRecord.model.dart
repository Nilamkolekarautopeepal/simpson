class FlashRecord {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  FlashRecord({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory FlashRecord.fromJson(Map<String, dynamic> json) => FlashRecord(
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
  String? sequenceFileName;
  int? ecu;
  String? sequenceFile;
  Protocol? protocol;
  String? txHeader;
  String? rxHeader;
  String? sectorframetransferlen;
  bool? isActive;
  String? addressDataFormat;
  dynamic defaultEraseByte;
  dynamic sendChecksumMethod;
  dynamic flashDiagnosticMode;
  String? sendseedbyte;
  dynamic flashSeedKeyLength;
  dynamic flashAddressDataFormat;
  dynamic flashEraseType;
  dynamic flashFraseByte;
  dynamic flashNaxBlkseqcntr;
  dynamic flashsepTime;
  dynamic flashCheckSumType;
  dynamic flashStatus;
  List<FileElement>? file;

  Result({
    this.id,
    this.sequenceFileName,
    this.ecu,
    this.sequenceFile,
    this.protocol,
    this.txHeader,
    this.rxHeader,
    this.sectorframetransferlen,
    this.isActive,
    this.addressDataFormat,
    this.defaultEraseByte,
    this.sendChecksumMethod,
    this.flashDiagnosticMode,
    this.sendseedbyte,
    this.flashSeedKeyLength,
    this.flashAddressDataFormat,
    this.flashEraseType,
    this.flashFraseByte,
    this.flashNaxBlkseqcntr,
    this.flashsepTime,
    this.flashCheckSumType,
    this.flashStatus,
    this.file,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        sequenceFileName: json["sequence_file_name"],
        ecu: json["ecu"],
        sequenceFile: json["sequence_file"],
        protocol: json["protocol"] == null
            ? null
            : Protocol.fromJson(json["protocol"]),
        txHeader: json["tx_header"],
        rxHeader: json["rx_header"],
        sectorframetransferlen: json["sectorframetransferlen"],
        isActive: json["is_active"],
        addressDataFormat: json["address_data_format"],
        defaultEraseByte: json["default_erase_byte"],
        sendChecksumMethod: json["send_checksum_method"],
        flashDiagnosticMode: json["flash_diagnostic_mode"],
        sendseedbyte: json["sendseedbyte"],
        flashSeedKeyLength: json["flash_seed_key_length"],
        flashAddressDataFormat: json["flash_address_data_format"],
        flashEraseType: json["flash_erase_type"],
        flashFraseByte: json["flash_frase_byte"],
        flashNaxBlkseqcntr: json["flash_nax_blkseqcntr"],
        flashsepTime: json["flashsep_time"],
        flashCheckSumType: json["flash_check_sum_type"],
        flashStatus: json["flash_status"],
        file: json["file"] == null
            ? []
            : List<FileElement>.from(
                json["file"]!.map((x) => FileElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sequence_file_name": sequenceFileName,
        "ecu": ecu,
        "sequence_file": sequenceFile,
        "protocol": protocol?.toJson(),
        "tx_header": txHeader,
        "rx_header": rxHeader,
        "sectorframetransferlen": sectorframetransferlen,
        "is_active": isActive,
        "address_data_format": addressDataFormat,
        "default_erase_byte": defaultEraseByte,
        "send_checksum_method": sendChecksumMethod,
        "flash_diagnostic_mode": flashDiagnosticMode,
        "sendseedbyte": sendseedbyte,
        "flash_seed_key_length": flashSeedKeyLength,
        "flash_address_data_format": flashAddressDataFormat,
        "flash_erase_type": flashEraseType,
        "flash_frase_byte": flashFraseByte,
        "flash_nax_blkseqcntr": flashNaxBlkseqcntr,
        "flashsep_time": flashsepTime,
        "flash_check_sum_type": flashCheckSumType,
        "flash_status": flashStatus,
        "file": file == null
            ? []
            : List<dynamic>.from(file!.map((x) => x.toJson())),
      };
}

class FileElement {
  int? id;
  String? swPartNo;
  dynamic exFile;
  String? dataFileName;
  int? sequenceFileName;
  String? hexSrecFile;
  String? dataFile;
  IsActive? isActive;

  FileElement({
    this.id,
    this.swPartNo,
    this.exFile,
    this.dataFileName,
    this.sequenceFileName,
    this.hexSrecFile,
    this.dataFile,
    this.isActive,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
        id: json["id"],
        swPartNo: json["sw_part_no"],
        exFile: json["ex_file"],
        dataFileName: json["data_file_name"],
        sequenceFileName: json["sequence_file_name"],
        hexSrecFile: json["hex_srec_file"],
        dataFile: json["data_file"],
        isActive: isActiveValues.map[json["is_active"]]!,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sw_part_no": swPartNo,
        "ex_file": exFile,
        "data_file_name": dataFileName,
        "sequence_file_name": sequenceFileName,
        "hex_srec_file": hexSrecFile,
        "data_file": dataFile,
        "is_active": isActiveValues.reverse[isActive],
      };
}

enum IsActive { ACTIVE, INACTIVE }

final isActiveValues =
    EnumValues({"ACTIVE": IsActive.ACTIVE, "INACTIVE ": IsActive.INACTIVE});

class Protocol {
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

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
