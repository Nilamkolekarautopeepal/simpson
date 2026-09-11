import 'package:simpson/modals/all.models.dart';

/// =======================================================
/// StaticData  (equivalent of C# static class)
/// =======================================================
class StaticData {
  static List<EcuDataSet> ecuInfo = [];
}

/// =======================================================
/// ECU DATA SET
/// =======================================================
class EcuDataSet {
  int? ecuID;
  String? ecuName;
  String? chasisId;

  int? dtcDatasetId;
  int? pidDatasetId;
  int ivnPidDatasetId;
  int ivnDtcDatasetId;

  String? clearDtcIndex;
  String? readDtcIndex;
  String? writePidIndex;
  String? iorTestFnIndex;
  String? seedKeyIndex;

  String? txHeader;
  String? rxHeader;
  Protocol? protocol;

  String? channelId;
  String? modelName;
  String? submodelName;
  String? modelYear;

  //Ecu? ecu2;
  int? ffSet;
  String? firingSequence;
  int? noOfInjectors;

  EcuDataSet({
    this.ecuID,
    this.ecuName,
    this.protocol,
    this.chasisId,
    this.dtcDatasetId,
    this.pidDatasetId,
    this.ivnPidDatasetId = 0,
    this.ivnDtcDatasetId = 0,
    this.clearDtcIndex,
    this.readDtcIndex,
    this.writePidIndex,
    this.iorTestFnIndex,
    this.seedKeyIndex,
    this.txHeader,
    this.rxHeader,
    this.channelId,
    this.modelName,
    this.submodelName,
    this.modelYear,
    //this.ecu2,
    this.ffSet,
    this.firingSequence,
    this.noOfInjectors,
  });

  /// Optional JSON support
  factory EcuDataSet.fromJson(Map<String, dynamic> json) {
    return EcuDataSet(
      ecuID: json['ecu_ID'],
      ecuName: json['ecu_name'],
      protocol: Protocol.fromJson(json['protocol']),
      chasisId: json['chasis_id'],
      dtcDatasetId: json['dtc_dataset_id'],
      pidDatasetId: json['pid_dataset_id'],
      ivnPidDatasetId: json['ivn_pid_dataset_id'] ?? 0,
      ivnDtcDatasetId: json['ivn_dtc_dataset_id'] ?? 0,
      clearDtcIndex: json['clear_dtc_index'],
      readDtcIndex: json['read_dtc_index'],
      writePidIndex: json['write_pid_index'],
      iorTestFnIndex: json['ior_test_fn_index'],
      seedKeyIndex: json['seed_key_index'],
      txHeader: json['tx_header'],
      rxHeader: json['rx_header'],
      channelId: json['channelId'],
      modelName: json['modelName'],
      submodelName: json['submodelName'],
      modelYear: json['modelYear'],
      ffSet: json['ff_set'],
      firingSequence: json['firingSequence'],
      noOfInjectors: json['no_of_injectors'],
    );
  }
}

/// =======================================================
/// SESSION STATIC DATA
/// =======================================================
class SessionStaticData {
  static List<SessionResponseJobCardModel> sessionResponse = [];
}

/// =======================================================
/// SESSION RESPONSE MODEL
/// =======================================================
class SessionResponseJobCardModel {
  String? id;
  String? remoteSessionId;
  String? jobCardSession;
  dynamic caseId;
  String? status;
  int? expertUser;
  dynamic expertDevice;
  String? expertEmail;
  bool? requestStatus;

  SessionResponseJobCardModel({
    this.id,
    this.remoteSessionId,
    this.jobCardSession,
    this.caseId,
    this.status,
    this.expertUser,
    this.expertDevice,
    this.expertEmail,
    this.requestStatus,
  });

  factory SessionResponseJobCardModel.fromJson(Map<String, dynamic> json) {
    return SessionResponseJobCardModel(
      id: json['id'],
      remoteSessionId: json['remote_session_id'],
      jobCardSession: json['job_card_session'],
      caseId: json['case_id'],
      status: json['status'],
      expertUser: json['expert_user'],
      expertDevice: json['expert_device'],
      expertEmail: json['expert_email'],
      requestStatus: json['request_status'],
    );
  }
}
