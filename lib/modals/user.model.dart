class User {
  Token? token;
  String? user;
  String? role;
  String? firstName;
  String? lastName;
  DateTime? expires;
  Licences? licences;
  int? userId;
  Profile? profile;
  List<dynamic>? deviceData;
  List<dynamic>? vehicleModels;

  User({
    this.token,
    this.user,
    this.role,
    this.firstName,
    this.lastName,
    this.expires,
    this.licences,
    this.userId,
    this.profile,
    this.deviceData,
    this.vehicleModels,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        token: json["token"] == null ? null : Token.fromJson(json["token"]),
        user: json["user"],
        role: json["role"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        expires:
            json["expires"] == null ? null : DateTime.parse(json["expires"]),
        licences: json["licences"] == null
            ? null
            : Licences.fromJson(json["licences"]),
        userId: json["user_id"],
        profile:
            json["profile"] == null ? null : Profile.fromJson(json["profile"]),
        deviceData: json["device_data"] == null
            ? []
            : List<dynamic>.from(json["device_data"]!.map((x) => x)),
        vehicleModels: json["vehicle_models"] == null
            ? []
            : List<dynamic>.from(json["vehicle_models"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "token": token?.toJson(),
        "user": user,
        "role": role,
        "first_name": firstName,
        "last_name": lastName,
        "expires": expires?.toIso8601String(),
        "licences": licences?.toJson(),
        "user_id": userId,
        "profile": profile?.toJson(),
        "device_data": deviceData == null
            ? []
            : List<dynamic>.from(deviceData!.map((x) => x)),
        "vehicle_models": vehicleModels == null
            ? []
            : List<dynamic>.from(vehicleModels!.map((x) => x)),
      };
}

class Licences {
  bool? allDtc;
  bool? selfTest;
  bool? ecuFlashing;
  bool? write;
  bool? liveParameter;
  bool? dtc;
  bool? ecuInformation;
  bool? regeneration;
  bool? sessionLog;

  Licences({
    this.allDtc,
    this.selfTest,
    this.ecuFlashing,
    this.write,
    this.liveParameter,
    this.dtc,
    this.ecuInformation,
    this.regeneration,
    this.sessionLog,
  });

  factory Licences.fromJson(Map<String, dynamic> json) => Licences(
        allDtc: json["All DTC"],
        selfTest: json["Self Test"],
        ecuFlashing: json["ECU Flashing"],
        write: json["Write"],
        liveParameter: json["Live Parameter"],
        dtc: json["DTC"],
        ecuInformation: json["ECU Information"],
        regeneration: json["Regeneration"],
        sessionLog: json["Session Log"],
      );

  Map<String, dynamic> toJson() => {
        "All DTC": allDtc,
        "Self Test": selfTest,
        "ECU Flashing": ecuFlashing,
        "Write": write,
        "Live Parameter": liveParameter,
        "DTC": dtc,
        "ECU Information": ecuInformation,
        "Regeneration": regeneration,
        "Session Log": sessionLog,
      };
}

class Profile {
  int? id;
  Oem? oem;
  List<WorkshopGroupModel>? workshopGroupModels;
  String? email;
  String? mobile;
  dynamic otp;
  String? role;
  bool? status;
  dynamic parent;
  int? user;
  int? workshop;
  dynamic reportTo;
  List<int>? runTimeLicenses;

  Profile({
    this.id,
    this.oem,
    this.workshopGroupModels,
    this.email,
    this.mobile,
    this.otp,
    this.role,
    this.status,
    this.parent,
    this.user,
    this.workshop,
    this.reportTo,
    this.runTimeLicenses,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json["id"],
        oem: json["oem"] == null ? null : Oem.fromJson(json["oem"]),
        workshopGroupModels: json["workshop_group_models"] == null
            ? []
            : List<WorkshopGroupModel>.from(json["workshop_group_models"]!
                .map((x) => WorkshopGroupModel.fromJson(x))),
        email: json["email"],
        mobile: json["mobile"],
        otp: json["otp"],
        role: json["role"],
        status: json["status"],
        parent: json["parent"],
        user: json["user"],
        workshop: json["workshop"],
        reportTo: json["report_to"],
        runTimeLicenses: json["run_time_licenses"] == null
            ? []
            : List<int>.from(json["run_time_licenses"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "oem": oem?.toJson(),
        "workshop_group_models": workshopGroupModels == null
            ? []
            : List<dynamic>.from(workshopGroupModels!.map((x) => x.toJson())),
        "email": email,
        "mobile": mobile,
        "otp": otp,
        "role": role,
        "status": status,
        "parent": parent,
        "user": user,
        "workshop": workshop,
        "report_to": reportTo,
        "run_time_licenses": runTimeLicenses == null
            ? []
            : List<dynamic>.from(runTimeLicenses!.map((x) => x)),
      };
}

class Oem {
  int? id;
  DateTime? created;
  DateTime? modified;
  String? name;
  String? slug;
  dynamic createdBy;
  bool? isActive;
  String? oemFile;
  String? color;
  String? appName;
  int? admin;
  dynamic manager;

  Oem({
    this.id,
    this.created,
    this.modified,
    this.name,
    this.slug,
    this.createdBy,
    this.isActive,
    this.oemFile,
    this.color,
    this.appName,
    this.admin,
    this.manager,
  });

  factory Oem.fromJson(Map<String, dynamic> json) => Oem(
        id: json["id"],
        created:
            json["created"] == null ? null : DateTime.parse(json["created"]),
        modified:
            json["modified"] == null ? null : DateTime.parse(json["modified"]),
        name: json["name"],
        slug: json["slug"],
        createdBy: json["created_by"],
        isActive: json["is_active"],
        oemFile: json["oem_file"],
        color: json["color"],
        appName: json["app_name"],
        admin: json["admin"],
        manager: json["manager"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "created": created?.toIso8601String(),
        "modified": modified?.toIso8601String(),
        "name": name,
        "slug": slug,
        "created_by": createdBy,
        "is_active": isActive,
        "oem_file": oemFile,
        "color": color,
        "app_name": appName,
        "admin": admin,
        "manager": manager,
      };
}

class WorkshopGroupModel {
  int? id;
  String? name;

  WorkshopGroupModel({
    this.id,
    this.name,
  });

  factory WorkshopGroupModel.fromJson(Map<String, dynamic> json) =>
      WorkshopGroupModel(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Token {
  String? refresh;
  String? access;

  Token({
    this.refresh,
    this.access,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        refresh: json["refresh"],
        access: json["access"],
      );

  Map<String, dynamic> toJson() => {
        "refresh": refresh,
        "access": access,
      };
}
