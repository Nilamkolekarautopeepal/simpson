import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyrefresh/easy_refresh.dart';

class LoadMoreWidget extends StatelessWidget {
  final Widget child;
  final Function loadData;
  final Function loadMoreData;
  final EdgeInsetsGeometry? padding;

  const LoadMoreWidget({
    Key? key,
    required this.loadMoreData,
    required this.loadData,
    required this.child,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      firstRefresh: false,
      enableControlFinishRefresh: false,
      enableControlFinishLoad: false,
      header: DeliveryHeader(
        backgroundColor: AppColors.primary,
      ),
      footer: BallPulseFooter(
        backgroundColor: Colors.white,
        color: AppColors.primary,
      ),
      onLoad: () => loadMoreData(),
      onRefresh: () => loadData(),
      child: child,
    );
  }
}
