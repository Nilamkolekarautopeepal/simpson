import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/modals/user.model.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:get/get.dart';
///[auth] to access current authenticated user
///
final Auth auth = new Auth();

class Auth {

   User currentUser = User.empty();

  Auth() {
    
  }
  ///Loads [currentUser] From Shared Preferences
  ///
Future<Null> loadUser() async {
  appLogs("Loads [currentUser]");
Map<String, dynamic>? userJson = await AppPreferences.getUserData();
if (userJson != null && userJson.isNotEmpty) {
  currentUser = User.fromMap(userJson);  // no await if fromMap is sync
  } else {
    currentUser = User.empty();
  }
}

  ///Saves [currentUser] to Shared Preferences
  ///
  Future<Null> saveUser() async {
    appLogs("Saves [currentUser]");
  }

  ///clear [currentUser] from Shared Preferences
  ///
  Future<Null> clearUser() async {
    appLogs("clear [currentUser]");
    currentUser = User.empty();
    // await NotificationService.instance.clear();
  }

    Future<Null> exceptionLogout(String exception) async {
      if(exception=='AuthenticationError'){
         currentUser = User.empty();
         AppPreferences.clearAll();
         Get.offAndToNamed(Routes.LOGIN);
      }
  }
}




  bool getListRole() {
    if (auth.currentUser.empRole!.contains('HelpDesk Admin') ||
        auth.currentUser.empRole!.contains('admin') ||
        auth.currentUser.empRole!.contains('Asset Manager')) {
      return true;
    }
    return false;
  }







