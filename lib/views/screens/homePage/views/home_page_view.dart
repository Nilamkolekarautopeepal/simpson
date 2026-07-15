// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:simpson/common_widgets/custom_app_bar.dart';
// import 'package:simpson/dev/dev_screen.dart';
// import 'package:simpson/themes/app_colors.dart';
// import '../controllers/home_page_controller.dart';


// class HomePageView extends GetView<HomePageController> {
//   const HomePageView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: controller.station,
//         actions: [
//           Obx(
//             () => InkWell(
//               onTap: controller.retryPlcConnection,
//               borderRadius: BorderRadius.circular(6),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (controller.isPlcConnecting.value)
//                       const SizedBox(
//                         width: 10,
//                         height: 10,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 1.6, color: Colors.white),
//                       )
//                     else
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: controller.isPlcConnected.value
//                               ? Colors.greenAccent
//                               : Colors.redAccent,
//                         ),
//                       ),
//                     const SizedBox(width: 8),
//                     Text(
//                       controller.isPlcConnecting.value
//                           ? 'Connecting…'
//                           : (controller.isPlcConnected.value ? 'PLC ' : 'PLC '),
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12.5,
//                           fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Obx(() {
//             if (!controller.canConnectDongle.value) {
//               return const SizedBox.shrink();
//             }
//             return InkWell(
//               onTap: controller.retryDongleConnection,
//               borderRadius: BorderRadius.circular(6),
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (controller.dongleConnecting.value)
//                       const SizedBox(
//                         width: 10,
//                         height: 10,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 1.6, color: Colors.white),
//                       )
//                     else
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: controller.dongleConnected.value
//                               ? Colors.greenAccent
//                               : Colors.redAccent,
//                         ),
//                       ),
//                     const SizedBox(width: 8),
//                     Text(
//                       controller.dongleConnecting.value
//                           ? 'Connecting…'
//                           : 'Dongle ',
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12.5,
//                           fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: controller.logout,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       backgroundColor: const Color(0xFFF4F5F7),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildSidebar(),
//           Expanded(child: _buildMainContent()),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebar() {
//     return Container(
//       width: 230,
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Expanded(
//             child: Obx(
//               () {
//                 final visibleCount = (controller.currentStepIndex.value + 1)
//                     .clamp(0, controller.steps.length);
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   itemCount: visibleCount,
//                   itemBuilder: (context, index) {
//                     final step = controller.steps[index];
//                     if (step.type == StepType.iqaGroup) {
//                       return _buildIqaGroupTile(index);
//                     }
//                     return _buildStepTile(index);
//                   },
//                 );
//               },
//             ),
//           ),
//           const Divider(height: 1),
//           InkWell(
//             onTap: () => _showRecipeDialog(),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),
//                   const SizedBox(width: 10),
//                   Text(
//                     'Recipe',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   const Spacer(),
//                   Obx(
//                     () => controller.harnessReceipes.isEmpty
//                         ? const SizedBox.shrink()
//                         : Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 7, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: AppColors.themeColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               '${controller.harnessReceipes.length}',
//                               style: TextStyle(
//                                   fontSize: 11, color: AppColors.themeColor),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Divider(height: 1),
//           InkWell(
//             onTap: () => Get.to(() => const DevLogsPage()),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Icon(Icons.bug_report_outlined,
//                       size: 18, color: Colors.grey.shade700),
//                   const SizedBox(width: 10),
//                   Text(
//                     'API Logs',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepTile(int index) {
//     final step = controller.steps[index];
//     final isCompleted = index < controller.currentStepIndex.value;
//     final isActive = index == controller.currentStepIndex.value;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
//                 size: 16,
//                 color:
//                     isCompleted ? AppColors.themeColor : AppColors.themeColor,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 step.label,
//                 style: TextStyle(
//                   fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//                   color: Colors.black87,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           TextField(
//             cursorColor: AppColors.themeColor,
//             controller: controller.stepControllers[index],
//             focusNode: controller.stepFocusNodes[index],
//             enabled: true,
//             style: const TextStyle(fontSize: 13),
//             decoration: InputDecoration(
//               isDense: true,
//               filled: true,
//               fillColor:
//                   isCompleted ? Colors.green.withOpacity(0.06) : Colors.white,
//               contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: Colors.grey.shade200),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: AppColors.themeColor),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
//               ),
//               hintText: isActive ? 'Scan or enter ${step.label}' : '',
//             ),
//             onChanged: (_) => controller.onFieldChanged(index),
//             onSubmitted: (_) => controller.submitStep(index),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIqaGroupTile(int index) {
//     final isActive = index == controller.currentStepIndex.value;
//     final isCompleted = index < controller.currentStepIndex.value;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
//                 size: 16,
//                 color: AppColors.themeColor,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 'IQA',
//                 style: TextStyle(
//                   fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//                   color: Colors.black87,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           ...List.generate(controller.iqaLabels.length, (i) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     controller.iqaLabels[i],
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 2),
//                   // TextField(
//                   //   cursorColor: AppColors.themeColor,
//                   //   controller: controller.iqaControllers[i],
//                   //   focusNode: controller.iqaFocusNodes[i],
//                   //   enabled: true,
//                   //   style: const TextStyle(fontSize: 13),
//                   //   decoration: InputDecoration(
//                   //     isDense: true,
//                   //     filled: true,
//                   //     fillColor: Colors.white,
//                   //     contentPadding: const EdgeInsets.symmetric(
//                   //         horizontal: 12, vertical: 12),
//                   //     border: OutlineInputBorder(
//                   //       borderRadius: BorderRadius.circular(6),
//                   //       borderSide: BorderSide(color: Colors.grey.shade200),
//                   //     ),
//                   //     enabledBorder: OutlineInputBorder(
//                   //       borderRadius: BorderRadius.circular(6),
//                   //       borderSide: BorderSide(color: AppColors.themeColor),
//                   //     ),
//                   //     focusedBorder: OutlineInputBorder(
//                   //       borderRadius: BorderRadius.circular(6),
//                   //       borderSide:
//                   //           BorderSide(color: AppColors.themeColor, width: 1.5),
//                   //     ),
//                   //     hintText: 'Scan ${controller.iqaLabels[i]}',
//                   //   ),
//                   //   onChanged: (_) => controller.onIqaFieldChanged(i),
//                   //   onSubmitted: (_) => controller.submitIqaField(i),
//                   // ),
//                Focus(
//   onKeyEvent: (node, event) {
//     if (event is KeyDownEvent &&
//         event.logicalKey == LogicalKeyboardKey.tab) {
//       controller.submitIqaField(i);
//       return KeyEventResult.handled;
//     }
//     return KeyEventResult.ignored;
//   },
//   child: TextField(
//     cursorColor: AppColors.themeColor,
//     controller: controller.iqaControllers[i],
//     focusNode: controller.iqaFocusNodes[i],
//     enabled: true,
//     maxLength: 7,
//     style: const TextStyle(fontSize: 13),
//     decoration: InputDecoration(
//       isDense: true,
//       filled: true,
//       fillColor: Colors.white,
//       counterText: '',
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: BorderSide(color: Colors.grey.shade200),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: BorderSide(color: AppColors.themeColor),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
//       ),
//       hintText: 'Scan ${controller.iqaLabels[i]}',
//     ),
//     onChanged: (_) => controller.onIqaFieldChanged(i),
//     onSubmitted: (_) => controller.submitIqaField(i),
//   ),
// ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Obx(() {
//                   if (!controller.allStepsComplete) {
//                     return const SizedBox.shrink();
//                   }
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildFlashSection(),
//                       if (controller.flashComplete.value) ...[
//                         const SizedBox(height: 16),
//                         _buildDtcSection(),
//                         const SizedBox(height: 12),
//                         _buildPidSection(),
//                       ],
//                     ],
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ),
//         _buildActivitySection(),
//       ],
//     );
//   }

