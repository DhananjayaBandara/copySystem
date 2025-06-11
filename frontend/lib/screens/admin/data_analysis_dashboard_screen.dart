import 'package:flutter/material.dart';
import 'sessions_analytics_tab.dart';
import 'workshops_analytics_tab.dart';
import 'trainers_analytics_tab.dart';
import 'participants_analytics_tab.dart';
import '../../utils/constants.dart';
import '../../widgets/app_footer.dart';

const _tabData = [
  {'title': 'Sessions', 'icon': Icons.event},
  {'title': 'Workshops', 'icon': Icons.work},
  {'title': 'Trainers', 'icon': Icons.person},
  {'title': 'Participants', 'icon': Icons.group},
];

class DataAnalysisDashboardScreen extends StatefulWidget {
  const DataAnalysisDashboardScreen({Key? key}) : super(key: key);

  @override
  _DataAnalysisDashboardScreenState createState() =>
      _DataAnalysisDashboardScreenState();
}

class _DataAnalysisDashboardScreenState
    extends State<DataAnalysisDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabData.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: accentColor.withOpacity(0.3),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs:
              _tabData
                  .map(
                    (tab) => Tab(
                      icon: Icon(tab['icon'] as IconData),
                      text: tab['title'] as String,
                    ),
                  )
                  .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement export or filter action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export functionality coming soon!')),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.download),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            SessionsAnalyticsTab(),
            WorkshopsAnalyticsTab(),
            TrainersAnalyticsTab(),
            ParticipantsAnalyticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
