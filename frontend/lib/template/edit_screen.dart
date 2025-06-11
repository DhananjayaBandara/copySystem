import 'package:flutter/material.dart';
import '../../widgets/dialog_box.dart';
import '../widgets/app_footer.dart';

typedef FetchEntityFunction = Future<Map<String, dynamic>> Function(int id);
typedef UpdateEntityFunction =
    Future<bool> Function(int id, Map<String, String> data);

class EditableFieldConfig {
  final String key;
  final String label;
  final IconData icon;
  final bool isRequired;
  final TextInputType? keyboardType;

  EditableFieldConfig({
    required this.key,
    required this.label,
    required this.icon,
    this.isRequired = false,
    this.keyboardType,
  });
}

class EditDetailsScreen extends StatefulWidget {
  final int entityId;
  final String screenTitle;
  final String buttonText;
  final String formTitle;
  final FetchEntityFunction fetchEntity;
  final UpdateEntityFunction updateEntity;
  final List<EditableFieldConfig> fields;
  final Widget? child; // <-- Add this line to accept a custom child widget

  const EditDetailsScreen({
    super.key,
    required this.entityId,
    required this.screenTitle,
    this.buttonText = 'Save Changes',
    required this.formTitle,
    required this.fetchEntity,
    required this.updateEntity,
    required this.fields,
    this.child, // <-- Add this line
  });

  @override
  _EditDetailsScreenState createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, String> entityData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    entityData = {for (var f in widget.fields) f.key: ''};
    loadEntityDetails();
  }

  void loadEntityDetails() async {
    try {
      final data = await widget.fetchEntity(widget.entityId);
      setState(() {
        for (var field in widget.fields) {
          entityData[field.key] = (data[field.key] ?? '').toString();
        }
        isLoading = false;
      });
    } catch (error) {
      await CustomDialog.showError(
        context,
        title: 'Failed to Load',
        errors: {
          'Error': ['Could not load details.'],
        },
      );
      Navigator.of(context).pop();
    }
  }

  void updateEntity() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final success = await widget.updateEntity(widget.entityId, entityData);

        if (success) {
          await CustomDialog.showSuccess(
            context,
            title: '${widget.screenTitle} Updated',
            message: 'Details have been successfully updated.',
            onOkPressed: () => Navigator.of(context).pop(),
          );
        } else {
          // Show snackbar instead of dialog for update failure
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Something went wrong. Try again.')),
            );
          }
        }
      } catch (error) {
        await CustomDialog.showError(
          context,
          title: 'Error',
          errors:
              error is Map<String, dynamic>
                  ? error
                  : {
                    'Error': ['An unexpected error occurred.'],
                  },
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle),
        backgroundColor: Colors.indigo,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            widget.formTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...widget.fields.map((field) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                initialValue: entityData[field.key],
                                decoration: _inputDecoration(
                                  field.label,
                                  field.icon,
                                ),
                                keyboardType: field.keyboardType,
                                onSaved:
                                    (value) =>
                                        entityData[field.key] =
                                            value?.trim() ?? '',
                                validator: (value) {
                                  if (field.isRequired &&
                                      (value == null || value.isEmpty)) {
                                    return '${field.label} is required';
                                  }
                                  return null;
                                },
                              ),
                            );
                          }).toList(),
                          // --- Insert custom child widget if provided ---
                          if (widget.child != null) ...[
                            const SizedBox(height: 16),
                            widget.child!,
                          ],
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: updateEntity,
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text(
                                widget.buttonText,
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.indigo.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
