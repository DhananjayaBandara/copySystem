import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../trainer/trainer_dashboard_screen.dart';

class TrainerLoginScreen extends StatefulWidget {
  const TrainerLoginScreen({super.key});

  @override
  State<TrainerLoginScreen> createState() => _TrainerLoginScreenState();
}

class _TrainerLoginScreenState extends State<TrainerLoginScreen> {
  @override
  void initState() {
    super.initState();
    // Show dialog after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForTrainerId();
    });
  }

  Future<void> _promptForTrainerId() async {
    int? trainerId = await showDialog<int>(
      context: context,
      builder: (context) {
        final _controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Trainer ID'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Trainer ID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final id = int.tryParse(_controller.text);
                if (id != null) {
                  Navigator.of(context).pop(id);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (trainerId != null) {
      try {
        await ApiService.getTrainerDetails(trainerId);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerDashboardScreen(trainerId: trainerId),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trainer with ID $trainerId not found.')),
        );
        _promptForTrainerId();
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
