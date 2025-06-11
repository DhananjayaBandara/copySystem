import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/widgets/app_footer.dart';

class PublicationScreen extends StatefulWidget {
  const PublicationScreen({super.key});

  @override
  State<PublicationScreen> createState() => _PublicationScreenState();
}

class _PublicationScreenState extends State<PublicationScreen> {
  late Future<List<dynamic>> sessions;
  Map<int, bool> sessionSelection = {};
  Map<int, List<String>> sessionEmails = {};
  Map<int, bool> showEmails = {};
  Set<String> selectedEmails = {};
  bool allEmailsSelected = false;

  @override
  void initState() {
    super.initState();
    sessions = ApiService.getSessions();
  }

  Future<void> toggleSession(int sessionId, bool? value) async {
    if (!sessionEmails.containsKey(sessionId)) {
      final fetchedEmails = await ApiService.getEmailsBySession(sessionId);
      setState(() {
        sessionEmails[sessionId] = List<String>.from(fetchedEmails);
      });
    }

    final emails = sessionEmails[sessionId] ?? [];

    setState(() {
      sessionSelection[sessionId] = value ?? false;
      if (value == true) {
        selectedEmails.addAll(emails);
      } else {
        selectedEmails.removeAll(emails);
      }
    });
  }

  void toggleEmail(String email, bool? selected) {
    setState(() {
      if (selected == true) {
        selectedEmails.add(email);
      } else {
        selectedEmails.remove(email);
      }
    });
  }

  Future<void> fetchEmailsForSession(int sessionId) async {
    if (!sessionEmails.containsKey(sessionId)) {
      final emails = await ApiService.getEmailsBySession(sessionId);
      setState(() {
        sessionEmails[sessionId] = List<String>.from(emails);
      });
    }
    setState(() {
      showEmails[sessionId] = !(showEmails[sessionId] ?? false);
    });
  }

  Future<void> toggleAllParticipantEmails() async {
    if (allEmailsSelected) {
      setState(() {
        selectedEmails.clear();
        allEmailsSelected = false;
      });
    } else {
      try {
        final allEmails = await ApiService.getAllParticipantEmails();
        setState(() {
          selectedEmails.addAll(allEmails);
          allEmailsSelected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${allEmails.length} emails selected.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching emails: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      body: FutureBuilder<List<dynamic>>(
        future: sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sessions found.'));
          }

          final sessionList = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          selectedEmails.isEmpty
                              ? null
                              : () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: selectedEmails.join(','),
                                  query: Uri.encodeFull(
                                    'subject=Workshop Publication&body=Dear Participant,\n\nPlease find the publication details attached.\n\nBest regards,',
                                  ),
                                );

                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open email client.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      icon: const Icon(Icons.send),
                      label: const Text("Send Publication"),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.select_all),
                    label: const Text("Select All Participants"),
                    onPressed: () => toggleAllParticipantEmails(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: sessionList.length,
                  itemBuilder: (context, index) {
                    final session = sessionList[index];
                    final sessionId = session['id'];
                    final emails = sessionEmails[sessionId] ?? [];
                    final isSessionSelected =
                        sessionSelection[sessionId] ?? false;
                    final isShowingEmails = showEmails[sessionId] ?? false;

                    return Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Checkbox(
                              value: isSessionSelected,
                              onChanged: (value) {
                                toggleSession(sessionId, value);
                              },
                            ),
                            title: Text('Session ID: $sessionId'),
                            subtitle: Text(
                              'Date: ${session['date_time']} | Location: ${session['location']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.email_outlined),
                              onPressed: () {
                                fetchEmailsForSession(sessionId);
                              },
                            ),
                          ),
                          if (isShowingEmails)
                            Column(
                              children:
                                  emails
                                      .map(
                                        (email) => CheckboxListTile(
                                          value: selectedEmails.contains(email),
                                          onChanged: (value) {
                                            toggleEmail(email, value);
                                          },
                                          title: Text(email),
                                        ),
                                      )
                                      .toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
