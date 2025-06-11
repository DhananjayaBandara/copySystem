import 'package:flutter/material.dart';

class CustomDialog {
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOkPressed,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('✅ $title'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (onOkPressed != null) {
                    onOkPressed(); // Optional callback
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> errors,
  }) async {
    String formatErrors(Map<String, dynamic> errors) {
      List<String> bulletPoints = [];
      errors.forEach((field, messages) {
        if (messages is List) {
          for (var message in messages) {
            bulletPoints.add('• $message');
          }
        } else {
          bulletPoints.add('• $messages');
        }
      });
      return bulletPoints.join('\n');
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('❌ $title'),
            content: Text(formatErrors(errors)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
