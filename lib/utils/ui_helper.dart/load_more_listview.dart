import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:simpson/themes/app_colors.dart';

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
        header: DeliveryHeader(
          backgroundColor: AppColors.primary,
        ),
        footer: BallPulseFooter(
          backgroundColor: Colors.white,
          color: AppColors.primary,
        ),
        onLoad: () async => loadMoreData(),
        onRefresh: () async => loadData(),
        child: ListView(
          children: children.isNotEmpty
              ? children
              : [
                  Container(
                    height: MediaQuery.of(Get.context!).size.height / 1,
                    child: Center(
                        child:
                         
                            Text("No Data Found")),
                  )
                ],
          padding: padding,
        )
        /*
         ListView(
          children: [
           Container(width: double.infinity, child: Column(children: children)),
            Text("No more data")
          ],
           padding: padding,
         ),*/
        );
  }
}
