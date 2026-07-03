
import 'package:simpson/common_widgets/buttons.dart';
import 'package:simpson/common_widgets/text_field.dart';
import 'package:simpson/themes/app_theme.dart';
import 'package:simpson/utils/ui_helper_widgets.dart';
import 'package:simpson/views/screens/login/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordScreen extends StatelessWidget {
  final LoginController loginCtrl =
      Get.put(LoginController()); // Inject controller
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Obx(() => WillPopScope(
          onWillPop: () async {
            Get.offAllNamed('/loginScreen');
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
                            "Forget Paassword",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          C20(),
                          AppTextFormField(
                            hintText: 'Enter your Email Address',
                            controller: loginCtrl.forgetEmailController.value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$')
                                  .hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          // C15(),
                          // AppTextFormField(
                          //   hintText: 'Enter your Password',
                          //   controller: loginCtrl.passwordController.value,
                          //   suffixIcon: InkWell(
                          //     onTap: () {
                          //       if(loginCtrl.hidePassword.value){
                          //         loginCtrl.hidePassword.value = false;
                          //       } else {
                          //         loginCtrl.hidePassword.value = true;
                          //       }
                          //     },
                          //     child: Icon(
                          //       loginCtrl.hidePassword.value
                          //       ? Icons.visibility_off_outlined
                          //       : Icons.visibility_outlined,
                          //       color: Colors.grey,
                          //     ),
                          //   ),
                          //   obscureText: loginCtrl.hidePassword.value ? true : false,
                          //   validator: (value) {
                          //     if (value == "") {
                          //       return "requried this field";
                          //     } else {
                          //       return null;
                          //     }
                          //   },
                          // ),
                          C20(),
                          AppButton(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                if (formKey.currentState!.validate()) {
                                  loginCtrl.forgetpassword();
                                }
                              },
                              color: AppColors.primary,
                              title: "SEND OTP"),
                          C150(),
                        ],
                      ),
                    ),
                  ))),
        ));
  }
}
