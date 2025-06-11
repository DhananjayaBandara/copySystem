import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import '../../template/create_screen.dart';

class CreateTrainerScreen extends StatelessWidget {
  const CreateTrainerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomFormScreen(
      title: 'Create Trainer',
      icon: Icons.person_add_alt_1,
      submitButtonText: 'Create Trainer',
      initialData: {
        'name': '',
        'designation': '',
        'email': '',
        'contact_number': '',
        'expertise': '',
      },
      fields: [
        FormFieldConfig(
          label: 'Name',
          icon: Icons.person,
          keyName: 'name',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Designation',
          icon: Icons.work,
          keyName: 'designation',
        ),
        FormFieldConfig(
          label: 'Email',
          icon: Icons.email,
          keyName: 'email',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Contact Number',
          icon: Icons.phone,
          keyName: 'contact_number',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Expertise',
          icon: Icons.school,
          keyName: 'expertise',
        ),
      ],
      onSubmit: (formData) async {
        final success = await ApiService.createTrainer(formData);
        if (!success) {
          throw {
            'Error': ['Failed to create trainer.'],
          };
        }
      },
    );
  }
}
