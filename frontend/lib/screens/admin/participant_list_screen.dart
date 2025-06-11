import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/search_bar.dart';
import 'participant_details_screen.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class ParticipantListScreen extends StatefulWidget {
  @override
  _ParticipantListScreenState createState() => _ParticipantListScreenState();
}

class _ParticipantListScreenState extends State<ParticipantListScreen> {
  late Future<List<dynamic>> participants;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    participants = ApiService.getParticipants();
  }

  void _refreshParticipants() {
    setState(() {
      participants = ApiService.getParticipants();
    });
  }

  Future<void> _confirmDelete(int participantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Participant'),
            content: Text('Are you sure you want to delete this participant?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteParticipant(participantId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Participant deleted successfully!')),
        );
        _refreshParticipants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete participant!')),
        );
      }
    }
  }

  void _navigateToDetails(Map<String, dynamic> participant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ParticipantDetailsScreen(participant: participant),
      ),
    );
  }

  List<dynamic> _filterParticipants(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all.where((p) {
      return (p['name'] ?? '').toLowerCase().contains(query) ||
          (p['email'] ?? '').toLowerCase().contains(query) ||
          (p['nic'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search participants',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: participants,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No participants available.'));
                } else {
                  final filtered = _filterParticipants(snapshot.data!);
                  final indexedParticipants = indexListElements(
                    filtered,
                    valueKey: 'participant',
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: indexedParticipants.length,
                    itemBuilder: (context, index) {
                      final participant =
                          indexedParticipants[index]['participant'];
                      final participantIndex =
                          indexedParticipants[index]['index'];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Text(
                              participantIndex.toString(),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            participant['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Email: ${participant['email'] ?? 'N/A'}\nNIC: ${participant['nic'] ?? 'N/A'}',
                          ),
                          isThreeLine: true,
                          onTap: () => _navigateToDetails(participant),
                          trailing: SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Participant',
                                  onPressed:
                                      () => _confirmDelete(participant['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
