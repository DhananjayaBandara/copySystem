import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class QrCodePreviewScreen extends StatelessWidget {
  final String sessionToken;
  final int sessionId;

  const QrCodePreviewScreen({
    Key? key,
    required this.sessionToken,
    required this.sessionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String attendanceUrl =
        "http://127.0.0.1:8000/api/sessions/$sessionToken/attendance/";

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () => _downloadQRCodeAsPDF(attendanceUrl),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: attendanceUrl,
                version: QrVersions.auto,
                size: 250.0,
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan the QR Code to mark attendance',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              SelectableText(
                attendanceUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadQRCodeAsPDF(String data) async {
    final pdf = pw.Document();

    final image = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    ).toImageData(200);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Scan to Mark Attendance'),
                pw.SizedBox(height: 10),
                pw.Image(pw.MemoryImage(image!.buffer.asUint8List())),
                pw.SizedBox(height: 10),
                pw.Text(data, style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
