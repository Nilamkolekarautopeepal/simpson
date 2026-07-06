import 'package:simpson/themes/app_textstyles.dart';
import 'package:flutter/material.dart';

class TextFieldLableWidget extends StatelessWidget {
  const TextFieldLableWidget({super.key, required this.lable});
  final String lable;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(lable, style: TextStyles.textFieldLable),
    );
  }
}

//