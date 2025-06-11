import 'package:flutter/material.dart';
import 'analytics_card.dart';

class EnhancedMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const EnhancedMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
