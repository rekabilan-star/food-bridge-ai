import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../data/models/donation_model.dart';

class PdfGenerator {
  static Future<File> generateDonationReport(DonationModel donation) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Food Rescue Donation Report')),
              pw.SizedBox(height: 20),
              pw.Text('Donation ID: ${donation.id}'),
              pw.Text('Food Name: ${donation.foodName}'),
              pw.Text('Donor: ${donation.donorName}'),
              pw.Text('Status: ${donation.status.toUpperCase()}'),
              pw.Text('Pickup Address: ${donation.pickupAddress}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Status', 'Time', 'Description'],
                data: donation.timeline.map((t) => [
                  t.status,
                  t.time.toString(),
                  t.description
                ]).toList(),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Thank you for contributing to a zero-waste world!', 
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/donation_${donation.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
