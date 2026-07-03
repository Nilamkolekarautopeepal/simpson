import 'package:get_storage/get_storage.dart';
import 'package:simpson/services/local_storage_services/local_storage_model.dart';
import 'package:simpson/services/local_storage_services/local_storages_string.dart';
import 'package:simpson/utils/strings.dart';

class LocalServices {

  static storeDataInLocalStorage({required String key, dynamic value}) async {
    await GetStorage().write(key, value);
  }

  static retrieveDataFromLocalStorage({required String key}) {
    return GetStorage().read(key) ?? "";
  }

  static LocalStorageDataModel retrieveAllDataFromLocalStorage() {
    final box = GetStorage();
    LocalStorageDataModel storeAllData = LocalStorageDataModel(
      appVersion: box.read(LocalStorageString.appVersion) ?? Strings.empty,
      token: box.read(LocalStorageString.token) ?? Strings.empty,
    );
    return storeAllData;
  }

  static removeDataFromLocalStorage({required String key}) async {
    await GetStorage().remove(key);
  }

  static Future<bool> removeAllDataFromLocalStorage() async {
    final box = GetStorage();
    await box.remove(LocalStorageString.appVersion);
    await box.remove(LocalStorageString.token);

    final appVersion = box.read(LocalStorageString.appVersion);
    final token = box.read(LocalStorageString.token);

    if (appVersion == null && token == null) {
      return true;
    } else {
      return false;
    }
  }
}
