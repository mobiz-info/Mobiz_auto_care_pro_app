import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'job_card_detail_screen.dart';
import 'job_card_create_screen.dart';
import 'quotation_create_screen.dart';
import 'job_quotation_form_screen.dart';

class QuotationViewScreen extends StatefulWidget {
  final String quotationId;
  final Map<String, dynamic>? initialData;
  final bool jobWorkflow;

  const QuotationViewScreen({
    super.key,
    required this.quotationId,
    this.initialData,
    this.jobWorkflow = false,
  });

  @override
  State<QuotationViewScreen> createState() => _QuotationViewScreenState();
}

class _QuotationViewScreenState extends State<QuotationViewScreen> {
  String get currencySymbol {
    try {
      return context.read<AuthProvider>().currencySymbol;
    } catch (_) {
      return CountryConfig.currencySymbol;
    }
  }

  bool _isLoading = true;
  bool _isPipelineActionRunning = false;
  String _errorMessage = '';
  Map<String, dynamic>? _quotation;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  bool get _hasPricedItems {
    final quote = _quotation;
    if (quote == null) return false;
    final items = List<dynamic>.from(quote['items'] ?? []);
    final extras = List<dynamic>.from(quote['extras'] ?? []);
    return items.any(
          (item) =>
              _parseDouble(item['total']) > 0 ||
              (_parseDouble(item['rate']) *
                          _parseDouble(item['quantity'] ?? item['qty'] ?? 1) -
                      _parseDouble(item['discount'])) >
                  0,
        ) ||
        extras.any((item) => _parseDouble(item['total']) > 0);
  }

