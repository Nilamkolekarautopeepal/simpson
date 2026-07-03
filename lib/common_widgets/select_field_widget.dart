import 'package:simpson/common_widgets/input_decoration_widget.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/themes/app_textstyles.dart';
import 'package:flutter/material.dart';


class SelectFieldWidget extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? value;
  final bool? isRequired;
  final bool? enabled;
  final Function? onTap;
  final Icon? icon;
  final FocusNode? focusNode;

  const SelectFieldWidget({
    Key? key,
    this.label,
    this.hintText,
    this.value,
    this.isRequired = true,
    this.enabled = true,
    this.onTap,
    this.icon,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool showHintText = value!.trim().isEmpty;
    return InkWell(
      focusNode: focusNode,
      onTap: ()=> enabled ?? onTap,
      child: Column(
        key: Key('$value'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InputDecorator(
            textAlignVertical: TextAlignVertical.center,
            decoration: getInputDecoration1(label!, true, Icon(Icons.search)),
            child: Text(
              showHintText ? '$hintText' : '$value',
              style: showHintText
                  ? TextStyles.hintStyle
                  : TextStyles.defaultRegular,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectField1Widget extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? value;
  final bool? isRequired;
  final bool? enabled;
  final Function? onTap;
  final Icon? icon;
  final FocusNode? focusNode;

  const SelectField1Widget({
    Key? key,
    this.label,
    this.hintText,
    this.value,
    this.isRequired = true,
    this.enabled = true,
    this.onTap,
    this.icon,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool showHintText = value!.trim().isEmpty;
    return InkWell(
      focusNode: focusNode,
      onTap:()=> enabled ?? onTap,
      child: Column(
        key: Key('$value'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InputDecorator(
            textAlignVertical: TextAlignVertical.center,
            decoration: getInputDecoration1(label!, true, Icon(Icons.search))
                .copyWith(fillColor: AppColors.grey),
            child: Text(
              showHintText ? '$hintText' : '$value',
              style: TextStyles.defaultRegular,
            ),
          ),
        ],
      ),
    );
  }
}
