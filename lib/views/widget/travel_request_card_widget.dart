import 'package:autopeepalApp/modals/travelRequest.modal.dart';
import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelRequestCard extends StatelessWidget {
  final TravelRequest request;

  const TravelRequestCard({Key? key, required this.request}) : super(key: key);

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Not specified';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (request.employeeName ?? 'TR').isNotEmpty
        ? request.employeeName!.substring(0, 1)
        : 'TR';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                CircleAvatar(
                  // ignore: deprecated_member_use
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    initials,
                    style:  TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.employeeName ?? 'Travel Request',
                        style:  TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                           color: AppColors.primary
                        ),
                      ),
                      if (request.empDetails?.designation != null &&
                          request.empDetails!.designation!.isNotEmpty)
                        Text(
                          request.empDetails!.designation!,
                          style: TextStyle(
                            fontSize: 13,
                             color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusIndicator(request.docstatus ?? 0),
              ],
            ),

            const SizedBox(height: 16),

            // Travel purpose and type
            _buildSectionHeader('Travel Details'),
            const SizedBox(height: 8),
            _buildDetailRow('Purpose', request.purposeOfTravel ?? 'Not specified'),
            _buildDetailRow('Type', request.travelType ?? 'Not specified'),
            // _buildDetailRow('Funding', request.travelFunding ?? 'Not specified'),
            if (request.travelProof != null && request.travelProof!.isNotEmpty)
              _buildDetailRow('Proof', request.travelProof!),

            const SizedBox(height: 16),

            // Travel itinerary
            _buildSectionHeader('Itinerary'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildLocationBlock(
                    label: 'From',
                    location: request.travelFrom ?? 'Not specified',
                    icon: Icons.flight_takeoff,
                    color: Colors.blue[50]!,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLocationBlock(
                    label: 'To',
                    location: request.travelTo ?? 'Not specified',
                    icon: Icons.flight_land,
                    color: Colors.green[50]!,
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 12),
            // _buildDetailRow(
            //   'Departure',
            //   _formatDate(request.departureDate),
            //   icon: Icons.calendar_today,
            // ),

            const SizedBox(height: 16),

            // Contact information
            // _buildSectionHeader('Contact Information'),
            // const SizedBox(height: 8),
            // _buildDetailRow('Email', request.preferedEmail ?? 'Not specified', icon: Icons.email),
            // _buildDetailRow('Phone', request.cellNumber ?? 'Not specified', icon: Icons.phone),

            // const SizedBox(height: 16),

            // Travel expenses
            if (request.travelExpense != null && request.travelExpense!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Expenses'),
                  const SizedBox(height: 8),
                  ...request.travelExpense!.entries.map((entry) => 
                    _buildExpenseRow(entry.key, entry.value.toString())
                  ).toList(),
                ],
              ),
            
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatDate(request.modified)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
         color: AppColors.primary,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: 18, color:  AppColors.primary),
            ),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBlock({
    required String label,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            location,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(String category, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              amount,
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(int docstatus) {
    final statusInfo = {
      0: {'text': 'Draft', 'color': Colors.orange},
      1: {'text': 'Submitted', 'color':  AppColors.primary},
      2: {'text': 'Approved', 'color': Colors.green},
    };

    final status = statusInfo[docstatus] ?? 
      {'text': 'Unknown', 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status['color'] as Color,
          width: 1,
        ),
      ),
      child: Text(
        status['text'] as String,
        style: TextStyle(
          color: status['color'] as Color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}