  String _formatDateWithTime(String dateStrRaw) {
    if (dateStrRaw.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStrRaw);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d-$m-$y $h:$min';
    } catch (_) {
      return dateStrRaw;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _quotation = Map<String, dynamic>.from(widget.initialData!);
      _isLoading = false;
    } else {
      _loadQuotationDetails();
    }
  }

  Future<void> _loadQuotationDetails() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final res = widget.jobWorkflow
          ? await ApiService.getJobQuotationDetail(widget.quotationId, token)
          : await ApiService.getQuotationDetail(widget.quotationId, token);
      if (res['success'] == true && res['quotation'] != null) {
        setState(() {
          _quotation = Map<String, dynamic>.from(res['quotation'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load quotation';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptQuotation() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || _quotation == null || _isPipelineActionRunning) return;
    setState(() => _isPipelineActionRunning = true);
    try {
      final res = widget.jobWorkflow
          ? await ApiService.acceptJobQuotation(widget.quotationId, token)
          : await ApiService.acceptQuotation(widget.quotationId, token);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _quotation!['is_accepted'] = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Quotation accepted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Could not accept quotation'),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPipelineActionRunning = false);
    }
  }

  Future<void> _convertToJobCard() async {
    final token = context.read<AuthProvider>().token;
    if (token == null ||
        _quotation == null ||
        _quotation!['is_accepted'] != true ||
        _isPipelineActionRunning)
      return;
    setState(() => _isPipelineActionRunning = true);
    try {
      final res = widget.jobWorkflow
          ? await ApiService.convertJobQuotationToJobCard(
              widget.quotationId,
              token,
            )
          : await ApiService.convertQuotationToJobCard(
              widget.quotationId,
              token,
            );
      if (!mounted) return;
      if (res['success'] == true) {
        final jobCardId = res['job_card_id']?.toString() ?? '';
        setState(() => _quotation!['job_card_id'] = jobCardId);
        if (jobCardId.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => widget.jobWorkflow
                  ? JobCardCreateScreen(existingJobCardId: jobCardId)
                  : JobCardDetailScreen(jobCardId: jobCardId),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Could not convert quotation'),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPipelineActionRunning = false);
    }
  }

  Future<void> _editQuotation() async {
    final q = _quotation;
    if (q == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.jobWorkflow
            ? JobQuotationFormScreen(
                lead: q['lead'] is Map
                    ? Map<String, dynamic>.from(q['lead'] as Map)
                    : null,
                existingQuotation: q,
              )
            : QuotationCreateScreen(
                customer: {
                  'id': q['customer_id'],
                  'name': q['customer_name'],
                  'phone': q['customer_phone'],
                  'type': q['customer_type'],
                },
                vehicle: {
                  'id': q['vehicle_id'],
                  'no': q['vehicle_number'],
                  'type': q['vehicle_type'],
                },
                existingQuotation: q,
                leadId: q['lead_id']?.toString(),
                jobWorkflow: widget.jobWorkflow,
              ),
      ),
    );
    if (updated == true && mounted) {
      await _loadQuotationDetails();
    }
  }

  Future<void> _deleteQuotation() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || _quotation == null || _isPipelineActionRunning) return;
    final qNum = (_quotation!['quotation_number'] ?? '').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('Delete Quotation'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete quotation $qNum? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              context.tr('Delete'),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isPipelineActionRunning = true);
    try {
      final res = await ApiService.deleteJobQuotation(widget.quotationId, token);
      if (!mounted) return;
      if (res['success'] == true || res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to delete quotation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPipelineActionRunning = false);
    }
  }

  // ── Build PDF Document Bytes ──────────────────────────────────────────────
  Future<Uint8List> _buildQuotationPdfBytes(BuildContext context) async {
    final q = _quotation!;
    final companyName =
        context.read<AuthProvider>().companyName ?? ApiService.appName;
    final branchName =
        q['branch_name'] ?? context.read<AuthProvider>().branchName ?? '';
    final currencySymbol = this.currencySymbol;

    pw.Font? notoFont;
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      notoFont = pw.Font.ttf(fontData);
    } catch (_) {
      try {
        notoFont = await PdfGoogleFonts.notoSansRegular();
      } catch (_) {}
    }

    pw.MemoryImage? logoImage;
    pw.MemoryImage? sealImage;
    try {
      final branchLogo = (q['branch_logo'] ?? '').toString();
      final compLogo = (q['company_logo'] ?? '').toString();
      final authCompLogo = (context.read<AuthProvider>().companyLogo ?? '')
          .toString();
      final logoUrl = branchLogo.isNotEmpty
          ? branchLogo
          : (compLogo.isNotEmpty ? compLogo : authCompLogo);
      if (logoUrl.isNotEmpty) {
        final res = await http.get(Uri.parse(logoUrl));
        if (res.statusCode == 200) {
          logoImage = pw.MemoryImage(res.bodyBytes);
        }
      }
    } catch (_) {}

    try {
      final sealUrl = (q['company_seal_url'] ?? '').toString();
      if (sealUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(sealUrl));
        if (response.statusCode == 200) {
          sealImage = pw.MemoryImage(response.bodyBytes);
        }
      }
    } catch (_) {}

    if (logoImage == null) {
      try {
        final logoData = await rootBundle.load(
          'assets/icons/Wash-Pilot_Blue-Icon.png',
        );
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}
    }

    final rawItems = (q['items'] as List<dynamic>? ?? []);
    final rawExtras = (q['extras'] as List<dynamic>? ?? []);
    final rawReportedIssues = (q['reported_issues'] as List<dynamic>? ?? []);

    final rawInspection = q['inspection_details'];
    final inspectionDetails = rawInspection is Map<String, dynamic>
        ? rawInspection
        : (rawInspection is Map ? Map<String, dynamic>.from(rawInspection) : <String, dynamic>{});
    final inspectionAt = (q['inspection_at'] ?? '').toString();
    final tentativeDeliveryAt = (q['tentative_delivery_at'] ?? '').toString();
    final daysNeeded = (q['days_needed'] ?? '').toString().isNotEmpty
        ? q['days_needed'].toString()
        : ((q['additional_days_needed'] != null && q['additional_days_needed'] != 0)
            ? '${q['additional_days_needed']} Days'
            : '');
    final preparedByName = (q['prepared_by_name'] ?? '').toString();

    // Damage marks
    final damageMarks = (inspectionDetails['damage_marks'] as List<dynamic>?) ?? [];

    // Checklist
    final rawChecklist = inspectionDetails['checklist'];
    final List<Map<String, dynamic>> checklistList = [];
    if (rawChecklist is Map) {
      rawChecklist.forEach((key, val) {
        if (val is Map) {
          final m = Map<String, dynamic>.from(val);
          final status = (m['status'] ?? '').toString().trim().toLowerCase();
          final value = (m['value'] ?? '').toString().trim();
          final remarks = (m['remarks'] ?? '').toString().trim();
          final name = (m['name'] ?? key).toString();
          final category = (m['category'] ?? '').toString();
          if (status.isNotEmpty || value.isNotEmpty || remarks.isNotEmpty) {
            checklistList.add({
              'key': key.toString(),
              'name': name,
              'category': category,
              'status': status,
              'value': value,
              'remarks': remarks,
            });
          }
        }
      });
    }

    final tyre = inspectionDetails['tyre'] is Map ? Map<String, dynamic>.from(inspectionDetails['tyre'] as Map) : <String, dynamic>{};
    final tyreServices = inspectionDetails['tyre_services'] is Map ? Map<String, dynamic>.from(inspectionDetails['tyre_services'] as Map) : <String, dynamic>{};
    final oil = inspectionDetails['oil_service'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['oil_service'] as Map)
        : (inspectionDetails['oil'] is Map ? Map<String, dynamic>.from(inspectionDetails['oil'] as Map) : <String, dynamic>{});
    final brake = inspectionDetails['brake_service'] is Map ? Map<String, dynamic>.from(inspectionDetails['brake_service'] as Map) : <String, dynamic>{};
    final wheelAlignment = inspectionDetails['wheel_alignment'] is Map ? Map<String, dynamic>.from(inspectionDetails['wheel_alignment'] as Map) : <String, dynamic>{};

    final hasTyre = tyre.values.any((v) => v != null && v.toString().trim().isNotEmpty && v.toString().trim() != '{}' && v.toString().trim() != '[]');
    final hasTyreServices = tyreServices.values.any((v) => v != null && v.toString().trim().isNotEmpty && v.toString().trim() != '{}' && v.toString().trim() != '[]');
    final hasOil = oil.values.any((v) => v != null && v.toString().trim().isNotEmpty && v.toString().trim() != '{}' && v.toString().trim() != '[]');
    final hasBrake = brake.values.any((v) => v != null && v.toString().trim().isNotEmpty && v.toString().trim() != '{}' && v.toString().trim() != '[]');
    final hasAlignment = wheelAlignment.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final hasInspection = checklistList.isNotEmpty ||
        damageMarks.isNotEmpty ||
        hasTyre ||
        hasTyreServices ||
        hasOil ||
        hasBrake ||
        hasAlignment ||
        inspectionAt.isNotEmpty;

    // 1. Group: Services / Reported Issues
    final List<Map<String, dynamic>> serviceRows = [];
    if (rawReportedIssues.isNotEmpty) {
      for (final raw in rawReportedIssues) {
        if (raw is Map) {
          final issue = Map<String, dynamic>.from(raw);
          final catName = (issue['category_name'] ?? '').toString();
          final sName = (issue['service_name'] ?? '').toString();
          final issueText = (issue['issue_text'] ?? '').toString();
          final pricing = issue['pricing'] is Map ? Map<String, dynamic>.from(issue['pricing'] as Map) : null;
          final rate = _parseDouble(pricing?['rate'] ?? issue['rate']);
          final qty = _parseDouble(pricing?['quantity'] ?? issue['quantity'] ?? 1);
          final disc = _parseDouble(pricing?['discount'] ?? issue['discount']);
          final tot = pricing?['total'] != null
              ? _parseDouble(pricing!['total'])
              : ((rate * qty) - disc).clamp(0.0, double.infinity);
          final warranty = (issue['warranty'] ?? '').toString();
          final remarks = (issue['remarks'] ?? '').toString();

          serviceRows.add({
            'title': sName.isNotEmpty
                ? (catName.isNotEmpty ? '$catName · $sName' : sName)
                : 'Service',
            'subtitle': issueText.isNotEmpty ? issueText : null,
            'rate': rate,
            'quantity': qty,
            'discount': disc,
            'total': tot,
            'warranty': warranty,
            'remarks': remarks,
          });
        }
      }
    }
    // Also include standalone requested services (skip reported issues to prevent duplication)
    for (final raw in rawItems) {
      if (raw is Map) {
        final it = Map<String, dynamic>.from(raw);
        final isAccessory = it['line_type'] == 'accessory' ||
            (it['stock_item_name'] != null && it['stock_item_name'].toString().isNotEmpty);
        final isIssue = it['line_type'] == 'issue' ||
            (it['reported_issue_id'] != null && it['reported_issue_id'].toString().isNotEmpty);
        if (!isAccessory && !isIssue) {
          final sName = (it['service_name'] ?? 'Service').toString();
          final alreadyPresent = serviceRows.any((sr) {
            final title = (sr['title'] ?? '').toString();
            return title == sName || title.endsWith('· $sName');
          });
          if (!alreadyPresent) {
            final rate = _parseDouble(it['rate']);
            final qty = _parseDouble(it['quantity'] ?? it['stock_qty'] ?? 1);
            final disc = _parseDouble(it['discount']);
            final tot = it['total'] != null
                ? _parseDouble(it['total'])
                : ((rate * qty) - disc).clamp(0.0, double.infinity);
            serviceRows.add({
              'title': sName,
              'subtitle': (it['remarks'] ?? '').toString().isNotEmpty ? it['remarks'].toString() : null,
              'rate': rate,
              'quantity': qty,
              'discount': disc,
              'total': tot,
              'warranty': (it['warranty_years'] ?? it['warranty'] ?? '').toString(),
              'remarks': (it['remarks'] ?? '').toString(),
            });
          }
        }
      }
    }

    // 2. Group: Accessories / Stock items
    final List<Map<String, dynamic>> accessoryRows = [];
    for (final raw in rawItems) {
      if (raw is Map) {
        final it = Map<String, dynamic>.from(raw);
        final isAccessory = it['line_type'] == 'accessory' ||
            (it['stock_item_name'] != null && it['stock_item_name'].toString().isNotEmpty);
        if (isAccessory) {
          final rate = _parseDouble(it['rate']);
          final qty = _parseDouble(it['quantity'] ?? it['stock_qty'] ?? 1);
          final disc = _parseDouble(it['discount']);
          final tot = it['total'] != null
              ? _parseDouble(it['total'])
              : ((rate * qty) - disc).clamp(0.0, double.infinity);
          final name = (it['stock_item_name'] ?? it['service_name'] ?? 'Accessory').toString();
          final partNumber = (it['part_number'] ?? it['product_code'] ?? '').toString();
          final warranty = (it['warranty_years'] ?? '').toString();
          final remarks = (it['remarks'] ?? '').toString();

          accessoryRows.add({
            'title': name,
            'part_number': partNumber,
            'rate': rate,
            'quantity': qty,
            'discount': disc,
            'total': tot,
            'warranty': warranty,
            'remarks': remarks,
          });
        }
      }
    }

    // 3. Group: Labour Charges
    final List<Map<String, dynamic>> labourRows = [];
    for (final raw in rawExtras) {
      if (raw is Map) {
        final ex = Map<String, dynamic>.from(raw);
        if (ex['line_type'] == 'labour') {
          final price = _parseDouble(ex['price'] ?? ex['cost']);
          final qty = _parseDouble(ex['quantity'] ?? ex['qty'] ?? 1);
          final disc = _parseDouble(ex['discount']);
          final tot = ex['total'] != null
              ? _parseDouble(ex['total'])
              : ((price * qty) - disc).clamp(0.0, double.infinity);
          final name = (ex['name'] ?? 'Labour').toString();
          final remarks = (ex['remarks'] ?? '').toString();

          labourRows.add({
            'title': name,
            'rate': price,
            'quantity': qty,
            'discount': disc,
            'total': tot,
            'remarks': remarks,
          });
        }
      }
    }

    // 4. Group: Extras
    final List<Map<String, dynamic>> extraRows = [];
    for (final raw in rawExtras) {
      if (raw is Map) {
        final ex = Map<String, dynamic>.from(raw);
        if (ex['line_type'] != 'labour') {
          final price = _parseDouble(ex['price']);
          final qty = _parseDouble(ex['quantity'] ?? ex['qty'] ?? 1);
          final disc = _parseDouble(ex['discount']);
          final tot = ex['total'] != null
              ? _parseDouble(ex['total'])
              : ((price * qty) - disc).clamp(0.0, double.infinity);
          final name = (ex['name'] ?? 'Extra').toString();
          final remarks = (ex['remarks'] ?? '').toString();

          extraRows.add({
            'title': name,
            'rate': price,
            'quantity': qty,
            'discount': disc,
            'total': tot,
            'remarks': remarks,
          });
        }
      }
    }

    // Totals calculations
    final double servicesTotal = serviceRows.fold(0.0, (sum, e) => sum + (e['total'] as double));
    final double accessoriesTotal = accessoryRows.fold(0.0, (sum, e) => sum + (e['total'] as double));
    final double labourTotal = labourRows.fold(0.0, (sum, e) => sum + (e['total'] as double));
    final double extrasTotal = extraRows.fold(0.0, (sum, e) => sum + (e['total'] as double));

    final subtotal = _parseDouble(q['subtotal']);
    final discount = _parseDouble(q['discount']);
    final taxAmount = _parseDouble(q['tax_amount']);
    final taxPercent = _parseDouble(q['tax_percentage']);
    final grandTotal = _parseDouble(q['grand_total']);
    final isGrandTotal = (q['is_grand_total'] as bool?) ?? true;

    final double computedSubtotal = servicesTotal + accessoriesTotal + labourTotal + extrasTotal;
    final double finalSubtotal = subtotal > 0 ? subtotal : computedSubtotal;
    final double computedGrandTotal = (finalSubtotal - discount + taxAmount).clamp(0.0, double.infinity);
    final double finalGrandTotal = grandTotal > 0 ? grandTotal : computedGrandTotal;

    final qNumber = q['quotation_number'] ?? '';
    final dateStr = _formatDateWithTime((q['created_at'] ?? q['date'] ?? '').toString());

    final pdf = pw.Document(
      title: qNumber.isNotEmpty ? qNumber : 'Quotation',
      theme: notoFont != null
          ? pw.ThemeData.withFont(base: notoFont, bold: notoFont)
          : null,
    );

    // Helpers for table cells
    pw.Widget headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
          ),
        );

    pw.Widget bodyCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey900,
            ),
          ),
        );

    pw.Widget sectionHeader(String title) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context ctx) {
          if (ctx.pageNumber > 1) {
            return pw.SizedBox();
          }
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.indigo900, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(
                          logoImage,
                          width: 65,
                          height: 65,
                          fit: pw.BoxFit.contain,
                        ),
                        pw.SizedBox(width: 10),
                      ],
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              companyName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.indigo900,
                              ),
                            ),
                            if (branchName.isNotEmpty)
                              pw.Text(
                                branchName,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'QUOTATION',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      qNumber,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      pw.Text(
                        'Date: $dateStr',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context ctx) => [
          // Customer & Vehicle Details Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'QUOTATION FOR',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.indigo900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        q['customer_name'] ?? 'Customer',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if ((q['customer_phone'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          'Phone: ${q['customer_phone']}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      if ((q['city'] ?? '').toString().isNotEmpty ||
                          (q['state'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          '${q['city'] ?? ''}${((q['city'] ?? '').toString().isNotEmpty && (q['state'] ?? '').toString().isNotEmpty) ? ', ' : ''}${q['state'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      if ((q['tax_number'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          'TRN/Tax No: ${q['tax_number']}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VEHICLE DETAILS',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.indigo900,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        q['vehicle_number'] ?? '',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if ((q['vehicle_type'] ?? '').toString().isNotEmpty ||
                          (q['vehicle_model'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          '${q['vehicle_type'] ?? ''}${(q['vehicle_model'] ?? '').toString().isNotEmpty ? " • ${q['vehicle_model']}" : ""}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                        ),
                      if ((q['engine_number'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          'Engine: ${q['engine_number']}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      if ((q['chassis_number'] ?? '').toString().isNotEmpty)
                        pw.Text(
                          'Chassis: ${q['chassis_number']}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Vehicle Inspection Details ────────────────────────────────────
          if (hasInspection) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.indigo200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VEHICLE INSPECTION DETAILS',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      if (inspectionAt.isNotEmpty)
                        pw.Text(
                          'Inspection Date: ${_formatDateWithTime(inspectionAt)}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 5),

                  // Recorded Damages Table
                  if (damageMarks.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Table(
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.5),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(1.5),
                        3: pw.FlexColumnWidth(2.5),
                      },
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text('Vehicle Part / View', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text('Damage Type', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text('Severity', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text('Remarks', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ),
                          ],
                        ),
                        ...damageMarks.map((dm) {
                          final m = dm is Map ? dm : <String, dynamic>{};
                          final part = (m['part'] ?? 'Part').toString();
                          final view = (m['view'] ?? '').toString();
                          final type = (m['damage_type'] ?? 'Scratch').toString();
                          final sev = (m['severity'] ?? 'Minor').toString();
                          final rem = (m['remarks'] ?? '').toString();

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text('$part ($view)', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey900)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(type, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(sev, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: sev.toLowerCase() == 'severe' ? PdfColors.red800 : (sev.toLowerCase() == 'moderate' ? PdfColors.amber800 : PdfColors.green800))),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(rem.isNotEmpty ? rem : '-', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],

                  // Dynamic Checklist Table
                  if (checklistList.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Table(
                      columnWidths: const {
                        0: pw.FlexColumnWidth(3),
                        1: pw.FlexColumnWidth(1.4),
                        2: pw.FlexColumnWidth(1.6),
                        3: pw.FlexColumnWidth(2),
                      },
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Item / Checkpoint', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Status', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Reading / Value', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Remarks', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                            ),
                          ],
                        ),
                        ...checklistList.map((item) {
                          final status = (item['status'] ?? '').toString();
                          PdfColor badgeColor = PdfColors.grey700;
                          PdfColor badgeBg = PdfColors.grey100;
                          String statusLabel = status.toUpperCase();

                          if (status == 'good' || status == 'pass') {
                            badgeColor = PdfColors.green800;
                            badgeBg = PdfColors.green50;
                            statusLabel = status == 'pass' ? 'PASS' : 'GOOD';
                          } else if (status == 'attention') {
                            badgeColor = PdfColors.amber800;
                            badgeBg = PdfColors.amber50;
                            statusLabel = 'ATTENTION';
                          } else if (status == 'critical' || status == 'fail') {
                            badgeColor = PdfColors.red800;
                            badgeBg = PdfColors.red50;
                            statusLabel = status == 'fail' ? 'FAIL' : 'CRITICAL';
                          }

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(
                                  item['category'].toString().isNotEmpty
                                      ? '${item['category']} · ${item['name']}'
                                      : item['name'].toString(),
                                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: pw.BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: pw.BorderRadius.circular(2),
                                    border: pw.Border.all(color: badgeColor, width: 0.5),
                                  ),
                                  child: pw.Text(
                                    statusLabel,
                                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: badgeColor),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(
                                  item['value'].toString().isNotEmpty ? item['value'].toString() : '-',
                                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(3),
                                child: pw.Text(
                                  item['remarks'].toString().isNotEmpty ? item['remarks'].toString() : '-',
                                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],

                  // Legacy Tyre / Oil details if any
                  if (hasTyre || hasOil || hasBrake || hasAlignment) ...[
                    pw.SizedBox(height: 5),
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (hasTyre && (tyre['pressure'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Tyre Pressure', tyre['pressure'].toString()),
                        if (hasTyre && (tyre['tread_depth'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Tread Depth', tyre['tread_depth'].toString()),
                        if (hasOil && (oil['oil_type'] ?? oil['type'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Oil Type', (oil['oil_type'] ?? oil['type']).toString()),
                        if (hasOil && (oil['brand'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Oil Brand', oil['brand'].toString()),
                        if (hasOil && (oil['grade'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Oil Grade', oil['grade'].toString()),
                        if (hasBrake && (brake['front'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Front Brake', brake['front'].toString()),
                        if (hasBrake && (brake['rear'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Rear Brake', brake['rear'].toString()),
                        if (hasAlignment && (wheelAlignment['remarks'] ?? '').toString().isNotEmpty)
                          _pdfMetricTag('Alignment', wheelAlignment['remarks'].toString()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── 1. Services Table ─────────────────────────────────────────────
          if (serviceRows.isNotEmpty) ...[
            sectionHeader('SERVICES'),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(4),
                2: pw.FixedColumnWidth(35),
                3: pw.FixedColumnWidth(60),
                4: pw.FixedColumnWidth(55),
                5: pw.FixedColumnWidth(65),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  children: [
                    headerCell('#', align: pw.TextAlign.center),
                    headerCell('Service / Issue Particulars'),
                    headerCell('Qty', align: pw.TextAlign.center),
                    headerCell('Rate', align: pw.TextAlign.right),
                    headerCell('Discount', align: pw.TextAlign.right),
                    headerCell('Total', align: pw.TextAlign.right),
                  ],
                ),
                ...serviceRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final s = entry.value;
                  final qty = s['quantity'] as double;
                  final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
                  final rate = s['rate'] as double;
                  final disc = s['discount'] as double;
                  final total = s['total'] as double;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      bodyCell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              s['title'] ?? '',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            if (s['subtitle'] != null)
                              pw.Text(
                                s['subtitle'],
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            if ((s['remarks'] ?? '').toString().isNotEmpty)
                              pw.Text(
                                'Note: ${s['remarks']}',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey600,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      bodyCell(qtyStr, align: pw.TextAlign.center),
                      bodyCell('$currencySymbol${rate.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      bodyCell(disc > 0 ? '$currencySymbol${disc.toStringAsFixed(2)}' : '-', align: pw.TextAlign.right),
                      bodyCell('$currencySymbol${total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ],

          // ── 2. Parts & Accessories Table ──────────────────────────────────
          if (accessoryRows.isNotEmpty) ...[
            sectionHeader('ACCESSORIES & SPARE PARTS'),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(20),
                1: pw.FixedColumnWidth(65),
                2: pw.FlexColumnWidth(4),
                3: pw.FixedColumnWidth(40),
                4: pw.FixedColumnWidth(30),
                5: pw.FixedColumnWidth(55),
                6: pw.FixedColumnWidth(50),
                7: pw.FixedColumnWidth(60),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  children: [
                    headerCell('#', align: pw.TextAlign.center),
                    headerCell('Part No'),
                    headerCell('Part / Accessory Description'),
                    headerCell('Warranty', align: pw.TextAlign.center),
                    headerCell('Qty', align: pw.TextAlign.center),
                    headerCell('Rate', align: pw.TextAlign.right),
                    headerCell('Discount', align: pw.TextAlign.right),
                    headerCell('Total', align: pw.TextAlign.right),
                  ],
                ),
                ...accessoryRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final p = entry.value;
                  final partNo = (p['part_number'] ?? '').toString();
                  final qty = p['quantity'] as double;
                  final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
                  final rate = p['rate'] as double;
                  final disc = p['discount'] as double;
                  final total = p['total'] as double;
                  final warranty = p['warranty']?.toString() ?? '';

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      bodyCell('$idx', align: pw.TextAlign.center),
                      bodyCell(partNo.isNotEmpty ? partNo : '-'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              p['title'] ?? '',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            if ((p['remarks'] ?? '').toString().isNotEmpty)
                              pw.Text(
                                'Note: ${p['remarks']}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                              ),
                          ],
                        ),
                      ),
                      bodyCell(
                        warranty.isNotEmpty && warranty != '0' ? '$warranty yrs' : '-',
                        align: pw.TextAlign.center,
                      ),
                      bodyCell(qtyStr, align: pw.TextAlign.center),
                      bodyCell('$currencySymbol${rate.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      bodyCell(disc > 0 ? '$currencySymbol${disc.toStringAsFixed(2)}' : '-', align: pw.TextAlign.right),
                      bodyCell('$currencySymbol${total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ],

          // ── 3. Labour Charges Table ───────────────────────────────────────
          if (labourRows.isNotEmpty) ...[
            sectionHeader('LABOUR CHARGES'),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(5),
                2: pw.FixedColumnWidth(65),
                3: pw.FixedColumnWidth(60),
                4: pw.FixedColumnWidth(65),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  children: [
                    headerCell('#', align: pw.TextAlign.center),
                    headerCell('Labour Particulars'),
                    headerCell('Cost / Rate', align: pw.TextAlign.right),
                    headerCell('Discount', align: pw.TextAlign.right),
                    headerCell('Total', align: pw.TextAlign.right),
                  ],
                ),
                ...labourRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final l = entry.value;
                  final rate = l['rate'] as double;
                  final disc = l['discount'] as double;
                  final total = l['total'] as double;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      bodyCell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              l['title'] ?? '',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            if ((l['remarks'] ?? '').toString().isNotEmpty)
                              pw.Text(
                                'Note: ${l['remarks']}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                              ),
                          ],
                        ),
                      ),
                      bodyCell('$currencySymbol${rate.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      bodyCell(disc > 0 ? '$currencySymbol${disc.toStringAsFixed(2)}' : '-', align: pw.TextAlign.right),
                      bodyCell('$currencySymbol${total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ],

          // ── 4. Extras Table ───────────────────────────────────────────────
          if (extraRows.isNotEmpty) ...[
            sectionHeader('EXTRAS'),
            pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(4),
                2: pw.FixedColumnWidth(35),
                3: pw.FixedColumnWidth(60),
                4: pw.FixedColumnWidth(55),
                5: pw.FixedColumnWidth(65),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  children: [
                    headerCell('#', align: pw.TextAlign.center),
                    headerCell('Extra Description'),
                    headerCell('Qty', align: pw.TextAlign.center),
                    headerCell('Rate', align: pw.TextAlign.right),
                    headerCell('Discount', align: pw.TextAlign.right),
                    headerCell('Total', align: pw.TextAlign.right),
                  ],
                ),
                ...extraRows.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final ex = entry.value;
                  final qty = ex['quantity'] as double;
                  final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
                  final rate = ex['rate'] as double;
                  final disc = ex['discount'] as double;
                  final total = ex['total'] as double;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      bodyCell('$idx', align: pw.TextAlign.center),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              ex['title'] ?? '',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                            if ((ex['remarks'] ?? '').toString().isNotEmpty)
                              pw.Text(
                                'Note: ${ex['remarks']}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                              ),
                          ],
                        ),
                      ),
                      bodyCell(qtyStr, align: pw.TextAlign.center),
                      bodyCell('$currencySymbol${rate.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      bodyCell(disc > 0 ? '$currencySymbol${disc.toStringAsFixed(2)}' : '-', align: pw.TextAlign.right),
                      bodyCell('$currencySymbol${total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),
          ],

          // ── Notes & Comments ──────────────────────────────────────────────
          if ((q['customer_comments'] ?? '').toString().trim().isNotEmpty ||
              (q['additional_services'] ?? '').toString().trim().isNotEmpty ||
              (q['internal_notes'] ?? '').toString().trim().isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if ((q['customer_comments'] ?? '').toString().trim().isNotEmpty) ...[
                    pw.Text('Comment to client:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.Text(q['customer_comments'].toString(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                  if ((q['additional_services'] ?? '').toString().trim().isNotEmpty) ...[
                    if ((q['customer_comments'] ?? '').toString().trim().isNotEmpty) pw.SizedBox(height: 4),
                    pw.Text('Additional notes:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    pw.Text(q['additional_services'].toString(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 12),

          // ── Financial Summary Box ─────────────────────────────────────────
          if (isGrandTotal) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Column(
                    children: [
                      if (servicesTotal > 0)
                        _pdfSummaryLine('Services Subtotal:', '$currencySymbol${servicesTotal.toStringAsFixed(2)}'),
                      if (accessoriesTotal > 0)
                        _pdfSummaryLine('Parts & Accessories:', '$currencySymbol${accessoriesTotal.toStringAsFixed(2)}'),
                      if (labourTotal > 0)
                        _pdfSummaryLine('Labour Charges:', '$currencySymbol${labourTotal.toStringAsFixed(2)}'),
                      if (extrasTotal > 0)
                        _pdfSummaryLine('Extras:', '$currencySymbol${extrasTotal.toStringAsFixed(2)}'),
                      _pdfSummaryLine('Subtotal:', '$currencySymbol${finalSubtotal.toStringAsFixed(2)}', isBold: true),
                      if (discount > 0)
                        _pdfSummaryLine(
                          (q['discount_type'] == 'percentage' && _parseDouble(q['discount_percentage']) > 0)
                              ? 'Discount (${_parseDouble(q['discount_percentage']).toStringAsFixed(_parseDouble(q['discount_percentage']) % 1 == 0 ? 0 : 1)}%):'
                              : 'Discount:',
                          '-$currencySymbol${discount.toStringAsFixed(2)}',
                          color: PdfColors.green800,
                        ),
                      if (taxAmount > 0)
                        _pdfSummaryLine('Tax ($taxPercent%):', '$currencySymbol${taxAmount.toStringAsFixed(2)}'),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Divider(color: PdfColors.grey400, height: 1),
                      ),
                      _pdfSummaryLine(
                        'GRAND TOTAL:',
                        '$currencySymbol${finalGrandTotal.toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 12,
                        color: PdfColors.indigo900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          pw.SizedBox(height: 14),

          // ── Schedule & Sign-off Section ───────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Schedule metrics row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (inspectionAt.isNotEmpty)
                      _pdfMetricTag('Inspection', _formatDateWithTime(inspectionAt)),
                    if (tentativeDeliveryAt.isNotEmpty)
                      _pdfMetricTag('Tentative Delivery', _formatDateWithTime(tentativeDeliveryAt)),
                    if (daysNeeded.isNotEmpty)
                      _pdfMetricTag('Days Needed', daysNeeded),
                    if (preparedByName.isNotEmpty)
                      _pdfMetricTag('Prepared By', preparedByName),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Dual Signatures (Customer + Authorized Signatory)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Customer Acceptance & Signature
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'I hereby confirm and approve the estimated services, parts, and prices outlined in this quotation.',
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                          ),
                          pw.SizedBox(height: 30),
                          pw.Container(
                            width: 170,
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Customer Signature & Date',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // Workshop Authorized Signatory & Seal
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (sealImage != null) ...[
                          pw.Image(sealImage, width: 65, height: 42, fit: pw.BoxFit.contain),
                          pw.SizedBox(height: 4),
                        ] else ...[
                          pw.SizedBox(height: 42),
                        ],
                        pw.Container(
                          width: 170,
                          height: 1,
                          color: PdfColors.grey400,
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Authorized Signatory',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                        ),
                        if (branchName.isNotEmpty)
                          pw.Text(
                            branchName,
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'Thank you for choosing ${branchName.isNotEmpty ? branchName : companyName}!',
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Powered by Mobiz Technologies FZE | www.mobiztechnologies.com',
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetricTag(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildQuotationShareText() {
    if (_quotation == null) return '';
    final q = _quotation!;
    final companyName =
        context.read<AuthProvider>().companyName ?? ApiService.appName;
    final branchName =
        q['branch_name'] ??
        context.read<AuthProvider>().branchName ??
        'our branch';
    final currencySymbol = this.currencySymbol;
    final qNum = q['quotation_number'] ?? '';
    final rawItems = (q['items'] as List<dynamic>? ?? []);
    final rawExtras = (q['extras'] as List<dynamic>? ?? []);
    final rawReportedIssues = (q['reported_issues'] as List<dynamic>? ?? []);

    final itemLines = <String>[];

    // Services
    if (rawReportedIssues.isNotEmpty) {
      for (final raw in rawReportedIssues) {
        if (raw is Map) {
          final issue = Map<String, dynamic>.from(raw);
          final sName = (issue['service_name'] ?? 'Service').toString();
          final issueText = (issue['issue_text'] ?? '').toString();
          final pricing = issue['pricing'] is Map ? Map<String, dynamic>.from(issue['pricing'] as Map) : null;
          final rate = _parseDouble(pricing?['rate'] ?? issue['rate']);
          final qty = _parseDouble(pricing?['quantity'] ?? issue['quantity'] ?? 1);
          final disc = _parseDouble(pricing?['discount'] ?? issue['discount']);
          final tot = pricing?['total'] != null
              ? _parseDouble(pricing!['total'])
              : ((rate * qty) - disc).clamp(0.0, double.infinity);
          final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);

          String line = "• $sName";
          if (issueText.isNotEmpty) line += " ($issueText)";
          if (qty > 1) line += " x$qtyStr";
          line += ": $currencySymbol${tot.toStringAsFixed(2)}";
          itemLines.add(line);
        }
      }
    }
    // Also include standalone requested services
    for (final raw in rawItems) {
      if (raw is Map) {
        final it = Map<String, dynamic>.from(raw);
        final isAccessory = it['line_type'] == 'accessory' ||
            (it['stock_item_name'] != null && it['stock_item_name'].toString().isNotEmpty);
        if (!isAccessory) {
          final name = it['service_name'] ?? 'Service';
          final rate = _parseDouble(it['rate']);
          final qty = _parseDouble(it['quantity'] ?? it['stock_qty'] ?? 1);
          final disc = _parseDouble(it['discount']);
          final tot = it['total'] != null ? _parseDouble(it['total']) : ((rate * qty) - disc).clamp(0.0, double.infinity);
          final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
          String line = "• $name";
          if (qty > 1) line += " x$qtyStr";
          line += ": $currencySymbol${tot.toStringAsFixed(2)}";
          itemLines.add(line);
        }
      }
    }

    // Accessories
    for (final raw in rawItems) {
      if (raw is Map) {
        final it = Map<String, dynamic>.from(raw);
        final isAccessory = it['line_type'] == 'accessory' ||
            (it['stock_item_name'] != null && it['stock_item_name'].toString().isNotEmpty);
        if (isAccessory) {
          final name = (it['stock_item_name'] ?? it['service_name'] ?? 'Accessory').toString();
          final qty = _parseDouble(it['quantity'] ?? it['stock_qty'] ?? 1);
          final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
          final rate = _parseDouble(it['rate']);
          final disc = _parseDouble(it['discount']);
          final tot = it['total'] != null ? _parseDouble(it['total']) : ((rate * qty) - disc).clamp(0.0, double.infinity);
          itemLines.add("• [Part] $name x$qtyStr: $currencySymbol${tot.toStringAsFixed(2)}");
        }
      }
    }

    // Labour
    for (final raw in rawExtras) {
      if (raw is Map && raw['line_type'] == 'labour') {
        final name = (raw['name'] ?? 'Labour').toString();
        final tot = raw['total'] != null ? _parseDouble(raw['total']) : _parseDouble(raw['price']);
        itemLines.add("• [Labour] $name: $currencySymbol${tot.toStringAsFixed(2)}");
      }
    }

    // Extras
    for (final raw in rawExtras) {
      if (raw is Map && raw['line_type'] != 'labour') {
        final name = (raw['name'] ?? 'Extra').toString();
        final qty = _parseDouble(raw['quantity'] ?? raw['qty'] ?? 1);
        final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
        final tot = raw['total'] != null ? _parseDouble(raw['total']) : _parseDouble(raw['price']);
        itemLines.add("• [Extra] $name x$qtyStr: $currencySymbol${tot.toStringAsFixed(2)}");
      }
    }

    final servicesStr = itemLines.join("\n");
    final subtotal = _parseDouble(q['subtotal']);
    final discount = _parseDouble(q['discount']);
    final taxAmount = _parseDouble(q['tax_amount']);
    final grandTotal = _parseDouble(q['grand_total']);
    final isGrandTotal = (q['is_grand_total'] as bool?) ?? true;

    final buffer = StringBuffer();
    buffer.writeln("Dear ${q['customer_name'] ?? 'Customer'},\n");
    buffer.writeln("Here is your *Quotation $qNum* from $companyName:\n");
    buffer.writeln("*Quotation Details:*");
    if ((q['vehicle_number'] ?? '').toString().isNotEmpty) {
      final vType = (q['vehicle_type'] ?? '').toString();
      final vModel = (q['vehicle_model'] ?? '').toString();
      String vInfo = q['vehicle_number'].toString();
      if (vType.isNotEmpty) vInfo += " · $vType";
      if (vModel.isNotEmpty) vInfo += " · $vModel";
      buffer.writeln("Vehicle: $vInfo");
    }
    if (servicesStr.isNotEmpty) {
      buffer.writeln("\nPricing Breakdown:\n$servicesStr");
    }
    if (q['customer_comments'] != null &&
        q['customer_comments'].toString().trim().isNotEmpty) {
      buffer.writeln("\nNotes: ${q['customer_comments']}");
    }
    if (isGrandTotal) {
      buffer.writeln("\nSubtotal: $currencySymbol${subtotal.toStringAsFixed(2)}");
      if (discount > 0) {
        buffer.writeln("Discount: -$currencySymbol${discount.toStringAsFixed(2)}");
      }
      if (taxAmount > 0) {
        buffer.writeln("Tax: $currencySymbol${taxAmount.toStringAsFixed(2)}");
      }
      buffer.writeln("*Grand Total: $currencySymbol${grandTotal.toStringAsFixed(2)}*");
    }
    final thanksName = branchName.isNotEmpty ? branchName : companyName;
    buffer.writeln("\nThank you for choosing $thanksName!");
    buffer.writeln("Powered by Mobiz Technologies FZE | www.mobiztechnologies.com");

    return buffer.toString();
  }

  Future<void> _shareQuotationPdf(BuildContext context) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final pdfBytes = await _buildQuotationPdfBytes(context);
      if (mounted) nav.pop(); // Dismiss loader

      final qNum = (_quotation?['quotation_number'] ?? 'quotation').replaceAll(
        '/',
        '_',
      );
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$qNum.pdf');
      await file.writeAsBytes(pdfBytes);

      final messageText = _buildQuotationShareText();
      final xFile = XFile(file.path, mimeType: 'application/pdf');

      if (!mounted) return;

      // Show dialog with quotation text + share button
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Color(0xFF000080)),
              SizedBox(width: 8),
              Text(
                'Share Quotation',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quotation details to send with PDF:',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      messageText,
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: messageText));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Text copied to clipboard!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16),
                  label: Text(
                    'Copy Text',
                    style: GoogleFonts.inter(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await Share.shareXFiles(
                  [xFile],
                  text: messageText,
                  subject: 'Quotation $qNum',
                );
              },
              icon: const Icon(Icons.share, size: 16),
              label: Text('Share PDF', style: GoogleFonts.inter()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        if (nav.canPop()) nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Print PDF Document ───────────────────────────────────────────────────
  Future<void> _printQuotationPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pdfBytes = await _buildQuotationPdfBytes(context);
      final qNum = (_quotation?['quotation_number'] ?? 'quotation').replaceAll(
        '/',
        '_',
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '$qNum.pdf',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error printing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Show Share Options Bottom Sheet ───────────────────────────────────────
  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    context.tr('Share Quotation'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: Color(0xFF000080),
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    context.tr('Share Quotation PDF Document'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Shares PDF file along with pre-filled quotation summary text',
                    ),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _shareQuotationPdf(context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(
                      Icons.print_outlined,
                      color: Color(0xFF000080),
                    ),
                  ),
                  title: Text(
                    context.tr('Print Quotation PDF'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('Opens print preview and printer selection'),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _printQuotationPdf(context);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _backToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.tr('Quotation Preview'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_quotation != null &&
              _quotation!['is_accepted'] != true &&
              (_quotation!['job_card_id'] ?? '').toString().isEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: context.tr('Edit quotation'),
              onPressed: _isPipelineActionRunning ? null : _editQuotation,
            ),
          if (_quotation != null && _quotation!['is_accepted'] != true)
            IconButton(
              icon: _isPipelineActionRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              tooltip: context.tr(
                widget.jobWorkflow || _hasPricedItems
                    ? 'Accept quotation'
                    : 'Add a priced item before acceptance',
              ),
              onPressed:
                  _isPipelineActionRunning ||
                      (!widget.jobWorkflow && !_hasPricedItems)
                  ? null
                  : _acceptQuotation,
            ),
          if (_quotation != null &&
              _quotation!['is_accepted'] == true &&
              (widget.jobWorkflow || _hasPricedItems) &&
              (_quotation!['job_card_id'] ?? '').toString().isEmpty)
            IconButton(
              icon: const Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.white,
              ),
              tooltip: context.tr(
                widget.jobWorkflow
                    ? 'Convert to Job Order'
                    : 'Convert to job card',
              ),
              onPressed: _isPipelineActionRunning ? null : _convertToJobCard,
            ),
          if (_quotation != null &&
              (_quotation!['job_card_id'] ?? '').toString().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.assignment_outlined, color: Colors.white),
              tooltip: context.tr('Open job card'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => widget.jobWorkflow
                      ? JobCardCreateScreen(
                          existingJobCardId: _quotation!['job_card_id']
                              .toString(),
                        )
                      : JobCardDetailScreen(
                          jobCardId: _quotation!['job_card_id'].toString(),
                        ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: context.tr('Share PDF'),
            onPressed: _quotation != null
                ? () => _shareQuotationPdf(context)
                : null,
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            tooltip: context.tr('Share Options'),
            onPressed: _quotation != null
                ? () => _showShareOptions(context)
                : null,
          ),
          if (_quotation != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: context.tr('Delete quotation'),
              onPressed: _isPipelineActionRunning ? null : _deleteQuotation,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
            )
          : _quotation == null
          ? Center(child: Text(context.tr('Quotation not found')))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.jobWorkflow ? 1100 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Paper Preview Card
                      _buildQuotationCard(),
                      const SizedBox(height: 24),

                      // Action Buttons: Accept, Share & Back to Dashboard
                      if (_quotation != null && _quotation!['is_accepted'] != true) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isPipelineActionRunning ||
                                    (!widget.jobWorkflow && !_hasPricedItems)
                                ? null
                                : _acceptQuotation,
                            icon: _isPipelineActionRunning
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, color: Colors.white),
                            label: Text(
                              context.tr('Accept Quotation'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareQuotationPdf(context),
                              icon: Icon(Icons.share, color: Colors.white),
                              label: Text(
                                context.tr('Share Quotation'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _backToDashboard,
                              icon: Icon(
                                Icons.home_outlined,
                                color: Color(0xFF000080),
                              ),
                              label: Text(
                                context.tr('Back to Dashboard'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF000080),
                                side: const BorderSide(
                                  color: Color(0xFF000080),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQuotationCard() {
    final q = _quotation!;
    final items = (q['items'] as List<dynamic>? ?? []);
    final extras = (q['extras'] as List<dynamic>? ?? []);

    final branchLogoUrl = (q['branch_logo'] ?? '').toString();
    final companyLogoUrl = (q['company_logo'] ?? '').toString();
    final authCompanyLogo = (context.watch<AuthProvider>().companyLogo ?? '')
        .toString();
    final logoUrl = branchLogoUrl.isNotEmpty
        ? branchLogoUrl
        : (companyLogoUrl.isNotEmpty ? companyLogoUrl : authCompanyLogo);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & Quotation Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (logoUrl.isNotEmpty) ...[
                    Image.network(
                      logoUrl,
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.read<AuthProvider>().companyName ??
                            ApiService.appName,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF000080),
                        ),
                      ),
                      if (q['branch_name'] != null &&
                          q['branch_name'].toString().isNotEmpty)
                        Text(
                          q['branch_name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF000080).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  q['quotation_number'] ?? '',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '${context.tr("Date")}: ${_formatDateWithTime((q['created_at'] ?? q['date'] ?? '').toString())}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ),
          ),
          if ((q['job_card_id'] ?? '').toString().isNotEmpty ||
              (q['job_card_number'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final jobBtn = ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => widget.jobWorkflow
                            ? JobCardCreateScreen(
                                existingJobCardId:
                                    q['job_card_id'].toString(),
                              )
                            : JobCardDetailScreen(
                                jobCardId: q['job_card_id'].toString(),
                              ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.tr('View Job Order'),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('Linked Job Order'),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  Text(
                                    (q['job_card_number'] ?? '').toString().isNotEmpty
                                        ? q['job_card_number'].toString()
                                        : 'Job Order #${q['job_card_id']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: jobBtn,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Linked Job Order'),
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                            Text(
                              (q['job_card_number'] ?? '').toString().isNotEmpty
                                  ? q['job_card_number'].toString()
                                  : 'Job Order #${q['job_card_id']}',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E3A8A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      jobBtn,
                    ],
                  );
                },
              ),
            ),
          ],
          Divider(height: 28),

          // Customer & Vehicle Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Customer & Vehicle Information'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: Color(0xFF000080),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      q['customer_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      q['customer_phone'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${q['vehicle_number'] ?? ''} ${(q['vehicle_type'] != null && q['vehicle_type'].toString().isNotEmpty) ? "· ${q['vehicle_type']}" : ""} ${(q['vehicle_model'] != null && q['vehicle_model'].toString().isNotEmpty) ? "· ${q['vehicle_model']}" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if ((q['reported_issues'] as List<dynamic>? ?? []).isNotEmpty) ...[
            Text(
              context.tr('Reported Issues'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 10),
            ...(q['reported_issues'] as List<dynamic>).map((rawIssue) {
              final issue = Map<String, dynamic>.from(rawIssue as Map);
              final photos = List<dynamic>.from(issue['photos'] ?? []);
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${issue['category_name'] ?? ''} · ${issue['service_name'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000080),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(issue['issue_text']?.toString() ?? ''),
                    if (photos.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: photos
                            .map(
                              (photo) => ClipRRect(
                                borderRadius: BorderRadius.circular(6.r),
                                child: Image.network(
                                  photo.toString(),
                                  width: 76.w,
                                  height: 76.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 76.w,
                                    height: 76.h,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // Items Table
          if (items.isNotEmpty) ...[
            Text(
              context.tr('Services & Stock Items'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 10),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        context.tr('Service / Stock'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        context.tr('Qty'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        context.tr('Warranty'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        context.tr('Total'),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                ...items.map((it) {
                  final itemQty = _parseDouble(
                    it['quantity'] ?? it['stock_qty'] ?? 1,
                  );
                  final qtyStr = itemQty % 1 == 0
                      ? itemQty.toInt().toString()
                      : itemQty.toStringAsFixed(2);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it['service_name'] ?? '',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                            if (it['stock_item_name'] != null &&
                                it['stock_item_name'].toString().isNotEmpty)
                              Text(
                                'Stock: ${it['stock_item_name']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (it['free_topup'] != null &&
                                it['free_topup'].toString().isNotEmpty)
                              Text(
                                'Topup: ${it['free_topup']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            if (it['remarks'] != null &&
                                it['remarks'].toString().trim().isNotEmpty)
                              Text(
                                'Remarks: ${it['remarks']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            Text(
                              'Rate: $currencySymbol${_parseDouble(it['rate']).toStringAsFixed(2)} · Discount: $currencySymbol${_parseDouble(it['discount']).toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          qtyStr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '${it['warranty_years']} yrs',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '$currencySymbol${_parseDouble(it['total'] ?? (_parseDouble(it['rate']) * itemQty - _parseDouble(it['discount']))).clamp(0, double.infinity).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Particulars Table
          if (extras.isNotEmpty) ...[
            Text(
              context.tr('Particulars'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.4),
                  3: FlexColumnWidth(1.4),
                  4: FlexColumnWidth(1.4),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.tr('Particular'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.tr('Qty'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.tr('Rate'),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.tr('Discount'),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          context.tr('Total'),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...extras.map((ex) {
                    final exQty = _parseDouble(
                      ex['quantity'] ?? ex['qty'] ?? 1,
                    );
                    final qtyStr = exQty % 1 == 0
                        ? exQty.toInt().toString()
                        : exQty.toStringAsFixed(2);
                    final remarks = (ex['remarks'] ?? '').toString().trim();
                    final price = _parseDouble(ex['price']);
                    final disc = _parseDouble(ex['discount']);
                    final discType = (ex['discount_type'] ?? 'amount')
                        .toString();
                    final discPct = _parseDouble(ex['discount_percentage']);
                    final tot = ex['total'] != null
                        ? _parseDouble(ex['total'])
                        : ((price * exQty) - disc).clamp(0.0, double.infinity);

                    String discText = '-';
                    if (disc > 0) {
                      if (discType == 'percentage') {
                        final pctStr = discPct % 1 == 0
                            ? discPct.toInt().toString()
                            : discPct.toStringAsFixed(1);
                        discText =
                            '$pctStr% (-$currencySymbol${disc.toStringAsFixed(2)})';
                      } else {
                        discText = '-$currencySymbol${disc.toStringAsFixed(2)}';
                      }
                    }

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex['line_type'] == 'labour'
                                    ? 'Labour: ${ex['name'] ?? ''}'
                                    : ex['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (remarks.isNotEmpty)
                                Text(
                                  'Note: $remarks',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            qtyStr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12.sp),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '$currencySymbol${price.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(fontSize: 12.sp),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            discText,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: disc > 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                              fontWeight: disc > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '$currencySymbol${tot.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Additional Service Notes & Days Needed
          if (q['additional_services'] != null &&
              q['additional_services'].toString().trim().isNotEmpty) ...[
            Text(
              context.tr('Additional Service Notes'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              q['additional_services'],
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
          ],
          if (q['additional_days_needed'] != null &&
              _parseDouble(q['additional_days_needed']) > 0) ...[
            Row(
              children: [
                Text(
                  '${context.tr("Days Needed")}: ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  '${q['additional_days_needed']} days',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Color(0xFF000080),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],

          if (widget.jobWorkflow ||
              (q['inspection_at'] ?? '').toString().isNotEmpty ||
              (q['tentative_delivery_at'] ?? '').toString().isNotEmpty ||
              (q['customer_comments'] ?? '').toString().trim().isNotEmpty ||
              (q['internal_notes'] ?? '').toString().trim().isNotEmpty ||
              (q['company_seal_url'] ?? '').toString().isNotEmpty ||
              (q['prepared_by_name'] ?? '').toString().isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Schedule & Sign-off',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            if ((q['inspection_at'] ?? '').toString().isNotEmpty)
              _summaryRow(
                'Inspection',
                _formatDateWithTime(q['inspection_at'].toString()),
              ),
            if ((q['days_needed'] ?? '').toString().isNotEmpty ||
                (q['additional_days_needed'] != null && q['additional_days_needed'] != 0) ||
                (q['tentative_delivery_at'] ?? '').toString().isNotEmpty)
              _summaryRow(
                'Days Needed',
                (q['days_needed'] ?? '').toString().isNotEmpty
                    ? q['days_needed'].toString()
                    : ((q['additional_days_needed'] != null && q['additional_days_needed'] != 0)
                        ? '${q['additional_days_needed']} Days'
                        : _formatDateWithTime(q['tentative_delivery_at'].toString())),
              ),
            if ((q['prepared_by_name'] ?? '').toString().isNotEmpty)
              _summaryRow('Prepared by', q['prepared_by_name'].toString()),
            if ((q['customer_comments'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Comment to client',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text(q['customer_comments'].toString()),
            ],
            if ((q['internal_notes'] ?? '').toString().trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                'Internal notes',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange.shade700,
                ),
              ),
              Text(q['internal_notes'].toString()),
            ],
            if ((q['company_seal_url'] ?? '').toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Image.network(
                  q['company_seal_url'].toString(),
                  height: 76.h,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            Container(
              height: 75.h,
              margin: EdgeInsets.only(top: 12.h),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade500)),
              ),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text('Signature'),
              ),
            ),
          ],

          if ((q['is_grand_total'] as bool?) ?? true) ...[
            const Divider(height: 24),

            // Financial Summary
            _summaryRow(
              context.tr('Subtotal'),
              '$currencySymbol${_parseDouble(q["subtotal"]).toStringAsFixed(2)}',
            ),
            if (_parseDouble(q['discount']) > 0) ...[
              const SizedBox(height: 6),
              _summaryRow(
                (q['discount_type'] == 'percentage' &&
                        _parseDouble(q['discount_percentage']) > 0)
                    ? '${context.tr("Discount")} (${_parseDouble(q['discount_percentage']).toStringAsFixed(_parseDouble(q['discount_percentage']) % 1 == 0 ? 0 : 2)}%)'
                    : context.tr('Discount'),
                '-$currencySymbol${_parseDouble(q["discount"]).toStringAsFixed(2)}',
              ),
            ],
            if (_parseDouble(q['tax_amount']) > 0) ...[
              const SizedBox(height: 6),
              _summaryRow(
                '${context.tr("Tax")} (${q["tax_percentage"]}%)',
                '$currencySymbol${_parseDouble(q["tax_amount"]).toStringAsFixed(2)}',
              ),
            ],
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Grand Total'),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF000080),
                  ),
                ),
                Text(
                  '$currencySymbol${_parseDouble(q["grand_total"]).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF000080),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
