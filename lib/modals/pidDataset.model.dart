class PidDataset {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  PidDataset({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory PidDataset.fromJson(Map<String, dynamic> json) => PidDataset(
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
  String? code;
  String? description;
  List<Code>? codes;

  Result({
    this.id,
    this.code,
    this.description,
    this.codes,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        code: json["code"],
        description: json["description"],
        codes: json["codes"] == null
            ? []
            : List<Code>.from(json["codes"]!.map((x) => Code.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "description": description,
        "codes": codes == null
            ? []
            : List<dynamic>.from(codes!.map((x) => x.toJson())),
      };
}

class Code {
  int? id;
  String? code;
  String? shortName;
  int? totalLen;
  bool? read;
  bool? write;
  String? writePid;
  bool? reset;
  String? resetValue;
  bool? ioCtrl;
  dynamic ioCtrlPid;
  bool? freezFrame;
  bool? routineTest;
  bool? memoryAddress;
  bool? iupr;
  bool? isStatic;
  bool? ecuParameter;
  int? priority;
  List<PiCodeVariables>? piCodeVariable;

  Code({
    this.id,
    this.code,
    this.shortName,
    this.totalLen,
    this.read,
    this.write,
    this.writePid,
    this.reset,
    this.resetValue,
    this.ioCtrl,
    this.ioCtrlPid,
    this.freezFrame,
    this.routineTest,
    this.memoryAddress,
    this.iupr,
    this.isStatic,
    this.ecuParameter,
    this.priority,
    this.piCodeVariable,
  });

  factory Code.fromJson(Map<String, dynamic> json) => Code(
        id: json["id"],
        code: json["code"],
        shortName: json["short_name"],
        totalLen: json["total_len"],
        read: json["read"],
        write: json["write"],
        writePid: json["write_pid"],
        reset: json["reset"],
        resetValue: json["reset_value"],
        ioCtrl: json["io_ctrl"],
        ioCtrlPid: json["io_ctrl_pid"],
        freezFrame: json["freez_frame"],
        routineTest: json["routine_test"],
        memoryAddress: json["memory_address"],
        iupr: json["iupr"],
        isStatic: json["is_static"],
        ecuParameter: json["ecu_parameter"],
        priority: json["priority"],
        piCodeVariable: json["pi_code_variable"] == null
            ? []
            : List<PiCodeVariables>.from(json["pi_code_variable"]!
                .map((x) => PiCodeVariables.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "short_name": shortName,
        "total_len": totalLen,
        "read": read,
        "write": write,
        "write_pid": writePid,
        "reset": reset,
        "reset_value": resetValue,
        "io_ctrl": ioCtrl,
        "io_ctrl_pid": ioCtrlPid,
        "freez_frame": freezFrame,
        "routine_test": routineTest,
        "memory_address": memoryAddress,
        "iupr": iupr,
        "is_static": isStatic,
        "ecu_parameter": ecuParameter,
        "priority": priority,
        "pi_code_variable": piCodeVariable == null
            ? []
            : List<dynamic>.from(piCodeVariable!.map((x) => x.toJson())),
      };
}

// class PiCodeVariable {
//   int? id;
//   String? shortName;
//   String? longName;
//   int? bytePosition;
//   int? length;
//   bool? bitcoded;
//   dynamic startBitPosition;
//   dynamic endBitPosition;
//   double? resolution;
//   double? offset;
//   int? min;
//   double? max;
//   MessageType? messageType;
//   String? unit;
//   Endian? endian;
//   NumType? numType;
//   List<Group>? group;
//   int? priority;
//   List<Message>? messages;

//   PiCodeVariable({
//     this.id,
//     this.shortName,
//     this.longName,
//     this.bytePosition,
//     this.length,
//     this.bitcoded,
//     this.startBitPosition,
//     this.endBitPosition,
//     this.resolution,
//     this.offset,
//     this.min,
//     this.max,
//     this.messageType,
//     this.unit,
//     this.endian,
//     this.numType,
//     this.group,
//     this.priority,
//     this.messages,
//   });

//   factory PiCodeVariable.fromJson(Map<String, dynamic> json) => PiCodeVariable(
//         id: json["id"],
//         shortName: json["short_name"],
//         longName: json["long_name"],
//         bytePosition: json["byte_position"],
//         length: json["length"],
//         bitcoded: json["bitcoded"],
//         startBitPosition: json["start_bit_position"],
//         endBitPosition: json["end_bit_position"],
//         resolution: json["resolution"]?.toDouble(),
//         offset: json["offset"]?.toDouble(),
//         min: json["min"],
//         max: json["max"]?.toDouble(),
//         messageType: messageTypeValues.map[json["message_type"]]!,
//         unit: json["unit"],
//         endian: endianValues.map[json["endian"]]!,
//         numType: numTypeValues.map[json["num_type"]]!,
//         group: json["group"] == null
//             ? []
//             : List<Group>.from(json["group"]!.map((x) => Group.fromJson(x))),
//         priority: json["priority"],
//         messages: json["messages"] == null
//             ? []
//             : List<Message>.from(
//                 json["messages"]!.map((x) => Message.fromJson(x))),
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "short_name": shortName,
//         "long_name": longName,
//         "byte_position": bytePosition,
//         "length": length,
//         "bitcoded": bitcoded,
//         "start_bit_position": startBitPosition,
//         "end_bit_position": endBitPosition,
//         "resolution": resolution,
//         "offset": offset,
//         "min": min,
//         "max": max,
//         "message_type": messageTypeValues.reverse[messageType],
//         "unit": unit,
//         "endian": endianValues.reverse[endian],
//         "num_type": numTypeValues.reverse[numType],
//         "group": group == null
//             ? []
//             : List<dynamic>.from(group!.map((x) => x.toJson())),
//         "priority": priority,
//         "messages": messages == null
//             ? []
//             : List<dynamic>.from(messages!.map((x) => x.toJson())),
//       };
// }

class PiCodeVariables {
  int? id;
  String? shortName;
  String? longName;
  int? bytePosition;
  int? length;
  bool? bitcoded;
  dynamic startBitPosition;
  dynamic endBitPosition;
  double? resolution;
  double? offset;
  double? min;
  double? max;
  MessageType? messageType;
  String? unit;
  Endian? endian;
  NumType? numType;
  List<Group>? group;
  int? priority;
  List<Message>? messages;

  PiCodeVariables({
    this.id,
    this.shortName,
    this.longName,
    this.bytePosition,
    this.length,
    this.bitcoded,
    this.startBitPosition,
    this.endBitPosition,
    this.resolution,
    this.offset,
    this.min,
    this.max,
    this.messageType,
    this.unit,
    this.endian,
    this.numType,
    this.group,
    this.priority,
    this.messages,
  });

  factory PiCodeVariables.fromJson(Map<String, dynamic> json) => PiCodeVariables(
        id: json["id"],
        shortName: json["short_name"],
        longName: json["long_name"],
        bytePosition: json["byte_position"],
        length: json["length"],
        bitcoded: json["bitcoded"],
        startBitPosition: json["start_bit_position"],
        endBitPosition: json["end_bit_position"],
        resolution: json["resolution"]?.toDouble(),
        offset: json["offset"]?.toDouble(),
        min: json["min"]?.toDouble(),
        max: json["max"]?.toDouble(),
        messageType: messageTypeValues.map[json["message_type"]]!,
        unit: json["unit"],
        endian: endianValues.map[json["endian"]]!,
        numType: numTypeValues.map[json["num_type"]]!,
        group: json["group"] == null
            ? []
            : List<Group>.from(json["group"]!.map((x) => Group.fromJson(x))),
        priority: json["priority"],
        messages: json["messages"] == null
            ? []
            : List<Message>.from(
                json["messages"]!.map((x) => Message.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "short_name": shortName,
        "long_name": longName,
        "byte_position": bytePosition,
        "length": length,
        "bitcoded": bitcoded,
        "start_bit_position": startBitPosition,
        "end_bit_position": endBitPosition,
        "resolution": resolution,
        "offset": offset,
        "min": min,
        "max": max,
        "message_type": messageTypeValues.reverse[messageType],
        "unit": unit,
        "endian": endianValues.reverse[endian],
        "num_type": numTypeValues.reverse[numType],
        "group": group == null
            ? []
            : List<dynamic>.from(group!.map((x) => x.toJson())),
        "priority": priority,
        "messages": messages == null
            ? []
            : List<dynamic>.from(messages!.map((x) => x.toJson())),
      };
}

enum Endian { BIG }

final endianValues = EnumValues({"BIG": Endian.BIG});

class Group {
  int? id;
  String? value;

  Group({
    this.id,
    this.value,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json["id"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "value": value,
      };
}

enum MessageType { ASCII, CONTINUOUS, ENUMRATED, IQA }

final messageTypeValues = EnumValues({
  "ASCII": MessageType.ASCII,
  "CONTINUOUS": MessageType.CONTINUOUS,
  "ENUMRATED": MessageType.ENUMRATED,
  "IQA": MessageType.IQA
});

class Message {
  String? code;
  String? message;

  Message({
    this.code,
    this.message,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        code: json["code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "message": message,
      };
}

enum NumType { SIGNED, UNSIGNED }

final numTypeValues =
    EnumValues({"SIGNED": NumType.SIGNED, "UNSIGNED": NumType.UNSIGNED});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
