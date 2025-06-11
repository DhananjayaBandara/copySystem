import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const AppFooter({
    Key? key,
    this.backgroundColor = Colors.indigo,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'National Workshop Portal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '© 2025 National Digital Capacity Building Program | ICTA Sri Lanka',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            'Contact: info@icta.lk | Hotline: +94 11 2 369 099',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.facebook, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Icon(Icons.linked_camera, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Icon(Icons.language, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Powered by ICTA Sri Lanka',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
