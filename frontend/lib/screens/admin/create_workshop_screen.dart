import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/dialog_box.dart';
import '../../template/create_screen.dart';
import 'create_session_screen.dart';

class CreateWorkshopScreen extends StatelessWidget {
  const CreateWorkshopScreen({Key? key}) : super(key: key);

  Future<void> handleWorkshopSubmit(
    BuildContext context,
    Map<String, dynamic> formData,
  ) async {
    final success = await ApiService.createWorkshop(formData);

    if (success) {
      final workshops = await ApiService.getWorkshops();
      final newWorkshop = workshops.last;

      await CustomDialog.showSuccess(
        context,
        title: 'Workshop Created',
        message: 'The workshop has been successfully created.',
        onOkPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSessionScreen(),
              settings: RouteSettings(
                arguments: {
                  'workshop_id': newWorkshop['id'],
                  'workshop_title': newWorkshop['title'],
                  'workshop_description': newWorkshop['description'],
                },
              ),
            ),
          );
        },
      );
    } else {
      throw {
        'Submission Error': [
          'Failed to create the workshop. Please try again.',
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormScreen(
      title: 'Create Workshop',
      icon: Icons.library_books,
      initialData: {'title': '', 'description': ''},
      submitButtonText: 'Create Workshop',
      onSubmit: (formData) => handleWorkshopSubmit(context, formData),
      fields: [
        FormFieldConfig(
          label: 'Title',
          icon: Icons.title,
          keyName: 'title',
          isRequired: true,
        ),
        FormFieldConfig(
          label: 'Description',
          icon: Icons.description,
          keyName: 'description',
          isRequired: true,
        ),
      ],
    );
  }
}
