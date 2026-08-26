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
      backgroundColor: const Color(0xFF12414D),
      body: Row(
        children: [
          // ── Left half: logo only, exactly 50% width ──
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF12414D),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(right:1),
                child: Image.asset(
                  'asset/images/simpsons_engine_img.png',
                  width: 1100,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                        "🔴 [LoginScreen] Failed to load simpsons_engine_img.png: $error");
                    return const Text(
                      'Logo not found',
                      style: TextStyle(color: Colors.red),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Right half: glassy pill login form, exactly 50% width ──
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF12414D),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _GlassPillField(
                        icon: Icons.person_outline,
                        hint: 'User ID',
                        controller: controller.usernameController.value,
                      ),
                      const SizedBox(height: 18),

                      Obx(
                        () => _GlassPillField(
                          icon: Icons.lock_outline,
                          hint: 'Password',
                          controller: controller.passwordController.value,
                          obscureText: controller.hidePassword.value,
                          trailing: IconButton(
                            splashRadius: 18,
                            icon: Icon(
                              controller.hidePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => controller.hidePassword.toggle(),
                          ),
                        ),
                      ),

                      // Inline error message
                      Obx(
                        () => controller.errorMessage.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, left: 8),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8A80),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Remember me
                      Obx(
                        () => InkWell(
                          onTap: () => controller.rememberMe.toggle(),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Checkbox(
                                    value: controller.rememberMe.value,
                                    activeColor: Colors.white,
                                    checkColor: const Color(0xFF14424F),
                                    side: const BorderSide(
                                        color: Colors.white54, width: 1.4),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (_) =>
                                        controller.rememberMe.toggle(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Remember Me',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── LOGIN button — solid dark pill, glossy top highlight ──
                      Obx(
                        () => _GlossyButton(
                          isLoading: controller.isLoading.value,
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.login(),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Powered by',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Image.asset(
                              'asset/images/icon_simpson.png',
                              height: 20,
                              color: Colors.white.withOpacity(0.6),
                              colorBlendMode: BlendMode.srcIn,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                'SIMPSON',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}

/// One glossy, pill-shaped input field — leading icon, frosted-glass
/// fill, soft top highlight to read as "glossy" rather than flat.
class _GlassPillField extends StatelessWidget {
  const _GlassPillField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.trailing,
  });

  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3D7887).withOpacity(0.55),
            const Color(0xFF2A6272).withOpacity(0.45),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.white.withOpacity(0.3),
            selectionHandleColor: Colors.white,
          ),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

/// The dark, glossy LOGIN button — near-black fill with a subtle
/// lighter sheen along the top edge for a pressed-glass look.
class _GlossyButton extends StatelessWidget {
  const _GlossyButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPressed,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF16333B),
                Color(0xFF0C2126),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'LOGIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}
