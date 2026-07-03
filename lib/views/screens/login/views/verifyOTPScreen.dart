import 'package:autopeepalApp/common_widgets/buttons.dart';
import 'package:autopeepalApp/common_widgets/text_field.dart';
import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:autopeepalApp/views/screens/login/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VerifyOTPScreen extends StatelessWidget {
  final LoginController loginCtrl =
      Get.put(LoginController()); // Inject controller
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Obx(() => WillPopScope(
          onWillPop: () async {
            Get.offNamed('/forgetPasswodScreen');
            return false;
          },
          child: Scaffold(
              body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.white,
                        AppColors.baseWhite,
                      ],
                    ),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Image.asset(
                              'asset/logo/erphrms.png',
                              height: 280,
                              width: 280,
                            ),
                          ),
                          C100(),
                          Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          C20(),
                          AppTextFormField(
                            hintText: 'Enter received OTP',
                            controller: loginCtrl.verifyOTPController.value,
                            validator: (value) {
                              if (value == "") {
                                return "requried this field";
                              } else {
                                return null;
                              }
                            },
                            keyboardType: TextInputType.number,
                          ),
                          C20(),
                          AppButton(
                              onTap: () {
                                final String email = Get.arguments['email'];

                                FocusScope.of(context).unfocus();
                                if (formKey.currentState!.validate()) {
                                  loginCtrl.verifyOTP(email);
                                }
                              },
                              color: Colors.green,
                              title: "VERIFY OTP"),
                          C150(),
                        ],
                      ),
                    ),
                  ))),
        ));
  }
}
