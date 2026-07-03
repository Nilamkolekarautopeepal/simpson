import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/extension/app_extensions.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:simpson/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';

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
      onTap: () => onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: Sizes.s10, vertical: Sizes.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label.asEmptyIfEmptyOrNull,
              style: TextStyles.smallLabel.copyWith(
                fontFamily: "Inter-Medium",
              ),
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
              style: labelStyle ??
                  TextStyles.labelStyle.copyWith(
                    fontFamily: "Inter-Medium",
                  ),
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

class LabelsWithMark extends StatelessWidget {
  final String label;
  final bool? isColor;
  final bool? isRequired;
  const LabelsWithMark(
      {super.key, required this.label, this.isColor, this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5, bottom: 10),
      child: RichText(
        overflow: TextOverflow.clip,
        textAlign: TextAlign.start,
        softWrap: true,
        maxLines: 1,
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: Color(0xFF667085),
              fontSize: FontSizes.s14,
              fontFamily: "Inter-Medium",
              fontWeight: FontWeight.w500),
          children: isRequired == true
              ? <TextSpan>[
                  TextSpan(
                      text: ' *',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isRequired == true ? Color(0xFF667085) : null))
                ]
              : null,
        ), textScaler: TextScaler.linear(1),
      ),
    );
  }
}

class LabelsWithMark1 extends StatelessWidget {
  final String label;
  final bool? isColor;
  final bool? isRequired;
  const LabelsWithMark1(
      {super.key, required this.label, this.isColor, this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5, bottom: 3),
      child: RichText(
        overflow: TextOverflow.clip,
        textAlign: TextAlign.start,
        softWrap: true,
        maxLines: 1,
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: Color(0xFF667085),
              fontFamily: "Inter-Medium",
              fontSize: FontSizes.s14,
              fontWeight: FontWeight.w500),
          children: isRequired == true
              ? <TextSpan>[
                  TextSpan(
                      text: ' *',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isRequired == true ? Colors.red : null))
                ]
              : null,
        ), textScaler: TextScaler.linear(1),
      ),
    );
  }
}
