import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/views/screens/login/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);
  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Left panel: full-bleed branding image ──
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'asset/images/ic_backgroungimg.png',
                  fit: BoxFit.cover,
                ),
                // Subtle dark gradient so the logo/any overlay text stays readable
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Image.asset(
                    'asset/images/ic_sidialogo1.png',
                    width: 400,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          "🔴 [LoginScreen] Failed to load ic_sidialogo1.png: $error");
                      return const Text(
                        'Logo not found',
                        style: TextStyle(color: Colors.red),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Right panel: login form ──
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'asset/images/ic_sidialogo1.png',
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Station
                      const Text(
                        'Station',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.selectedStation.value,
                          items: controller.stationOptions
                              .map(
                                (station) => DropdownMenuItem(
                                  value: station,
                                  child: Text(station),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedStation.value = value;
                            }
                          },
                          decoration: _fieldDecoration('Select Station'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller.usernameController.value,
                        cursorColor: AppColors.themeColor,
                        decoration: _fieldDecoration('Enter Username'),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => TextField(
                          controller: controller.passwordController.value,
                          cursorColor: AppColors.themeColor,
                          obscureText: controller.hidePassword.value,
                          decoration:
                              _fieldDecoration('Enter Password').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.hidePassword.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade400,
                              ),
                              onPressed: () => controller.hidePassword.toggle(),
                            ),
                          ),
                        ),
                      ),

                      // Inline error message
                      Obx(
                        () => controller.errorMessage.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      // Remember me + Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(
                            () => InkWell(
                              onTap: () => controller.rememberMe.toggle(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: Checkbox(
                                      value: controller.rememberMe.value,
                                      activeColor: AppColors.themeColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (_) =>
                                          controller.rememberMe.toggle(),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password ?',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Sign in button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Obx(
                          () => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.themeColor,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : () => controller.login(),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Register',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Column(
                        children: [
                          const Text(
                            'Powered by',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'asset/images/ic_sidialogo1.png',
                              height: 22,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    "🔴 [LoginScreen] Failed to load ic_sidialogo1.png (footer): $error");
                                return const Text(
                                  'Logo not found',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade600,
        fontFamily: "Roboto-Regular",
        fontSize: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.themeColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}