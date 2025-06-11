import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../trainer/trainer_details_screen.dart';
import '../trainer/create_trainer_screen.dart';
import '../trainer/edit_trainer_screen.dart';
import '../../widgets/search_bar.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class TrainerListScreen extends StatefulWidget {
  @override
  _TrainerListScreenState createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  late Future<List<dynamic>> trainers;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    trainers = ApiService.getTrainers();
  }

  void _refreshTrainers() {
    setState(() {
      trainers = ApiService.getTrainers();
    });
  }

  Future<void> _confirmDeleteTrainer(int trainerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this trainer?'),
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

    if (confirm == true) {
      final success = await ApiService.deleteTrainer(trainerId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trainer deleted successfully!')),
        );
        _refreshTrainers();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete trainer!')));
      }
    }
  }

  List<dynamic> _filterTrainers(List<dynamic> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (t) =>
              (t['name'] ?? '').toLowerCase().contains(q) ||
              (t['email'] ?? '').toLowerCase().contains(q) ||
              (t['designation'] ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  void _navigateToCreateTrainer() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateTrainerScreen()),
    );
    if (created != null) _refreshTrainers();
  }

  void _navigateToEditTrainer(int id) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTrainerScreen(trainerId: id)),
    );
    if (updated != null) _refreshTrainers();
  }

  void _navigateToDetails(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainerDetailsScreen(trainerId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trainers'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Trainer',
            onPressed: _navigateToCreateTrainer,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Trainers',
            onPressed: _refreshTrainers,
          ),
        ],
      ),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search trainers',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: trainers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No trainers available.'));
                }

                final filtered = _filterTrainers(snapshot.data!);
                final indexedTrainers = indexListElements(
                  filtered,
                  valueKey: 'trainer',
                );

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: indexedTrainers.length,
                  itemBuilder: (context, index) {
                    final trainer = indexedTrainers[index]['trainer'];
                    final trainerIndex = indexedTrainers[index]['index'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: InkWell(
                        onTap: () => _navigateToDetails(trainer['id']),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo.shade100,
                                child: Text(
                                  trainerIndex.toString(),
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trainer['name'] ?? 'No name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      trainer['designation'] ??
                                          'No designation',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    if (trainer['email'] != null) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        trainer['email'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed:
                                        () => _navigateToEditTrainer(
                                          trainer['id'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed:
                                        () => _confirmDeleteTrainer(
                                          trainer['id'],
                                        ),
                                  ),
                                ],
                              ),
                            ],
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
