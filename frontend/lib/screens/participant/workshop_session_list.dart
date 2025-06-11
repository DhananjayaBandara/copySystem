import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/api_service.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/app_footer.dart';
import '../participant/session_detail_screen.dart';

class WorkshopSessionListScreen extends StatefulWidget {
  @override
  _WorkshopSessionListScreenState createState() =>
      _WorkshopSessionListScreenState();
}

class _WorkshopSessionListScreenState extends State<WorkshopSessionListScreen> {
  late Future<List<dynamic>> _sessionsFuture;
  String _searchQuery = '';
  List<DateTime> sessionDates = [];
  Map<DateTime, int> sessionDateToId = {};

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _loadSessions();
  }

  Future<List<dynamic>> _loadSessions() async {
    final sessions = await ApiService.getSessions();
    // Sort sessions by date_time descending (newest first)
    sessions.sort((a, b) {
      final aDate = DateTime.tryParse(a['date_time'] ?? '') ?? DateTime(1970);
      final bDate = DateTime.tryParse(b['date_time'] ?? '') ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    sessionDates =
        sessions.map<DateTime>((s) => DateTime.parse(s['date_time'])).toList();
    sessionDateToId = {
      for (var s in sessions)
        DateTime.parse(s['date_time']).copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            ):
            s['id'],
    };
    return sessions;
  }

  List<dynamic> _filterSessions(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (s) =>
              (s['workshop']?['title'] ?? '').toLowerCase().contains(q) ||
              (s['location'] ?? '').toLowerCase().contains(q) ||
              (s['target_audience'] ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Header
      appBar: AppBar(
        title: const Text('Available Sessions'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _sessionsFuture = _loadSessions();
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'National Workshop Portal',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.info_outline_rounded,
                  size: 40,
                ),
                children: [
                  const Text(
                    'This portal provides access to various workshops and sessions organized by the National Digital Capacity Building Program.',
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Help'),
                      content: const Text(
                        'Use the search bar to find specific sessions. Click on a session to view details.\n\n'
                        'If you encounter any issues, please contact support at info@icta.lk.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      // Body
      body: Container(
        color: Colors.indigo.shade50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session List & Search (left)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 12,
                  top: 8,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 8,
                      ),
                      child: ReusableSearchBar(
                        hintText: 'Search sessions',
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<dynamic>>(
                        future: _sessionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load sessions.\n${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text(
                                'No sessions available.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }

                          final sessions = _filterSessions(snapshot.data!);
                          if (sessions.isEmpty) {
                            return const Center(
                              child: Text(
                                'No sessions match your search.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 8,
                            ),
                            itemCount: sessions.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final workshop = session['workshop'] ?? {};
                              final dateTime =
                                  session['date_time'] != null
                                      ? DateTime.tryParse(session['date_time'])
                                      : null;
                              final formattedDate =
                                  dateTime != null
                                      ? "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}"
                                      : '';
                              final formattedTime =
                                  dateTime != null
                                      ? "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}"
                                      : '';

                              return Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.indigo.shade100,
                                    child: Icon(
                                      Icons.event,
                                      color: Colors.indigo,
                                      size: 32,
                                    ),
                                  ),
                                  title: Text(
                                    workshop['title'] ?? 'Workshop',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (session['location'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                session['location'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedTime,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (session['target_audience'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.group,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                session['target_audience'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.indigo.shade700,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => SessionDetailScreen(
                                              sessionId: session['id'],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Calendar (right)
            Container(
              width: 340,
              margin: const EdgeInsets.only(top: 16, right: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Sessions Calendar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    eventLoader: (day) {
                      return sessionDates
                          .where(
                            (d) =>
                                d.year == day.year &&
                                d.month == day.month &&
                                d.day == day.day,
                          )
                          .toList();
                    },
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      final normalized = DateTime(
                        selectedDay.year,
                        selectedDay.month,
                        selectedDay.day,
                      );
                      final sessionId = sessionDateToId[normalized];
                      if (sessionId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SessionDetailScreen(sessionId: sessionId),
                          ),
                        );
                      }
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.indigo,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Footer
      bottomNavigationBar: const AppFooter(),
    );
  }
}
