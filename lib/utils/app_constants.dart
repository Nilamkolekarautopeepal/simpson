// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simpson/themes/app_colors.dart';

// final List<String> defaultList = [Strings.select];

///App Constants
///
class Constants {
  /*Delay Constants*/

  static const Duration milliseconds100 = Duration(milliseconds: 100);
  static const Duration milliseconds300 = Duration(milliseconds: 100);
  static const Duration milliseconds700 = Duration(milliseconds: 700);
  static const Duration delayM = Duration(milliseconds: 1500);
  static const Duration delayL = Duration(milliseconds: 3000);
  static const Duration delayS = Duration(milliseconds: 400);
  static const int delayExtraSmall = 100;
  static const int delaySmall = 200;
  static const int addToCartDelay = 150;
  static const int delayMedium = 500;
  static const int delayLarge = 1000;
  static const int delayXL = 1500;
  static const int delayXXL = 2000;
  static const int splashDelay = 4;
  static const int pageLimit = 15;
  static const int oneRecord = 1;
  static const int allRecords = 0;
  static const int searchMinimumCh = 2;
  static const int defaultOffset = 0;
  static const int errorMaxLines = 3;
  static const int mobileNumberLength = 10;
  static const int otpLength = 6;
  static const int addressDetailsMaxLength = 240;
  static const int addressDetailsMaxLine = 4;
  static const int editTextMaxLines = 1;
  static const int dropDownLabelMaxLines = 2;
  static const String indiaPhoneCode = "+91";
  static const String countryCode = "INDIA";
  static const int maxCodeLength = 30;
  static const int promoCodeLength = 15;
  static const int empCodeLength = 5;
  static const int descriptionLength = 240;
  static const double viewportFraction = 1.0;
  static const double defaultAspectRatio = 1.0;
  static const double lineAspectRatio = 4 / 3;
  static const Pattern userNamePattern = r"^[a-zA-Z. ']+$";
  static const int searchOneCharacter = 1;
  static const Pattern addressPattern = r"^[^\s].+[^\s]$";
  static const Pattern onlyNumbers = r'[0-9]';
  static const Pattern phonePattern = r'^[6-9]\d{9}$';
  static const Pattern code1Pattern = r'^[a-zA-Z0-9-]+$';
  static const Pattern code2Pattern = r'^[a-zA-Z-.]+$';
  static const Pattern masterCodePattern = r'^(?! )[A-Z0-9-_\/]*(?<! )$';
  static const Pattern masterNamePattern =r'^(?! )[A-Za-z0-9-()-_\s\/]*(?<! )$';
  static const Pattern masterProdNamePattern =r'^(?! )[A-Za-z0-9-&-_\s\/]*(?<! )$';
  static const Pattern masterProdHSNGtinPattern = r'^(?! )[0-9]*(?<! )$';
  static const Pattern masterProdDecimalPattern = r'^[0-9]+(\.[0-9]{1,2})?$';
  static const Pattern masterCommonPatternWithOutSpace =r'^(?! )[A-Za-z0-9-_\s\/]*(?<! )$';
  static const Pattern masterCommonPattern =r"^[A-Za-z0-9-_\.\^\,\;\:\*\'@#$=+/\[\]\\()\s\/]*$";
  static const Pattern pinCodePattern = r"[1-9]{1}[0-9]{5}";
  static List<TextInputFormatter> code1Formatters = [
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9-]")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),];
    static List<TextInputFormatter> code2Formatters = [
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z-.]")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),];
    static List<TextInputFormatter> userNameFormatter = [
    FilteringTextInputFormatter.allow(RegExp("[a-zA-Z ']")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> nameFormatter = [
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9. ']")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> nameOfCard = [
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z ']")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> paymentFormater = [
    FilteringTextInputFormatter.allow(RegExp("[0-9.']")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
    LengthLimitingTextInputFormatter(7),
  ];

  static List<TextInputFormatter> expFormater = [
    FilteringTextInputFormatter.allow(RegExp("[0-9.']")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
    LengthLimitingTextInputFormatter(2),
  ];

  static List<TextInputFormatter> capitalAlphaNumeric = [
    FilteringTextInputFormatter.allow(RegExp("[A-Z0-9]")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> mobileNumber = [
    FilteringTextInputFormatter.allow(RegExp("[0-9]{0,9}")),
    LengthLimitingTextInputFormatter(10),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> searchTextField = [
    LengthLimitingTextInputFormatter(10),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> pincodeNumber = [
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9 ']")),
    LengthLimitingTextInputFormatter(7),
  ];
  static List<TextInputFormatter> pincodeNumber2 = [
    FilteringTextInputFormatter.allow(RegExp("[A-Z0-9 ']")),
    LengthLimitingTextInputFormatter(7),
  ];
  static List<TextInputFormatter> ageNumber = [
    FilteringTextInputFormatter.allow(RegExp("[0-9]{0,9}")),
    LengthLimitingTextInputFormatter(3),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> otp = [
    FilteringTextInputFormatter.allow(RegExp("[0-9]{0,9}")),
    LengthLimitingTextInputFormatter(otpLength),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> addressTextField = [
    FilteringTextInputFormatter.allow(RegExp("[^&<>']")),
    LengthLimitingTextInputFormatter(100),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> branchNameTextField = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_ -]')),
    LengthLimitingTextInputFormatter(40),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> bucessineTextField = [
    FilteringTextInputFormatter.allow(RegExp("[^&<>']")),
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9 ']")),
    LengthLimitingTextInputFormatter(40),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];
  static List<TextInputFormatter> nameTextField = [
    FilteringTextInputFormatter.allow(RegExp("[^&<>']")),
    FilteringTextInputFormatter.allow(RegExp("[A-Za-z ']")),
    LengthLimitingTextInputFormatter(40),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];

  static List<TextInputFormatter> timeDuration = [
    FilteringTextInputFormatter.allow(RegExp("[0-9]")),
    LengthLimitingTextInputFormatter(3),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];

  static List<TextInputFormatter> cardFormater = [
    LengthLimitingTextInputFormatter(19),
    FilteringTextInputFormatter.allow(RegExp("[0-9]")),
    CardNumberFormatter(),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];

  static List<TextInputFormatter> cvvFormater = [
    LengthLimitingTextInputFormatter(3),
    FilteringTextInputFormatter.allow(RegExp("[0-9]")),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];

  static List<TextInputFormatter> monthYearFormater = [
    LengthLimitingTextInputFormatter(5),
    FilteringTextInputFormatter.allow(RegExp("[0-9]")),
    MonthYearInputFormatter(),
    FilteringTextInputFormatter.deny(RegExp("^\\s")),
  ];

  static List<BoxShadow> boxShadowList = [
    BoxShadow(
      color: Color(0x33c4c4c4),
      offset: Offset(0, 2),
      blurRadius: 19,
      spreadRadius: 0,
    )
  ];
  static List<BoxShadow> boxShadowProduct = [
    BoxShadow(
        color: Color(0x56282828),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0)
  ];

  static const String fullDay = "FULL DAY";
  static const String halfDay = "HALF DAY";
  static const String other = "OTHER";
  static const int defaultOutletId = 15;
  static const int defaultOrgId = 2;
  static const int defaultDistributorId = 1000;
  static const int defaultBannerLimit = 25;

  //DO NOT ADD MORE STATUS
  static const List<String> defaultStatusList = ['ACTIVE', 'INACTIVE'];
  static const String payment = "PAYMENT";

  static List<Color> gradientColors = [
    AppColors.primary,
    AppColors.secondary,
  ];
  static const int maxPincodeLength = 4;
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue previousValue, TextEditingValue nextValue) {
    String inputText = nextValue.text;

    if (nextValue.selection.baseOffset == 0) {
      return nextValue;
    }

    StringBuffer bufferString = StringBuffer();
    for (int i = 0; i < inputText.length; i++) {
      bufferString.write(inputText[i]);
      int nonZeroIndexValue = i + 1;
      if (nonZeroIndexValue % 4 == 0 && nonZeroIndexValue != inputText.length) {
        bufferString.write(' ');
      }
    }

    String string = bufferString.toString();
    return nextValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class MonthYearInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final StringBuffer newText = StringBuffer();
    final String cleanedText = newValue.text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < cleanedText.length; i++) {
      if (i == 2) {
        newText.write('/');
      }
      newText.write(cleanedText[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
