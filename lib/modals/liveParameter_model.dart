import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:simpson/modals/all.models.dart';

class LiveParameterSelectModel {
  String? ecuName;
  List<PidCode>? roots;

  LiveParameterSelectModel({this.ecuName, this.roots});

  factory LiveParameterSelectModel.fromJson(Map<String, dynamic> json) =>
      LiveParameterSelectModel(
        ecuName: json['ecu_name'],
        roots: json['roots'] != null
            ? List<PidCode>.from(json['roots'].map((x) => PidCode.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'ecu_name': ecuName,
        'roots': roots?.map((x) => x.toJson()).toList(),
      };
}

class PidCode {
  int? id;
  String? code;
  String? shortName;
  int? priority;
  bool? read;
  bool? write;
  String? writePid;
  bool? reset;
  int? totalLen;
  String? resetValue;
  bool? ioCtrl;
  String? ioCtrlPid;
  bool? isActive;
  bool? memoryAddress;
  bool? freezFrame;
  bool? routineTest;
  bool? ecuParameter;
  bool? isStatic;
  String? header;
  List<PiCodeVariable>? piCodeVariable;

  PidCode({
    this.id,
    this.code,
    this.shortName,
    this.priority,
    this.read,
    this.write,
    this.writePid,
    this.reset,
    this.totalLen,
    this.resetValue,
    this.ioCtrl,
    this.ioCtrlPid,
    this.isActive,
    this.memoryAddress,
    this.freezFrame,
    this.routineTest,
    this.ecuParameter,
    this.isStatic,
    this.header,
    this.piCodeVariable,
  });

  factory PidCode.fromJson(Map<String, dynamic> json) => PidCode(
        id: json['id'],
        code: json['code'],
        shortName: json['short_name'],
        priority: json['priority'],
        read: json['read'],
        write: json['write'],
        writePid: json['write_pid'],
        reset: json['reset'],
        totalLen: json['total_len'],
        resetValue: json['reset_value'],
        ioCtrl: json['io_ctrl'],
        ioCtrlPid: json['io_ctrl_pid'],
        isActive: json['is_active'],
        memoryAddress: json['memory_address'],
        freezFrame: json['freez_frame'],
        routineTest: json['routine_test'],
        ecuParameter: json['ecu_parameter'],
        isStatic: json['is_static'],
        header: json['Header'],
        piCodeVariable: json['pi_code_variable'] != null
            ? List<PiCodeVariable>.from(
                json['pi_code_variable'].map((x) => PiCodeVariable.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'short_name': shortName,
        'priority': priority,
        'read': read,
        'write': write,
        'write_pid': writePid,
        'reset': reset,
        'total_len': totalLen,
        'reset_value': resetValue,
        'io_ctrl': ioCtrl,
        'io_ctrl_pid': ioCtrlPid,
        'is_active': isActive,
        'memory_address': memoryAddress,
        'freez_frame': freezFrame,
        'routine_test': routineTest,
        'ecu_parameter': ecuParameter,
        'is_static': isStatic,
        'Header': header,
        'pi_code_variable': piCodeVariable?.map((x) => x.toJson()).toList(),
      };
}

class Variables {
  int id;
  String name;
  dynamic value;

  Variables({
    required this.id,
    required this.name,
    this.value,
  });

  factory Variables.fromJson(Map<String, dynamic> json) {
    return Variables(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }
}

class Variable {
  String? pidName;
  int? pidNumber;
  String? responseValue;

  Variable({
     this.pidName,
     this.pidNumber,
     this.responseValue,
  });

  /// Create a Variable from JSON
  factory Variable.fromJson(Map<String, dynamic> json) {
    return Variable(
      pidName: json['pidName'] ?? "",
      pidNumber: json['pidNumber'] ?? 0,
      responseValue: json['responseValue'] ?? "",
    );
  }

  /// Convert Variable to JSON
  Map<String, dynamic> toJson() {
    return {
      'pidName': pidName,
      'pidNumber': pidNumber,
      'responseValue': responseValue,
    };
  }
}

class ReadPidResponseModel {
  String? status;
   Uint8List?  dataArray;
  int? pidId;
  String? pidName;
  String? responseValue;
  String? unit;
  List<Variable>? variables; // <-- Use the new 'Variable' class here

  ReadPidResponseModel({
     this.status,
     this.dataArray,
     this.pidId,
     this.pidName,
     this.responseValue,
     this.unit,
     this.variables,
  });

  factory ReadPidResponseModel.fromJson(Map<String, dynamic> json) {
  return ReadPidResponseModel(
    status: json['Status'] ?? "",
    dataArray: json['DataArray'] == null
        ? null
        : Uint8List.fromList(List<int>.from(json['DataArray'])),
    pidId: json['pid_id'] ?? 0,
    pidName: json['pid_name'] ?? "",
    responseValue: json['responseValue'] ?? "",
    unit: json['unit'] ?? "",
    variables: (json['Variables'] as List<dynamic>? ?? [])
        .map((e) => Variable.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

  Map<String, dynamic> toJson() => {
        'Status': status,
        'DataArray': dataArray,
        'pid_id': pidId,
        'pid_name': pidName,
        'responseValue': responseValue,
        'unit': unit,
        'Variables': variables?.map((e) => e.toJson()).toList(),
      };
}

class PiCodeVariable {
   String? showResolution;
  String ?writeValue;
  RxBool isResetRx = false.obs; // optional, for UI
  Rx<Color> txtColor = Colors.black.obs;

  int id = 0;

  String shortName = "";
  bool selected = false;

  String longName = "";
  int bytePosition = 0;
  int length = 0;
  bool bitcoded = false;
  int? startBitPosition;
  int? endBitPosition;
  int? priority;
  double? resolution;
  double? offset;
  double? min;
  double? max;
  String messageType = "";
  String unit = "";
  String endian = "";
  String numType = "";

  List<dynamic> group = [];
  List<dynamic> messages = [];
  double dav = 0.0;

 
  bool isUnitVisible = false;
  double stepperValue = 0.0;
  double userValue = 0.0;

  
  bool isReset = false;
  String writeValueStatus = "";
  int actuatorWriteValue = 0;

  String index = "";
  String parameterName = "";

  PiCodeVariable({
    this.id = 0,
    String? shortName,
    bool? selected,
    this.longName = "",
    this.bytePosition = 0,
    this.length = 0,
    this.bitcoded = false,
    this.startBitPosition,
    this.endBitPosition,
    this.priority,
    this.resolution,
    this.offset,
    this.min,
    this.max,
    this.messageType = "",
    this.unit = "",
    this.endian = "",
    this.numType = "",
    List<dynamic>? group,
    List<dynamic>? messages,
    this.dav = 0.0,
    String? showResolution,
    bool? isUnitVisible,
    double? stepperValue,
    double? userValue,
    String? writeValue,
    bool? isReset,
    String? writeValueStatus,
    int? actuatorWriteValue,
    Color? txtColor,
    String? index,
    String? parameterName,
  }) {
    this.shortName = shortName ?? "";
    this.selected = selected ?? false;
    this.group = group ?? [];
    this.messages = messages ?? [];
    this.showResolution = showResolution ?? "";
  this.writeValue = writeValue ?? "";
  this.isResetRx.value = isReset ?? false;
  this.txtColor.value = txtColor ?? Colors.black;
    this.isUnitVisible = isUnitVisible ?? false;
    this.stepperValue = stepperValue ?? 0.0;
    this.userValue = userValue ?? 0.0;
    this.isReset = isReset ?? false;
    this.writeValueStatus = (writeValueStatus ?? "");
    this.actuatorWriteValue = actuatorWriteValue ?? 0;
    this.txtColor.value = txtColor ?? Colors.black;
    this.index = index ?? "";
    this.parameterName = parameterName ?? "";
  }
  void updateWriteValueStatus() {
    // Ensure writeValue is not null and has a value
    final currentValue = writeValue;

    try {
      if (messageType == "CONTINUOUS") {
        writeValueStatus = "(Range : $min - $max)";
      } else if (messageType == "ASCII" ||
          messageType == "BCD" ||
          messageType == "HEX") {
        // Make sure maxLength is an int, not RxString
        writeValueStatus = "$currentValue.length/";
      } else if (messageType == "IQA") {
        writeValueStatus = "$currentValue.length/7";
      }
    } catch (e) {
      print("Error in updateWriteValueStatus: $e");
    }
  }

  /// --- JSON serialization ---
  factory PiCodeVariable.fromJson(Map<String, dynamic> json) {
    return PiCodeVariable(
      id: json['id'] ?? 0,
      shortName: json['short_name'] ?? "",
      selected: json['Selected'] ?? false,
      longName: json['long_name'] ?? "",
      bytePosition: json['byte_position'] ?? 0,
      length: json['length'] ?? 0,
      bitcoded: json['bitcoded'] ?? false,
      startBitPosition: json['start_bit_position'],
      endBitPosition: json['end_bit_position'],
      priority: json['priority'],
      resolution: (json['resolution'] as num?)?.toDouble(),
      offset: (json['offset'] as num?)?.toDouble(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      messageType: json['message_type'] ?? "",
      unit: json['unit'] ?? "",
      endian: json['endian'] ?? "",
      numType: json['num_type'] ?? "",
      group: json['group'] ?? [],
      messages: json['messages'] ?? [],
      dav: (json['dav'] as num?)?.toDouble() ?? 0.0,
      showResolution: json['show_resolution'] ?? "",
      isUnitVisible: json['isUnitVisible'] ?? false,
      stepperValue: (json['stepper_value'] as num?)?.toDouble() ?? 0.0,
      userValue: (json['user_value'] as num?)?.toDouble() ?? 0.0,
      writeValue: json['write_value'] ?? "",
      isReset: json['IsReset'] ?? false,
      writeValueStatus: json['write_value_status'] ?? "",
      actuatorWriteValue: json['actuator_write_value'] ?? 0,
      txtColor:
          json['txt_color'] != null ? Color(json['txt_color']) : Colors.black,
      index: json['index'] ?? "",
      parameterName: json['parameter_name'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_name': shortName,
      'Selected': selected,
      'long_name': longName,
      'byte_position': bytePosition,
      'length': length,
      'bitcoded': bitcoded,
      'start_bit_position': startBitPosition,
      'end_bit_position': endBitPosition,
      'priority': priority,
      'resolution': resolution,
      'offset': offset,
      'min': min,
      'max': max,
      'message_type': messageType,
      'unit': unit,
      'endian': endian,
      'num_type': numType,
      'group': group,
      'messages': messages,
      'dav': dav,
      'show_resolution': showResolution,
      'isUnitVisible': isUnitVisible,
      'stepper_value': stepperValue,
      'user_value': userValue,
      'write_value': writeValue,
      'IsReset': isReset,
      'write_value_status': writeValueStatus,
      'actuator_write_value': actuatorWriteValue,
      'txt_color': txtColor.value.value,
      'index': index,
      'parameter_name': parameterName,
    };
  }
}

class PIDModel {
  int? count;
  dynamic next;
  dynamic previous;
  List<PIDResult>? results;
  String? message;

  PIDModel({this.count, this.next, this.previous, this.results, this.message});

  // From JSON
  factory PIDModel.fromJson(Map<String, dynamic> json) => PIDModel(
        count: json['count'],
        next: json['next'],
        previous: json['previous'],
        results: json['results'] != null
            ? List<PIDResult>.from(
                json['results'].map((x) => PIDResult.fromJson(x)))
            : null,
        message: json['message'],
      );

  // To JSON
  Map<String, dynamic> toJson() => {
        'count': count,
        'next': next,
        'previous': previous,
        'results': results?.map((x) => x.toJson()).toList(),
        'message': message,
      };
}

class PIDResult {
  int? id;
  String? code;
  String? description;
  List<PIDFrameDataset>? frameDatasets;

  PIDResult({this.id, this.code, this.description, this.frameDatasets});

  factory PIDResult.fromJson(Map<String, dynamic> json) => PIDResult(
        id: json['id'],
        code: json['code'],
        description: json['description'],
        frameDatasets: json['frame_datasets'] != null
            ? List<PIDFrameDataset>.from(
                json['frame_datasets'].map((x) => PIDFrameDataset.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'description': description,
        'frame_datasets': frameDatasets?.map((x) => x.toJson()).toList(),
      };
}

class PIDFrameDataset {
  int? id;
  String? frameName;
  String? frameId;
  List<PIDFrameId>? frameIds;

  PIDFrameDataset({this.id, this.frameName, this.frameId, this.frameIds});

  factory PIDFrameDataset.fromJson(Map<String, dynamic> json) =>
      PIDFrameDataset(
        id: json['id'],
        frameName: json['frame_name'],
        frameId: json['frame_id'],
        frameIds: json['frame_ids'] != null
            ? List<PIDFrameId>.from(
                json['frame_ids'].map((x) => PIDFrameId.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'frame_name': frameName,
        'frame_id': frameId,
        'frame_ids': frameIds?.map((x) => x.toJson()).toList(),
      };
}

class PIDFrameId {
  String? pidDescription;
  String? startByte;
  int? startByteVal;
  String? byteValue;
  int? byteLen;
  String? bitCoded;
  String? startBit;
  int? startBitVal;
  String? noOfBits;
  int? noOfBitsVal;
  String? resolution;
  double? resolutionVal;
  String? offset;
  double? offsetVal;
  String? unit;
  String? messageType;
  bool? selected;

  PIDFrameId({
    this.pidDescription,
    this.startByte,
    this.startByteVal,
    this.byteValue,
    this.byteLen,
    this.bitCoded,
    this.startBit,
    this.startBitVal,
    this.noOfBits,
    this.noOfBitsVal,
    this.resolution,
    this.resolutionVal,
    this.offset,
    this.offsetVal,
    this.unit,
    this.messageType,
    this.selected = false,
  });

  factory PIDFrameId.fromJson(Map<String, dynamic> json) => PIDFrameId(
        pidDescription: json['pid_description'],
        startByte: json['start_byte'],
        startByteVal: json['startByteVal'],
        byteValue: json['byte'],
        byteLen: json['byteLen'],
        bitCoded: json['bit_coded'],
        startBit: json['start_bit'],
        startBitVal: json['startBitVal'],
        noOfBits: json['no_of_bits'],
        noOfBitsVal: json['noOfBitsVal'],
        resolution: json['resolution'],
        resolutionVal: (json['resolutionVal'] as num?)?.toDouble(),
        offset: json['offset'],
        offsetVal: (json['offsetVal'] as num?)?.toDouble(),
        unit: json['unit'],
        messageType: json['message_type'],
        selected: json['Selected'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'pid_description': pidDescription,
        'start_byte': startByte,
        'startByteVal': startByteVal,
        'byte': byteValue,
        'byteLen': byteLen,
        'bit_coded': bitCoded,
        'start_bit': startBit,
        'startBitVal': startBitVal,
        'no_of_bits': noOfBits,
        'noOfBitsVal': noOfBitsVal,
        'resolution': resolution,
        'resolutionVal': resolutionVal,
        'offset': offset,
        'offsetVal': offsetVal,
        'unit': unit,
        'message_type': messageType,
        'Selected': selected,
      };
}

class FrameOfPidMessage {
  String? code;
  String? message;

  FrameOfPidMessage({this.code, this.message});

  factory FrameOfPidMessage.fromJson(Map<String, dynamic> json) =>
      FrameOfPidMessage(
        code: json['code'],
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };
}

class EcuModel {
  String? ecuName;
  ValueNotifier<double> opacity;
  List<PidCode> pidList;
  String? txHeader;
  String? rxHeader;
  Protocol? protocol;
  String? firingSequence;
  int? noOfInjectors;

  EcuModel({
    this.ecuName,
    double? opacity,
    List<PidCode>? pidList,
    this.txHeader,
    this.rxHeader,
    this.protocol,
    this.firingSequence,
    this.noOfInjectors,
  })  : opacity = ValueNotifier<double>(opacity ?? 1.0),
        pidList = pidList ?? [];

  factory EcuModel.fromJson(Map<String, dynamic> json) => EcuModel(
        ecuName: json['ecu_name'],
        opacity: (json['opacity'] != null)
            ? (json['opacity'] as num).toDouble()
            : 1.0,
        pidList: (json['pid_list'] as List<dynamic>?)
                ?.map((e) => PidCode.fromJson(e))
                .toList() ??
            [],
        txHeader: json['tx_header'],
        rxHeader: json['rx_header'],
        protocol: json['protocol'] != null
            ? Protocol.fromJson(json['protocol'])
            : null,
        firingSequence: json['firing_sequence'],
        noOfInjectors: json['no_of_injectors'],
      );

  get value => null;

  Map<String, dynamic> toJson() => {
        'ecu_name': ecuName,
        'opacity': opacity.value,
        'pid_list': pidList.map((e) => e.toJson()).toList(),
        'tx_header': txHeader,
        'rx_header': rxHeader,
        'protocol': protocol?.toJson(),
        'firing_sequence': firingSequence,
        'no_of_injectors': noOfInjectors,
      };
}

class IvnEcusModel {
  String? ecuName;
  ValueNotifier<double> opacity;
  List<PIDFrameId> pidList;

  IvnEcusModel({
    this.ecuName,
    double? opacity,
    List<PIDFrameId>? pidList,
  })  : opacity = ValueNotifier<double>(opacity ?? 1.0),
        pidList = pidList ?? [];

  factory IvnEcusModel.fromJson(Map<String, dynamic> json) => IvnEcusModel(
        ecuName: json['ecu_name'],
        opacity: (json['opacity'] != null)
            ? (json['opacity'] as num).toDouble()
            : 1.0,
        pidList: (json['pid_list'] as List<dynamic>?)
                ?.map((e) => PIDFrameId.fromJson(e))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'ecu_name': ecuName,
        'opacity': opacity.value,
        'pid_list': pidList.map((e) => e.toJson()).toList(),
      };
}

class Root {
  int? count;
  dynamic next;
  dynamic previous;
  List<Results>? results;
  String? message;

  Root({
    this.count,
    this.next,
    this.previous,
    this.results,
    this.message,
  });

  /// 🔽 JSON → Object
  factory Root.fromJson(Map<String, dynamic> json) {
    return Root(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: json['results'] != null
          ? (json['results'] as List).map((e) => Results.fromJson(e)).toList()
          : [],
    );
  }

  /// 🔼 Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results?.map((e) => e.toJson()).toList(),
    };
  }
}

class Results {
  int? id;
  String? code;
  String? description;
  List<PidCode>? codes;

  Results({
    this.id,
    this.code,
    this.description,
    this.codes,
  });

  /// 🔽 JSON → Object
  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      id: json['id'],
      code: json['code'],
      description: json['description'],
      codes: json['codes'] != null
          ? (json['codes'] as List).map((e) => PidCode.fromJson(e)).toList()
          : [],
    );
  }

  /// 🔼 Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'codes': codes?.map((e) => e.toJson()).toList(),
    };
  }
}



class PidGroupModel {
  int id;
  RxString groupName;
  RxBool isSelected;
  RxInt itemCount;

  PidGroupModel({
    required this.id,
    String groupName = '',
    bool isSelected = false,
    int itemCount = 0,
  })  : groupName = groupName.obs,
        isSelected = isSelected.obs,
        itemCount = itemCount.obs;
}

class TestRoutineResponseModel {
  String? ecuResponseStatus;
  String? ecuResponse;
  Uint8List? actualDataBytes;

  TestRoutineResponseModel({
    this.ecuResponseStatus,
    this.ecuResponse,
    this.actualDataBytes,
  });

  // fromJson
  factory TestRoutineResponseModel.fromJson(Map<String, dynamic> json) {
    return TestRoutineResponseModel(
      ecuResponseStatus: json['ECUResponseStatus'],
      ecuResponse: json['ECUResponse'],
      actualDataBytes: json['ActualDataBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['ActualDataBytes']))
          : null,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      "ECUResponseStatus": ecuResponseStatus,
      "ECUResponse": ecuResponse,
      "ActualDataBytes": actualDataBytes?.toList(),
    };
  }
}


class WriteParameterPid {
  String? writePamIndex;
  String? seedKeyIndex;
  String? ioCtrlPid;
  String? writePid;
  int? writeParaDataSize;
  int? writeParaNo;
  int? writeParaName;
  Uint8List? writeInput;
  String? readParameterPidDataType;
  List<VariantDataLists>? variantList;
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

  WriteParameterPid({
    this.writePamIndex,
    this.seedKeyIndex,
    this.ioCtrlPid,
    this.writePid,
    this.writeParaDataSize,
    this.writeParaNo,
    this.writeParaName,
    this.writeInput,
    this.readParameterPidDataType,
    this.variantList,
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
  });

  factory WriteParameterPid.fromJson(Map<String, dynamic> json) {
    return WriteParameterPid(
      writePamIndex: json['writepamindex'],
      seedKeyIndex: json['seedkeyindex'],
      ioCtrlPid: json['io_ctrl_pid'],
      writePid: json['write_pid'],
      writeParaDataSize: json['writeparadatasize'],
      writeParaNo: json['writeparano'],
      writeParaName: json['writeparaName'],
      // Handles conversion from List<int> to Uint8List
      writeInput: json['writeinput'] != null 
          ? Uint8List.fromList(List<int>.from(json['writeinput'])) 
          : null,
      readParameterPidDataType: json['ReadParameterPID_DataType'],
      variantList: json['variantList'] != null
          ? (json['variantList'] as List)
              .map((i) => VariantDataLists.fromJson(i))
              .toList()
          : null,
      pid: json['pid'],
      totalLen: json['totalLen'],
      totalBytes: json['totalBytes'],
      startByte: json['startByte'],
      noOfBytes: json['noOfBytes'],
      isBitcoded: json['IsBitcoded'],
      startBit: json['startBit'],
      noofBits: json['noofBits'],
      datatype: json['datatype'],
      resolution: (json['resolution'] as num?)?.toDouble(),
      offset: (json['offset'] as num?)?.toDouble(),
      unit: json['unit'],
      pidName: json['pidName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'writepamindex': writePamIndex,
      'seedkeyindex': seedKeyIndex,
      'io_ctrl_pid': ioCtrlPid,
      'write_pid': writePid,
      'writeparadatasize': writeParaDataSize,
      'writeparano': writeParaNo,
      'writeparaName': writeParaName,
      // Uint8List converts nicely to a List for JSON
      'writeinput': writeInput?.toList(),
      'ReadParameterPID_DataType': readParameterPidDataType,
      'variantList': variantList?.map((e) => e.toJson()).toList(),
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
    };
  }
}

class VariantDataLists {
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

  VariantDataLists({
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

  /// Factory constructor to create a VariantDataList from a JSON map
  factory VariantDataLists.fromJson(Map<String, dynamic> json) {
    return VariantDataLists(
      pidId: json['pid_id'],
      pidName: json['pid_name'],
      startByte: json['startByte'],
      noOfBytes: json['noOfBytes'],
      isBitcoded: json['IsBitcoded'],
      startBit: json['startBit'],
      noofBits: json['noofBits'],
      datatype: json['datatype'],
      // Standard practice: parse numbers as double regardless if int or double in JSON
      resolution: (json['resolution'] as num?)?.toDouble(),
      offset: (json['offset'] as num?)?.toDouble(),
      unit: json['unit'],
      beforeValue: json['beforeValue'],
    );
  }

  /// Converts the VariantDataList instance to a JSON map
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

class ReadPidPresponseModel {
  String status;
  String dataArray;
  int pidId;
  String pidName;
  String responseValue;
  String unit;
  List<Variable> variables;

  ReadPidPresponseModel({
    required this.status,
    required this.dataArray,
    required this.pidId,
    required this.pidName,
    required this.responseValue,
    required this.unit,
    required this.variables,
  });

  // Factory constructor to create from JSON
  factory ReadPidPresponseModel.fromJson(Map<String, dynamic> json) {
    return ReadPidPresponseModel(
      status: json['Status'] ?? '',
      dataArray: json['DataArray'] ?? '',
      pidId: json['pid_id'] ?? 0,
      pidName: json['pid_name'] ?? '',
      responseValue: json['responseValue'] ?? '',
      unit: json['unit'] ?? '',
      variables: (json['Variables'] as List<dynamic>? ?? [])
          .map((v) => Variable.fromJson(v))
          .toList(),
    );
  }

  // To JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'DataArray': dataArray,
      'pid_id': pidId,
      'pid_name': pidName,
      'responseValue': responseValue,
      'unit': unit,
      'Variables': variables.map((v) => v.toJson()).toList(),
    };
  }
}
