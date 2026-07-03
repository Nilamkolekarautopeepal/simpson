import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';

class AppDropdownButtonField<T> extends StatelessWidget {
  final FormFieldSetter<T>? onSaved;
  final String label;
  final T? value;
  final bool isRequired;
  final List<T>? items;
  final ValueChanged<T> onChanged;
  final Function(T)? getLabel;
  final bool? isExpanded;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final String prefix;
  final Widget? suffixIcon;
  final bool floatingLabel;
  final String hintText;
  final AutovalidateMode? autovalidateMode;
  // final Function(T)? validator;
  final FormFieldValidator<T>? validator;
  final Color? dropdownIconColor;

  final bool enabled;
  const AppDropdownButtonField({
    Key? key,
    required this.onChanged,
    this.onSaved,
    this.label = "",
    this.hintText = "",
    this.validator,
    this.isRequired = true,
    this.isExpanded = true,
    this.enabled = true,
    this.prefixIcon,
    this.prefix = "",
    @required this.items,
    @required this.getLabel,
    this.floatingLabel = false,
    this.value,
    this.focusNode,
    this.autovalidateMode,
    this.suffixIcon,
    this.dropdownIconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!items!.contains(value)) C0();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (label.isNotEmpty)
          RichText(
            text:
                TextSpan(text: label, style: TextStyles.labelStyle, children: [
              if (isRequired)
                TextSpan(
                  text: " *",
                  style: TextStyles.labelStyle.copyWith(
                    color: Colors.red,
                  ),
                )
            ]),
          ),
        C5(),
        DropdownButtonFormField(
          focusNode: focusNode,
          validator: validator,
          autovalidateMode: autovalidateMode,
          decoration: InputDecoration(
            enabled: enabled,
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 0.0),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            hintText: hintText,
            labelText: floatingLabel ? '$label${isRequired ? ' *' : ''}' : null,
            hintStyle: TextStyles.sublable10,
            errorStyle: TextStyles.errorStyle,
            labelStyle: TextStyles.labelStyle,
            errorMaxLines: Constants.errorMaxLines,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            prefix: Text(
              prefix,
              style: TextStyles.lable14,
            ),
          ),
          // InputDecoration.collapsed(
          //   filled: true,
          //   fillColor: AppColors.white,
          //   hintStyle: TextStyles.hintStyle,
          //   hintText: label,
          // ),
          isExpanded: isExpanded!,
          value: value,
          items: items?.map<DropdownMenuItem<T>>((T data) {
            return DropdownMenuItem<T>(
              value: data,
              child: Text(
                '${getLabel!(data)}',
                style: TextStyles.lable14,
                overflow: TextOverflow.ellipsis,
                maxLines: Constants.dropDownLabelMaxLines,
                softWrap: true,
              ),
            );
          }).toList(),
          onChanged: (T? value) => onChanged(value!),
          iconEnabledColor: dropdownIconColor,
        ),
        // Divider(
        //   color: Colors.grey,
        // )
      ],
    );
  }

  Color getColor(T data) {
    if (data == value) return Colors.black;
    return Colors.grey;
  }
}
