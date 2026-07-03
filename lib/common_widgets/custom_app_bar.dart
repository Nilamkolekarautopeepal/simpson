import 'package:autopeepalApp/common_widgets/background_widget.dart';
import 'package:autopeepalApp/common_widgets/text_field.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'custom_clipper_widget.dart';

double get extendedWidgetHeight => (screenWidth * 9) / 16;
int get maxTitleLine => 1;

AppBar appBarWithTitle({
 required String? title,
  List<Widget>? actions,
  bool titleAction = false,
}) {
  Widget titleWidget = Text(
    title!,
    style: TextStyles.appBarTitle,
    maxLines: maxTitleLine,
    overflow: TextOverflow.ellipsis,
  );
  return AppBar(
    titleSpacing: 0,
    title: titleWidget,
    actions: actions,
    backgroundColor: AppColors.primary,
  );
}

AppBar appBarWithTwoTitle({
 required String title,
 required String subTitle,
  Function? onTap,
  List<Widget>? actions,
  bool titleAction = false,
}) {
  String sortTitle = title;
  int maxLength = 20;

  if (sortTitle.length > maxLength) {
    sortTitle = sortTitle.substring(0, maxLength - 1) + "...";
  }

  Widget titleWidget = Text(
    sortTitle,
    style: TextStyles.appBarTitle.copyWith(
      fontSize: FontSizes.s15,
    ),
    maxLines: maxTitleLine,
    overflow: TextOverflow.ellipsis,
  );

  return AppBar(
    titleSpacing: 0.0,
    title: Container(
      child: GestureDetector(
        onTap:()=> titleAction ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title.length >= 30) C15(),
            if (!titleAction)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  titleWidget,
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: Sizes.s30,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
            if (titleAction)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  titleWidget,
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: Sizes.s30,
                  ),
                  Expanded(
                    child: Container(),
                  ),
                ],
              ),
            Text(
              subTitle,
              style: TextStyles.defaultRegular.copyWith(
                color: Colors.white,
                fontSize: FontSizes.s12,
              ),
              maxLines: title.length >= 30 ? null : maxTitleLine,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
    actions: actions,
  );
}

AppBar appBarWithSearch({
 required TextEditingController? searchTEC,
 required String? hintText,
 required Function onSubmitted,
  List<Widget>? actions,
}) {
  return AppBar(
    titleSpacing: 0,
    elevation: 0,
    leading: BackButton(
      color: Colors.black,
    ),
    backgroundColor: Colors.white,
    title: TextField(
      controller: searchTEC,
      decoration: InputDecoration(
        filled: true,
        disabledBorder: defaultInputBorder,
        enabledBorder: defaultInputBorder,
        focusedBorder: defaultInputBorder,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.zero,
        hintText: hintText,
        hintStyle: TextStyles.hintStyle,
        errorStyle: TextStyles.errorStyle,
        labelStyle: TextStyles.labelStyle,
      ),
      onSubmitted: (_) => onSubmitted(),
    ),
    actions: actions,
  );
}

class CustomAppBar extends StatelessWidget {
  final String title;
  final String subTitle;
  final bool showBackButton;
  final bool showLogoutButton;
  final bool? loginVerification;
  final Function? onBack;

  CustomAppBar(
      {required this.title,
     required this.subTitle,
      this.showBackButton = true,
      this.showLogoutButton = false,
      this.onBack,
      this.loginVerification});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: CustomAppBarDelegate(
          title: title,
          subTitle: subTitle,
          showBackButton: showBackButton,
          showLogoutButton: showLogoutButton,
          onBack:()=> onBack,
          loginVerification: loginVerification),
    );
  }
}

class CustomAppBarDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String subTitle;
  final bool showBackButton;
  final bool showLogoutButton;
  final Function? onBack;
  final bool? loginVerification;

  CustomAppBarDelegate({
   required this.title,
   required this.subTitle,
    this.showBackButton = true,
    this.showLogoutButton = false,
    this.loginVerification,
    this.onBack,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipperWidget(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundLinearGradientWidget(
            height: extendedWidgetHeight,
          ),
          Positioned(
            bottom: shrinkOffset / 4,
            child: Container(
              margin: EdgeInsets.only(
                bottom: extendedWidgetHeight / 3,
                left: Sizes.s20,
              ),
              child: Container(
                width: screenWidth - Sizes.s20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        // DevService.instance.openDevScreen(context);
                      },
                      child: Text(
                        title,
                        style: TextStyles.defaultRegular.copyWith(
                          fontSize: FontSizes.s25,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    C10(),
                    Text(
                      subTitle,
                      style: TextStyles.defaultRegular.copyWith(
                        fontSize: FontSizes.s16,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
                top: Sizes.s30 - shrinkOffset,
                child: BackButton(
                  color: Colors.white,
                  onPressed:()=> onBack,
                )),
          if (showLogoutButton)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: Sizes.s20),
                child: IconButton(
                  icon: Icon(
                    Icons.settings_power,
                    color: Colors.white,
                    size: Sizes.s40,
                  ),
                  onPressed: () => {}//auth.logout(context),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  double get maxExtent => extendedWidgetHeight;

  @override
  double get minExtent => kToolbarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}
