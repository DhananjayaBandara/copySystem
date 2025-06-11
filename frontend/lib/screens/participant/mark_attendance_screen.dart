import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String sessionToken;

  MarkAttendanceScreen({required this.sessionToken});

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  String nic = '';
  Map<String, dynamic>? participantDetails;
  bool isLoading = false;

  void fetchParticipantDetails() async {
    FocusScope.of(context).unfocus(); // hide keyboard
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getParticipantByNIC(nic);
      setState(() {
        isLoading = false;
        participantDetails = response;
      });

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ No participant found for this NIC.')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to fetch participant details.')),
      );
    }
  }

  void markAttendance() async {
    setState(() => isLoading = true);

    try {
      final success = await ApiService.markAttendance(widget.sessionToken, nic);
      setState(() => isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Attendance marked successfully!')),
        );
        setState(() {
          nic = '';
          participantDetails = null;
        });
        _formKey.currentState?.reset();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Failed to mark attendance.')));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❗ An error occurred: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Mark Attendance",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 90.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_ind,
                          size: 50,
                          color: Colors.indigo,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Enter your NIC to check in',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.badge),
                            labelText: 'NIC Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onChanged: (value) => nic = value,
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'NIC is required' : null,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: fetchParticipantDetails,
                          icon: Icon(Icons.search, color: Colors.white),
                          label: Text(
                            'Fetch Details',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              if (isLoading) CircularProgressIndicator(),
              if (participantDetails != null)
                AnimatedOpacity(
                  opacity: participantDetails != null ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Participant Details',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(thickness: 1.2),
                          ListTile(
                            leading: Icon(Icons.person, color: Colors.indigo),
                            title: Text(participantDetails!['name'] ?? ''),
                            subtitle: Text(participantDetails!['email'] ?? ''),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton.icon(
                            onPressed: markAttendance,
                            icon: Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Mark Attendance',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
