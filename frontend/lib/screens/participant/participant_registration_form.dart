import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/shared_preferences.dart';
import '../../models/participant.dart';
import '../../widgets/dialog_box.dart';
import '../../widgets/app_footer.dart';

class ParticipantRegistrationForm extends StatefulWidget {
  final int sessionId;
  final String? prefilledNic;

  const ParticipantRegistrationForm({
    Key? key,
    required this.sessionId,
    this.prefilledNic,
  }) : super(key: key);

  @override
  State<ParticipantRegistrationForm> createState() =>
      _ParticipantRegistrationFormState();
}

class _ParticipantRegistrationFormState
    extends State<ParticipantRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  Participant participant = Participant(
    id: 0,
    name: '',
    email: '',
    contactNumber: '',
    nic: '',
    dob: '',
    district: '',
    gender: 'Male',
    properties: {},
  );

  int? selectedTypeId;
  List<dynamic> participantTypes = [];
  List<String> requiredFields = [];

  final List<String> districts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  @override
  void initState() {
    super.initState();
    loadParticipantTypes();
    loadSavedParticipantData();
    if (widget.prefilledNic != null) {
      participant.nic = widget.prefilledNic!;
    }
  }

  Future<void> loadParticipantTypes() async {
    final types = await ApiService.getParticipantTypes();
    setState(() {
      participantTypes = types;
    });
  }

  Future<void> loadRequiredFields(int typeId) async {
    final details = await ApiService.getRequiredFieldsForType(typeId);
    setState(() {
      requiredFields = List<String>.from(details['required_fields']);
      participant.properties.clear();
    });
  }

  Future<void> loadSavedParticipantData() async {
    final data = await PreferenceHelper.loadParticipantInfo();
    setState(() {
      participant = Participant(
        id: 0,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        nic: widget.prefilledNic ?? data['nic'] ?? '',
        dob: data['dob'] ?? '',
        district: data['district'] ?? '',
        gender: data['gender'] ?? 'Male',
        properties: {},
      );
    });
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate() && selectedTypeId != null) {
      final payload = participant.toJson();
      payload['participant_type_id'] = selectedTypeId;

      try {
        final participantId = await ApiService.registerParticipant(payload);

        if (participantId != null) {
          await PreferenceHelper.saveParticipantInfo(
            name: participant.name,
            email: participant.email,
            contactNumber: participant.contactNumber,
            nic: participant.nic,
            dob: participant.dob,
            district: participant.district,
            gender: participant.gender,
          );

          final success = await ApiService.registerForSessionWithParticipant(
            widget.sessionId,
            participantId,
          );

          if (success) {
            await CustomDialog.showSuccess(
              context,
              title: 'Registration Successful',
              message: 'You have been successfully registered for the session.',
              onOkPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back
              },
            );
          } else {
            await CustomDialog.showError(
              context,
              title: 'Session Registration Failed',
              errors: {
                'error': [
                  'Participant registered but failed to register for session.',
                ],
              },
            );
          }
        }
      } catch (error) {
        if (error is Map<String, dynamic>) {
          await CustomDialog.showError(
            context,
            title: 'Registration Failed',
            errors: error,
          );
        } else {
          await CustomDialog.showError(
            context,
            title: 'Unexpected Error',
            errors: {
              'error': ['An unexpected error occurred. Please try again.'],
            },
          );
        }
      }
    }
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        title: Text(
          'Register for Session',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Participant Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: participant.name,
                      decoration: customInputDecoration('Name with Initials'),
                      onChanged: (val) => participant.name = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      initialValue: participant.email,
                      decoration: customInputDecoration('Email'),
                      onChanged: (val) => participant.email = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      initialValue: participant.contactNumber,
                      decoration: customInputDecoration('Contact Number'),
                      onChanged: (val) => participant.contactNumber = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      initialValue: participant.nic,
                      decoration: customInputDecoration('NIC'),
                      onChanged: (val) => participant.nic = val,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                      readOnly: widget.prefilledNic != null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: TextEditingController(text: participant.dob),
                      readOnly: true,
                      decoration: customInputDecoration(
                        'Date of Birth (YYYY-MM-DD)',
                      ).copyWith(suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            participant.dob =
                                picked.toIso8601String().split('T')[0];
                          });
                        }
                      },
                      validator:
                          (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          participant.district.isNotEmpty
                              ? participant.district
                              : null,
                      decoration: customInputDecoration('District'),
                      items:
                          districts
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => participant.district = val!),
                      validator:
                          (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: participant.gender,
                      decoration: customInputDecoration('Gender'),
                      items:
                          ['Male', 'Female', 'Other']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      onChanged:
                          (val) => setState(() => participant.gender = val!),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedTypeId,
                      decoration: customInputDecoration('Participant Type'),
                      items:
                          participantTypes
                              .map(
                                (type) => DropdownMenuItem<int>(
                                  value: type['id'],
                                  child: Text(type['name']),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() => selectedTypeId = val);
                        if (val != null) loadRequiredFields(val);
                      },
                    ),
                    ...requiredFields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: TextFormField(
                          decoration: customInputDecoration(
                            field.replaceAll("_", " ").toUpperCase(),
                          ),
                          onChanged:
                              (val) => participant.properties[field] = val,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: submitForm,
                        icon: Icon(Icons.check_circle_outline),
                        label: Text(
                          'Submit Registration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
      bottomNavigationBar: AppFooter(),
    );
  }
}
