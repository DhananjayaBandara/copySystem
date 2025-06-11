import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../template/edit_screen.dart';

class EditWorkshopScreen extends StatelessWidget {
  final int workshopId;

  const EditWorkshopScreen({required this.workshopId});

  @override
  Widget build(BuildContext context) {
    return EditDetailsScreen(
      entityId: workshopId,
      screenTitle: 'Edit Workshop',
      formTitle: 'Update Workshop Details',
      fetchEntity: ApiService.getWorkshopDetails,
      updateEntity: ApiService.updateWorkshop,
      fields: [
        EditableFieldConfig(
          key: 'title',
          label: 'Title',
          icon: Icons.title,
          isRequired: true,
        ),
        EditableFieldConfig(
          key: 'description',
          label: 'Description',
          icon: Icons.description,
          isRequired: false,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}
