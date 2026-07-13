// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/common_widgets/custom_app_bar.dart';
// import 'package:simpson/views/widget/psf_lane_card.dart';

// import '../controllers/psf_home_screen_controller.dart';

// class PsfHomeScreenView extends GetView<PsfHomeScreenController> {
//   const PsfHomeScreenView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonAppBar(
//         title: controller.station,
//         actions: [
//           Obx(
//             () => TextButton.icon(
//               onPressed: controller.onPlcButtonTapped,
//               icon: Icon(
//                 Icons.circle,
//                 size: 10,
//                 color: controller.isPlcConnected.value ? Colors.greenAccent : Colors.redAccent,
//               ),
//               label: Text(
//                 controller.isPlcConnected.value ? 'PLC Connected' : 'Connect PLC',
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//               ),
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.white.withOpacity(0.12),
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: controller.logout,
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       backgroundColor: const Color(0xFFF4F5F7),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _esnScanBar(),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   const int visibleLaneCount = 4; // bigger cards, 4 per screen
//                   const double spacing = 16;
//                   final double cardWidth =
//                       (constraints.maxWidth - spacing * (visibleLaneCount - 1)) / visibleLaneCount;
//                   final double cardHeight = constraints.maxHeight;

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: List.generate(PsfHomeScreenController.laneCount, (i) {
//                         return Padding(
//                           padding: EdgeInsets.only(right: i == PsfHomeScreenController.laneCount - 1 ? 0 : spacing),
//                           child: PsfLaneCard(
//                             laneIndex: i,
//                             lane: controller.lanes[i],
//                             controller: controller,
//                             width: cardWidth,
//                             height: cardHeight,
//                           ),
//                         );
//                       }),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _esnScanBar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 300,
//             child: TextField(
//               controller: controller.esnController,
//               decoration: const InputDecoration(
//                 hintText: 'Scan or enter ESN',
//                 isDense: true,
//                 border: OutlineInputBorder(),
//               ),
//               onSubmitted: (_) => controller.onScanEsn(),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Obx(
//             () => SizedBox(
//               height: 42,
//               child: ElevatedButton(
//                 onPressed: controller.isLookingUpEsn.value ? null : controller.onScanEsn,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF003874), // matches AppColors.themeColor
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: const Color(0xFF003874).withOpacity(0.5),
//                   disabledForegroundColor: Colors.white70,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                 ),
//                 child: controller.isLookingUpEsn.value
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                       )
//                     : const Text('IDENTIFY MODEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Obx(
//             () => controller.currentTargetLane.value != null
//                 ? TextButton(
//                     onPressed: controller.resetForNextEsn,
//                     child: const Text('RESET / NEXT ENGINE', style: TextStyle(fontWeight: FontWeight.w800)),
//                   )
//                 : const SizedBox.shrink(),
//           ),
//           const SizedBox(width: 12),
//           Obx(
//             () => controller.esnError.value.isEmpty
//                 ? const SizedBox.shrink()
//                 : Expanded(
//                     child: Text(controller.esnError.value, style: const TextStyle(fontSize: 12, color: Colors.red)),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import '../controllers/psf_home_screen_controller.dart';

class PsfHomeScreenView extends GetView<PsfHomeScreenController> {
  const PsfHomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f5f7),

      appBar: CommonAppBar(
        title: controller.station,
        actions: [

          Obx(
            () => Container(
              margin: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                onPressed: controller.onPlcButtonTapped,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(.15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                ),
                icon: Icon(
                  Icons.circle,
                  size: 12,
                  color: controller.isPlcConnected.value
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
                label: Text(
                  controller.isPlcConnected.value
                      ? "PLC Connected"
                      : "Connect PLC",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout,color: Colors.white),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: LayoutBuilder(
          builder: (context,constraints){

            const int visibleCards = 4;
            const double spacing = 15;

            final double cardWidth =
                (constraints.maxWidth -
                        ((visibleCards - 1) * spacing)) /
                    visibleCards;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(

                  4,

                  (index){

                    return Padding(

                      padding: EdgeInsets.only(
                        right: index==3?0:spacing,
                      ),

                      child: _buildLaneCard(
                        laneNo: index+1,
                        width: cardWidth,
                        height: constraints.maxHeight,
                      ),

                    );

                  },

                ),
              ),
            );

          },
        ),
      ),
    );
  }

  Widget _buildLaneCard({

    required int laneNo,
    required double width,
    required double height,

  }){

    return Container(

      width: width,
      height: height,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(
          color: Colors.grey.shade300,
        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(10),

            decoration: const BoxDecoration(

              color: Color(0xff003874),

              borderRadius: BorderRadius.only(

                topLeft: Radius.circular(10),

                topRight: Radius.circular(10),

              ),

            ),

            child: Text(

              "Lane $laneNo",

              style: const TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.bold,

                fontSize: 18,

              ),

            ),

          ),

          Expanded(

            child: SingleChildScrollView(

              padding: const EdgeInsets.all(12),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(

                    "ECU Model",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),

                  ),

                  const SizedBox(height:6),

                  TextField(

                    decoration: InputDecoration(

                      hintText: "Model Number",

                      isDense: true,

                      border: OutlineInputBorder(),

                    ),

                  ),

                  const SizedBox(height:12),

                  Row(

                    children: [

                      Container(

                        width: 12,

                        height: 12,

                        decoration: const BoxDecoration(

                          color: Colors.red,

                          shape: BoxShape.circle,

                        ),

                      ),

                      const SizedBox(width:8),

                      const Text(

                        "ECU Not Connected",

                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height:15),

                  const Text(

                    "Scan ESN Number",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),

                  ),

                  const SizedBox(height:6),

                  TextField(

                    decoration: InputDecoration(

                      hintText: "Scan ESN",

                      suffixIcon: Icon(Icons.qr_code_scanner),

                      border: OutlineInputBorder(),

                      isDense: true,

                    ),

                  ),

                  const SizedBox(height:15),

                  // CONTINUE IN PART-2
                                    const Text(
                    "Flashing Status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Status : Waiting",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "Progress : 0%",
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height:15),


                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton.icon(

                          onPressed: (){

                            // ECU Connect Function

                          },

                          icon: const Icon(
                            Icons.link,
                            size:18,
                          ),

                          label: const Text(
                            "Connect",
                          ),

                          style: ElevatedButton.styleFrom(

                            backgroundColor:
                                const Color(0xff003874),

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets.symmetric(
                                  vertical:12,
                                ),

                          ),

                        ),
                      ),


                      const SizedBox(width:10),


                      Expanded(
                        child: ElevatedButton.icon(

                          onPressed: (){

                            // Start Flashing Function

                          },

                          icon: const Icon(
                            Icons.flash_on,
                            size:18,
                          ),

                          label: const Text(
                            "Flash",
                          ),

                          style: ElevatedButton.styleFrom(

                            backgroundColor:
                                Colors.green,

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets.symmetric(
                                  vertical:12,
                                ),

                          ),

                        ),
                      ),

                    ],
                  ),


                  const SizedBox(height:15),


                  const Text(

                    "Live Parameters",

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize:16,

                    ),

                  ),


                  const SizedBox(height:8),


                  _parameterRow(
                    "Voltage",
                    "0 V",
                  ),

                  _parameterRow(
                    "Current",
                    "0 A",
                  ),

                  _parameterRow(
                    "Battery",
                    "0 %",
                  ),

                  _parameterRow(
                    "Temperature",
                    "0 °C",
                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }


  Widget _parameterRow(
      String title,
      String value,
  ){

    return Container(

      margin: const EdgeInsets.only(
        bottom:8,
      ),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: const Color(0xfff4f5f7),

        borderRadius:
            BorderRadius.circular(6),

      ),

      child: Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

        ],

      ),

    );

  }

}