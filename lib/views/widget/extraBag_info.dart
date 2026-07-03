import 'package:autopeepalApp/common_widgets/ui_helper_widgets.dart';
import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExtraBagInfo extends StatelessWidget {
  const ExtraBagInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 24),
        child: Column(
          children: [
            Text('Extra Bag Info',
              style: TextStyle(
                fontFamily: "Inter-Bold",
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            C10(),  
            Expanded(
              child: Text(
                'Our delivery partner is limited to carry approx 12kgs of items, hence we split your items into multiple packages with optimal weight combination to save cost.',
                style: TextStyle(
                  fontFamily: "Inter-Normal",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085)
                ),
                textAlign: TextAlign.center,
              )
            ), 
            Expanded(
              child: Text(
                'The delivery fee shown and charged is per package and not per order due to weight constraint. If your order is split into multiple packages, you may receive it from more than one delivery drivers.',
                style: TextStyle(
                  fontFamily: "Inter-Normal",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085)
                ),
                textAlign: TextAlign.center,
              )
            ),  
            Expanded(
              child: Text(
                "Please note, any changes made to the order, post placement via ‘Edit Order’ or ‘Shopper Communication’ while shopping may result into change in package count based on weight at that",
                style: TextStyle(
                  fontFamily: "Inter-Normal",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085)
                ),
                textAlign: TextAlign.center,
              )
            ),
            C5(),
            InkWell(
              onTap: (){
                Get.back();
              },
              child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Text(
                        "Okay",
                        style: TextStyle(
                            fontFamily: "Inter-SemiBold",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white),
                      ),
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}