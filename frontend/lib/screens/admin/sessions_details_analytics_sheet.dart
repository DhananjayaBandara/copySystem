import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import '../../utils/charts_utils.dart';
import '../../widgets/analytics_funnel.dart';
import '../../widgets/analytics_card.dart';
import '../../utils/constants.dart';

class SessionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> detail;

  const SessionDetailSheet({required this.detail});

  Color _getRatingColor(int rating) {
    if (rating >= 8) return positiveColor;
    if (rating >= 5) return Colors.amber;
    return negativeColor;
  }

  @override
  Widget build(BuildContext context) {
    final ratingDist = detail['feedback_rating_distribution'] as Map? ?? {};
    final registered = (detail['registered_count'] ?? 0) as int;
    final attended = (detail['attended_count'] ?? 0) as int;
    final feedbackParticipants =
        detail['feedback_participants'] is int
            ? detail['feedback_participants'] as int
            : (detail['feedback_participants'] is List
                ? (detail['feedback_participants'] as List).length
                : 0);
    final absent = registered - attended;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  detail['title'] ?? 'Session Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                AnalyticsCard(
                  title: 'Session Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workshop: ${detail['workshop'] ?? 'N/A'}'),
                      Text('Date: ${detail['date_time'] ?? 'N/A'}'),
                      Text('Registered: $registered'),
                      Text('Attended: $attended'),
                    ],
                  ),
                ),
                AnalyticsCard(
                  title: 'Session Funnel',
                  child: AnalyticsFunnel(
                    registered: registered,
                    attended: attended,
                    feedbackCount: feedbackParticipants,
                    compact: true,
                  ),
                ),
                AnalyticsCard(
                  title: 'Attendance Distribution',
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      AppCharts.createPieChart(
                        sections: AppCharts.createPieSections(
                          values: [
                            registered > 0
                                ? (attended.toDouble() / registered) * 100
                                : 0,
                            registered > 0
                                ? (absent.toDouble() / registered) * 100
                                : 0,
                          ],
                          colors: [positiveColor, negativeColor],
                          titles: ['Attended', 'Absent'],
                          radius: 70,
                        ),
                      ),
                    ),
                  ),
                ),
                AnalyticsCard(
                  title: 'Feedback Rating Distribution',
                  child:
                      ratingDist.isEmpty
                          ? const Text('No feedback ratings available.')
                          : SizedBox(
                            height: 240,
                            child: BarChart(
                              AppCharts.createVerticalBarChart(
                                barGroups: List.generate(10, (index) {
                                  final rating = index + 1;
                                  return BarChartGroups.createBarGroup(
                                    x: rating - 1,
                                    y:
                                        (ratingDist[rating.toString()] ?? 0)
                                            .toDouble(),
                                    color: _getRatingColor(rating),
                                  );
                                }),
                                maxY:
                                    (ratingDist.values.reduce(
                                              (a, b) => a > b ? a : b,
                                            )
                                            as num)
                                        .toDouble() *
                                    1.2,
                                bottomTitles: List.generate(
                                  10,
                                  (i) => '${i + 1}',
                                ),
                              ),
                            ),
                          ),
                ),
                if ((detail['feedback_suggestions'] as List?)?.isNotEmpty ??
                    false)
                  AnalyticsCard(
                    title: 'Top Suggestions/Problems',
                    child: Column(
                      children:
                          (detail['feedback_suggestions'] as List)
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 4.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Expanded(child: Text(s)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                AnalyticsCard(
                  title: 'Top Keywords',
                  child: Text(
                    detail['top_keywords']?.join(", ") ??
                        'No keywords available',
                  ),
                ),
                AnalyticsCard(
                  title: 'Participants',
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (detail['participants'] as List?)?.length ?? 0,
                    itemBuilder: (context, idx) {
                      final p = detail['participants'][idx];
                      return OpenContainer(
                        transitionType: ContainerTransitionType.fadeThrough,
                        closedElevation: 0,
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        closedBuilder:
                            (context, openContainer) => ListTile(
                              dense: true,
                              title: Text('${p['name']} (${p['email']})'),
                              trailing:
                                  p['attended']
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: positiveColor,
                                      )
                                      : const Icon(
                                        Icons.cancel,
                                        color: negativeColor,
                                      ),
                              subtitle: Text(
                                p['attended'] ? 'Attended' : 'Absent',
                              ),
                            ),
                        openBuilder:
                            (context, _) => Scaffold(
                              appBar: AppBar(
                                title: Text(p['name'] ?? 'Participant Details'),
                              ),
                              body: Center(
                                child: Text('Details for ${p['name']}'),
                              ),
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
