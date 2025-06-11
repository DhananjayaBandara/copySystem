import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'participant_registration_form.dart';
import '../../widgets/app_footer.dart';

class NicInputScreen extends StatefulWidget {
  final void Function(String nic)? onSubmit;
  final int sessionId;

  const NicInputScreen({Key? key, required this.sessionId, this.onSubmit})
    : super(key: key);

  @override
  _NicInputScreenState createState() => _NicInputScreenState();
}

class _NicInputScreenState extends State<NicInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicController = TextEditingController();
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nicController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final nic = _nicController.text.trim();

    try {
      final participants = await ApiService.getParticipants();
      final participant = participants.firstWhere(
        (p) => (p['nic']?.toString().toLowerCase() ?? '') == nic.toLowerCase(),
        orElse: () => null,
      );

      if (participant == null) {
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ParticipantRegistrationForm(
                  sessionId: widget.sessionId,
                  prefilledNic: nic,
                ),
          ),
        );
        return;
      }

      final participantId = participant['id'];
      final sessionInfo = await ApiService.getParticipantSessionsInfo(
        participantId,
      );
      final registeredSessions =
          (sessionInfo['sessions'] as List).map((s) => s['id']).toList();

      if (registeredSessions.contains(widget.sessionId)) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already registered for this session.'),
            backgroundColor: const Color.fromARGB(255, 229, 245, 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final success = await ApiService.registerForSessionWithParticipant(
        widget.sessionId,
        participantId,
      );
      setState(() => _loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered for the session!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register for the session.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NIC Input'),
        backgroundColor: Colors.blue.shade700,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade300, Colors.purple.shade300],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter Your NIC Number',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Please provide your National Identity Card number to register for the workshop session.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nicController,
                              decoration: InputDecoration(
                                labelText: 'NIC Number',
                                hintText: 'E.g., 123456789V or 200012345678',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade700,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.credit_card,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'NIC is required';
                                }
                                final nic = value.trim();
                                final oldNic = RegExp(r'^\d{9}[vV]$');
                                final newNic = RegExp(r'^\d{12}$');
                                if (!oldNic.hasMatch(nic) &&
                                    !newNic.hasMatch(nic)) {
                                  return 'Enter a valid NIC (9 digits + V or 12 digits)';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 24),
                            _loading
                                ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade700,
                                    ),
                                  ),
                                )
                                : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
