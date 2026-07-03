    import 'package:simpson/themes/app_theme.dart';
import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  @override
  Widget build(Object context) {
    return Container(
      color: AppColors.Warning,
      child: Row(
                children: [
                  IconButton(
                    
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                   
               
                    },
                  ),
                  Text('1'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () {
                      
                      
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                   
                    },
                  ),
                ],
              ),
    );
  }


  
}