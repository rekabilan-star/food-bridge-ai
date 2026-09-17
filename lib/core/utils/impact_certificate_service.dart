import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/donation_model.dart';
import 'package:intl/intl.dart';

class ImpactCertificateService {
  static Future<void> generateAndDisplay(DonationModel donation) async {
    final pdf = pw.Document();

    // Impact Calculations
    final int meals = donation.deliveryDetails?.membersServed ?? donation.membersServed;
    final double weightKg = meals * 0.5;
    final double co2Saved = weightKg * 2.5;
    final double waterSaved = weightKg * 50;

    // Load static assets for professional look (if available)
    // For now using built-in PDF shapes and fonts
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 5),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Stack(
              children: [
                // Background Watermark (Opacity simulation)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.05,
                    child: pw.Icon(
                      const pw.IconData(0xe801), // Nature/Eco icon simulation
                      size: 400,
                    ),
                  ),
                ),
                
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header
                    pw.Text('CERTIFICATE OF IMPACT',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                          letterSpacing: 2,
                        )),
                    pw.SizedBox(height: 10),
                    pw.Container(height: 2, width: 300, color: PdfColors.indigo900),
                    pw.SizedBox(height: 30),

                    pw.Text('This certificate is proudly presented to',
                        style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    pw.SizedBox(height: 15),
                    
                    pw.Text(donation.donorName ?? 'Valued Donor',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        )),
                    pw.SizedBox(height: 20),

                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 60),
                      child: pw.Text(
                        'In recognition of their generous contribution of surplus food to ${donation.assignedNgoName ?? "the community"}. Your rescue mission has directly impacted lives and supported a zero-waste ecosystem.',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800, lineSpacing: 1.5),
                      ),
                    ),

                    pw.Spacer(),

                    // Impact Stats Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('MEALS SERVED', meals.toString(), PdfColors.green900),
                        _buildStatCard('CO2 REDUCED', '${co2Saved.toStringAsFixed(1)} kg', PdfColors.blue900),
                        _buildStatCard('WATER SAVED', '${waterSaved.toInt()} L', PdfColors.cyan900),
                      ],
                    ),

                    pw.Spacer(),

                    // Footer with QR and Signatures
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Verification QR
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 60,
                              height: 60,
                              child: pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: donation.qrCode ?? donation.id,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('VERIFY RESCUE', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ),

                        // Signature
                        pw.Column(
                          children: [
                            pw.Container(
                              width: 150,
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                              ),
                              padding: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Center(
                                child: pw.Text(donation.assignedNgoName ?? 'Authorized NGO', 
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('OFFICIAL SEAL & SIGNATURE', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ),

                        // Date
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('ISSUED ON', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.Text(DateFormat('dd MMMM yyyy').format(DateTime.now()),
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.SizedBox(height: 5),
                            pw.Text('ID: ${donation.id.toUpperCase().substring(donation.id.length - 8)}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Impact_Certificate_${donation.id.substring(donation.id.length - 6)}.pdf',
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.05),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color.shade(0.7))),
        ],
      ),
    );
  }
}
