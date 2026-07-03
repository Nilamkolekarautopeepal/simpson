import 'package:simpson/common_widgets/text_field.dart';
import 'package:simpson/services/connectivity/connectivity_service.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/app_constants.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// custom button widgets
///

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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 58,
            // padding: padding ??
            //     EdgeInsets.symmetric(
            //         horizontal: Sizes.s25, vertical: Sizes.s15),
            margin: margin ?? EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: style ??
                        TextStyles.productTitle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white),
                    textAlign: textAlign ?? TextAlign.center,
                  ),
                ),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(Sizes.s9),
              ),
              color: isEnabled
                  ? (color ?? AppColors.primary)
                  : AppColors.pinkishGrey,
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
          ),
        );
      },
    );
  }
}

class AppButtonRow extends StatelessWidget {
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

  AppButtonRow({
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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 48,
            // padding: padding ??
            //     EdgeInsets.symmetric(
            //         horizontal: Sizes.s25, vertical: Sizes.s15),
            margin: margin ?? EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: style ??
                          TextStyles.productTitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white),
                      textAlign: textAlign ?? TextAlign.center,
                    ),
                    Text(
                      "Continue >",
                      style: style ??
                          TextStyles.productTitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white),
                    ),
                    if (!isOnline) CupertinoActivityIndicator()
                  ],
                ),
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(Sizes.s12),
              ),
              color: isEnabled
                  ? (color ?? AppColors.primary)
                  : AppColors.pinkishGrey,
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
          ),
        );
      },
    );
  }
}

class AppButtonRow2 extends StatelessWidget {
  final GestureTapCallback onTap;
  final String title;

  final Color? color;
  final Color? color2;

  final bool enabled;
  final bool boxShadow;
  final bool networkAware;
  final bool isContinoueVisible;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? style;
  final TextAlign? textAlign;

  AppButtonRow2({
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
    this.color2,
    required this.isContinoueVisible,
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
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: isEnabled ? onTap : () {},
            child: Container(
               height: 48,
             // margin: margin ?? EdgeInsets.zero,
              child: Padding(
                padding:  EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Row(
                    mainAxisAlignment: isContinoueVisible == true
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: style ??
                            TextStyles.productTitle.copyWith(
                                fontWeight: FontWeight.w600, color: color2),
                        textAlign: textAlign ?? TextAlign.center,
                      ),
                      Visibility(
                        visible: isContinoueVisible,
                        child: Text(
                          "Continue >",
                          style: style ??
                              TextStyles.productTitle.copyWith(
                                  fontWeight: FontWeight.w600, color: color2),
                        ),
                      ),
                      if (!isOnline) CupertinoActivityIndicator()
                    ],
                  ),
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(Sizes.s15),
                ),
                color: isEnabled
                    ? (color ?? AppColors.primary)
                    : AppColors.pinkishGrey,
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
            ),
          ),
        );
      },
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
  final double? buttonWidth;

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
    this.buttonWidth,
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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            width: buttonWidth,
            decoration: BoxDecoration(
              
              borderRadius: defaultBorderRadius,
              border: Border.all(
                  color: isEnabled
                      ? (color ?? AppColors.primary)
                      : AppColors.pinkishGrey),
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
            margin: margin ?? EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: style ??
                        TextStyles.buttonText.copyWith(
                            color: isEnabled
                                ? (color ?? AppColors.primary)
                                : AppColors.pinkishGrey),
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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            padding: padding ??
                EdgeInsets.symmetric(
                    horizontal: Sizes.s25, vertical: Sizes.s15),
            margin: margin ?? EdgeInsets.zero,
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
          onTap: isEnabled
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            padding: padding ?? EdgeInsets.symmetric(vertical: Sizes.s5),
            margin: margin ?? EdgeInsets.zero,
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
  final Function? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const SmallButton({
    Key? key,
    required this.title,
    this.onTap,
    this.fontSize,
    this.padding,
    this.margin,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap,
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
  final Function? onTap;
  final Function? onLongPress;
  final bool enabled;
  final double? size;

  const CustomIconButton({
    Key? key,
    required this.iconData,
    this.onTap,
    this.onLongPress,
    this.size,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => enabled ? onTap : null,
      onLongPress: () => onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.s5,
          vertical: Sizes.s5,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color:AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(Sizes.s3),
        ),
        child: Icon(
          iconData,
          color:AppColors.primary,
          size: size ?? Sizes.s15,
        ),
      ),
    );
  }
}

class AppButtonLoaading extends StatelessWidget {
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
  final bool? isLoading;

  AppButtonLoaading({
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
    this.isLoading,
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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 48,
            // padding: padding ??
            //     EdgeInsets.symmetric(
            //         horizontal: Sizes.s25, vertical: Sizes.s15),
            margin: margin ?? EdgeInsets.zero,
            child: Visibility(
              visible: isLoading == false,
              replacement: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      width: 50,
                      padding: EdgeInsets.all(10),
                      child: Container(),) //CircularProgressIndicator()),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: style ??
                          TextStyles.productTitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white),
                      textAlign: textAlign ?? TextAlign.center,
                    ),
                  ),
                  if (!isOnline) CupertinoActivityIndicator()
                ],
              ),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(Sizes.s12),
              ),
              color: isEnabled
                  ? (color ?? AppColors.primary)
                  : AppColors.pinkishGrey,
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
          ),
        );
      },
    );
  }
}

class AppButtonPColor extends StatelessWidget {
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

  AppButtonPColor({
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
              ? onTap
              : () {
                  if (networkAware && !isOnline) {
                    // AppToast.showMessage(Strings.internetErrorMessage);
                  }
                },
          child: Container(
            height: 48,

            // padding: padding ??
            //     EdgeInsets.symmetric(
            //         horizontal: Sizes.s25, vertical: Sizes.s15),
            margin: margin ?? EdgeInsets.zero,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: style ??
                        TextStyles.productTitle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                    textAlign: textAlign ?? TextAlign.center,
                  ),
                ),
                if (!isOnline) CupertinoActivityIndicator()
              ],
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(Sizes.s12),
              ),
              border: Border.all(
                  color: !isEnabled ? AppColors.gray800 : AppColors.primary),
              color: isEnabled
                  ? (color ?? AppColors.primary)
                  : AppColors.pinkishGrey,
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
          ),
        );
      },
    );
  }
}
