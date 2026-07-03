import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextFormField extends StatelessWidget {
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final String label;
  final String prefix;
  final String hintText;
  final String? initialValue;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final bool obscureText;
  final bool isNumber;
  final bool floatingLabel;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization? textCapitalization;
  final AutovalidateMode? autovalidateMode;

  const AppTextFormField({
    Key? key,
    this.controller,
    this.onSaved,
    this.validator,
    this.label = "",
    this.hintText = "",
    this.prefix = "",
    this.maxLength,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.isNumber = false,
    this.obscureText = false,
    this.autofocus = false,
    this.floatingLabel = false,
    this.initialValue,
    this.focusNode,
    this.maxLines = 1,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.inputFormatters,
    this.textCapitalization,
    this.autovalidateMode,
    this.textInputAction = TextInputAction.done,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readOnly) return buildReadOnlyTextField();

    Widget textFieldWidget = TextFormField(
      autovalidateMode: autovalidateMode,
      autofocus: autofocus,
      controller: controller,
      cursorColor: AppColors.primary,
      focusNode: focusNode,
      decoration: 
      InputDecoration(
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
        hintStyle: TextStyles.hintStyle,
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
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        if (isNumber) FilteringTextInputFormatter.allow(RegExp("[0-9]")),
        if (inputFormatters != null) ...?inputFormatters
      ],
      onSaved: onSaved,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      keyboardType: isNumber ? TextInputType.number : keyboardType,
      enabled: enabled,
      initialValue: initialValue,
      textInputAction: textInputAction,
      style: TextStyles.editText.copyWith(
        fontSize: FontSizes.s14,
        fontFamily: 'Inter-Regular',
        color: enabled ? Colors.black : Colors.grey,
      ),
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization ?? TextCapitalization.sentences,
    );

    if (floatingLabel) return textFieldWidget;

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
        textFieldWidget,
      ],
    );
  }

  Widget buildReadOnlyTextField() {
    String value = initialValue ?? "";

    if (value.isEmpty && controller != null) value = controller!.text;

    return Column(
      key: Key('$value'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (label.isNotEmpty)
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyles.labelStyle,
              children: [
                if (isRequired)
                  TextSpan(
                    text: " *",
                    style: TextStyles.labelStyle.copyWith(
                      color: Colors.red,
                    ),
                  )
              ],
            ),
          ),
        InputDecorator(
          decoration: InputDecoration(
            enabled: enabled,
            //disabledBorder: defaultInputBorder,
            filled: true,
            fillColor: AppColors.greyLight,
            contentPadding: EdgeInsets.zero,
            hintText: hintText,
            hintStyle: TextStyles.hintStyle,
            errorStyle: TextStyles.errorStyle,
            labelStyle: TextStyles.labelStyle,
            errorMaxLines: Constants.errorMaxLines,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            prefix: Text(
              prefix,
              style: TextStyles.lable14,
            ),
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
          ),
          child: Text(
            ' $value',
            style: TextStyles.lable14,
          ),
        ),
      ],
    );
  }
}

// class AppQuantityField extends StatelessWidget {
//   final String hintText;
//   final int maxLength;
//   final int maxLines;
//   final double? fontSize;
//   final TextInputType? keyboardType;
//   final bool enabled;
//   final TextEditingController? controller;
//   final bool autofocus;
//   final ValueChanged<String>? onSubmitted;
//   final ValueChanged<String>? onChanged;

//   const AppQuantityField({
//     Key? key,
//     this.autofocus = false,
//     this.controller,
//     this.hintText = "",
//     this.maxLength = 6,
//     this.fontSize,
//     this.keyboardType,
//     this.onSubmitted,
//     this.onChanged,
//     this.enabled = true,
//     this.maxLines = 1,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return FittedTextFieldContainer(
//       // minWidth: Sizes.s40,
//       child: TextField(
//         autofocus: autofocus,
//         controller: controller,
//         textAlign: TextAlign.center,
//         decoration: InputDecoration.collapsed(
//           enabled: enabled,
//           filled: true,
//           fillColor: AppColors.white,
//           hintText: hintText,
//           hintStyle: TextStyles.hintStyle,
//         ),
//         inputFormatters: [
//           if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
//           // ignore: deprecated_member_use
//           // WhitelistingTextInputFormatter(RegExp("[0-9]")),
//         ],
//         keyboardType: TextInputType.number,
//         enabled: enabled,
//         textInputAction: TextInputAction.done,
//         style: TextStyles.editText.copyWith(
//           color:AppColors.primary,
//           fontSize: fontSize,
//         ),
//         maxLines: maxLines,
// //        maxLength: maxLength,
//         textCapitalization: TextCapitalization.sentences,
//         onSubmitted: onSubmitted,
//         onChanged: onChanged,
//       ),
//     );
//   }
// }

BorderRadius defaultBorderRadius = BorderRadius.all(
  Radius.circular(Sizes.s10),
);

InputBorder defaultInputBorder = UnderlineInputBorder(
  borderSide: BorderSide(
    color: AppColors.pinkishGrey,
    width: Sizes.s1,
  ),
);
InputBorder defaultErrorInputBorder = UnderlineInputBorder(
  borderSide: BorderSide(
    color: AppColors.error,
    width: Sizes.s1,
  ),
);

InputBorder defaultFocusInputBorder = UnderlineInputBorder(
  borderSide: BorderSide(
    color: AppColors.primary,
    width: Sizes.s1,
  ),
);
