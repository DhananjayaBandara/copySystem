import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../template/edit_screen.dart';

class EditTrainerScreen extends StatelessWidget {
  final int trainerId;

  const EditTrainerScreen({required this.trainerId});

  @override
  Widget build(BuildContext context) {
    return EditDetailsScreen(
      entityId: trainerId,
      screenTitle: 'Edit Trainer',
      formTitle: 'Update Trainer Details',
      fetchEntity: ApiService.getTrainerDetails,
      updateEntity: ApiService.updateTrainer,
      fields: [
        EditableFieldConfig(
          key: 'name',
          label: 'Name',
          icon: Icons.person,
          isRequired: true,
        ),
        EditableFieldConfig(
          key: 'designation',
          label: 'Designation',
          icon: Icons.badge_outlined,
        ),
        EditableFieldConfig(
          key: 'email',
          label: 'Email',
          icon: Icons.email_outlined,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
        ),
        EditableFieldConfig(
          key: 'contact_number',
          label: 'Contact Number',
          icon: Icons.phone_android,
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),
        EditableFieldConfig(
          key: 'expertise',
          label: 'Expertise',
          icon: Icons.lightbulb_outline,
        ),
      ],
    );
  }
}
