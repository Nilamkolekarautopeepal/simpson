import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  String selectedMonth = '06';
  String selectedYear = '2025';
  String? selectedStatus; // null means "All"

  final List<String> months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12',
  ];

  final List<String> years = [
    '2023', '2024', '2025', '2026',
  ];

  final List<String?> statuses = [
    null, 'Pending', 'Approved', 'Rejected',
  ];

  String getMonthName(String monthNumber) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[int.parse(monthNumber) - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Dropdowns
        Row(
          children: [
            // Month
            DropdownButton<String>(
              value: selectedMonth,
              hint: const Text("Month"),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(getMonthName(month)),
                );
              }).toList(),
            ),
            const SizedBox(width: 16),
            // Year
            DropdownButton<String>(
              value: selectedYear,
              hint: const Text("Year"),
              onChanged: (value) {
                setState(() {
                  selectedYear = value!;
                });
              },
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
            ),
            const SizedBox(width: 16),
            // Status
            DropdownButton<String?>(
              value: selectedStatus,
              hint: const Text("Status"),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status ?? 'All'),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Display Filter Description
        Text(
          "Filters: ${getMonthName(selectedMonth)} $selectedYear • Status: ${selectedStatus ?? 'All'}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
