import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'edit_workshop_screen.dart';
import 'workshop_details_screen.dart';
import 'create_workshop_screen.dart';
import '../../widgets/search_bar.dart';
import 'create_session_screen.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class WorkshopListScreen extends StatefulWidget {
  @override
  _WorkshopListScreenState createState() => _WorkshopListScreenState();
}

class _WorkshopListScreenState extends State<WorkshopListScreen> {
  late Future<List<dynamic>> _workshopsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  void _loadWorkshops() {
    _workshopsFuture = ApiService.getWorkshops();
  }

  void _deleteWorkshop(int id) async {
    try {
      final success = await ApiService.deleteWorkshop(id);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Workshop deleted.')));
        _refreshList();
      } else {
        _showError('Failed to delete workshop.');
      }
    } catch (_) {
      _showError('An error occurred while deleting.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Workshop'),
            content: const Text(
              'Are you sure you want to delete this workshop?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteWorkshop(id);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _refreshList() {
    setState(() {
      _loadWorkshops();
    });
  }

  List<dynamic> _filter(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final query = _searchQuery.toLowerCase();
    return all
        .where(
          (w) =>
              (w['title'] ?? '').toLowerCase().contains(query) ||
              w['id'].toString().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshops'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            tooltip: 'Add Workshop',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateWorkshopScreen()),
              );
              _refreshList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search workshops',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _workshopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data ?? [];
                final results = _filter(data);
                final indexedWorkshops = indexListElements(
                  results,
                  valueKey: 'workshop',
                );

                if (indexedWorkshops.isEmpty) {
                  return const Center(child: Text('No workshops found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: indexedWorkshops.length,
                  itemBuilder: (context, index) {
                    final w = indexedWorkshops[index]['workshop'];
                    final workshopIndex = indexedWorkshops[index]['index'];
                    final workshop = {
                      'id': w['id'],
                      'title': w['title'] ?? 'Untitled',
                      'description': w['description'] ?? '',
                    };
                    return WorkshopCard(
                      workshop: w,
                      index: workshopIndex,
                      onDelete: () => _confirmDelete(w['id']),
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditWorkshopScreen(
                                  workshopId: workshop['id'],
                                ),
                          ),
                        );
                        _refreshList();
                      },
                      onView:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => WorkshopDetailsScreen(
                                    workshopId: w['id'],
                                  ),
                            ),
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class WorkshopCard extends StatelessWidget {
  final Map<String, dynamic> workshop;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const WorkshopCard({
    required this.workshop,
    required this.index,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = workshop['title'] ?? 'Untitled';
    final id = workshop['id'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            index.toString(),
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: $id'),
        onTap: onView,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Add Session',
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () async {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateSessionScreen(),
                    settings: RouteSettings(
                      arguments: {
                        'workshop_id': workshop['id'],
                        'workshop_title': workshop['title'],
                        'workshop_description': workshop['description'],
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
