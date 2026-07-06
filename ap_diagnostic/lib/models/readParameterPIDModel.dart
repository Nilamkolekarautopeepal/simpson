class ReadParameterPID {
  int? pidId;
  String? pid;
  int? totalLen;
  List<PidVariable>? variables;

  ReadParameterPID({
    this.pidId,
    this.pid,
    this.totalLen,
    this.variables,
  });

  factory ReadParameterPID.fromJson(Map<String, dynamic> json) {
    return ReadParameterPID(
      pidId: json['pid_id'],
      pid: json['pid'],
      totalLen: json['totalLen'],
      variables: json['variables'] != null
          ? (json['variables'] as List)
              .map((e) => PidVariable.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid_id': pidId,
      'pid': pid,
      'totalLen': totalLen,
      'variables': variables?.map((e) => e.toJson()).toList(),
    };
  }
}

class PidVariable {
  int? totalBytes;
  int? startByte;
  int? noOfBytes;
  bool? isBitcoded;
  int? startBit;
  int? noofBits;
  String? datatype;
  double? resolution;
  double? offset;
  int? pidNumber;
  String? pidName;
  int? readParameterIndex;
  List<SelectedParameterMessage>? messages;

  PidVariable({
    this.totalBytes,
    this.startByte,
    this.noOfBytes,
    this.isBitcoded,
    this.startBit,
    this.noofBits,
    this.datatype,
    this.resolution,
    this.offset,
    this.pidNumber,
    this.pidName,
    this.readParameterIndex,
    this.messages,
  });

 factory PidVariable.fromJson(Map<String, dynamic> json) {
  return PidVariable(
    totalBytes: json['totalBytes'],
    startByte: json['startByte'],
    noOfBytes: json['noOfBytes'],
    isBitcoded: json['IsBitcoded'],
    startBit: json['startBit'],
    noofBits: json['noofBits'],
    datatype: json['datatype'],
    resolution: (json['resolution'] as num?)?.toDouble(),
    offset: (json['offset'] as num?)?.toDouble(),
    pidNumber: json['pidNumber'],
    pidName: json['pidName'],
    readParameterIndex: json['readParameterIndex'],
    messages: (json['messages'] as List<dynamic>?)
        ?.map((e) => SelectedParameterMessage.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
  Map<String, dynamic> toJson() {
    return {
      'totalBytes': totalBytes,
      'startByte': startByte,
      'noOfBytes': noOfBytes,
      'IsBitcoded': isBitcoded,
      'startBit': startBit,
      'noofBits': noofBits,
      'datatype': datatype,
      'resolution': resolution,
      'offset': offset,
      'pidNumber': pidNumber,
      'pidName': pidName,
      'readParameterIndex': readParameterIndex,
      'messages': messages?.map((e) => e.toJson()).toList(),
    };
  }
}

class SelectedParameterMessage {
  String? code;
  String? message;

  SelectedParameterMessage({
    this.code,
    this.message,
  });

  factory SelectedParameterMessage.fromJson(Map<String, dynamic> json) {
    return SelectedParameterMessage(
      code: json['code'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
    };
  }
}

class PIDFrameId {
  String? framID;
  String? pidDescription;
  String? startByte;
  String? byteValue;
  String? bitCoded;
  String? startBit;
  String? noOfBits;
  String? resolution;
  String? offset;
  String? unit;
  dynamic messageType;
  List<FrameOfPidMessage>? frameOfPidMessage;
  String? endian;
  String? numType;

  PIDFrameId({
    this.framID,
    this.pidDescription,
    this.startByte,
    this.byteValue,
    this.bitCoded,
    this.startBit,
    this.noOfBits,
    this.resolution,
    this.offset,
    this.unit,
    this.messageType,
    this.frameOfPidMessage,
    this.endian,
    this.numType,
  });

  factory PIDFrameId.fromJson(Map<String, dynamic> json) {
    return PIDFrameId(
      framID: json['FramID'],
      pidDescription: json['pid_description'],
      startByte: json['start_byte'],
      byteValue: json['byte'],
      bitCoded: json['bit_coded'],
      startBit: json['start_bit'],
      noOfBits: json['no_of_bits'],
      resolution: json['resolution'],
      offset: json['offset'],
      unit: json['unit'],
      messageType: json['message_type'],
      frameOfPidMessage: json['frame_of_pid_message'] != null
          ? (json['frame_of_pid_message'] as List)
              .map((e) => FrameOfPidMessage.fromJson(e))
              .toList()
          : [],
      endian: json['endian'],
      numType: json['num_type'],
    );
  }

  get byte => null;

  Map<String, dynamic> toJson() {
    return {
      'FramID': framID,
      'pid_description': pidDescription,
      'start_byte': startByte,
      'byte': byteValue,
      'bit_coded': bitCoded,
      'start_bit': startBit,
      'no_of_bits': noOfBits,
      'resolution': resolution,
      'offset': offset,
      'unit': unit,
      'message_type': messageType,
      'frame_of_pid_message':
          frameOfPidMessage?.map((e) => e.toJson()).toList(),
      'endian': endian,
      'num_type': numType,
    };
  }
}

class FrameOfPidMessage {
  String? code;
  String? message;

  FrameOfPidMessage({
    this.code,
    this.message,
  });

  factory FrameOfPidMessage.fromJson(Map<String, dynamic> json) {
    return FrameOfPidMessage(
      code: json['code'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
    };
  }
}

class IVNSelectedPID {
  String? frameId;
  List<PIDFrameId>? frameIds;

  IVNSelectedPID({
    this.frameId,
    this.frameIds,
  });

  factory IVNSelectedPID.fromJson(Map<String, dynamic> json) {
    return IVNSelectedPID(
      frameId: json['frame_id'],
      frameIds: json['frame_ids'] != null
          ? (json['frame_ids'] as List)
              .map((e) => PIDFrameId.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frame_id': frameId,
      'frame_ids': frameIds?.map((e) => e.toJson()).toList(),
    };
  }
}