//   void _showRecipeDialog() {
//     Get.dialog(
//       Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: SizedBox(
//           width: 860,
//           height: 520,
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Row(
//                   children: [
//                     const Text('Recipe',
//                         style: TextStyle(
//                             fontSize: 17, fontWeight: FontWeight.w800)),
//                     const SizedBox(width: 10),
//                     Obx(
//                       () => Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: AppColors.themeColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${controller.harnessReceipes.length} sensor${controller.harnessReceipes.length == 1 ? '' : 's'}',
//                           style: TextStyle(
//                               fontSize: 12, color: AppColors.themeColor),
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     Obx(
//                       () => ElevatedButton.icon(
//                         onPressed: controller.isReadingPlcValues.value
//                             ? null
//                             : controller.readAllSensorValues,
//                         icon: controller.isReadingPlcValues.value
//                             ? const SizedBox(
//                                 width: 14,
//                                 height: 14,
//                                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                               )
//                             : const Icon(Icons.download, size: 16),
//                         label: Text(controller.isReadingPlcValues.value ? 'Reading…' : 'Write Values'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.themeColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                           textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: () async {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.themeColor,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.zero,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                       ),
//                       child: const Text(
//                         'WRITE VALUE',
//                         style: TextStyle(
//                           fontSize: 10.5,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon:
//                           const Icon(Icons.close, size: 20, color: Colors.grey),
//                       onPressed: () => Get.back(),
//                       splashRadius: 18,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 const Divider(height: 1),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: Obx(() {
//                     if (controller.harnessReceipes.isEmpty) {
//                       return Center(
//                         child: Text(
//                           'No recipe data yet — scan a harness first.',
//                           style: TextStyle(color: Colors.grey.shade500),
//                         ),
//                       );
//                     }
//                     return SingleChildScrollView(child: _buildRecipeTable());
//                   }),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecipeTable() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // ── header row ──
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F7FA),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Row(
//               children: [
//                 Expanded(
//                     flex: 3,
//                     child: Text('SENSOR NAME',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('REG. ADDRESS',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('TYPE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 // Expanded(
//                 //     flex: 2,
//                 //     child: Text('PIN NO',
//                 //         style: TextStyle(
//                 //             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('VALUE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 1,
//                     child: Text('UNIT',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('WRITE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//               ],
//             ),
//           ),
//           const SizedBox(height: 4),
//           // ── data rows ──
//           ...controller.harnessReceipes.map((sensor) {
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//               margin: const EdgeInsets.only(bottom: 4),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade200),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Text(
//                       sensor.sensorName ?? '-',
//                       style: const TextStyle(
//                           fontSize: 12.5, fontWeight: FontWeight.w600),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       '${sensor.regAddress ?? '-'}',
//                       style:
//                           TextStyle(fontSize: 12, color: Colors.grey.shade700),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 3),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF5F7FA),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           sensor.type ?? '-',
//                           style: const TextStyle(fontSize: 11),
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Expanded(
//                   //   flex: 2,
//                   //   child: Text(
//                   //     '${sensor.pinNo ?? '-'}',
//                   //     style:
//                   //         TextStyle(fontSize: 12, color: Colors.grey.shade700),
//                   //   ),
//                   // ),
//                   Expanded(
//                     flex: 2,
//                     child: Obx(() {
//                       // Static API value by default. Only replaced once
//                       // the operator explicitly writes this sensor via
//                       // the WRITE action — no automatic PLC read here.
//                       final live = sensor.id != null ? controller.livePlcValues[sensor.id] : null;
//                       final display = live ?? '${sensor.value ?? '-'}';
//                       final isLive = live != null && live != 'ERR';
//                       return Text(
//                         display,
//                         style: TextStyle(
//                           fontSize: 12.5,
//                           fontWeight: FontWeight.bold,
//                           color: live == 'ERR'
//                               ? Colors.red
//                               : (isLive
//                                   ? AppColors.themeColor
//                                   : Colors.grey.shade500),
//                         ),
//                       );
//                     }),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Text(
//                       sensor.unit ?? '-',
//                       style:
//                           TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: _SensorWriteAction(
//                       sensor: sensor,
//                       controller: controller,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildFlashSection() {
//     return Obx(() {
//       final expanded = controller.flashExpanded.value;

//       String? statusText;
//       if (controller.flashInProgress.value) {
//         statusText = '${(controller.flashProgress.value * 100).round()}%';
//       }

//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Column(
//           children: [
//             InkWell(
//               borderRadius: BorderRadius.circular(10),
//               onTap: controller.toggleFlash,
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 child: Row(
//                   children: [
//                     const Text('Flash File',
//                         style: TextStyle(fontWeight: FontWeight.w600)),
//                     const Spacer(),
//                     if (controller.flashComplete.value) ...[
//                       Column(
//                         children: [
//                           Container(
//                             width: 22,
//                             height: 22,
//                             decoration: const BoxDecoration(
//                               color: AppColors.themeColor,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.check,
//                                 color: Colors.white, size: 14),
//                           ),
//                           const SizedBox(height: 5),
//                           Text(
//                             'Flashing Successful',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 color: AppColors.themeColor,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 10),
//                     ] else if (statusText != null) ...[
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: AppColors.themeColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           statusText,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.themeColor,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                     ],
//                     Icon(expanded ? Icons.expand_less : Icons.expand_more),
//                   ],
//                 ),
//               ),
//             ),
//             if (expanded)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//                 child: _buildFlashBody(),
//               ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildFlashBody() {
//     return Obx(() {
//       if (controller.flashComplete.value) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (controller.selectedFlashFile.value != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   controller.selectedFlashFile.value!,
//                   style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
//                 ),
//               ),
//             Row(
//               children: [
//                 const Expanded(child: SizedBox.shrink()),
//                 Text(
//                   controller.formattedElapsed,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: 1.0,
//                 minHeight: 6,
//                 backgroundColor: Colors.grey.shade200,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Center(
//               child: Column(
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: const BoxDecoration(
//                       color: AppColors.themeColor,
//                       shape: BoxShape.circle,
//                     ),
//                     child:
//                         const Icon(Icons.check, color: Colors.white, size: 22),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Flashing successful',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }

//       if (controller.flashInProgress.value) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             if (controller.selectedFlashFile.value != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Text(
//                   controller.selectedFlashFile.value!,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
//                 ),
//               ),
//             Text(
//               controller.formattedElapsed,
//               style: const TextStyle(
//                 fontSize: 34,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: controller.flashProgress.value,
//                 minHeight: 10,
//                 backgroundColor: Colors.grey.shade300,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${(controller.flashProgress.value * 100).round()}%',
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             //const SizedBox(height: 24),
//             // Column(
//             //   children: [
//             //     Image.asset('asset/new/gifPhone.gif', height: 90),
//             //     Image.asset('asset/new/gifDownArrow.gif', height: 26),
//             //     Image.asset('asset/new/ic_engine.png', height: 90),
//             //   ],
//             // ),
//           ],
//         );
//       }

//       if (controller.flashFilesLoading.value) {
//         return const Padding(
//           padding: EdgeInsets.symmetric(vertical: 20),
//           child: Center(
//             child: SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ),
//         );
//       }

//       if (controller.flashFilesError.value.isNotEmpty) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Text(
//             controller.flashFilesError.value,
//             style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
//           ),
//         );
//       }

//       if (controller.availableFlashFiles.isEmpty) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Text(
//             'No flash files available',
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
//           ),
//         );
//       }

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!controller.dongleConnected.value)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: Colors.orange.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.info_outline,
//                         size: 16, color: Colors.orange.shade800),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Waiting for the dongle to connect automatically…',
//                         style: TextStyle(
//                             fontSize: 12, color: Colors.orange.shade800),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ConstrainedBox(
//             constraints: const BoxConstraints(maxHeight: 260),
//             child: ListView.separated(
//               shrinkWrap: true,
//               padding: EdgeInsets.zero,
//               itemCount: controller.availableFlashFiles.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 8),
//               itemBuilder: (context, index) {
//                 final file = controller.availableFlashFiles[index];
//                 final isSelected = controller.selectedFlashFile.value == file;

//                 return GestureDetector(
//                   onTap: () => controller.selectFlashFile(file),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border.all(
//                         color: isSelected
//                             ? AppColors.themeColor
//                             : Colors.grey.shade300,
//                         width: isSelected ? 1.5 : 1,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: ListTile(
//                       dense: true,
//                       title: Text(
//                         file,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13,
//                           color: Colors.black,
//                         ),
//                       ),
//                       trailing: Container(
//                         width: 22,
//                         height: 22,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: isSelected
//                               ? AppColors.themeColor
//                               : Colors.transparent,
//                           border: Border.all(
//                             color: AppColors.themeColor,
//                             width: 1.5,
//                           ),
//                         ),
//                         child: isSelected
//                             ? const Icon(Icons.check,
//                                 color: Colors.white, size: 14)
//                             : null,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 12),
//           Center(
//             child: ElevatedButton(
//               onPressed: (controller.selectedFlashFile.value != null &&
//                       controller.dongleConnected.value)
//                   ? controller.startFlashing
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.themeColor,
//                 disabledBackgroundColor: Colors.grey.shade300,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Start Flashing',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildDtcSection() {
//     return Obx(() => _buildExpandableSection(
//           title: 'DTC',
//           expanded: controller.dtcExpanded.value,
//           onTap: controller.toggleDtc,
//           trailingLabel: 'Count: ${controller.dtcCount}',
//           items: controller.dtcList,
//           itemBuilder: _buildDtcCard,
//         ));
//   }

//   Widget _buildDtcCard(String raw) {
//     final splitIndex = raw.indexOf(' - ');
//     final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     final description =
//         splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             code,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12.5,
//               color: Colors.black87,
//             ),
//           ),
//           if (description.isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               description,
//               style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPidSection() {
//     return Obx(() => _buildExpandableSection(
//           title: 'PID',
//           expanded: controller.pidExpanded.value,
//           onTap: controller.togglePid,
//           trailingLabel: null,
//           items: controller.pidList,
//           itemBuilder: _buildPidCard,
//         ));
//   }

//   Widget _buildPidCard(String raw) {
//     final splitIndex = raw.indexOf(' — ');
//     final label = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     final value = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12.5,
//               color: Colors.black87,
//             ),
//           ),
//           if (value.isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               value,
//               style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildExpandableSection({
//     required String title,
//     required bool expanded,
//     required VoidCallback onTap,
//     required String? trailingLabel,
//     required List<String> items,
//     Widget Function(String item)? itemBuilder,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             borderRadius: BorderRadius.circular(10),
//             onTap: onTap,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Text(title,
//                       style: const TextStyle(fontWeight: FontWeight.w600)),
//                   const Spacer(),
//                   if (trailingLabel != null) ...[
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: AppColors.themeColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         trailingLabel,
//                         style: TextStyle(
//                             fontSize: 12, color: AppColors.themeColor),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                   ],
//                   Icon(expanded ? Icons.expand_less : Icons.expand_more),
//                 ],
//               ),
//             ),
//           ),
//           if (expanded)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//               child: items.isEmpty
//                   ? Text(
//                       'No data yet',
//                       style:
//                           TextStyle(color: Colors.grey.shade500, fontSize: 13),
//                     )
//                   : (itemBuilder != null
//                       ? Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children:
//                               items.map((item) => itemBuilder(item)).toList(),
//                         )
//                       : Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: items
//                               .map((item) => Padding(
//                                     padding:
//                                         const EdgeInsets.symmetric(vertical: 4),
//                                     child: Text('• $item',
//                                         style: const TextStyle(fontSize: 13)),
//                                   ))
//                               .toList(),
//                         )),
//             ),
//         ],
//       ),
//     );
//   }

//   void _copyActivityLog() {
//     final text = controller.activityLog.join('\n');
//     Clipboard.setData(ClipboardData(text: text));
//     Get.snackbar(
//       'Copied',
//       '${controller.activityLog.length} log line${controller.activityLog.length == 1 ? '' : 's'} copied to clipboard',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppColors.themeColor,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );
//   }

// //   Widget _buildActivitySection() {
// //     return Container(
// //       constraints: const BoxConstraints(maxHeight: 180),
// //       margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(10),
// //         border: Border.all(color: Colors.grey.shade300),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.04),
// //             blurRadius: 8,
// //             offset: const Offset(0, -2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Row(
// //           //   children: [
// //           //     const Text('Activity',
// //           //         style: TextStyle(fontWeight: FontWeight.w600)),
// //           //     const Spacer(),
// //           //     Obx(
// //           //       () => IconButton(
// //           //         icon: const Icon(Icons.copy, size: 18),
// //           //         color: AppColors.themeColor,
// //           //         tooltip: 'Copy all activity log',
// //           //         visualDensity: VisualDensity.compact,
// //           //         onPressed: controller.activityLog.isEmpty
// //           //             ? null
// //           //             : () => _copyActivityLog(),
// //           //       ),
// //           //     ),
// //           //   ],
// //           // ),
// //           Row(
// //   children: [
// //     const Text(
// //       'Activity',
// //       style: TextStyle(fontWeight: FontWeight.w600),
// //     ),
// //     const Spacer(),

// //     Obx(() => IconButton(
// //           icon: const Icon(Icons.save_alt, size: 18),
// //           tooltip: "Save Activity Log",
// //           color: AppColors.themeColor,
// //           onPressed: controller.activityLog.isEmpty
// //               ? null
// //               : () async {
// //                   await controller.saveActivityLog();
// //                 },
// //         )),

// //     Obx(() => IconButton(
// //           icon: const Icon(Icons.copy, size: 18),
// //           tooltip: "Copy Activity Log",
// //           color: AppColors.themeColor,
// //           onPressed: controller.activityLog.isEmpty
// //               ? null
// //               : () => _copyActivityLog(),
// //         )),
// //   ],
// // ),
// //           const Divider(height: 16),
// //           Expanded(
// //             child: Obx(
// //               () => ListView(
// //                 padding: EdgeInsets.zero,
// //                 children: controller.activityLog
// //                     .map((entry) => Padding(
// //                           padding: const EdgeInsets.symmetric(vertical: 3),
// //                           child: Text(
// //                             entry,
// //                             style: TextStyle(
// //                                 fontSize: 12.5, color: Colors.grey.shade700),
// //                           ),
// //                         ))
// //                     .toList(),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// Color _activityLogColor(String entry) {
//   final lower = entry.toLowerCase();

//   // Explicit markers used throughout HomePageController's _log() calls.
//   if (entry.contains('❌') ||
//       lower.contains('failed') ||
//       lower.contains('error') ||
//       lower.contains('mismatch') ||
//       lower.contains('not recognized') ||
//       lower.contains('not found')) {
//     return Colors.red.shade700;
//   }

//   if (entry.contains('✅') ||
//       lower.contains('successful') ||
//       lower.contains('success') ||
//       lower.contains('connected') ||
//       lower.contains('complete')) {
//     return Colors.green.shade700;
//   }

//   return Colors.grey.shade700; // neutral/info lines unchanged
// }

// Widget _buildActivitySection() {
//   return Container(
//     constraints: const BoxConstraints(maxHeight: 180),
//     margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(10),
//       border: Border.all(color: Colors.grey.shade300),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.04),
//           blurRadius: 8,
//           offset: const Offset(0, -2),
//         ),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text(
//               'Activity',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const Spacer(),
//             Obx(() => IconButton(
//                   icon: const Icon(Icons.save_alt, size: 18),
//                   tooltip: "Save Activity Log",
//                   color: AppColors.themeColor,
//                   onPressed: controller.activityLog.isEmpty
//                       ? null
//                       : () async {
//                           await controller.saveActivityLog();
//                         },
//                 )),
//             Obx(() => IconButton(
//                   icon: const Icon(Icons.copy, size: 18),
//                   tooltip: "Copy Activity Log",
//                   color: AppColors.themeColor,
//                   onPressed: controller.activityLog.isEmpty
//                       ? null
//                       : () => _copyActivityLog(),
//                 )),
//           ],
//         ),
//         const Divider(height: 16),
//         Expanded(
//           child: Obx(
//             () => ListView(
//               padding: EdgeInsets.zero,
//               children: controller.activityLog
//                   .map((entry) => Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 3),
//                         child: Text(
//                           entry,
//                           style: TextStyle(
//                             fontSize: 12.5,
//                             color: _activityLogColor(entry),
//                             fontWeight: _activityLogColor(entry) ==
//                                     Colors.grey.shade700
//                                 ? FontWeight.normal
//                                 : FontWeight.w600,
//                           ),
//                         ),
//                       ))
//                   .toList(),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }

// /// "WRITE VALUE" button for one Recipe row. Tapping it opens a small
// /// dialog with its own input field — write the value there, and the
// /// confirmed value (read back from the PLC after writing) shows right
// /// inside that same dialog.
// class _SensorWriteAction extends StatelessWidget {
//   const _SensorWriteAction({required this.sensor, required this.controller});

//   final harness_ds.Receipe sensor;
//   final HomePageController controller;

//   void _openWriteValueDialog() {
//     final valueController = TextEditingController();

//     Get.dialog(
//       Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: SizedBox(
//           width: 360,
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         'Write Value — ${sensor.sensorName ?? '-'}',
//                         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, size: 18, color: Colors.grey),
//                       onPressed: () => Get.back(),
//                       splashRadius: 16,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Reg Address: ${sensor.regAddress ?? '-'}  •  Type: ${sensor.type ?? '-'}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                 ),
//                 const SizedBox(height: 18),
//                 TextField(
//                   controller: valueController,
//                   autofocus: true,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     labelText: 'Value',
//                     filled: true,
//                     fillColor: const Color(0xFFF5F7FA),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Obx(() {
//                   final id = sensor.id;
//                   final isWriting = id != null && controller.writeInFlightSensorIds.contains(id);
//                   final live = id != null ? controller.livePlcValues[id] : null;

//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       if (live != null) ...[
//                         Container(
//                           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//                           decoration: BoxDecoration(
//                             color: live == 'ERR'
//                                 ? Colors.red.withOpacity(0.08)
//                                 : AppColors.themeColor.withOpacity(0.08),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             live == 'ERR'
//                                 ? 'Write failed / not confirmed'
//                                 : 'Confirmed value: $live ${sensor.unit ?? ''}',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: live == 'ERR' ? Colors.red : AppColors.themeColor,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                       ],
//                       SizedBox(
//                         height: 44,
//                         child: ElevatedButton(
//                           onPressed: isWriting
//                               ? null
//                               : () async {
//                                   final value = int.tryParse(valueController.text.trim());
//                                   if (value == null) return;
//                                   await controller.writeSensorValue(sensor, value);
//                                 },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.themeColor,
//                             disabledBackgroundColor: AppColors.themeColor.withOpacity(0.5),
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                           ),
//                           child: isWriting
//                               ? const SizedBox(
//                                   width: 18,
//                                   height: 18,
//                                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                                 )
//                               : const Text('WRITE VALUE', style: TextStyle(fontWeight: FontWeight.bold)),
//                         ),
//                       ),
//                     ],
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 32,
//       child: ElevatedButton(
//         onPressed: _openWriteValueDialog,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.themeColor,
//           foregroundColor: Colors.white,
//           padding: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//         ),
//         child: const Text(
//           'WRITE VALUE',
//           style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:simpson/common_widgets/custom_app_bar.dart';
// import 'package:simpson/dev/dev_screen.dart';
// import 'package:simpson/modals/harness.model.dart' as harness_ds;
// import 'package:simpson/themes/app_colors.dart';
// import '../controllers/home_page_controller.dart';
// // StepType is exported from home_page_controller.dart

// class HomePageView extends GetView<HomePageController> {
//   const HomePageView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: controller.station,
//         actions: [
//           Obx(
//             () => InkWell(
//               onTap: controller.retryPlcConnection,
//               borderRadius: BorderRadius.circular(6),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (controller.isPlcConnecting.value)
//                       const SizedBox(
//                         width: 10,
//                         height: 10,
//                         child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
//                       )
//                     else
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: controller.isPlcConnected.value ? Colors.greenAccent : Colors.redAccent,
//                         ),
//                       ),
//                     const SizedBox(width: 8),
//                     Text(
//                       controller.isPlcConnecting.value
//                           ? 'Connecting…'
//                           : (controller.isPlcConnected.value ? 'PLC ' : 'PLC '),
//                       style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Obx(() {
//             if (!controller.canConnectDongle.value) {
//               return const SizedBox.shrink();
//             }
//             return InkWell(
//               onTap: controller.retryDongleConnection,
//               borderRadius: BorderRadius.circular(6),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (controller.dongleConnecting.value)
//                       const SizedBox(
//                         width: 10,
//                         height: 10,
//                         child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
//                       )
//                     else
//                       Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: controller.dongleConnected.value ? Colors.greenAccent : Colors.redAccent,
//                         ),
//                       ),
//                     const SizedBox(width: 8),
//                     Text(
//                       controller.dongleConnecting.value
//                           ? 'Connecting…'
//                           : 'Dongle ',
//                       style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: controller.logout,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       backgroundColor: const Color(0xFFF4F5F7),
//       body: Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildSidebar(),
//           Expanded(child: _buildMainContent()),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebar() {
//     return Container(
//       width: 230,
//       color: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Expanded(
//             child: Obx(
//               () {
//                 final visibleCount = (controller.currentStepIndex.value + 1)
//                     .clamp(0, controller.steps.length);
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   itemCount: visibleCount,
//                   itemBuilder: (context, index) {
//                     final step = controller.steps[index];
//                     if (step.type == StepType.iqaGroup) {
//                       return _buildIqaGroupTile(index);
//                     }
//                     return _buildStepTile(index);
//                   },
//                 );
//               },
//             ),
//           ),
//           const Divider(height: 1),
//           InkWell(
//             onTap: () => _showRecipeDialog(),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),
//                   const SizedBox(width: 10),
//                   Text(
//                     'Recipe',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   const Spacer(),
//                   Obx(
//                     () => controller.harnessReceipes.isEmpty
//                         ? const SizedBox.shrink()
//                         : Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 7, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: AppColors.themeColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               '${controller.harnessReceipes.length}',
//                               style: TextStyle(
//                                   fontSize: 11, color: AppColors.themeColor),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Divider(height: 1),
//           InkWell(
//             onTap: () => Get.to(() => const DevLogsPage()),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Icon(Icons.bug_report_outlined,
//                       size: 18, color: Colors.grey.shade700),
//                   const SizedBox(width: 10),
//                   Text(
//                     'API Logs',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepTile(int index) {
//     final step = controller.steps[index];
//     final isCompleted = index < controller.currentStepIndex.value;
//     final isActive = index == controller.currentStepIndex.value;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
//                 size: 16,
//                 color: isCompleted ? AppColors.themeColor : AppColors.themeColor,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 step.label,
//                 style: TextStyle(
//                   fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//                   color: Colors.black87,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           TextField(
//             cursorColor: AppColors.themeColor,
//             controller: controller.stepControllers[index],
//             focusNode: controller.stepFocusNodes[index],
//             enabled: true,
//             style: const TextStyle(fontSize: 13),
//             decoration: InputDecoration(
//               isDense: true,
//               filled: true,
//               fillColor:
//                   isCompleted ? Colors.green.withOpacity(0.06) : Colors.white,
//               contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: Colors.grey.shade200),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: AppColors.themeColor),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(6),
//                 borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
//               ),
//               hintText: isActive ? 'Scan or enter ${step.label}' : '',
//             ),
//             onChanged: (_) => controller.onFieldChanged(index),
//             onSubmitted: (_) => controller.submitStep(index),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildIqaGroupTile(int index) {
//     final isActive = index == controller.currentStepIndex.value;
//     final isCompleted = index < controller.currentStepIndex.value;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
//                 size: 16,
//                 color: AppColors.themeColor,
//               ),
//               const SizedBox(width: 6),
//               Text(
//                 'IQA',
//                 style: TextStyle(
//                   fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
//                   color: Colors.black87,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           ...List.generate(controller.iqaLabels.length, (i) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     controller.iqaLabels[i],
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                   ),
//                   const SizedBox(height: 2),
//                   TextField(
//                     cursorColor: AppColors.themeColor,
//                     controller: controller.iqaControllers[i],
//                     focusNode: controller.iqaFocusNodes[i],
//                     enabled: true,
//                     style: const TextStyle(fontSize: 13),
//                     decoration: InputDecoration(
//                       isDense: true,
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 12),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(6),
//                         borderSide: BorderSide(color: Colors.grey.shade200),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(6),
//                         borderSide: BorderSide(color: AppColors.themeColor),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(6),
//                         borderSide:
//                             BorderSide(color: AppColors.themeColor, width: 1.5),
//                       ),
//                       hintText: 'Scan ${controller.iqaLabels[i]}',
//                     ),
//                     onChanged: (_) => controller.onIqaFieldChanged(i),
//                     onSubmitted: (_) => controller.submitIqaField(i),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return Column(
//       children: [
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Obx(() {
//                   if (!controller.allStepsComplete) {
//                     return const SizedBox.shrink();
//                   }
//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildFlashSection(),
//                       if (controller.flashComplete.value) ...[
//                         const SizedBox(height: 16),
//                         _buildDtcSection(),
//                         const SizedBox(height: 12),
//                         _buildPidSection(),
//                       ],
//                     ],
//                   );
//                 }),
//               ],
//             ),
//           ),
//         ),
//         _buildActivitySection(),
//       ],
//     );
//   }

//   /// Recipe popup: static reference table straight from the harness
//   /// API (sensor_name / reg_address / type / pin_no / value / unit).
//   /// A sensor's VALUE only ever changes from the static API value once
//   /// the operator uses the WRITE action on that row — there is no
//   /// automatic PLC read here.
//   void _showRecipeDialog() {
//     Get.dialog(
//       Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: SizedBox(
//           width: 860,
//           height: 520,
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Row(
//                   children: [
//                     const Text('Recipe',
//                         style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
//                     const SizedBox(width: 10),
//                     Obx(
//                       () => Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: AppColors.themeColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${controller.harnessReceipes.length} sensor${controller.harnessReceipes.length == 1 ? '' : 's'}',
//                           style: TextStyle(
//                               fontSize: 12, color: AppColors.themeColor),
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       icon: const Icon(Icons.close, size: 20, color: Colors.grey),
//                       onPressed: () => Get.back(),
//                       splashRadius: 18,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 const Divider(height: 1),
//                 const SizedBox(height: 12),
//                 Expanded(
//                   child: Obx(() {
//                     if (controller.harnessReceipes.isEmpty) {
//                       return Center(
//                         child: Text(
//                           'No recipe data yet — scan a harness first.',
//                           style: TextStyle(color: Colors.grey.shade500),
//                         ),
//                       );
//                     }
//                     return SingleChildScrollView(child: _buildRecipeTable());
//                   }),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecipeTable() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // ── header row ──
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF5F7FA),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Row(
//               children: [
//                 Expanded(
//                     flex: 3,
//                     child: Text('SENSOR NAME',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('REG. ADDRESS',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('TYPE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('PIN NO',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 2,
//                     child: Text('VALUE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 1,
//                     child: Text('UNIT',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//                 Expanded(
//                     flex: 3,
//                     child: Text('WRITE',
//                         style: TextStyle(
//                             fontSize: 11, fontWeight: FontWeight.bold))),
//               ],
//             ),
//           ),
//           const SizedBox(height: 4),
//           // ── data rows ──
//           ...controller.harnessReceipes.map((sensor) {
//             return Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//               margin: const EdgeInsets.only(bottom: 4),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade200),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Text(
//                       sensor.sensorName ?? '-',
//                       style: const TextStyle(
//                           fontSize: 12.5, fontWeight: FontWeight.w600),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       '${sensor.regAddress ?? '-'}',
//                       style: TextStyle(
//                           fontSize: 12, color: Colors.grey.shade700),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 3),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF5F7FA),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           sensor.type ?? '-',
//                           style: const TextStyle(fontSize: 11),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       '${sensor.pinNo ?? '-'}',
//                       style: TextStyle(
//                           fontSize: 12, color: Colors.grey.shade700),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Obx(() {
//                       // Static API value by default. Only replaced once
//                       // the operator explicitly writes this sensor via
//                       // the WRITE action — no automatic PLC read here.
//                       final live = sensor.id != null ? controller.livePlcValues[sensor.id] : null;
//                       final display = live ?? '${sensor.value ?? '-'}';
//                       final isLive = live != null && live != 'ERR';
//                       return Text(
//                         display,
//                         style: TextStyle(
//                           fontSize: 12.5,
//                           fontWeight: FontWeight.bold,
//                           color: live == 'ERR'
//                               ? Colors.red
//                               : (isLive ? AppColors.themeColor : Colors.grey.shade500),
//                         ),
//                       );
//                     }),
//                   ),
//                   Expanded(
//                     flex: 1,
//                     child: Text(
//                       sensor.unit ?? '-',
//                       style: TextStyle(
//                           fontSize: 12, color: Colors.grey.shade600),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 3,
//                     child: _SensorWriteAction(
//                       sensor: sensor,
//                       controller: controller,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildFlashSection() {
//     return Obx(() {
//       final expanded = controller.flashExpanded.value;

//       String? statusText;
//       if (controller.flashInProgress.value) {
//         statusText = '${(controller.flashProgress.value * 100).round()}%';
//       }

//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Column(
//           children: [
//             InkWell(
//               borderRadius: BorderRadius.circular(10),
//               onTap: controller.toggleFlash,
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                 child: Row(
//                   children: [
//                     const Text('Flash File',
//                         style: TextStyle(fontWeight: FontWeight.w600)),
//                     const Spacer(),
//                     if (controller.flashComplete.value) ...[
//                       Column(
//                         children: [
//                           Container(
//                             width: 22,
//                             height: 22,
//                             decoration: const BoxDecoration(
//                               color: AppColors.themeColor,
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.check,
//                                 color: Colors.white, size: 14),
//                           ),
//                           const SizedBox(height: 5),
//                           Text(
//                             'Flashing Successful',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 color: AppColors.themeColor,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 10),
//                     ] else if (statusText != null) ...[
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: AppColors.themeColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           statusText,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.themeColor,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                     ],
//                     Icon(expanded ? Icons.expand_less : Icons.expand_more),
//                   ],
//                 ),
//               ),
//             ),
//             if (expanded)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//                 child: _buildFlashBody(),
//               ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildFlashBody() {
//     return Obx(() {
//       if (controller.flashComplete.value) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (controller.selectedFlashFile.value != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   controller.selectedFlashFile.value!,
//                   style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
//                 ),
//               ),
//             Row(
//               children: [
//                 const Expanded(child: SizedBox.shrink()),
//                 Text(
//                   controller.formattedElapsed,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: 1.0,
//                 minHeight: 6,
//                 backgroundColor: Colors.grey.shade200,
//                 valueColor:  AlwaysStoppedAnimation<Color>(AppColors.themeColor),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Center(
//               child: Column(
//                 children: [
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: const BoxDecoration(
//                       color:AppColors.themeColor,
//                       shape: BoxShape.circle,
//                     ),
//                     child:
//                         const Icon(Icons.check, color: Colors.white, size: 22),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'Flashing successful',
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }

//       if (controller.flashInProgress.value) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             if (controller.selectedFlashFile.value != null)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Text(
//                   controller.selectedFlashFile.value!,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
//                 ),
//               ),
//             Text(
//               controller.formattedElapsed,
//               style: const TextStyle(
//                 fontSize: 34,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: controller.flashProgress.value,
//                 minHeight: 10,
//                 backgroundColor: Colors.grey.shade300,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${(controller.flashProgress.value * 100).round()}%',
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Column(
//               children: [
//                 Image.asset('asset/new/gifPhone.gif', height: 90),
//                 Image.asset('asset/new/gifDownArrow.gif', height: 26),
//                 Image.asset('asset/new/ic_engine.png', height: 90),
//               ],
//             ),
//           ],
//         );
//       }

//       if (controller.flashFilesLoading.value) {
//         return const Padding(
//           padding: EdgeInsets.symmetric(vertical: 20),
//           child: Center(
//             child: SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ),
//         );
//       }

//       if (controller.flashFilesError.value.isNotEmpty) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Text(
//             controller.flashFilesError.value,
//             style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
//           ),
//         );
//       }

//       if (controller.availableFlashFiles.isEmpty) {
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           child: Text(
//             'No flash files available',
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
//           ),
//         );
//       }

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!controller.dongleConnected.value)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 10),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: Colors.orange.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.info_outline,
//                         size: 16, color: Colors.orange.shade800),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'Waiting for the dongle to connect automatically…',
//                         style: TextStyle(
//                             fontSize: 12, color: Colors.orange.shade800),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ConstrainedBox(
//             constraints: const BoxConstraints(maxHeight: 260),
//             child: ListView.separated(
//               shrinkWrap: true,
//               padding: EdgeInsets.zero,
//               itemCount: controller.availableFlashFiles.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 8),
//               itemBuilder: (context, index) {
//                 final file = controller.availableFlashFiles[index];
//                 final isSelected = controller.selectedFlashFile.value == file;

//                 return GestureDetector(
//                   onTap: () => controller.selectFlashFile(file),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border.all(
//                         color: isSelected
//                             ? AppColors.themeColor
//                             : Colors.grey.shade300,
//                         width: isSelected ? 1.5 : 1,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: ListTile(
//                       dense: true,
//                       title: Text(
//                         file,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 13,
//                           color: Colors.black,
//                         ),
//                       ),
//                       trailing: Container(
//                         width: 22,
//                         height: 22,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: isSelected
//                               ? AppColors.themeColor
//                               : Colors.transparent,
//                           border: Border.all(
//                             color: AppColors.themeColor,
//                             width: 1.5,
//                           ),
//                         ),
//                         child: isSelected
//                             ? const Icon(Icons.check,
//                                 color: Colors.white, size: 14)
//                             : null,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 12),
//           Center(
//             child: ElevatedButton(
//               onPressed: (controller.selectedFlashFile.value != null &&
//                       controller.dongleConnected.value)
//                   ? controller.startFlashing
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.themeColor,
//                 disabledBackgroundColor: Colors.grey.shade300,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Start Flashing',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   Widget _buildDtcSection() {
//     return Obx(() => _buildExpandableSection(
//           title: 'DTC',
//           expanded: controller.dtcExpanded.value,
//           onTap: controller.toggleDtc,
//           trailingLabel: 'Count: ${controller.dtcCount}',
//           items: controller.dtcList,
//           itemBuilder: _buildDtcCard,
//         ));
//   }

//   Widget _buildDtcCard(String raw) {
//     final splitIndex = raw.indexOf(' - ');
//     final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     final description =
//         splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             code,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12.5,
//               color: Colors.black87,
//             ),
//           ),
//           if (description.isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               description,
//               style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPidSection() {
//     return Obx(() => _buildExpandableSection(
//           title: 'PID',
//           expanded: controller.pidExpanded.value,
//           onTap: controller.togglePid,
//           trailingLabel: null,
//           items: controller.pidList,
//           itemBuilder: _buildPidCard,
//         ));
//   }

//   Widget _buildPidCard(String raw) {
//     final splitIndex = raw.indexOf(' — ');
//     final label = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     final value = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12.5,
//               color: Colors.black87,
//             ),
//           ),
//           if (value.isNotEmpty) ...[
//             const SizedBox(height: 2),
//             Text(
//               value,
//               style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildExpandableSection({
//     required String title,
//     required bool expanded,
//     required VoidCallback onTap,
//     required String? trailingLabel,
//     required List<String> items,
//     Widget Function(String item)? itemBuilder,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         children: [
//           InkWell(
//             borderRadius: BorderRadius.circular(10),
//             onTap: onTap,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//               child: Row(
//                 children: [
//                   Text(title,
//                       style: const TextStyle(fontWeight: FontWeight.w600)),
//                   const Spacer(),
//                   if (trailingLabel != null) ...[
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: AppColors.themeColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         trailingLabel,
//                         style: TextStyle(
//                             fontSize: 12, color: AppColors.themeColor),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                   ],
//                   Icon(expanded ? Icons.expand_less : Icons.expand_more),
//                 ],
//               ),
//             ),
//           ),
//           if (expanded)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
//               child: items.isEmpty
//                   ? Text(
//                       'No data yet',
//                       style:
//                           TextStyle(color: Colors.grey.shade500, fontSize: 13),
//                     )
//                   : (itemBuilder != null
//                       ? Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children:
//                               items.map((item) => itemBuilder(item)).toList(),
//                         )
//                       : Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: items
//                               .map((item) => Padding(
//                                     padding:
//                                         const EdgeInsets.symmetric(vertical: 4),
//                                     child: Text('• $item',
//                                         style: const TextStyle(fontSize: 13)),
//                                   ))
//                               .toList(),
//                         )),
//             ),
//         ],
//       ),
//     );
//   }

//   void _copyActivityLog() {
//     final text = controller.activityLog.join('\n');
//     Clipboard.setData(ClipboardData(text: text));
//     Get.snackbar(
//       'Copied',
//       '${controller.activityLog.length} log line${controller.activityLog.length == 1 ? '' : 's'} copied to clipboard',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: AppColors.themeColor,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );
//   }

//   Widget _buildActivitySection() {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 180),
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text('Activity',
//                   style: TextStyle(fontWeight: FontWeight.w600)),
//               const Spacer(),
//               Obx(
//                 () => IconButton(
//                   icon: const Icon(Icons.copy, size: 18),
//                   color: AppColors.themeColor,
//                   tooltip: 'Copy all activity log',
//                   visualDensity: VisualDensity.compact,
//                   onPressed: controller.activityLog.isEmpty
//                       ? null
//                       : () => _copyActivityLog(),
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 16),
//           Expanded(
//             child: Obx(
//               () => ListView(
//                 padding: EdgeInsets.zero,
//                 children: controller.activityLog
//                     .map((entry) => Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 3),
//                           child: Text(
//                             entry,
//                             style: TextStyle(
//                                 fontSize: 12.5, color: Colors.grey.shade700),
//                           ),
//                         ))
//                     .toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Inline "write a value" control for one Recipe row: a small number
// /// field + send button. Kept as its own StatefulWidget so its
// /// TextEditingController survives the Recipe dialog's Obx rebuilds.
// class _SensorWriteAction extends StatefulWidget {
//   const _SensorWriteAction({required this.sensor, required this.controller});

//   final harness_ds.Receipe sensor;
//   final HomePageController controller;

//   @override
//   State<_SensorWriteAction> createState() => _SensorWriteActionState();
// }

// class _SensorWriteActionState extends State<_SensorWriteAction> {
//   final TextEditingController _valueController = TextEditingController();

//   @override
//   void dispose() {
//     _valueController.dispose();
//     super.dispose();
//   }

//   void _submit() async {
//     final text = _valueController.text.trim();
//     final value = int.tryParse(text);
//     if (value == null) return;

//     await widget.controller.writeSensorValue(widget.sensor, value);
//     _valueController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final id = widget.sensor.id;
//       final isWriting = id != null && widget.controller.writeInFlightSensorIds.contains(id);

//       return Row(
//         children: [
//           SizedBox(
//             width: 60,
//             height: 32,
//             child: TextField(
//               controller: _valueController,
//               enabled: !isWriting,
//               keyboardType: TextInputType.number,
//               style: const TextStyle(fontSize: 12),
//               decoration: InputDecoration(
//                 isDense: true,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                 filled: true,
//                 fillColor: const Color(0xFFF5F7FA),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                   borderSide: BorderSide.none,
//                 ),
//                 hintText: 'val',
//                 hintStyle: const TextStyle(fontSize: 11),
//               ),
//               onSubmitted: (_) => _submit(),
//             ),
//           ),
//           const SizedBox(width: 6),
//           SizedBox(
//             width: 32,
//             height: 32,
//             child: IconButton(
//               padding: EdgeInsets.zero,
//               icon: isWriting
//                   ? const SizedBox(
//                       width: 14,
//                       height: 14,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : Icon(Icons.send, size: 16, color: AppColors.themeColor),
//               onPressed: isWriting ? null : _submit,
//               tooltip: 'Write value to PLC',
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/dev/dev_screen.dart';
import 'package:simpson/modals/harness.model.dart' as harness_ds;
import 'package:simpson/themes/app_colors.dart';
import '../controllers/home_page_controller.dart';
// StepType is exported from home_page_controller.dart

class HomePageView extends GetView<HomePageController> {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station,
        actions: [
          Obx(
            () => InkWell(
              onTap: controller.retryPlcConnection,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.isPlcConnecting.value)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
                      )
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.isPlcConnected.value ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isPlcConnecting.value
                          ? 'Connecting…'
                          : (controller.isPlcConnected.value ? 'PLC ' : 'PLC '),
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            if (!controller.canConnectDongle.value) {
              return const SizedBox.shrink();
            }
            return InkWell(
              onTap: controller.retryDongleConnection,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.dongleConnecting.value)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
                      )
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.dongleConnected.value ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      controller.dongleConnecting.value
                          ? 'Connecting…'
                          : 'Dongle ',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: controller.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(
              () {
                final visibleCount = (controller.currentStepIndex.value + 1)
                    .clamp(0, controller.steps.length);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleCount,
                  itemBuilder: (context, index) {
                    final step = controller.steps[index];
                    if (step.type == StepType.iqaGroup) {
                      return _buildIqaGroupTile(index);
                    }
                    return _buildStepTile(index);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => _showRecipeDialog(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'Recipe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => controller.harnessReceipes.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.harnessReceipes.length}',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.themeColor),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => Get.to(() => const DevLogsPage()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'API Logs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(int index) {
    final step = controller.steps[index];
    final isCompleted = index < controller.currentStepIndex.value;
    final isActive = index == controller.currentStepIndex.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isCompleted ? AppColors.themeColor : AppColors.themeColor,
              ),
              const SizedBox(width: 6),
              Text(
                step.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            cursorColor: AppColors.themeColor,
            controller: controller.stepControllers[index],
            focusNode: controller.stepFocusNodes[index],
            enabled: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor:
                  isCompleted ? Colors.green.withOpacity(0.06) : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.themeColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
              ),
              hintText: isActive ? 'Scan or enter ${step.label}' : '',
            ),
            onChanged: (_) => controller.onFieldChanged(index),
            onSubmitted: (_) => controller.submitStep(index),
          ),
        ],
      ),
    );
  }

  Widget _buildIqaGroupTile(int index) {
    final isActive = index == controller.currentStepIndex.value;
    final isCompleted = index < controller.currentStepIndex.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: AppColors.themeColor,
              ),
              const SizedBox(width: 6),
              Text(
                'IQA',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(controller.iqaLabels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.iqaLabels[i],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    cursorColor: AppColors.themeColor,
                    controller: controller.iqaControllers[i],
                    focusNode: controller.iqaFocusNodes[i],
                    enabled: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: AppColors.themeColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            BorderSide(color: AppColors.themeColor, width: 1.5),
                      ),
                      hintText: 'Scan ${controller.iqaLabels[i]}',
                    ),
                    onChanged: (_) => controller.onIqaFieldChanged(i),
                    onSubmitted: (_) => controller.submitIqaField(i),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  if (!controller.allStepsComplete) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFlashSection(),
                      if (controller.flashComplete.value) ...[
                        const SizedBox(height: 16),
                        _buildDtcSection(),
                        const SizedBox(height: 12),
                        _buildPidSection(),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        _buildActivitySection(),
      ],
    );
  }

  /// Recipe popup: static reference table straight from the harness
  /// API (sensor_name / reg_address / type / pin_no / value / unit).
  /// A sensor's VALUE only ever changes from the static API value once
  /// the operator uses the WRITE action on that row — there is no
  /// automatic PLC read here.
  void _showRecipeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 860,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Recipe',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.harnessReceipes.length} sensor${controller.harnessReceipes.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.themeColor),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isReadingPlcValues.value
                            ? null
                            : controller.readAllSensorValues,
                        icon: controller.isReadingPlcValues.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download, size: 16),
                        label: Text(controller.isReadingPlcValues.value ? 'Reading…' : 'Write Values'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.harnessReceipes.isEmpty) {
                      return Center(
                        child: Text(
                          'No recipe data yet — scan a harness first.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    return SingleChildScrollView(child: _buildRecipeTable());
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── header row ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('SENSOR NAME',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('REG. ADDRESS',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('TYPE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('PIN NO',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('VALUE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('UNIT',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('WRITE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── data rows ──
          ...controller.harnessReceipes.map((sensor) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      sensor.sensorName ?? '-',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${sensor.regAddress ?? '-'}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sensor.type ?? '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${sensor.pinNo ?? '-'}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Obx(() {
                      // Static API value by default. Only replaced once
                      // the operator explicitly writes this sensor via
                      // the WRITE action — no automatic PLC read here.
                      final live = sensor.id != null ? controller.livePlcValues[sensor.id] : null;
                      final display = live ?? '-';
                      final isLive = live != null && live != 'ERR';
                      return Text(
                        display,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: live == 'ERR'
                              ? Colors.red
                              : (isLive ? AppColors.themeColor : Colors.grey.shade500),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      sensor.unit ?? '-',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _SensorWriteAction(
                      sensor: sensor,
                      controller: controller,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlashSection() {
    return Obx(() {
      final expanded = controller.flashExpanded.value;

      String? statusText;
      if (controller.flashInProgress.value) {
        statusText = '${(controller.flashProgress.value * 100).round()}%';
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: controller.toggleFlash,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text('Flash File',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (controller.flashComplete.value) ...[
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.themeColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Flashing Successful',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.themeColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ] else if (statusText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildFlashBody(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFlashBody() {
    return Obx(() {
      if (controller.flashComplete.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.selectedFlashFile.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.selectedFlashFile.value!,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ),
            Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Text(
                  controller.formattedElapsed,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor:  AlwaysStoppedAnimation<Color>(AppColors.themeColor),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color:AppColors.themeColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Flashing successful',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      if (controller.flashInProgress.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (controller.selectedFlashFile.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  controller.selectedFlashFile.value!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ),
            Text(
              controller.formattedElapsed,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: controller.flashProgress.value,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(controller.flashProgress.value * 100).round()}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Image.asset('asset/new/gifPhone.gif', height: 90),
                Image.asset('asset/new/gifDownArrow.gif', height: 26),
                Image.asset('asset/new/ic_engine.png', height: 90),
              ],
            ),
          ],
        );
      }

      if (controller.flashFilesLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (controller.flashFilesError.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            controller.flashFilesError.value,
            style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
          ),
        );
      }

      if (controller.availableFlashFiles.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No flash files available',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!controller.dongleConnected.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for the dongle to connect automatically…',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.availableFlashFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final file = controller.availableFlashFiles[index];
                final isSelected = controller.selectedFlashFile.value == file;

                return GestureDetector(
                  onTap: () => controller.selectFlashFile(file),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.themeColor
                            : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        file,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      trailing: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.themeColor
                              : Colors.transparent,
                          border: Border.all(
                            color: AppColors.themeColor,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: (controller.selectedFlashFile.value != null &&
                      controller.dongleConnected.value)
                  ? controller.startFlashing
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Flashing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDtcSection() {
    return Obx(() => _buildExpandableSection(
          title: 'DTC',
          expanded: controller.dtcExpanded.value,
          onTap: controller.toggleDtc,
          trailingLabel: 'Count: ${controller.dtcCount}',
          items: controller.dtcList,
          itemBuilder: _buildDtcCard,
        ));
  }

  Widget _buildDtcCard(String raw) {
    final splitIndex = raw.indexOf(' - ');
    final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    final description =
        splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPidSection() {
    return Obx(() => _buildExpandableSection(
          title: 'PID',
          expanded: controller.pidExpanded.value,
          onTap: controller.togglePid,
          trailingLabel: null,
          items: controller.pidList,
          itemBuilder: _buildPidCard,
        ));
  }

  Widget _buildPidCard(String raw) {
    final splitIndex = raw.indexOf(' — ');
    final label = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    final value = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required String? trailingLabel,
    required List<String> items,
    Widget Function(String item)? itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (trailingLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trailingLabel,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.themeColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: items.isEmpty
                  ? Text(
                      'No data yet',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    )
                  : (itemBuilder != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              items.map((item) => itemBuilder(item)).toList(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text('• $item',
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                        )),
            ),
        ],
      ),
    );
  }

  void _copyActivityLog() {
    final text = controller.activityLog.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '${controller.activityLog.length} log line${controller.activityLog.length == 1 ? '' : 's'} copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.themeColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Activity',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Obx(
                () => IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: AppColors.themeColor,
                  tooltip: 'Copy all activity log',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.activityLog.isEmpty
                      ? null
                      : () => _copyActivityLog(),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: Obx(
              () => ListView(
                padding: EdgeInsets.zero,
                children: controller.activityLog
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            entry,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade700),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline "write a value" control for one Recipe row: a small number
/// field + send button. Writes to the PLC, then reads the register
/// back for real confirmation (see writeSensorValue in the
/// controller) — the VALUE cell updates with whatever the PLC
/// actually confirms, not just an echo of what was typed. Kept as its
/// own StatefulWidget so its TextEditingController survives the
/// Recipe dialog's Obx rebuilds.
class _SensorWriteAction extends StatefulWidget {
  const _SensorWriteAction({required this.sensor, required this.controller});

  final harness_ds.Receipe sensor;
  final HomePageController controller;

  @override
  State<_SensorWriteAction> createState() => _SensorWriteActionState();
}

class _SensorWriteActionState extends State<_SensorWriteAction> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _valueController.text.trim();
    final value = int.tryParse(text);
    if (value == null) return;

    await widget.controller.writeSensorValue(widget.sensor, value);
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = widget.sensor.id;
      final isBusy = id != null && widget.controller.writeInFlightSensorIds.contains(id);

      return Row(
        children: [
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: _valueController,
              enabled: !isBusy,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                hintText: 'value',
                hintStyle: const TextStyle(fontSize: 11),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          // const SizedBox(width: 6),
          // SizedBox(
          //   width: 32,
          //   height: 32,
          //   child: IconButton(
          //     padding: EdgeInsets.zero,
          //     icon: isBusy
          //         ? const SizedBox(
          //             width: 14,
          //             height: 14,
          //             child: CircularProgressIndicator(strokeWidth: 2),
          //           )
          //         : Icon(Icons.send, size: 16, color: AppColors.themeColor),
          //     onPressed: isBusy ? null : _submit,
          //     tooltip: 'Write value to PLC',
          //   ),
          // ),
        ],
      );
    });
  }
}
