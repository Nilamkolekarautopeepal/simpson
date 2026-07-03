import 'dart:async';
import 'dart:ui';

import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/utils/app_logs.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';


const double _blurFactor = 2.0;

class AppLoader {
  static bool _isLoading = false;

  static void start() {
    appLogs('AppLoader.start');
    _isLoading = true;
    // ignore: deprecated_member_use
    final loadingWidget = WillPopScope(
      onWillPop: () => Future.value(false),
      child: Material(
        child: FullScreenLoaderWidget(),
        type: MaterialType.transparency,
      ),
    );
    Get.to(
      loadingWidget,
      opaque: false,
      transition: Transition.fadeIn,
    );
  }

  static void stop() {
    if (_isLoading) {
      appLogs('AppLoader.stop');
      _isLoading = false;
      Get.back();
    }
  }
}

class FullScreenLoaderWidget extends StatelessWidget {
  const FullScreenLoaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: _blurFactor,
        sigmaY: _blurFactor,
      ),
      child: new Container(
        color: Colors.white10,
        child: new Center(
          child: LoadingWidget(),
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final double? size;

  const LoadingWidget({Key? key, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SpinKitRipple(
          color: AppColors.primary,
          size: size ?? Sizes.s150,
        ),
        SpinKitRing(
          color: AppColors.primary,
          size: size ?? Sizes.s50,
          lineWidth: Sizes.s5,
        ),
      ],
    );
  }
}
