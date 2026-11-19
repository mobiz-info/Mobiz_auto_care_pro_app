import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class JobCardPdfHelper {
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == '-') return '-';
    final str = dateStr.trim();
    // Match yyyy-mm-dd or yyyy/mm/dd
    final ymdMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(str);
    if (ymdMatch != null) {
      final y = ymdMatch.group(1)!;
      final m = ymdMatch.group(2)!.padLeft(2, '0');
      final d = ymdMatch.group(3)!.padLeft(2, '0');
      return '$d-$m-$y';
    }
    // Match dd-mm-yyyy or dd/mm/yyyy
    final dmyMatch = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(str);
    if (dmyMatch != null) {
      final d = dmyMatch.group(1)!.padLeft(2, '0');
      final m = dmyMatch.group(2)!.padLeft(2, '0');
      final y = dmyMatch.group(3)!;
      return '$d-$m-$y';
    }
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        final d = parsed.day.toString().padLeft(2, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        final y = parsed.year.toString();
        return '$d-$m-$y';
      }
    } catch (_) {}
    return str;
  }

  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty || dateStr == '-') return '-';
    final str = dateStr.trim();
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        final d = parsed.day.toString().padLeft(2, '0');
        final m = parsed.month.toString().padLeft(2, '0');
        final y = parsed.year.toString();
        final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
        final minute = parsed.minute.toString().padLeft(2, '0');
        final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
        return '$d-$m-$y, $hour:$minute $ampm';
      }
    } catch (_) {}
    return formatDate(str);
  }

  static Future<Uint8List> generateJobCardPdfBytes(
    Map<String, dynamic> jc, {
    String? companyName,
    String? branchName,
    String? companyLogo,
  }) async {
    pw.Font? notoFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      notoFont = pw.Font.ttf(fontData);
    } catch (_) {}

    final pdf = pw.Document(
      title: 'Job Card ${jc['job_number'] ?? ''}',
      theme: notoFont != null
          ? pw.ThemeData.withFont(base: notoFont, bold: notoFont)
          : pw.ThemeData.base(),
    );

    pw.ImageProvider? logoImage;
    final effectiveLogoUrl = (companyLogo != null && companyLogo.isNotEmpty)
        ? companyLogo
        : (jc['company_logo']?.toString() ?? '');
    if (effectiveLogoUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(effectiveLogoUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(res.bodyBytes);
        }
      } catch (_) {}
    }
    if (logoImage == null) {
      try {
        final logoData = await rootBundle.load('assets/icons/mobiz_autocare_logo_blue.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}
    }

    final customer = jc['customer'] as Map<String, dynamic>? ?? {};
    final vehicle = jc['vehicle'] as Map<String, dynamic>? ?? {};
    final services = (jc['services'] as List<dynamic>?) ?? [];
    final parts = (jc['parts'] as List<dynamic>?) ?? [];
    final labour = (jc['labour'] as List<dynamic>?) ?? [];
    final extras = (jc['extras'] as List<dynamic>?) ?? [];

    final jobNo = jc['job_number']?.toString() ?? 'JC-000';
    final jobDate = formatDate(jc['job_date']?.toString());
    // final deliveryDate = ...;
    // final leadTime = ...;
    final status = (jc['status_display'] ?? jc['status'] ?? 'New').toString().toUpperCase();
    // final currentSection = ...;
    // final currentService = ...;
    final remarks = jc['additional_remarks']?.toString() ?? '';
    final appointment = jc['appointment_details']?.toString() ?? '';

    final reportedIssues = (jc['reported_issues'] as List<dynamic>?) ?? [];
    final rawInspection = jc['inspection_details'];
    final inspectionDetails = rawInspection is Map<String, dynamic>
        ? rawInspection
        : (rawInspection is Map ? Map<String, dynamic>.from(rawInspection) : <String, dynamic>{});
    final inspectionAt = (jc['inspection_at'] ?? '').toString();

    final tyre = inspectionDetails['tyre'] is Map ? Map<String, dynamic>.from(inspectionDetails['tyre'] as Map) : <String, dynamic>{};
    final wheelAlignment = inspectionDetails['wheel_alignment'] is Map ? Map<String, dynamic>.from(inspectionDetails['wheel_alignment'] as Map) : <String, dynamic>{};
    final oil = inspectionDetails['oil'] is Map ? Map<String, dynamic>.from(inspectionDetails['oil'] as Map) : <String, dynamic>{};

    final hasTyre = tyre.values.any((v) => v != null && v.toString().trim().isNotEmpty && v.toString().trim() != '{}' && v.toString().trim() != '[]');
    final hasAlignment = wheelAlignment.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    final hasOil = oil.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    final hasInspection = hasTyre || hasAlignment || hasOil || inspectionAt.isNotEmpty;

    final custName = customer['name']?.toString() ?? jc['customer_name']?.toString() ?? '-';
    final custPhone = customer['phone']?.toString() ?? jc['customer_phone']?.toString() ?? '-';
    final custWhatsapp = customer['whatsapp']?.toString() ?? jc['customer_whatsapp']?.toString() ?? custPhone;
    final custType = customer['customer_type']?.toString() ?? 'Individual';
    final custAddress = customer['address']?.toString() ?? '';

    final vPlate = vehicle['vehicle_number']?.toString() ?? vehicle['no']?.toString() ?? jc['vehicle_number']?.toString() ?? '-';
    final vMake = vehicle['make']?.toString() ?? jc['vehicle_make']?.toString() ?? '';
    final vModel = vehicle['model']?.toString() ?? jc['vehicle_model']?.toString() ?? '';
    final vSegment = vehicle['segment']?.toString() ?? jc['vehicle_segment']?.toString() ?? '';
    final vType = vehicle['vehicle_type']?.toString() ?? jc['vehicle_type']?.toString() ?? '';
    final vFuel = vehicle['fuel_type']?.toString() ?? '';
    final vTrans = vehicle['transmission_type']?.toString() ?? '';
    final vColor = vehicle['color']?.toString() ?? '';
    final vYear = vehicle['model_year']?.toString() ?? '';
    final vTrim = vehicle['variant_trim']?.toString() ?? '';
    final vChassis = vehicle['chassis_number']?.toString() ?? '';
    final vEngine = vehicle['engine_number']?.toString() ?? '';
    final vOdo = vehicle['current_odometer_km']?.toString() ?? '';

    final cName = companyName ?? 'MOBIZ AUTOCARE PRO';
    final bName = branchName ?? jc['branch_name']?.toString() ?? 'Main Branch';

    // Calculate totals
    double servicesTotal = 0;
    for (final s in services) {
      servicesTotal += (s['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    double partsTotal = 0;
    for (final p in parts) {
      partsTotal += (p['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    double labourTotal = 0;
    for (final l in labour) {
      labourTotal += (l['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    double extrasTotal = 0;
    for (final e in extras) {
      extrasTotal += (e['total_amount'] as num?)?.toDouble() ?? 0.0;
    }
    final grandTotal = (jc['estimated_cost'] as num?)?.toDouble() ??
        (servicesTotal + partsTotal + labourTotal + extrasTotal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(height: 38, child: pw.Image(logoImage))
                    else
                      pw.Text(cName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text(bName, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'JOB CARD / WORK ORDER',
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Job No: $jobNo', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text('Date: $jobDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Status: $status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by Mobiz Auto Care Pro', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (context) => [
          pw.SizedBox(height: 10),

          // ── Customer & Vehicle Row ─────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Customer Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Text(custName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Phone: $custPhone', style: const pw.TextStyle(fontSize: 9)),
                      if (custWhatsapp != custPhone && custWhatsapp.isNotEmpty)
                        pw.Text('WhatsApp: $custWhatsapp', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Type: $custType', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      if (custAddress.isNotEmpty)
                        pw.Text('Address: $custAddress', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              // Vehicle Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('VEHICLE DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Text('Plate: $vPlate', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('$vMake $vModel $vTrim'.trim(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Type/Seg: ${[vType, vSegment].where((s) => s.isNotEmpty).join(' • ')}', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Fuel: $vFuel | Trans: $vTrans | Color: $vColor', style: const pw.TextStyle(fontSize: 8)),
                      if (vYear.isNotEmpty) pw.Text('Model Year: $vYear', style: const pw.TextStyle(fontSize: 8)),
                      if (vChassis.isNotEmpty) pw.Text('Chassis No: $vChassis', style: const pw.TextStyle(fontSize: 8)),
                      if (vEngine.isNotEmpty) pw.Text('Engine No: $vEngine', style: const pw.TextStyle(fontSize: 8)),
                      if (vOdo.isNotEmpty && vOdo != '0') pw.Text('Odometer: $vOdo KM', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),



          pw.SizedBox(height: 12),

          // ── Reported Issues Table ───────────────────────────────────────
          if (reportedIssues.isNotEmpty) ...[
            pw.Text('REPORTED ISSUES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', isHeader: true, flex: 1),
                    _cell('Service', isHeader: true, flex: 4),
                    _cell('Issue / Concern Description', isHeader: true, flex: 7),
                  ],
                ),
                ...reportedIssues.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final issue = entry.value;
                  String sName = '';
                  if (issue is Map) {
                    if (issue['service_name'] != null && issue['service_name'].toString().isNotEmpty) {
                      sName = issue['service_name'].toString();
                    } else if (issue['service'] is Map) {
                      sName = (issue['service']['name'] ?? '').toString();
                    } else if (issue['service'] != null && !issue['service'].toString().startsWith('{')) {
                      sName = issue['service'].toString();
                    }
                  }
                  String desc = '';
                  if (issue is Map) {
                    if (issue['issue_text'] != null && issue['issue_text'].toString().isNotEmpty) {
                      desc = issue['issue_text'].toString();
                    } else if (issue['issue_description'] != null && issue['issue_description'].toString().isNotEmpty) {
                      desc = issue['issue_description'].toString();
                    } else if (issue['description'] != null && issue['description'].toString().isNotEmpty) {
                      desc = issue['description'].toString();
                    } else if (issue['issue'] is Map) {
                      desc = (issue['issue']['name'] ?? '').toString();
                    } else if (issue['issue'] != null && !issue['issue'].toString().startsWith('{')) {
                      desc = issue['issue'].toString();
                    }
                  } else {
                    desc = issue.toString();
                  }
                  return pw.TableRow(
                    children: [
                      _cell('$idx', flex: 1),
                      _cell(sName.isNotEmpty ? sName : '-', flex: 4),
                      _cell(desc.isNotEmpty ? desc : '-', flex: 7),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Vehicle Inspection Details ────────────────────────────────────
          if (hasInspection) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('VEHICLE INSPECTION DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      if (inspectionAt.isNotEmpty)
                        pw.Text('Inspection Date: ${formatDateTime(inspectionAt)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 6),

                  // Tyre Inspection
                  if (hasTyre) ...[
                    pw.Text('Tyre Inspection', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 3),
                    if (tyre['wheel_assessment'] is Map && (tyre['wheel_assessment'] as Map).isNotEmpty) ...[
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (tyre['wheel_assessment'] as Map).entries.map((e) {
                          final k = e.key.toString();
                          final v = e.value.toString();
                          if (v.trim().isEmpty) return pw.SizedBox.shrink();
                          PdfColor bColor = PdfColors.green700;
                          PdfColor bBg = PdfColors.green50;
                          final low = v.toLowerCase();
                          if (low.contains('replace') || low.contains('poor') || low.contains('bad') || low.contains('critical')) {
                            bColor = PdfColors.red700;
                            bBg = PdfColors.red50;
                          } else if (low.contains('fair') || low.contains('moderate') || low.contains('check')) {
                            bColor = PdfColors.orange800;
                            bBg = PdfColors.orange50;
                          }
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: bBg,
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: bColor, width: 0.5),
                            ),
                            child: pw.Text('$k: $v', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: bColor)),
                          );
                        }).toList(),
                      ),
                      pw.SizedBox(height: 4),
                    ],
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      children: [
                        if ((tyre['pressure'] ?? '').toString().trim().isNotEmpty)
                          _pdfMetric('Pressure', tyre['pressure'].toString()),
                        if ((tyre['tread_depth'] ?? '').toString().trim().isNotEmpty)
                          _pdfMetric('Tread Depth', tyre['tread_depth'].toString()),
                        if ((tyre['twi_value'] ?? '').toString().trim().isNotEmpty)
                          _pdfMetric('TWI', tyre['twi_value'].toString()),
                        if ((tyre['wear_indicators'] ?? '').toString().trim().isNotEmpty)
                          _pdfMetric('Wear Ind.', tyre['wear_indicators'].toString()),
                        if ((tyre['dot_year'] ?? '').toString().trim().isNotEmpty)
                          _pdfMetric('DOT Year', tyre['dot_year'].toString()),
                      ],
                    ),
                    ...[
                      ('Wear Distribution', tyre['wear_distribution']),
                      ('Surface Damage', tyre['surface_damage']),
                      ('Structural Damage', tyre['structural_damage']),
                      ('Valve Issues', tyre['valve_issues']),
                      ('Rim Issues', tyre['rim_issues']),
                    ].where((p) => p.$2 != null && (p.$2 is List ? (p.$2 as List).isNotEmpty : p.$2.toString().trim().isNotEmpty)).map((p) {
                      final strVal = p.$2 is List ? (p.$2 as List).join(', ') : p.$2.toString();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: '${p.$1}: ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                              pw.TextSpan(text: strVal, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.red800)),
                            ],
                          ),
                        ),
                      );
                    }),
                    pw.SizedBox(height: 5),
                  ],

                  // Wheel Alignment
                  if (hasAlignment) ...[
                    pw.Text('Wheel Alignment & Balancing', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 3),
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      children: wheelAlignment.entries
                          .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
                          .map((e) => _pdfMetric(e.key.toString(), e.value.toString()))
                          .toList(),
                    ),
                    pw.SizedBox(height: 5),
                  ],

                  // Oil & Fluids
                  if (hasOil) ...[
                    pw.Text('Oil & Fluids Inspection', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 3),
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      children: oil.entries
                          .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
                          .map((e) => _pdfMetric(e.key.toString(), e.value.toString()))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Services Table ────────────────────────────────────────────────
          if (services.isNotEmpty) ...[
            pw.Text('SERVICES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', isHeader: true, flex: 1),
                    _cell('Service Particulars', isHeader: true, flex: 6),
                    _cell('Qty', isHeader: true, flex: 2, align: pw.TextAlign.center),
                    _cell('Rate (₹)', isHeader: true, flex: 2, align: pw.TextAlign.right),
                    _cell('Disc (₹)', isHeader: true, flex: 2, align: pw.TextAlign.right),
                    _cell('Total (₹)', isHeader: true, flex: 3, align: pw.TextAlign.right),
                  ],
                ),
                ...services.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', flex: 1),
                      _cell(s['service_name']?.toString() ?? '', flex: 6),
                      _cell('${s['quantity'] ?? 1}', flex: 2, align: pw.TextAlign.center),
                      _cell('${(s['rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 2, align: pw.TextAlign.right),
                      _cell('${(s['discount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 2, align: pw.TextAlign.right),
                      _cell('${(s['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 3, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Parts & Accessories Table ─────────────────────────────────────
          if (parts.isNotEmpty) ...[
            pw.Text('ACCESSORIES & SPARE PARTS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', isHeader: true, flex: 1),
                    _cell('Part Description', isHeader: true, flex: 4),
                    _cell('Part Number', isHeader: true, flex: 3),
                    _cell('Qty', isHeader: true, flex: 2, align: pw.TextAlign.center),
                    _cell('Rate (₹)', isHeader: true, flex: 2, align: pw.TextAlign.right),
                    _cell('Total (₹)', isHeader: true, flex: 3, align: pw.TextAlign.right),
                  ],
                ),
                ...parts.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', flex: 1),
                      _cell(p['product_name']?.toString() ?? '', flex: 4),
                      _cell(p['part_number']?.toString() ?? '-', flex: 3),
                      _cell('${p['quantity'] ?? 1}', flex: 2, align: pw.TextAlign.center),
                      _cell('${(p['rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 2, align: pw.TextAlign.right),
                      _cell('${(p['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 3, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Labour Charges Table ──────────────────────────────────────────
          if (labour.isNotEmpty) ...[
            pw.Text('LABOUR CHARGES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', isHeader: true, flex: 1),
                    _cell('Labour Particulars', isHeader: true, flex: 6),
                    _cell('Qty', isHeader: true, flex: 2, align: pw.TextAlign.center),
                    _cell('Rate (₹)', isHeader: true, flex: 2, align: pw.TextAlign.right),
                    _cell('Total (₹)', isHeader: true, flex: 3, align: pw.TextAlign.right),
                  ],
                ),
                ...labour.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final l = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', flex: 1),
                      _cell(l['labour_particulars']?.toString() ?? '', flex: 6),
                      _cell('${l['quantity'] ?? 1}', flex: 2, align: pw.TextAlign.center),
                      _cell('${(l['rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 2, align: pw.TextAlign.right),
                      _cell('${(l['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 3, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Extras Table ──────────────────────────────────────────────────
          if (extras.isNotEmpty) ...[
            pw.Text('EXTRAS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('#', isHeader: true, flex: 1),
                    _cell('Extra Details', isHeader: true, flex: 6),
                    _cell('Qty', isHeader: true, flex: 2, align: pw.TextAlign.center),
                    _cell('Rate (₹)', isHeader: true, flex: 2, align: pw.TextAlign.right),
                    _cell('Total (₹)', isHeader: true, flex: 3, align: pw.TextAlign.right),
                  ],
                ),
                ...extras.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final ex = entry.value;
                  return pw.TableRow(
                    children: [
                      _cell('$idx', flex: 1),
                      _cell(ex['extra_details']?.toString() ?? '', flex: 6),
                      _cell('${ex['quantity'] ?? 1}', flex: 2, align: pw.TextAlign.center),
                      _cell('${(ex['rate'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 2, align: pw.TextAlign.right),
                      _cell('${(ex['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', flex: 3, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // ── Totals Summary ────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 240,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    if (servicesTotal > 0)
                      _summaryRow('Services Subtotal:', '₹${servicesTotal.toStringAsFixed(2)}'),
                    if (partsTotal > 0)
                      _summaryRow('Parts & Accessories:', '₹${partsTotal.toStringAsFixed(2)}'),
                    if (labourTotal > 0)
                      _summaryRow('Labour Charges:', '₹${labourTotal.toStringAsFixed(2)}'),
                    if (extrasTotal > 0)
                      _summaryRow('Extras:', '₹${extrasTotal.toStringAsFixed(2)}'),
                    pw.Divider(color: PdfColors.grey400, height: 8),
                    _summaryRow(
                      'ESTIMATED TOTAL:',
                      '₹${grandTotal.toStringAsFixed(2)}',
                      isBold: true,
                      color: PdfColors.blue900,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (remarks.isNotEmpty || appointment.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (remarks.isNotEmpty)
                    pw.Text('Remarks: $remarks', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                  if (appointment.isNotEmpty)
                    pw.Text('Appointment: $appointment', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 24),

          // ── Signatures ────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text('Service Advisor / Workshop', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfMetric(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(': ', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: isHeader ? 8.5 : 8,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHeader ? PdfColors.black : PdfColors.grey900,
          ),
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 10 : 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 11 : 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static Future<File> getJobCardPdfFile(
    Map<String, dynamic> jc, {
    String? companyName,
    String? branchName,
    String? companyLogo,
  }) async {
    final pdfBytes = await generateJobCardPdfBytes(
      jc,
      companyName: companyName,
      branchName: branchName,
      companyLogo: companyLogo,
    );

    final dir = await getTemporaryDirectory();
    final cleanJobNo = (jc['job_number'] ?? 'job_card').toString().replaceAll('/', '_');
    final file = File('${dir.path}/JobCard_$cleanJobNo.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<void> shareJobCardPdf(
    Map<String, dynamic> jc, {
    String? companyName,
    String? branchName,
    String? companyLogo,
  }) async {
    final file = await getJobCardPdfFile(
      jc,
      companyName: companyName,
      branchName: branchName,
      companyLogo: companyLogo,
    );

    final customer = jc['customer'] as Map<String, dynamic>? ?? {};
    final vehicle = jc['vehicle'] as Map<String, dynamic>? ?? {};
    final custName = customer['name']?.toString() ?? jc['customer_name']?.toString() ?? 'Customer';
    final jobNo = jc['job_number']?.toString() ?? 'Job Order';
    final vPlate = vehicle['vehicle_number']?.toString() ?? vehicle['no']?.toString() ?? jc['vehicle_number']?.toString() ?? '';
    final vMake = vehicle['make']?.toString() ?? jc['vehicle_make']?.toString() ?? '';
    final vModel = vehicle['model']?.toString() ?? jc['vehicle_model']?.toString() ?? '';
    final vehDesc = [vPlate, vMake, vModel].where((s) => s.isNotEmpty).join(' - ');
    final total = (jc['estimated_cost'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final delivery = formatDateTime(jc['expected_delivery_date']?.toString() ?? jc['delivery_date']?.toString());
    final cName = companyName ?? 'Mobiz Auto Care Pro';

    final messageText =
        "Dear *$custName*,\n\n"
        "Here is the Job Card *$jobNo* for your vehicle *$vehDesc*.\n\n"
        "*Job Order Summary:*\n"
        "• Status: ${jc['status_display'] ?? jc['status'] ?? 'New'}\n"
        "• Section: ${jc['current_section'] ?? 'Inspection'}\n"
        "• Estimated Total: ₹$total\n"
        "${delivery.isNotEmpty ? '• Expected Delivery: $delivery\n' : ''}"
        "\nThank you for choosing $cName!";

    await Share.shareXFiles([XFile(file.path)], text: messageText);
  }
}
