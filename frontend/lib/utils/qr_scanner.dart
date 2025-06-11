import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../screens/participant/mark_attendance_screen.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final url = scanData.code!;
      controller.pauseCamera(); // Pause camera after first scan

      // Extract session token from URL
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 4 && segments[2] == 'sessions') {
        final sessionToken = segments[3];

        // Navigate to MarkAttendanceScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MarkAttendanceScreen(sessionToken: sessionToken),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid QR code')));
        controller.resumeCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Session QR Code')),
      body: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
    );
  }
}
