import 'dart:typed_data';
import 'package:ap_diagnostic/enum/seedkeyIndexType.dart';
import 'package:ap_diagnostic/enum/writeParameter.dart';

class WriteParameterPID {
  WriteParameterIndex? writePamIndex;
  SEEDKEYINDEXTYPE? seedKeyIndex;
  String? ioCtrlPid;
  String? writePid;
  int? writeInputSize;
  int? writeParaNo;
  int? writeParaName;
  Uint8List? writeInput;
  String? readParameterPidDataType;
  String? pid;
  int? totalLen;
  int? totalBytes;
  int? startByte;
  int? noOfBytes;
  bool? isBitcoded;
  int? startBit;
  int? noofBits;
  String? datatype;
  double? resolution;
  double? offset;
  String? unit;
  String? pidName;
  List<VariantDataList>? variantList;

 

  WriteParameterPID({
    this.writePamIndex,
    this.seedKeyIndex,
    this.ioCtrlPid,
    this.writePid,
    this.writeInputSize,
    this.writeParaNo,
    this.writeParaName,
    this.writeInput,
    this.readParameterPidDataType,
    this.pid,
    this.totalLen,
    this.totalBytes,
    this.startByte,
    this.noOfBytes,
    this.isBitcoded,
    this.startBit,
    this.noofBits,
    this.datatype,
    this.resolution,
    this.offset,
    this.unit,
    this.pidName,
    this.variantList,
  });

  factory WriteParameterPID.fromJson(Map<String, dynamic> json) {
    return WriteParameterPID(
      // Handling Enum parsing from String if necessary
     writePamIndex: json['writepamindex'] != null
    ? WriteParameterIndex.values.firstWhere(
        (e) => e.name == json['writepamindex'],
        orElse: () => WriteParameterIndex.values.first,
      )
    : null,
      seedKeyIndex: json['seedkeyindex'] != null
    ? SEEDKEYINDEXTYPE.values.firstWhere(
        (e) => e.name == json['seedkeyindex'],
        orElse: () => SEEDKEYINDEXTYPE.values.first,
      )
    : null,
      ioCtrlPid: json['io_ctrl_pid'],
      writePid: json['write_pid'],
      writeInputSize: json['writeinput_size'],
      writeParaNo: json['writeparano'],
      writeParaName: json['writeparaName'],
      // Converting List<int> from JSON to Uint8List
      writeInput: json['writeinput'] != null 
          ? Uint8List.fromList(List<int>.from(json['writeinput'])) 
          : null,
      readParameterPidDataType: json['ReadParameterPID_DataType'],
      pid: json['pid'],
      totalLen: json['totalLen'],
      totalBytes: json['totalBytes'],
      startByte: json['startByte'],
      noOfBytes: json['noOfBytes'],
      isBitcoded: json['IsBitcoded'],
      startBit: json['startBit'],
      noofBits: json['noofBits'],
      datatype: json['datatype'],
      resolution: json['resolution']?.toDouble(),
      offset: json['offset']?.toDouble(),
      unit: json['unit'],
      pidName: json['pidName'],
      variantList: json['variantList'] != null
          ? (json['variantList'] as List)
              .map((i) => VariantDataList.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'writepamindex': writePamIndex?.toString().split('.').last,
      'seedkeyindex': seedKeyIndex?.toString().split('.').last,
      'io_ctrl_pid': ioCtrlPid,
      'write_pid': writePid,
      'writeinput_size': writeInputSize,
      'writeparano': writeParaNo,
      'writeparaName': writeParaName,
      'writeinput': writeInput?.toList(),
      'ReadParameterPID_DataType': readParameterPidDataType,
      'pid': pid,
      'totalLen': totalLen,
      'totalBytes': totalBytes,
      'startByte': startByte,
      'noOfBytes': noOfBytes,
      'IsBitcoded': isBitcoded,
      'startBit': startBit,
      'noofBits': noofBits,
      'datatype': datatype,
      'resolution': resolution,
      'offset': offset,
      'unit': unit,
      'pidName': pidName,
      'variantList': variantList?.map((v) => v.toJson()).toList(),
    };
  }
}

class VariantDataList {
  int? pidId;
  String? pidName;
  int? startByte;
  int? noOfBytes;
  bool? isBitcoded;
  int? startBit;
  int? noofBits;
  String? datatype;
  double? resolution;
  double? offset;
  String? unit;
  String? beforeValue;

  VariantDataList({
    this.pidId,
    this.pidName,
    this.startByte,
    this.noOfBytes,
    this.isBitcoded,
    this.startBit,
    this.noofBits,
    this.datatype,
    this.resolution,
    this.offset,
    this.unit,
    this.beforeValue,
  });

  // Convert JSON map to VariantDataList object
  factory VariantDataList.fromJson(Map<String, dynamic> json) {
    return VariantDataList(
      pidId: json['pid_id'],
      pidName: json['pid_name'],
      startByte: json['startByte'],
      noOfBytes: json['noOfBytes'],
      isBitcoded: json['IsBitcoded'],
      startBit: json['startBit'],
      noofBits: json['noofBits'],
      datatype: json['datatype'],
      // Logic to handle both int and double from JSON for numeric fields
      resolution: json['resolution']?.toDouble(),
      offset: json['offset']?.toDouble(),
      unit: json['unit'],
      beforeValue: json['beforeValue'],
    );
  }

  // Convert VariantDataList object to JSON map
  Map<String, dynamic> toJson() {
    return {
      'pid_id': pidId,
      'pid_name': pidName,
      'startByte': startByte,
      'noOfBytes': noOfBytes,
      'IsBitcoded': isBitcoded,
      'startBit': startBit,
      'noofBits': noofBits,
      'datatype': datatype,
      'resolution': resolution,
      'offset': offset,
      'unit': unit,
      'beforeValue': beforeValue,
    };
  }
}