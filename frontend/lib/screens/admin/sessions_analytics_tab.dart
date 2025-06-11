import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animations/animations.dart';
import '../../services/analytics_api_service.dart';
import '../../utils/charts_utils.dart';
import '../../widgets/analytics_funnel.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/analytics_card.dart';
import 'sessions_details_analytics_sheet.dart';
import '../../utils/constants.dart';
import 'dart:async';

class SessionsAnalyticsTab extends StatefulWidget {
  const SessionsAnalyticsTab({Key? key}) : super(key: key);

  @override
  _SessionsAnalyticsTabState createState() => _SessionsAnalyticsTabState();
}

class _SessionsAnalyticsTabState extends State<SessionsAnalyticsTab> {
  late Future<Map<String, dynamic>> _overviewFuture;
  late Future<List<dynamic>> _sessionsListFuture;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _overviewFuture = AnalyticsApiService.getSessionsOverview();
    _sessionsListFuture = AnalyticsApiService.getSessionsList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _openSessionDetail(int sessionId) async {
    final detail = await AnalyticsApiService.getSessionDetail(sessionId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SessionDetailSheet(detail: detail),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _overviewFuture,
      builder: (context, overviewSnapshot) {
        if (overviewSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (overviewSnapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading sessions overview',
              style: TextStyle(color: negativeColor),
            ),
          );
        }
        final overview = overviewSnapshot.data!;
        final int totalRegistered = overview['total_registered'] ?? 0;
        final int totalAttended = overview['total_attended'] ?? 0;
        final int feedbackCount = overview['feedback_count'] ?? 0;

        return FutureBuilder<List<dynamic>>(
          future: _sessionsListFuture,
          builder: (context, listSnapshot) {
            if (listSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (listSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Error loading sessions list',
                  style: TextStyle(color: negativeColor),
                ),
              );
            }
            final sessions = listSnapshot.data!;
            final filteredSessions =
                _searchQuery.isEmpty
                    ? sessions
                    : sessions
                        .where(
                          (s) =>
                              (s['title']?.toLowerCase() ?? '').contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (s['workshop']?.toLowerCase() ?? '').contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();

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
                          'Sessions Overview',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Metrics Grid
                        GridView.count(
                          crossAxisCount: isWide ? 3 : 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: isWide ? 2 : 4,
                          children: [
                            EnhancedMetricCard(
                              icon: Icons.event_note,
                              title: 'Total Sessions',
                              value: '${overview['total_sessions']}',
                            ),
                            EnhancedMetricCard(
                              icon: Icons.group,
                              title: 'Total Registered',
                              value: '$totalRegistered',
                            ),
                            EnhancedMetricCard(
                              icon: Icons.check_circle,
                              title: 'Total Attended',
                              value: '$totalAttended',
                              color: positiveColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Session Funnel
                        AnalyticsFunnel(
                          registered: totalRegistered,
                          attended: totalAttended,
                          feedbackCount: feedbackCount,
                          title: 'Session Funnel',
                        ),
                        const SizedBox(height: 16),
                        // Attendance Comparison
                        AnalyticsCard(
                          title: 'Attendance Rate',
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Registered vs. Attended'),
                                  Text(
                                    '${overview['average_attendance_rate']}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 240,
                                child: BarChart(
                                  AppCharts.createVerticalBarChart(
                                    barGroups: [
                                      BarChartGroups.createBarGroup(
                                        x: 0,
                                        y: totalRegistered.toDouble(),
                                        color: primaryColor,
                                      ),
                                      BarChartGroups.createBarGroup(
                                        x: 1,
                                        y: totalAttended.toDouble(),
                                        color: positiveColor,
                                      ),
                                    ],
                                    maxY:
                                        (totalRegistered > totalAttended
                                                ? totalRegistered
                                                : totalAttended)
                                            .toDouble() *
                                        1.2,
                                    bottomTitles: ['Registered', 'Attended'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Attendance per Session
                        AnalyticsCard(
                          title: 'Attendance per Session',
                          child: _buildAttendancePerSessionChart(overview),
                        ),
                        const SizedBox(height: 16),
                        // Feedback Summary
                        AnalyticsCard(
                          title: 'Feedback Summary',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Responses: $feedbackCount'),
                              Text(
                                'Avg. Rating: ${overview['average_feedback_rating'] ?? "-"}',
                              ),
                              Text(
                                'Top Keywords: ${overview['common_feedback_keywords']?.join(", ") ?? "-"}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sessions List
                        AnalyticsCard(
                          title: 'Sessions List',
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Search by title or workshop',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      _searchQuery.isNotEmpty
                                          ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed:
                                                () => setState(
                                                  () => _searchQuery = '',
                                                ),
                                          )
                                          : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                onChanged: _onSearchChanged,
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredSessions.length,
                                itemBuilder: (context, index) {
                                  final session = filteredSessions[index];
                                  return OpenContainer(
                                    transitionType:
                                        ContainerTransitionType.fadeThrough,
                                    closedElevation: 0,
                                    closedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    closedBuilder:
                                        (context, openContainer) => Card(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.event,
                                              color: primaryColor,
                                            ),
                                            title: Text(
                                              session['title'] ??
                                                  'Session ${index + 1}',
                                            ),
                                            subtitle: Text(
                                              'Workshop: ${session['workshop'] ?? '-'}\n'
                                              'Date: ${session['date_time'] ?? '-'}\n'
                                              'Registered: ${session['registered_count'] ?? 0} | '
                                              'Attended: ${session['attended_count'] ?? 0} | '
                                              'Avg. Rating: ${session['avg_feedback_rating'] ?? "-"}',
                                            ),
                                            onTap:
                                                () => _openSessionDetail(
                                                  session['id'],
                                                ),
                                          ),
                                        ),
                                    openBuilder:
                                        (context, _) =>
                                            SessionDetailSheet(detail: session),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttendancePerSessionChart(Map<String, dynamic> overview) {
    final sessionTitles = (overview['session_titles'] as List<dynamic>?) ?? [];
    final attendancePerSession =
        (overview['attendance_per_session'] as List<dynamic>?) ?? [];

    if (sessionTitles.isEmpty || attendancePerSession.isEmpty) {
      return const Text('No session attendance data.');
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        AppCharts.createVerticalBarChart(
          barGroups: List.generate(
            sessionTitles.length,
            (i) => BarChartGroups.createBarGroup(
              x: i,
              y: (attendancePerSession[i] as num).toDouble(),
              color: positiveColor,
            ),
          ),
          maxY:
              (attendancePerSession.reduce((a, b) => a > b ? a : b) as num)
                  .toDouble() *
              1.2,
          bottomTitles: sessionTitles.map((t) => t.toString()).toList(),
        ),
      ),
    );
  }
}
