import 'package:flutter/material.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/app_constants.dart';

InputDecoration getInputDecoration(
  String text,
  bool isRequired,
) {
  String requiredMark = isRequired ? " *" : "";
  text = text + requiredMark;

  return InputDecoration(
    labelText: text,
    enabled: true,
    disabledBorder: OutlineInputBorder(),
    filled: true,
    border: OutlineInputBorder(),
    fillColor: AppColors.white,
    // contentPadding: EdgeInsets.all(10),
    hintStyle: TextStyles.hintStyle1,
    errorStyle: TextStyles.errorStyle,
    labelStyle: TextStyles.labelStyle,
    errorMaxLines: Constants.errorMaxLines,
  );
}

InputDecoration getInputDecoration1(
  String text,
  bool isRequired,
  Widget icons,
) {
  String requiredMark = isRequired ? " *" : "";
  text = text + requiredMark;

  return InputDecoration(
    labelText: text,
    enabled: true,
    suffixIcon: icons,
    disabledBorder: OutlineInputBorder(),
    filled: true,
    border: OutlineInputBorder(
        //   borderRadius: BorderRadius.all(
        // Radius.circular(15.0)),
        ),
    fillColor: AppColors.white,
    // contentPadding: EdgeInsets.all(10),
    hintStyle: TextStyles.hintStyle,
    errorStyle: TextStyles.errorStyle,
    labelStyle: TextStyles.labelStyle,
    errorMaxLines: Constants.errorMaxLines,
  );
}

Widget getRequiredField(BuildContext context, String text, bool isRequired) {
  return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RichText(
          text: TextSpan(text: text, style: TextStyles.labelStyle, children: [
            if (isRequired)
              TextSpan(
                text: " *",
                style: TextStyles.labelStyle.copyWith(
                  color: Colors.red,
                ),
              )
          ]),
        ),
      ]);
}

BoxDecoration containerBoxDecoration() {
  return BoxDecoration(
      // ignore: deprecated_member_use
      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(5));
}

BoxDecoration dialogBoxDecoration() {
  return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15.0),
      boxShadow: [
        BoxShadow(
            offset: const Offset(12, 26),
            blurRadius: 50,
            spreadRadius: 0,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(.1)),
      ]);
}
