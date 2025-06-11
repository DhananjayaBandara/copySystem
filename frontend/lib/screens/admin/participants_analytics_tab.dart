import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_api_service.dart';
import '../../utils/charts_utils.dart';
import '../../utils/constants.dart';
import '../../widgets/analytics_card.dart';
import '../../widgets/metric_card.dart';
import 'dart:async';
import 'participant_details_screen.dart';

class ParticipantsAnalyticsTab extends StatefulWidget {
  const ParticipantsAnalyticsTab({Key? key}) : super(key: key);

  @override
  _ParticipantsAnalyticsTabState createState() =>
      _ParticipantsAnalyticsTabState();
}

class _ParticipantsAnalyticsTabState extends State<ParticipantsAnalyticsTab> {
  late Future<Map<String, dynamic>> _participantsData;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _participantsData = AnalyticsApiService.getParticipantsAnalytics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _participantsData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading participants data',
              style: TextStyle(color: negativeColor),
            ),
          );
        }
        final data = snapshot.data!;
        final top10 = (data['top_10_participants'] ?? []) as List;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participants Overview',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: isWide ? 3 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: isWide ? 2 : 4,
                      children: [
                        EnhancedMetricCard(
                          icon: Icons.group,
                          title: 'Total Participants',
                          value: '${data['total_participants'] ?? 0}',
                        ),
                        EnhancedMetricCard(
                          icon: Icons.check,
                          title: 'Attendance %',
                          value: '${data['attendance_percentage'] ?? 0}%',
                          color: positiveColor,
                        ),
                        EnhancedMetricCard(
                          icon: Icons.feedback,
                          title: 'Feedback Response Rate',
                          value: '${data['feedback_response_rate'] ?? 0}%',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (top10.isNotEmpty) ...[
                      AnalyticsCard(
                        title:
                            'Top 10 Participants (Sessions Attended & Registered)',
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: top10.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final p = top10[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text('${idx + 1}'),
                                ),
                                title: Text(
                                  p['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  p['email'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p['attended_sessions'] ?? 0} attended',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.event_note,
                                          color: Colors.indigo,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p['registered_sessions'] ?? 0} registered',
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ParticipantDetailsScreen(
                                            participant: p,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    AnalyticsCard(
                      title: 'Gender Distribution',
                      child:
                          (data['gender_distribution'] != null &&
                                  data['gender_distribution'] is Map)
                              ? Column(
                                children: [
                                  SizedBox(
                                    height: 160,
                                    child: PieChart(
                                      AppCharts.createPieChart(
                                        sections:
                                            (data['gender_distribution']
                                                    as Map<String, dynamic>)
                                                .entries
                                                .map((entry) {
                                                  final color =
                                                      entry.key.toLowerCase() ==
                                                              'male'
                                                          ? Colors.blue
                                                          : entry.key
                                                                  .toLowerCase() ==
                                                              'female'
                                                          ? Colors.pink
                                                          : Colors.grey;
                                                  return PieChartSectionData(
                                                    color: color,
                                                    value:
                                                        (entry.value as num)
                                                            .toDouble(),
                                                    title:
                                                        '${entry.key}: ${entry.value}',
                                                  );
                                                })
                                                .toList(),
                                        centerSpaceRadius: 50,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    children:
                                        (data['gender_distribution']
                                                as Map<String, dynamic>)
                                            .entries
                                            .map((entry) {
                                              final color =
                                                  entry.key.toLowerCase() ==
                                                          'male'
                                                      ? Colors.blue
                                                      : entry.key
                                                              .toLowerCase() ==
                                                          'female'
                                                      ? Colors.pink
                                                      : Colors.grey;
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 14,
                                                    height: 14,
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(entry.key),
                                                ],
                                              );
                                            })
                                            .toList(),
                                  ),
                                ],
                              )
                              : const Text('No gender distribution data.'),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsCard(
                      title: 'District Histogram',
                      child:
                          (data['district_histogram'] != null &&
                                  data['district_histogram'] is Map)
                              ? Column(
                                children: [
                                  SizedBox(
                                    height: 240,
                                    child: BarChart(
                                      AppCharts.createVerticalBarChart(
                                        barGroups: List.generate(
                                          districts.length,
                                          (i) {
                                            final district = districts[i];
                                            final count =
                                                (data['district_histogram'][district] ??
                                                        0)
                                                    as int;
                                            return BarChartGroups.createBarGroup(
                                              x: i,
                                              y: count.toDouble(),
                                              color: primaryColor,
                                            );
                                          },
                                        ),
                                        maxY:
                                            (data['district_histogram']
                                                    as Map<String, dynamic>)
                                                .values
                                                .fold<num>(
                                                  0,
                                                  (prev, e) =>
                                                      e > prev ? e : prev,
                                                )
                                                .toDouble() *
                                            1.2,
                                        bottomTitles: districts,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('District Count'),
                                    ],
                                  ),
                                ],
                              )
                              : const Text('No district histogram data.'),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsCard(
                      title: 'Participant Type Distribution',
                      child:
                          (data['type_distribution'] != null &&
                                  data['type_distribution'] is Map)
                              ? Column(
                                children: [
                                  SizedBox(
                                    height: 240,
                                    child: BarChart(
                                      AppCharts.createVerticalBarChart(
                                        barGroups:
                                            (data['type_distribution']
                                                    as Map<String, dynamic>)
                                                .entries
                                                .map((entry) {
                                                  final idx =
                                                      (data['type_distribution']
                                                              as Map<
                                                                String,
                                                                dynamic
                                                              >)
                                                          .keys
                                                          .toList()
                                                          .indexOf(entry.key);
                                                  return BarChartGroups.createBarGroup(
                                                    x: idx,
                                                    y:
                                                        (entry.value as num)
                                                            .toDouble(),
                                                    color: accentColor,
                                                  );
                                                })
                                                .toList(),
                                        maxY:
                                            (data['type_distribution']
                                                    as Map<String, dynamic>)
                                                .values
                                                .fold<num>(
                                                  0,
                                                  (prev, e) =>
                                                      e > prev ? e : prev,
                                                )
                                                .toDouble() *
                                            1.2,
                                        bottomTitles:
                                            (data['type_distribution']
                                                    as Map<String, dynamic>)
                                                .keys
                                                .toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Participant Type Count'),
                                    ],
                                  ),
                                ],
                              )
                              : const Text('No participant type data.'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
