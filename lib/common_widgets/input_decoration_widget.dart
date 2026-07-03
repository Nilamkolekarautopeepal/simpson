import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:flutter/material.dart';


InputDecoration getInputDecoration(
  String text,
  bool isRequired,
) {
  String requiredMark = isRequired ? " *" : "";
  text = text + requiredMark;

  return InputDecoration(
    labelText: text,
    enabled: true,
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
      Radius.circular(15.0),
    )),
    filled: true,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
      Radius.circular(15.0),
    )),
    fillColor: Colors.white54,
    contentPadding: EdgeInsets.all(10),
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
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
      Radius.circular(15.0),
    )),
    filled: true,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
      Radius.circular(15.0),
    )),
    fillColor: Colors.white54,
    contentPadding: EdgeInsets.all(10),
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
