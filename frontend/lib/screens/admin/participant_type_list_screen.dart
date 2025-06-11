import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/search_bar.dart';
import '../../template/create_screen.dart';
import '../../utils/list_utils.dart';
import '../../widgets/app_footer.dart';

class ParticipantTypeListScreen extends StatefulWidget {
  @override
  _ParticipantTypeListScreenState createState() =>
      _ParticipantTypeListScreenState();
}

class _ParticipantTypeListScreenState extends State<ParticipantTypeListScreen> {
  late Future<List<dynamic>> participantTypes;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    participantTypes = ApiService.getParticipantTypes();
  }

  void _refreshTypes() {
    setState(() {
      participantTypes = ApiService.getParticipantTypes();
    });
  }

  Future<void> _confirmDelete(int typeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete this participant type?',
            ),
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
      final success = await ApiService.deleteParticipantType(typeId);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted successfully')));
        _refreshTypes();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete')));
      }
    }
  }

  void _navigateToEdit(Map<String, dynamic> participantType) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EditParticipantTypeScreen(participantType: participantType),
      ),
    );
    if (updated != null) _refreshTypes();
  }

  void _navigateToAdd() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditParticipantTypeScreen(participantType: null),
      ),
    );
    if (added != null) _refreshTypes();
  }

  List<dynamic> _filterTypes(List<dynamic> types) {
    if (_searchQuery.isEmpty) return types;
    final query = _searchQuery.toLowerCase();
    return types
        .where(
          (t) =>
              (t['name'] ?? '').toLowerCase().contains(query) ||
              (t['description'] ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participant Types'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToAdd,
            tooltip: 'Add Participant Type',
          ),
        ],
      ),
      body: Column(
        children: [
          ReusableSearchBar(
            hintText: 'Search participant types',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: participantTypes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No participant types available.'));
                }

                final filtered = _filterTypes(snapshot.data!);
                final indexedTypes = indexListElements(
                  filtered,
                  valueKey: 'type',
                );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: indexedTypes.length,
                  itemBuilder: (context, index) {
                    final type = indexedTypes[index]['type'];
                    final typeIndex = indexedTypes[index]['index'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ParticipantTypeDetailsScreen(
                                    participantType: type,
                                  ),
                            ),
                          );
                        },
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
                                  typeIndex.toString(),
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
                                      type['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((type['description'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          type['description'],
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    if (type['participant_count'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 6.0,
                                        ),
                                        child: Text(
                                          'Participants: ${type['participant_count']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _navigateToEdit(type),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _confirmDelete(type['id']),
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

class EditParticipantTypeScreen extends StatelessWidget {
  final Map<String, dynamic>? participantType;

  const EditParticipantTypeScreen({super.key, this.participantType});

  @override
  Widget build(BuildContext context) {
    final bool isEdit = participantType != null;

    return CustomFormScreen(
      title: isEdit ? 'Edit Participant Type' : 'Add Participant Type',
      icon: Icons.groups_3,
      initialData: {
        'name': participantType?['name'] ?? '',
        'description': participantType?['description'] ?? '',
        'properties': participantType?['properties'] ?? <String>[],
      },
      submitButtonText: isEdit ? 'Update' : 'Create',
      fields: [
        FormFieldConfig(
          label: 'Name',
          icon: Icons.title,
          keyName: 'name',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Description',
          icon: Icons.description,
          keyName: 'description',
        ),
        FormFieldConfig(
          label: 'Properties',
          icon: Icons.list,
          keyName: 'properties',
          fieldType: FieldType.custom,
          customBuilder: (context, formData, onChanged) {
            List<String> properties = List<String>.from(
              formData['properties'] ?? [],
            );

            void addProperty() {
              properties.add('');
              onChanged(List.from(properties));
            }

            void removeProperty(int index) {
              properties.removeAt(index);
              onChanged(List.from(properties));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Properties',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...properties.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value,
                          decoration: const InputDecoration(
                            labelText: 'Property',
                          ),
                          onChanged: (value) {
                            properties[index] = value;
                            onChanged(List.from(properties));
                          },
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Property cannot be empty'
                                      : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeProperty(index),
                      ),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: addProperty,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Property'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade100,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            );
          },
        ),
      ],
      onSubmit: (formData) async {
        bool success;
        if (isEdit) {
          success = await ApiService.updateParticipantType(
            participantType!['id'],
            formData,
          );
        } else {
          success = await ApiService.createParticipantType(formData);
        }

        if (!success) {
          throw {
            'Error': ['Failed to save participant type.'],
          };
        }
      },
    );
  }
}

class ParticipantTypeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> participantType;

  ParticipantTypeDetailsScreen({required this.participantType});

  @override
  Widget build(BuildContext context) {
    final properties = participantType['properties'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(participantType['name'] ?? 'Participant Type Details'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant Type Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participantType['name'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        participantType['description'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Number of Participants: ${participantType['participant_count'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Properties Section
              Text(
                'Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              SizedBox(height: 10),
              properties.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No properties available.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                  : Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: properties.length,
                        separatorBuilder: (context, index) => Divider(),
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          if (property is String) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Colors.blue.shade900,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    property,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Text(
                              'Invalid property format',
                              style: TextStyle(color: Colors.red),
                            );
                          }
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
