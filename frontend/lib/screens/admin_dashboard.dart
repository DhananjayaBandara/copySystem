import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/api_service.dart';
import 'participant/workshop_session_list.dart';
import 'admin/session_details_screen.dart';
import 'admin/create_workshop_screen.dart';
import 'admin/create_session_screen.dart';
import 'admin/participant_type_list_screen.dart';
import 'admin/participant_list_screen.dart';
import 'admin/workshop_list_screen.dart';
import 'admin/session_list_screen.dart';
import 'admin/trainer_list_screen.dart';
import 'admin/data_analysis_dashboard_screen.dart';
import 'admin/publications_screen.dart';
import 'trainer/trainer_login.dart';
import 'homepage.dart';
import '../utils/constants.dart';
import '../widgets/app_footer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isSidebarOpen = true; // Controls sidebar visibility
  Map<String, int> counts = {
    "workshops": 0,
    "sessions": 0,
    "participants": 0,
    "participant_types": 0,
    "trainers": 0,
  };
  List<DateTime> sessionDates = [];
  Map<DateTime, int> sessionDateToId = {};

  @override
  void initState() {
    super.initState();
    // Fetch data asynchronously
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await ApiService.getAdminDashboardCounts();
      final sessions = await ApiService.getSessions();
      setState(() {
        counts = data;
        sessionDates =
            sessions
                .map<DateTime>((s) => DateTime.parse(s['date_time']))
                .toList();
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
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Admin Dashboard'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading:
            isMobile
                ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
                : IconButton(
                  icon: Icon(
                    _isSidebarOpen ? Icons.chevron_left : Icons.chevron_right,
                  ),
                  onPressed:
                      () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) {
              if (value == 'logout') {
                // Handle logout logic
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              } else if (value == 'trainer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrainerLoginScreen(),
                  ),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'trainer',
                    child: Text('Switch to Trainer Role'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context) : null,
      body: Row(
        children: [
          // Sidebar with Calendar
          if (!isMobile && _isSidebarOpen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 300,
              color: Colors.grey[100],
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Session Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: _buildCalendar(context)),
                ],
              ),
            ),
          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount:
                          isMobile
                              ? 1
                              : isTablet
                              ? 2
                              : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildSummaryCard(
                          context,
                          title: 'Workshops',
                          count: counts['workshops'] ?? 0,
                          icon: Icons.work,
                          color: primaryColor,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkshopListScreen(),
                                ),
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Sessions',
                          count: counts['sessions'] ?? 0,
                          icon: Icons.event,
                          color: positiveColor,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SessionListScreen(),
                                ),
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Participants',
                          count: counts['participants'] ?? 0,
                          icon: Icons.people,
                          color: Colors.amber,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ParticipantListScreen(),
                                ),
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Trainers',
                          count: counts['trainers'] ?? 0,
                          icon: Icons.person_add,
                          color: Colors.blue,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrainerListScreen(),
                                ),
                              ),
                        ),
                        _buildSummaryCard(
                          context,
                          title: 'Participant Types',
                          count: counts['participant_types'] ?? 0,
                          icon: Icons.category,
                          color: Colors.purple,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ParticipantTypeListScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isMobile ? 1 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                      children: [
                        _buildActionCard(
                          context,
                          title: 'Data Analysis Dashboard',
                          icon: Icons.analytics,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const DataAnalysisDashboardScreen(),
                                ),
                              ),
                        ),
                        _buildActionCard(
                          context,
                          title: 'Send Emails to Participants',
                          icon: Icons.email,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const PublicationScreen(),
                                ),
                              ),
                        ),
                        _buildActionCard(
                          context,
                          title: 'Create Workshop',
                          icon: Icons.add_box,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const CreateWorkshopScreen(),
                                ),
                              ),
                        ),
                        _buildActionCard(
                          context,
                          title: 'Create Session',
                          icon: Icons.event,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateSessionScreen(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, positiveColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Text(
              'Admin Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.work,
            title: 'Workshops',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WorkshopListScreen()),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event,
            title: 'Sessions',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SessionListScreen()),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Participants',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParticipantListScreen(),
                  ),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category,
            title: 'Participant Types',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParticipantTypeListScreen(),
                  ),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_add,
            title: 'Trainers',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainerListScreen()),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Data Analysis',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataAnalysisDashboardScreen(),
                  ),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.email,
            title: 'Send Emails',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PublicationScreen(),
                  ),
                ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: 'Workshop Sessions',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkshopSessionListScreen(),
                  ),
                ),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.exit_to_app,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.grey[100],
      hoverColor: primaryColor.withOpacity(0.1),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      eventLoader:
          (day) =>
              sessionDates
                  .where(
                    (d) =>
                        d.year == day.year &&
                        d.month == day.month &&
                        d.day == day.day,
                  )
                  .toList(),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.amber[200],
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.blue,
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
              builder: (context) => SessionDetailsScreen(sessionId: sessionId),
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
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 24, color: primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
