import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import 'analytics_card.dart';

class AnalyticsFunnel extends StatefulWidget {
  final int registered;
  final int attended;
  final int feedbackCount;
  final String title;
  final bool compact;

  const AnalyticsFunnel({
    required this.registered,
    required this.attended,
    required this.feedbackCount,
    this.title = '',
    this.compact = false,
    super.key,
  });

  @override
  State<AnalyticsFunnel> createState() => _AnalyticsFunnelState();
}

class _AnalyticsFunnelState extends State<AnalyticsFunnel> {
  int? _touchedIndex; // Tracks the touched bar index for tooltips

  @override
  Widget build(BuildContext context) {
    // Calculate max Y value for scaling
    final maxY =
        [
          widget.registered.toDouble(),
          widget.attended.toDouble(),
          widget.feedbackCount.toDouble(),
        ].reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity) *
        1.2; // 20% padding, avoid zero

    return AnalyticsCard(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: widget.compact ? 140 : 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: maxY,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: widget.registered.toDouble(),
                        width: widget.compact ? 20 : 30,
                        color: primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: _touchedIndex == 0 ? [0] : [],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: widget.attended.toDouble(),
                        width: widget.compact ? 20 : 30,
                        color: positiveColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: _touchedIndex == 1 ? [0] : [],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: widget.feedbackCount.toDouble(),
                        width: widget.compact ? 20 : 30,
                        color: Colors.amber,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: _touchedIndex == 2 ? [0] : [],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // Space for vertical labels
                      getTitlesWidget: (value, meta) {
                        const labels = ['Registered', 'Attended', 'Feedback'];
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                labels[index],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY)
                          return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          ['Registered', 'Attended', 'Feedback'][group.x];
                      final value = rod.toY.toInt();
                      return BarTooltipItem(
                        '$label: $value',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedIndex = null;
                        return;
                      }
                      _touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                gridData: const FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend: Always visible
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                label: 'Registered',
                color: primaryColor,
                value: widget.registered,
              ),
              _LegendItem(
                label: 'Attended',
                color: positiveColor,
                value: widget.attended,
              ),
              _LegendItem(
                label: 'Feedback',
                color: Colors.amber,
                value: widget.feedbackCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final int value;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
