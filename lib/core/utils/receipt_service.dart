import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/donation_model.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> generateAndPrintReceipt(DonationModel donation) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('FoodRescue AI - Donation Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ID: ${donation.id.toUpperCase().substring(donation.id.length - 8)}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Text('Donor: ${donation.donorName ?? "N/A"}'),
                pw.Text('NGO Partner: ${donation.assignedNgoName ?? "N/A"}'),
                pw.SizedBox(height: 24),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Food Item', 'Category', 'Serves'],
                    ...donation.items.map((i) => [i.foodName, i.category, i.membersServed.toString()])
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text('Status: ${donation.status.toUpperCase()}'),
                pw.Text('Pickup Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(donation.preparedTime)}'),
                if (donation.deliveryDetails?.completedAt != null)
                  pw.Text('Delivery Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(donation.deliveryDetails!.completedAt!)}'),
                pw.SizedBox(height: 64),
                pw.Divider(),
                pw.Center(child: pw.Text('Thank you for contributing to a hunger-free world!')),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
