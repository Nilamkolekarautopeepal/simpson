import 'package:flutter/material.dart';

class JobCardItem extends StatelessWidget {
  const JobCardItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + STATUS
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vecv/6458789e7e76e6/74567456547',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: const [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFFF47A1F),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'New',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 10),

          /// JOB NUMBER
          Row(
  children: [
    Image.asset(
      'asset/logo/Vector.png',
      width: 16,
      height: 16,
      color: Colors.grey, 
    ),
    const SizedBox(width: 6),
    const Text(
      'MC76453346723623327',
      style: TextStyle(fontSize: 13, color: Colors.black54),
    ),
  ],
)
,

          const SizedBox(height: 6),

          /// VEHICLE + DATE
          Row(
            children:  [
             Image.asset(
      'asset/logo/Vector (1).png',
      width: 16,
      height: 16,
      color: Colors.grey, 
    ),
              SizedBox(width: 6),
              Text(
                '65474874/ BSVI',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Spacer(),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                '01 May 2024',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
