import 'package:flutter/material.dart';
import 'package:frontend/screens/participant/nic_input_screen.dart';
import '../../services/api_service.dart';
import '../../models/session.dart';
import '../../widgets/app_footer.dart';
import 'package:intl/intl.dart';

class SessionDetailScreen extends StatefulWidget {
  final int sessionId;

  SessionDetailScreen({required this.sessionId});

  @override
  _SessionDetailScreenState createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? sessionData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSessionDetails();
  }

  void loadSessionDetails() async {
    final data = await ApiService.getSessionById(widget.sessionId);
    setState(() {
      sessionData = Session.fromJson(data);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200.0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        sessionData!.workshop.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo, Colors.blueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          buildInfoCard(
                            Icons.description,
                            "Description",
                            sessionData!.workshop.description,
                          ),
                          buildInfoCard(
                            Icons.confirmation_number,
                            "Session ID",
                            '${sessionData!.id}',
                          ),
                          buildInfoCard(
                            Icons.place,
                            "Location",
                            sessionData!.location,
                          ),
                          buildInfoCard(
                            Icons.calendar_today,
                            "Date",
                            sessionData!.dateTime.split("T")[0],
                          ),
                          buildInfoCard(
                            Icons.access_time,
                            "Time",
                            DateFormat.jm().format(
                              DateTime.parse(sessionData!.dateTime),
                            ),
                          ),
                          if (sessionData!.trainers.isNotEmpty)
                            buildInfoCard(
                              Icons.person,
                              "Trainers",
                              sessionData!.trainers
                                  .map((t) => t.name)
                                  .join('\n'),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.app_registration),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 5,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => NicInputScreen(
                                        sessionId: widget.sessionId,
                                      ),
                                ),
                              );
                            },
                            label: Text(
                              'Register for Session',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: AppFooter(),
    );
  }

  Widget buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(color: Colors.black87)),
      ),
    );
  }
}
