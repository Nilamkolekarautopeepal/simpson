import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';

class BillingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  const BillingRow({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.unitTextStyle,
          ),
          C10(), // Add space between label and value
          Expanded(
            child: Text(
              value,
              style: TextStyles.billcount,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class BillingRowWithPrimary extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  const BillingRowWithPrimary({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.unitTextStyle.copyWith(color: AppColors.primary),
          ),
          C10(), // Add space between label and value
          Expanded(
            child: Text(
              value,
              style: TextStyles.billcount.copyWith(color: AppColors.primary),
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
class BillingRowWithPrimaryRefund extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  const BillingRowWithPrimaryRefund({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.unitTextStyle.copyWith(color: AppColors.primary),
          ),
          C10(), // Add space between label and value
          Expanded(
            child: Text(
              value,
              style: TextStyles.billcount.copyWith(color: AppColors.primary,fontSize: 14,fontWeight: FontWeight.bold),
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
class BillingRowFinalPay extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  const BillingRowFinalPay({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.productTitle,
          ),
          C10(), // Add space between label and value
          Expanded(
            child: Text(
              value,
              style: TextStyles.productTitle,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class BillingRowHeading extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  const BillingRowHeading({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.unitTextStyle.copyWith(color: AppColors.gray800),
          ),
          C10(), // Add space between label and value
          Expanded(
            child: Text(
              value,
              style: TextStyles.productTitle.copyWith(fontSize: 14),
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class BillingRowwithinfoIcon extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final bool istopPadding;
  final Function() onTap;

  const BillingRowwithinfoIcon({
    Key? key,
    required this.label,
    required this.value,
    this.alignRight = false,
    required this.istopPadding,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: istopPadding == true ? 8.0 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyles.unitTextStyle,
              ),
              C2(),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: InkWell(
                  onTap: onTap,
                  child: Icon(
                    Icons.info,
                    color: Color(0xFFD0D5DD),
                    size: 12,
                  ),
                ),
              )
            ],
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.billcount,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
