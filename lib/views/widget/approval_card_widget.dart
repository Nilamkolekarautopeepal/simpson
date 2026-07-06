import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApprovalCard extends StatelessWidget {
  final IconData icon;
  final String approvalType;
  final String userName;
 final String routes;
  const ApprovalCard({
    super.key,
    required this.icon,
    required this.approvalType,
    required this.userName, 
    required this.routes,

  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ()=>Get.toNamed(routes),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:  AppColors.white,
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(approvalType, style:TextStyles.title),
          // subtitle: Text("\$userName"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
