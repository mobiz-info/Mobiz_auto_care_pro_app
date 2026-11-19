import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class JobLeadPdfHelper {
  static const _brand = PdfColor.fromInt(0xFF000080);
  static const _paleBlue = PdfColor.fromInt(0xFFF1F4FA);

  static Future<Uint8List> buildLeadPdf(
    Map<String, dynamic> lead, {
    String? companyName,
    String? companyLogo,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoFont = pw.Font.ttf(fontData);
    final document = pw.Document(
      title: 'Lead ${lead['lead_number'] ?? ''}',
      theme: pw.ThemeData.withFont(base: notoFont, bold: notoFont),
    );
    final logo = await _loadLogo(companyLogo);
    final services = List<Map<String, dynamic>>.from(
      (lead['service_interests'] ?? const []).whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
    final fallbackServices = (lead['service_name'] ?? '')
        .toString()
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final serviceRows = services.isNotEmpty
        ? services
              .map(
                (item) => [
                  (item['category_name'] ?? '').toString(),
                  (item['service_name'] ?? '').toString(),
                  _money(item['expected_value']),
                ],
              )
              .toList()
        : fallbackServices.map((name) => ['', name, '']).toList();
    final vehicle =
        [lead['vehicle_number'], lead['vehicle_make'], lead['vehicle_model']]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .join(' · ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (context) => [
          _header(logo, companyName, lead),
          pw.SizedBox(height: 8),
          pw.Container(height: 2, color: _brand),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _section('CUSTOMER', [
                  ['Name', lead['customer_name']],
                  ['Customer type', lead['customer_type_name']],
                  ['Mobile', lead['phone_number']],
                  ['WhatsApp', lead['whatsapp_number']],
                  ['Email', lead['email']],
                  ['State / Emirate', lead['state']],
                  ['City', lead['city']],
                ]),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _section('LEAD DETAILS', [
                  ['Registration date', _date(lead['lead_date'])],
                  ['Lead generation mode', lead['lead_generation_mode']],
                  ['Reference', lead['reference']],
                  ['In-charge staff', lead['staff_name']],
                  ['Status', lead['status']],
                  ['Next follow-up', _date(lead['next_follow_up_date'])],
                  ['Expected value', _money(lead['expected_value'])],
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _section('VEHICLE DETAILS', [
            ['Vehicle', vehicle],
            ['Segment', lead['vehicle_segment_name']],
          ]),
          pw.SizedBox(height: 16),
          pw.Text(
            'INTERESTED SERVICES',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
          pw.SizedBox(height: 6),
          if (serviceRows.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              color: _paleBlue,
              child: pw.Text('No service interests recorded.'),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Category', 'Service', 'Expected value'],
              data: serviceRows,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: _brand),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              oddRowDecoration: const pw.BoxDecoration(color: _paleBlue),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1),
              },
            ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _header(
    pw.ImageProvider? logo,
    String? companyName,
    Map<String, dynamic> lead,
  ) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (logo != null) ...[
        pw.Image(logo, width: 72, height: 72, fit: pw.BoxFit.contain),
        pw.SizedBox(width: 12),
      ],
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              companyName?.trim().isNotEmpty == true
                  ? companyName!.trim().toUpperCase()
                  : 'MOBIZ AUTO CARE PRO',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _brand,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Lead ${lead['lead_number'] ?? ''}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'LEAD DETAILS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _date(lead['lead_date']),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    ],
  );

  static Future<pw.ImageProvider?> _loadLogo(String? logoUrl) async {
    if (logoUrl?.trim().isNotEmpty == true) {
      try {
        final response = await http.get(Uri.parse(logoUrl!.trim()));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }
    try {
      final data = await rootBundle.load(
        'assets/icons/mobiz_autocare_mark_blue.png',
      );
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<void> shareLeadPdf(
    Map<String, dynamic> lead, {
    String? companyName,
    String? companyLogo,
  }) async {
    final bytes = await buildLeadPdf(
      lead,
      companyName: companyName,
      companyLogo: companyLogo,
    );
    await Printing.sharePdf(bytes: bytes, filename: _filename(lead));
  }

  static Future<void> downloadLeadPdf(
    Map<String, dynamic> lead, {
    String? companyName,
    String? companyLogo,
  }) async {
    final bytes = await buildLeadPdf(
      lead,
      companyName: companyName,
      companyLogo: companyLogo,
    );
    await Printing.layoutPdf(
      name: _filename(lead),
      onLayout: (_) async => bytes,
    );
  }

  static pw.Widget _section(String title, List<List<dynamic>> values) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: const pw.BoxDecoration(
          color: _paleBlue,
          border: pw.Border(left: pw.BorderSide(color: _brand, width: 2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _brand,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              data: values
                  .where((row) => row.length > 1 && _text(row[1]).isNotEmpty)
                  .map((row) => [_text(row[0]), _text(row[1])])
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: .35,
                ),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1.6),
              },
            ),
          ],
        ),
      );

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String _money(dynamic value) {
    final amount = double.tryParse(_text(value));
    return amount == null ? '' : amount.toStringAsFixed(2);
  }

  static String _date(dynamic value) {
    final date = DateTime.tryParse(_text(value));
    if (date == null) return _text(value);
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  static String _filename(Map<String, dynamic> lead) {
    final safeNumber = _text(
      lead['lead_number'],
    ).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'Job_Lead_${safeNumber.isEmpty ? 'lead' : safeNumber}.pdf';
  }
}
