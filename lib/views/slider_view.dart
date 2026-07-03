import 'dart:convert';
import 'package:simpson/api/app_api.dart';
import 'package:simpson/services/app_setting_services.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/utils/extension/app_extensions.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarouselScreen extends StatefulWidget {
  final bool isHomepage;

  CarouselScreen({required this.isHomepage});

  @override
  _CarouselScreenState createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  List<String> list = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    AppSetting? setting3;
    if (widget.isHomepage) {
      setting3 = await AppSettingsManager().getSetting("HomePageBanner");
    } else {
      setting3 = await AppSettingsManager().getSetting("CategoryBanner");
    }

    if (setting3 != null) {
      List<dynamic> decodedList = json.decode(setting3.value);
      setState(() {
        list = decodedList.cast<String>();
      });
    }
    if (list.isEmpty) {
      Map<String, dynamic> postData = Map();
      Map<String, dynamic> responseData = await AppAPIs.post(
          "api/AppSettings/GetAppSettingValues",
          data: postData);
      if (responseData.getBool("success")) {
        List<dynamic> rawList1 =
            responseData.getMap("response").getList("Table");
        List<AppSetting> appSettingList =
            rawList1.map((e) => AppSetting.fromJson(e)).toList();
        await AppSettingsManager().saveAllSettings(appSettingList);
        if (widget.isHomepage) {
          setting3 = await AppSettingsManager().getSetting("HomePageBanner");
        } else {
          setting3 = await AppSettingsManager().getSetting("CategoryBanner");
        }

        if (setting3 != null) {
          List<dynamic> decodedList = json.decode(setting3.value);
          setState(() {
            list = decodedList.cast<String>();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: list.isEmpty ? 0 : 150,
      child: list.isEmpty
          ? Container()
          : Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: CarouselSlider(
                options: CarouselOptions(
                    height: 400.0, autoPlay: true, viewportFraction: 0.8),
                items: list.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              );
                            },
                            placeholder: (context, url) => Container(
                              height: 120,
                              width: 120,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      // ignore: deprecated_member_use
                                      AppColors.primary.withOpacity(0.5)),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Center(child: Icon(Icons.error)),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }
}
