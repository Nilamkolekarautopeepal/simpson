import 'package:flutter/material.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/extension/string_extensions.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';


class LabelValueWidget extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextAlign? textAlign;
  final Function? onTap;

  const LabelValueWidget({
    Key? key,
    required this.label,
    required this.value,
    this.textAlign,
    this.valueStyle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:()=> onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: Sizes.s10, vertical: Sizes.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label.asEmptyIfEmptyOrNull,
              style: TextStyles.smallLabel,
              textAlign: textAlign ?? TextAlign.start,
            ),
            Text(
              value.asEmptyIfEmptyOrNull,
              style: valueStyle ?? TextStyles.valueStyle,
              textAlign: textAlign ?? TextAlign.start,
            )
          ],
        ),
      ),
    );
  }
}

class LabelValueEndWidget extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;

  const LabelValueEndWidget({
    Key? key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sizes.s10, vertical: Sizes.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label.asEmptyIfEmptyOrNull,
              style: labelStyle ?? TextStyles.labelStyle,
              textAlign: TextAlign.start,
            ),
          ),
          C10(),
          Expanded(
            child: Text(
              value.asEmptyIfEmptyOrNull,
              style: valueStyle ?? TextStyles.valueStyle,
              textAlign: TextAlign.end,
            ),
          )
        ],
      ),
    );
  }
}
