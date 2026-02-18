import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import '../../../core/api/models/analysis_response.dart';
import 'package:usb_camera_plugin_example/core/constants/app/app_assets.dart';

class PdfService {
  static Future<void> generateAndOpenPdf({
    required AnalysisResponse response,
    required String annotatedImageBase64,
    Map<String, dynamic>? websiteData,
  }) async {
    final pdf = pw.Document();

    // Load Background and Fonts
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    
    // Load local background image
    pw.MemoryImage? bgImage;
    try {
      final bytes = await rootBundle.load(AppAssets.bg);
      bgImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      print('PdfService: Error loading bg image: $e');
    }

    // Prepare Annotated Image
    pw.MemoryImage? profileImage;
    try {
      if (annotatedImageBase64.isNotEmpty) {
        final String rawBase64 = annotatedImageBase64.contains(',') 
            ? annotatedImageBase64.split(',')[1] 
            : annotatedImageBase64;
        profileImage = pw.MemoryImage(base64Decode(rawBase64));
      }
    } catch (e) {
      print('PdfService: Error decoding image: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ),
          buildBackground: (pw.Context context) {
            if (bgImage == null) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(bgImage, fit: pw.BoxFit.cover),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            // Content Layer
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'PROTOCOLO',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Y RESULTADOS',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xffD6B033),
                    fontSize: 42,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'ULTRASCAN 4D',
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xff888888),
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Annotated Image Component
            if (profileImage != null)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                child: pw.AspectRatio(
                  aspectRatio: 4 / 3,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromInt(0xffE7CC8D), width: 1.5),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                    ),
                  ),
                ),
              ),

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Text(
                'ANÁLISIS Y PROTOCOLOS',
                style: pw.TextStyle(
                  fontSize: 22,
                  color: PdfColors.white,
                ),
              ),
            ),

            pw.SizedBox(height: 15),

            // Sections from Website Data
            if (websiteData != null && (websiteData['sections'] as List).isNotEmpty)
              ... (websiteData['sections'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                final type = section['type'];
                const String contentKey = 'content';
                final content = section[contentKey];
                final nextSection = (index + 1 < (websiteData['sections'] as List).length)
                    ? (websiteData['sections'] as List)[index + 1] : null;

                if (type == 'heading') {
                  final text = content.toString();
                  if (text.isEmpty) return pw.SizedBox();
                  
                  if (nextSection != null && (nextSection['type'] == 'table' || nextSection[contentKey].toString().length > 100)) {
                    return pw.SizedBox();
                  }
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 25, bottom: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          text.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          width: 40,
                          height: 3,
                          margin: const pw.EdgeInsets.only(top: 5),
                          color: PdfColor.fromHex('#D6B033'),
                        ),
                      ],
                    ),
                  );
                } else if (type == 'table') {
                  final prevSection = (index > 0) ? (websiteData['sections'] as List)[index - 1] : null;
                  final title = (prevSection != null && prevSection['type'] == 'heading') ? prevSection[contentKey].toString() : "";

                  final rows = content as List;
                  if (rows.isEmpty) return pw.SizedBox();
                  
                  return _buildSectionCard(
                    title: title,
                    child: pw.Table(
                      children: rows.map((row) {
                        final cells = row as List;
                        if (cells.isEmpty) return pw.TableRow(children: [pw.SizedBox()]);
                        
                        return pw.TableRow(
                          children: cells.map((cell) {
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                              child: pw.Text(
                                cell.toString(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  final text = content.toString();
                  if (text.isEmpty) return pw.SizedBox();
                  
                  final prevSection = (index > 0) ? (websiteData['sections'] as List)[index - 1] : null;
                  final title = (prevSection != null && prevSection['type'] == 'heading') ? prevSection[contentKey].toString() : "";

                  return _buildSectionCard(
                    title: title,
                    child: pw.Text(
                      text,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  );
                }
              }).toList()
            else
              pw.Center(
                child: pw.Text(
                  "No data available",
                  style: pw.TextStyle(color: PdfColors.white),
                ),
              ),

            pw.SizedBox(height: 40),

            // Footer
            pw.Center(
              child: pw.Text(
                'UltraScan 4D es Marca Registrada de MediCompras Internacional C.A.2026',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save and Display PDF
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Premium_UltraScan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      print('PdfService: Error showing PDF: $e');
    }
  }

  static pw.Widget _buildSectionCard({required String title, required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#111111'), 
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.grey800, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey800, thickness: 0.5),
            pw.SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}
