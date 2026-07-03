import 'package:simpson/services/connectivity/connectivity_service.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/app_constants.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:simpson/utils/strings.dart';
import 'package:simpson/utils/ui_helper.dart/app_tost.dart';
import 'package:simpson/utils/ui_helper_widgets.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;

  final Color? color;
  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;

  AppButton({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.boxShadow = false,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => onTap(),
      child: Container(
        margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
        height: 48,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: style ??
                    TextStyles.productTitle.copyWith(color: AppColors.white),
                textAlign: textAlign ?? TextAlign.center,
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: (color ?? AppColors.primary),
          boxShadow: boxShadow
              ? [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: Sizes.s10,
                    spreadRadius: Sizes.s1,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;
  final Color? color;
  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String images;

  AppOutlineButton({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.boxShadow = false,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityWrapper.instance.onStatusChange,
      initialData: ConnectivityService.instance.lastConnectivityStatus,
      builder: (context, snapshot) {
        //  final bool isOnline = snapshot.data == true;
        final bool isOnline = snapshot.data == ConnectivityStatus.CONNECTED;
        //final bool isOnline = true;
        bool isEnabled = isOnline && enabled;
        if (!networkAware) {
          isEnabled = enabled;
        }
        return InkWell(
          onTap: isEnabled
              ? () async => onTap()
              : () async {
                  if (networkAware && !isOnline) {
                    AppTostMassage.showTostErrorMassage(
                        massage: Strings.internetErrorMessage);
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Sizes.s10),
              border: Border.all(
                  color: isEnabled
                      ? (color ?? AppColors.grey)
                      : AppColors.darkGrey),
              boxShadow: boxShadow
                  ? [
                      if (!isEnabled)
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                      if (isEnabled)
                        BoxShadow(
                          color: AppColors.secondary,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                    ]
                  : [],
            ),
            padding: padding ??
                EdgeInsets.symmetric(
                    horizontal: Sizes.s25, vertical: Sizes.s15),
            margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                    child: Center(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(images),
                        C5(),
                        Text(
                          title,
                          style: style ??
                              TextStyles.buttonText
                                  .copyWith(color: AppColors.black),
                          // textAlign: textAlign ?? TextAlign.center,
                        ),
                      ]),
                )),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppOutlineButtonForLogin2 extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;
  final Color? color;
  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String images;

  AppOutlineButtonForLogin2({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.boxShadow = false,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityWrapper.instance.onStatusChange,
      initialData: ConnectivityService.instance.lastConnectivityStatus,
      builder: (context, snapshot) {
        //  final bool isOnline = snapshot.data == true;
        final bool isOnline = snapshot.data == ConnectivityStatus.CONNECTED;
        //final bool isOnline = true;
        bool isEnabled = isOnline && enabled;
        if (!networkAware) {
          isEnabled = enabled;
        }
        return InkWell(
          onTap: isEnabled
              ? () async => onTap()
              : () async {
                  if (networkAware && !isOnline) {
                    AppTostMassage.showTostErrorMassage(
                        massage: Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              // ignore: deprecated_member_use
              color: AppColors.primary.withOpacity(0.2),
              border: Border.all(
                  width: 1,
                  color: isEnabled
                      ? (color ?? AppColors.primary)
                      : AppColors.primary),
              boxShadow: boxShadow
                  ? [
                      if (!isEnabled)
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                      if (isEnabled)
                        BoxShadow(
                          color: AppColors.secondary,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                    ]
                  : [],
            ),
            margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                    child: Center(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(images),
                        C5(),
                        Text(
                          title,
                          style: style ??
                              TextStyles.buttonText.copyWith(
                                  color: AppColors.primary,
                                  fontFamily: "Inter-Medium",
                                  fontWeight: FontWeight.w500,
                                  fontSize: FontSizes.s16),
                          // textAlign: textAlign ?? TextAlign.center,
                        ),
                      ]),
                )),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppOutlineButtonForLogin3 extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;
  final Color? color;
  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String images;

  AppOutlineButtonForLogin3({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.boxShadow = false,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => onTap(),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // ignore: deprecated_member_use
          color: AppColors.primary.withOpacity(0.2),
          boxShadow: boxShadow
              ? [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: Sizes.s10,
                    spreadRadius: Sizes.s1,
                  ),
                ]
              : [],
        ),
        margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
                child: Center(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left:15.0),
                      child: Text(
                        title,
                        style: style ??
                            TextStyles.buttonText.copyWith(
                                color: AppColors.primary,
                                fontFamily: "Inter-Medium",
                                fontWeight: FontWeight.w500,
                                fontSize: FontSizes.s16),
                     ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right:10.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ]),
            )),
          ],
        ),
      ),
    );
  }
}

class AppOutlineButtonForLogin extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;
  final Color? color;
  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String images;

  AppOutlineButtonForLogin({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.boxShadow = false,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityWrapper.instance.onStatusChange,
      initialData: ConnectivityService.instance.lastConnectivityStatus,
      builder: (context, snapshot) {
        //  final bool isOnline = snapshot.data == true;
        final bool isOnline = snapshot.data == ConnectivityStatus.CONNECTED;
        //final bool isOnline = true;
        bool isEnabled = isOnline && enabled;
        if (!networkAware) {
          isEnabled = enabled;
        }
        return InkWell(
          onTap: isEnabled
              ? () async => onTap()
              : () async {
                  if (networkAware && !isOnline) {
                    AppTostMassage.showTostErrorMassage(
                        massage: Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  width: 1,
                  color: isEnabled
                      ? (color ?? AppColors.grey)
                      : AppColors.darkGrey),
              boxShadow: boxShadow
                  ? [
                      if (!isEnabled)
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                      if (isEnabled)
                        BoxShadow(
                          color: AppColors.secondary,
                          blurRadius: Sizes.s10,
                          spreadRadius: Sizes.s1,
                        ),
                    ]
                  : [],
            ),
            margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                    child: Center(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(images),
                        C5(),
                        Text(
                          title,
                          style: style ??
                              TextStyles.buttonText.copyWith(
                                  color: Color(0xFF344054),
                                  fontFamily: "Inter-Medium",
                                  fontWeight: FontWeight.w500,
                                  fontSize: FontSizes.s16),
                          // textAlign: textAlign ?? TextAlign.center,
                        ),
                      ]),
                )),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppTextButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;

  final Color? color;
  final bool enabled;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;

  AppTextButton({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityWrapper.instance.onStatusChange,
      initialData: ConnectivityService.instance.lastConnectivityStatus,
      builder: (context, snapshot) {
        final bool isOnline = snapshot.data == ConnectivityStatus.CONNECTED;
        bool isEnabled = isOnline && enabled;
        if (!networkAware) {
          isEnabled = enabled;
        }
        return InkWell(
          onTap: isEnabled
              ? () async => onTap()
              : () async {
                  if (networkAware && !isOnline) {
                    AppTostMassage.showTostErrorMassage(
                        massage: Strings.internetErrorMessage);
                  }
                },
          child: Container(
            padding: padding ??
                EdgeInsets.symmetric(
                    horizontal: Sizes.s25, vertical: Sizes.s15),
            margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: style ??
                        TextStyles.buttonText.copyWith(
                          color: AppColors.primary,
                        ),
                    textAlign: textAlign ?? TextAlign.center,
                  ),
                ),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppSmallTextButton extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;

  final Color? color;
  final bool enabled;
  final bool networkAware;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;

  AppSmallTextButton({
    required this.onTap,
    required this.title,
    this.enabled = true,
    this.networkAware = false,
    this.color,
    this.padding,
    this.margin,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: ConnectivityWrapper.instance.onStatusChange,
      initialData: ConnectivityService.instance.lastConnectivityStatus,
      builder: (context, snapshot) {
        final bool isOnline = snapshot.data == ConnectivityStatus.CONNECTED;
        bool isEnabled = isOnline && enabled;
        if (!networkAware) {
          isEnabled = enabled;
        }
        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: isEnabled
              ? () async => onTap()
              : () async {
                  if (networkAware && !isOnline) {
                    AppTostMassage.showTostErrorMassage(
                        massage: Strings.internetErrorMessage);
                  }
                },
          child: Container(
            padding: padding ?? EdgeInsets.symmetric(vertical: Sizes.s5),
            margin:Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.all(16)
                : margin ?? EdgeInsets.zero,
            child: isOnline
                ? Text(
                    title,
                    style: style ??
                        TextStyles.buttonText.copyWith(
                          color: color ?? Colors.red,
                          fontSize: FontSizes.s12,
                        ),
                    textAlign: textAlign ?? TextAlign.start,
                  )
                : CupertinoActivityIndicator(),
          ),
        );
      },
    );
  }
}

class SmallButton extends StatelessWidget {
  final String title;
  final double? fontSize;
  final Function onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const SmallButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.fontSize,
    this.padding,
    this.margin,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap(),
      child: Container(
        margin: margin ??
            EdgeInsets.symmetric(
              vertical: Sizes.s8,
            ),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: Sizes.s10,
              vertical: Sizes.s6,
            ),
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          borderRadius: BorderRadius.circular(Sizes.s3),
          boxShadow: Constants.boxShadowProduct,
        ),
        child: Text(
          title,
          style: TextStyles.defaultRegular.copyWith(
            fontSize: fontSize ?? FontSizes.s15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData iconData;
  final Function onTap;
  final Function onLongPress;
  final bool enabled;
  final double? size;

  const CustomIconButton({
    Key? key,
    required this.iconData,
    required this.onTap,
    required this.onLongPress,
    this.size,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : appLogs("hi"),
      // onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.s5,
          vertical: Sizes.s5,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(Sizes.s3),
        ),
        child: Icon(
          iconData,
          color: AppColors.secondary,
          size: size ?? Sizes.s15,
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData? iconData;
  final GestureTapCallback onTap;
  final bool enabled;
  final double? size;

  const AppIconButton({
    Key? key,
    this.iconData,
    required this.onTap,
    this.size,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () async => onTap() : appLogs("hi"),
      child: Container(
        padding: EdgeInsets.all(Sizes.s15),
        decoration: BoxDecoration(
          color: AppColors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData ?? Icons.arrow_forward,
          color: AppColors.white,
          size: size ?? Sizes.s40,
        ),
      ),
    );
  }
}

class SmallDialogButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final bool invertedColors;

  const SmallDialogButton({
    required this.text,
    required this.onPressed,
    this.invertedColors = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ButtonStyle(
            // ignore: deprecated_member_use
            elevation: MaterialStateProperty.all(0),
            alignment: Alignment.center,
            side: WidgetStateProperty.all(
                BorderSide(width: 1, color: AppColors.primary)),
            padding: WidgetStateProperty.all(EdgeInsets.only(
                right: FontSizes.s20, left: FontSizes.s20, top: 0, bottom: 0)),
            backgroundColor: WidgetStateProperty.all(
                invertedColors ? AppColors.white : AppColors.primary),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            )),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
              color: invertedColors ? AppColors.primary : AppColors.white,
              fontSize: FontSizes.s14),
        ));
  }
}

class AppDialogButton extends StatelessWidget {
  final String title;
  final void Function() onTap;
  const AppDialogButton({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(56), color: AppColors.black),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            title,
            style: TextStyles.defaultBold.copyWith(
                color: AppColors.white,
                fontSize: FontSizes.s15,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// class AppGFButton extends StatelessWidget {
//   final Color? color;
//   final TextStyle? textStyle;
//   final String text;
//   final double? height;
//   final void Function() onPressed;
//   const AppGFButton({
//     super.key,
//     this.color,
//     required this.text,
//     required this.onPressed,
//     this.height,
//     this.textStyle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: Sizes.s200,
//       height: height,
//       child: GFButton(
//         textStyle: textStyle ?? TextStyles.buttonText,
//         shape: GFButtonShape.pills,
//         color: color ?? AppColors.primary,
//         onPressed: onPressed,
//         child: Text(text),
//       ),
//     );
//   }
// }
