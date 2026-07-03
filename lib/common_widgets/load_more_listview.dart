import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';

class LoadMoreListView extends StatelessWidget {
  final List<Widget> children;
  final Function loadData;
  final Function loadMoreData;
  final EdgeInsetsGeometry? padding;

  const LoadMoreListView({
    Key? key,
    required this.loadMoreData,
    required this.loadData,
    required this.children,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      // header: DeliveryHeader(
      //   backgroundColor: AppColors.primary,
      // ),
      // footer: BallPulseFooter(
      //   backgroundColor: Colors.white,
      //   color: AppColors.primary,
      // ),
      onLoad: () => loadMoreData() != null ? loadMoreData() : null,
      onRefresh: () => loadData() != null ? loadData() : null,
      child: ListView(
        children: children,
        padding: padding,
      ),
    );
  }
}
