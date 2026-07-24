import 'package:ap_diagnostic/usd_diagnostic.dart';
import 'package:ap_dongle_comm/utils/commController.dart';
import 'package:ap_dongle_comm/utils/dongleComm.dart';
import 'package:ecu_seedkey/ecu_seedkey.dart';
import 'package:flutter/foundation.dart';
import 'package:simpson/app.dart';
import 'package:simpson/utils/ui_helper.dart/dllFunctions.dart';

CommController? comm;
DongleComm? dongleCommWin;
UDSDiagnostic? dSDiagnostic;

class ConnectionWifi {
  Future<String> getDongleMacID(
    String ip, {
    String channelId = "00",
    int port = 6888,
  }) async {
    try {
      comm ??= CommController();
      print("CommController initialized.");
      dongleCommWin = DongleComm(channelId: channelId, isChannel: true);
      dongleCommWin!.comm = comm;
      print(
          "DongleComm initialized with channelId: $channelId and comm assigned");
      print("Connecting to $ip:$port via WiFi...");
      await comm!.connectWifi(
        host: ip,
        port: port,
      );
      print("WiFi connected.");
      dSDiagnostic ??= UDSDiagnostic(dongleCommWin!, ECUCalculateSeedkey());
      print("UDSDiagnostic initialized.");
      print("Sending Security Access command...");
      await dongleCommWin!.securityAccess();
      print("Security Access completed.");
      print("Sending Get MAC ID command...");
      Uint8List? macResp = await dongleCommWin!.getWifiMacId();
      print("Raw MAC response: $macResp");

      if (macResp == null || macResp.length < 9) {
        print("Error: Invalid MAC response");
        return "";
      }

      String macId = [
        macResp[3],
        macResp[4],
        macResp[5],
        macResp[6],
        macResp[7],
        macResp[8]
      ].map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(":");
      print("Parsed MAC ID: $macId");
      print("Sending Get Firmware Version command...");
      Uint8List? fwResp = await dongleCommWin!.getFirmwareVersion();
      print("Raw firmware response: $fwResp");

      if (fwResp != null && fwResp.length >= 6) {
        String ver =
            '${fwResp[3].toString().padLeft(2, '0')}.${fwResp[4].toString().padLeft(2, '0')}.${fwResp[5].toString().padLeft(2, '0')}';
        print("Dongle Firmware Version: $ver");
      }
      print("Initializing DLLFunctions...");
      App.dllFunctions = DLLFunctions(dongleCommWin!, dSDiagnostic!);
      print("DLLFunctions initialized.");

      return macId;
    } catch (e) {
      print("Error @getDongleMacID: $e");
      return "";
    }
  }

  bool _looksLikeDongleErrorText(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return false;
    try {
      final text = String.fromCharCodes(bytes);
      final lower = text.toLowerCase();
      return lower.contains('no resp') ||
          lower.contains('socket_closed') ||
          lower.contains('error') ||
          lower.contains('timeout');
    } catch (_) {
      return false;
    }
  }

  Future<({String macId, DLLFunctions dll, CommController comm})?>
      connectDongleForLane(
    String ip, {
    String channelId = "00",
    int port = 6888,
  }) async {
    try {
      final laneComm = CommController();
      print("[Lane $ip] CommController created.");

      final laneDongleComm = DongleComm(channelId: channelId, isChannel: true);
      laneDongleComm.comm = laneComm;
      print("[Lane $ip] DongleComm created with channelId: $channelId");

      print("[Lane $ip] Connecting via WiFi...");
      await laneComm.connectWifi(
        host: ip,
        port: port,
      );
      print("[Lane $ip] WiFi connected.");

      final laneDiagnostic =
          UDSDiagnostic(laneDongleComm, ECUCalculateSeedkey());
      print("[Lane $ip] UDSDiagnostic created.");

      print("[Lane $ip] Sending Security Access command...");
      await laneDongleComm.securityAccess();

      print("[Lane $ip] Sending Get MAC ID command...");
      final Uint8List? macResp = await laneDongleComm.getWifiMacId();

      if (_looksLikeDongleErrorText(macResp)) {
        print("[Lane $ip] ❌ Get MAC ID got no real response from the dongle "
            "(\"${String.fromCharCodes(macResp!)}\") — the physical dongle "
            "at $ip isn't answering commands (likely failed Security Access "
            "just before this too). Treating as a failed connection rather "
            "than reporting false success.");
        await laneComm.disconnect();
        return null;
      }

      if (macResp == null || macResp.length < 9) {
        print(
            "[Lane $ip] Error: Invalid MAC response (length=${macResp?.length})");
        await laneComm.disconnect();
        return null;
      }

      final macId = [
        macResp[3],
        macResp[4],
        macResp[5],
        macResp[6],
        macResp[7],
        macResp[8]
      ].map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(":");
      print("[Lane $ip] Parsed MAC ID: $macId");

      final dll = DLLFunctions(laneDongleComm, laneDiagnostic);
      print("[Lane $ip] DLLFunctions created (independent instance).");

      return (macId: macId, dll: dll, comm: laneComm);
    } catch (e) {
      print("[Lane $ip] Error @connectDongleForLane: $e");
      return null;
    }
  }

  Future<bool> checkStillConnected() async {
    if (comm == null || dongleCommWin == null) {
      print('checkStillConnected: no active connection to check');
      return false;
    }
    if (!comm!.isConnected.value) {
      print('checkStillConnected: comm reports not connected');
      return false;
    }

    try {
      final resp = await dongleCommWin!
          .getFirmwareVersion()
          .timeout(const Duration(seconds: 3));
      return resp != null && resp.length >= 6;
    } catch (e) {
      print('checkStillConnected failed: $e');
      return false;
    }
  }
}
