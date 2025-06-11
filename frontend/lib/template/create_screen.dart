import 'package:flutter/material.dart';
import 'package:frontend/widgets/dialog_box.dart';
import 'package:frontend/widgets/custom_datetime_picker.dart';
import '../widgets/app_footer.dart';

enum FieldType { text, date, time, dateTime, custom }

class FormFieldConfig {
  final String label;
  final IconData icon;
  final String keyName;
  final bool isRequired;
  final FieldType fieldType;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> formData,
    void Function(dynamic) onChanged,
  )?
  customBuilder;

  FormFieldConfig({
    required this.label,
    required this.icon,
    required this.keyName,
    this.isRequired = false,
    this.fieldType = FieldType.text,
    this.customBuilder,
  });
}

class CustomFormScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> initialData;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final String submitButtonText;

  const CustomFormScreen({
    Key? key,
    required this.title,
    required this.icon,
    required this.initialData,
    required this.fields,
    required this.onSubmit,
    required this.submitButtonText,
  }) : super(key: key);

  @override
  _CustomFormScreenState createState() => _CustomFormScreenState();
}

class _CustomFormScreenState extends State<CustomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> formData;

  @override
  void initState() {
    super.initState();
    formData = Map<String, dynamic>.from(widget.initialData);
  }

  Widget buildInputField(FormFieldConfig config) {
    final value = formData[config.keyName];

    void onChanged(dynamic newValue) {
      setState(() {
        formData[config.keyName] = newValue;
      });
    }

    if (config.fieldType == FieldType.date ||
        config.fieldType == FieldType.time ||
        config.fieldType == FieldType.dateTime) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CustomDateTimePicker(
          label: config.label,
          type:
              config.fieldType == FieldType.date
                  ? DateTimeType.date
                  : config.fieldType == FieldType.time
                  ? DateTimeType.time
                  : DateTimeType.dateTime,
          icon: config.icon,
          dateTimeString: value ?? '',
          isRequired: config.isRequired,
          onChanged: (newValue) {
            onChanged(newValue);
          },
        ),
      );
    }

    if (config.fieldType == FieldType.custom && config.customBuilder != null) {
      return config.customBuilder!(context, formData, onChanged);
    }

    // Default text input
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        decoration: InputDecoration(
          labelText: config.label,
          prefixIcon: Icon(config.icon),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        validator:
            config.isRequired
                ? (value) =>
                    value == null || value.isEmpty
                        ? '${config.label} is required'
                        : null
                : null,
        onSaved: (value) => formData[config.keyName] = value ?? '',
        onChanged: onChanged,
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await widget.onSubmit(formData);
        await CustomDialog.showSuccess(
          context,
          title: '${widget.title} Saved',
          message:
              'The ${widget.title.toLowerCase()} has been successfully saved.',
          onOkPressed: () => Navigator.of(context).pop(),
        );
      } catch (errors) {
        await CustomDialog.showError(
          context,
          title: 'Failed to Save ${widget.title}',
          errors:
              errors is Map<String, dynamic>
                  ? errors
                  : {
                    'Error': ['Unexpected error occurred.'],
                  },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(widget.icon, size: 60, color: Colors.indigo),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '${widget.title} Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...widget.fields.map(buildInputField).toList(),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: handleSubmit,
                      icon: const Icon(Icons.save),
                      label: Text(widget.submitButtonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
