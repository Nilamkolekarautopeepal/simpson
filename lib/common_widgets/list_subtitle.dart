
import 'package:flutter/material.dart';

class ListSubtitle extends StatelessWidget {
  final String title;
 final String title2;

  const ListSubtitle({super.key, required this.title, required this.title2});
  @override
  Widget build(Object context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image widget
      Text(
         title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        // Text widget
        Text(
         title2,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
