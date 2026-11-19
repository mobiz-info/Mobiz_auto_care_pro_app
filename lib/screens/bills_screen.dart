import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../config/country_config.dart';
import '../services/api_service.dart';
import 'invoice_create_screen.dart';
import 'package:http/http.dart' as http;

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final ValueNotifier<DateTime?> _fromDateNotifier;
  late final ValueNotifier<DateTime?> _toDateNotifier;
  late final ValueNotifier<String?> _paymentModeNotifier;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _fromDateNotifier = ValueNotifier(today);
    _toDateNotifier = ValueNotifier(today);
    _paymentModeNotifier = ValueNotifier(null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInvoices(context);
    });
  }

  @override
  void dispose() {
    _fromDateNotifier.dispose();
    _toDateNotifier.dispose();
    _paymentModeNotifier.dispose();
    super.dispose();
  }


  String currencySymbol(BuildContext context) {
    try {
      return context.read<AuthProvider>().currencySymbol;
    } catch (_) {
      return CountryConfig.currencySymbol;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(BuildContext context, DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthName(context, d.month)} ${d.year}';

  String _monthName(BuildContext context, int m) => context.tr(
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1]);

  String _formatDisplayDate(BuildContext context, String raw) {
    try {
      final d = DateTime.parse(raw);
      return _displayDate(context, d);
    } catch (_) {
      return raw;
    }
  }

  String _fmt(dynamic value) {
    final d = (value is num)
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Future<void> _fetchInvoices(BuildContext context) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    context.read<InvoiceProvider>().fetchInvoices(
      token,
      fromDate: _fromDateNotifier.value != null ? _formatDate(_fromDateNotifier.value!) : null,
      toDate: _toDateNotifier.value != null ? _formatDate(_toDateNotifier.value!) : null,
      paymentMode: _paymentModeNotifier.value,
    );
  }

  void _openCreditNoteModal(BuildContext context, Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreditNoteBottomSheet(
        inv: inv,
        currencySymbol: currencySymbol(context),
        onSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(msg)),
              backgroundColor: Colors.green.shade700,
            ),
          );
          _fetchInvoices(context);
        },
      ),
    );
  }

  Future<void> _deleteInvoice(BuildContext context, Map<String, dynamic> inv) async {
    final invoiceNumber = inv['invoice_number'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(context.tr('Delete Invoice'), style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          context.tr('Delete invoice $invoiceNumber?\n\nThis will also remove all linked receipts.\n\nThis action cannot be undone.'),
          style: GoogleFonts.inter(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel'), style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: Text(context.tr('Delete'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final res = await ApiService.deleteInvoice(inv['id'], token);
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Invoice $invoiceNumber deleted successfully')),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _fetchInvoices(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(res['message'] ?? 'Failed to delete invoice')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Error: $e')), backgroundColor: Colors.red.shade600),
      );
    }
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final initial = isFrom ? (_fromDateNotifier.value ?? DateTime.now()) : (_toDateNotifier.value ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: Color(0xFF000080), onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    if (isFrom) {
      _fromDateNotifier.value = picked;
      if (_toDateNotifier.value != null && _toDateNotifier.value!.isBefore(picked)) {
        _toDateNotifier.value = picked;
      }
    } else {
      _toDateNotifier.value = picked;
      if (_fromDateNotifier.value != null && _fromDateNotifier.value!.isAfter(picked)) {
        _fromDateNotifier.value = picked;
      }
    }
    _fetchInvoices(context);
  }

  // ── PDF Generation & Share/Download/Print ──────────────────────────
  // ── PDF Generation & Share/Download/Print ──────────────────────────
  Future<Uint8List> _getInvoicePdfBytes(BuildContext context, Map<String, dynamic> inv) async {
    final invoiceNumber = inv['invoice_number'] as String? ?? '';
    final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final pdfUrl = "$baseUrl/media/invoices/invoice-$cleanInvoiceNo.pdf?t=${DateTime.now().millisecondsSinceEpoch}";
    try {
      final response = await http.get(
        Uri.parse(pdfUrl),
        headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}

    final invId = inv['id']?.toString() ?? '';
    if (invId.isNotEmpty) {
      try {
        final directUrl = "$baseUrl/invoices/$invId/pdf/?t=${DateTime.now().millisecondsSinceEpoch}";
        final response = await http.get(
          Uri.parse(directUrl),
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }

    final localPdf = await _generateInvoicePdf(context, inv);
    return localPdf.save();
  }

  Future<pw.Document> _generateInvoicePdf(BuildContext context, Map<String, dynamic> inv) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoFont = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      title: inv['invoice_number']?.toString() ?? 'Invoice',
      theme: pw.ThemeData.withFont(
        base: notoFont,
        bold: notoFont,
      ),
    );
    final services = inv['services'] as List<dynamic>? ?? [];
    final tradingItems = inv['trading_items'] as List<dynamic>? ?? [];
    final allItems = <Map<String, dynamic>>[];
    for (final s in services) {
      final qty = _toDouble(s['qty'], 1.0);
      final rate = _toDouble(s['rate'], 0.0);
      final net = _toDouble(s['net_taxable_amount'], qty * rate);
      final qtyStr = qty > 1 ? qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1) : '1';
      allItems.add({
        'name': s['name'] ?? '',
        'qty': qtyStr,
        'rate': _fmt(rate),
        'net': _fmt(net),
        'raw_rate': rate,
      });
    }
    for (final t in tradingItems) {
      if (t['is_operational'] == true) continue;
      final qty = _toDouble(t['qty'], 1.0);
      final rate = _toDouble(t['rate'], 0.0);
      final disc = _toDouble(t['discount'], 0.0);
      final net = (qty * rate) - disc;
      final qtyStr = qty > 1 ? qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1) : '1';
      allItems.add({
        'name': t['item_name'] ?? 'Stock Item',
        'qty': qtyStr,
        'rate': _fmt(rate),
        'net': _fmt(net),
        'raw_rate': rate,
      });
    }
    // Sort services/items in PDF from price high to low
    allItems.sort((a, b) {
      final rateA = _toDouble(a['raw_rate'], 0.0);
      final rateB = _toDouble(b['raw_rate'], 0.0);
      return rateB.compareTo(rateA);
    });

    pw.ImageProvider? logoImage;
    try {
      final logoUrl = inv['company_logo'] as String? ?? '';
      if (logoUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      }
    } catch (_) {}

    if (logoImage == null) {
      try {
        final logoData = await rootBundle.load('assets/icons/mobiz_autocare_mark_blue.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}
    }

    pw.ImageProvider? sealImage;
    try {
      final sealUrl = (inv['company_seal'] ?? inv['company_seal_url']) as String? ?? '';
      if (sealUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(sealUrl));
        if (response.statusCode == 200) {
          sealImage = pw.MemoryImage(response.bodyBytes);
        }
      }
    } catch (_) {}

    final String invBranch = inv['branch']?.toString() ?? '';
    final String authBranch = context.read<AuthProvider>().branchName ?? '';
    final String branchName = invBranch.isNotEmpty
        ? invBranch
        : (authBranch.isNotEmpty ? authBranch : 'our service');

    final companyName = context.read<AuthProvider>().companyName ?? 'Mobiz Autocare Pro';
    final branchAddress = inv['branch_address']?.toString() ?? '';
    final branchPhone = inv['branch_phone']?.toString() ?? '';
    final branchEmail = inv['branch_email']?.toString() ?? '';
    final branchGst = inv['branch_gst']?.toString() ?? '';
    final dateStr = inv['date']?.toString() ?? '';
    final customisation = (inv['customisation'] as Map<String, dynamic>?) ?? {};
    final String nonTaxTitle = (customisation['non_tax_title'] ?? 'PROFORMA INVOICE').toString().trim();
    final bool showVehicleNumber = customisation['show_vehicle_number'] != false;
    final bool showVehicleMake = customisation['show_vehicle_make'] != false;
    final bool showVehicleModel = customisation['show_vehicle_model'] != false;
    final bool showVehicleSegment = customisation['show_vehicle_segment'] != false;
    final bool showVehicleType = customisation['show_vehicle_type'] != false;
    final bool showVehicleColor = customisation['show_vehicle_color'] != false;
    final bool showVehicleFuelType = customisation['show_vehicle_fuel_type'] != false;
    final bool showVehicleWheelType = customisation['show_vehicle_wheel_type'] != false;
    final bool showVehicleEmissionStd = customisation['show_vehicle_emission_std'] != false;

    final String rawCompanyTrn = (inv['company_trn'] ?? inv['branch_gst'] ?? branchGst).toString().trim();
    final String companyTrn = rawCompanyTrn.replaceAll(RegExp(r'^(TRN\s*:\s*|TRN\s*)', caseSensitive: false), '').trim();
    final String cleanBranchAddress = companyTrn.isNotEmpty
        ? branchAddress
            .split('\n')
            .where((line) => !RegExp(r'\bTRN\b|\bGSTIN?\b', caseSensitive: false).hasMatch(line))
            .join('\n')
            .trim()
        : branchAddress;
    final String custTrn = (inv['customer']?['tax_number'] ?? inv['customer']?['tin_number'] ?? inv['customer_tax_number'] ?? inv['customer_tin_number'] ?? '').toString().trim();

    String paymentMode = (inv['payment_mode'] ?? '').toString().trim();
    if (paymentMode.isEmpty) {
      if (inv['invoice_type'] == 'creditinvoice') {
        paymentMode = 'Credit';
      } else if (inv['invoice_type'] == 'cashinvoice') {
        paymentMode = 'Cash';
      }
    } else {
      paymentMode = paymentMode.replaceAll('_', ' ');
      paymentMode = paymentMode.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }

    final symbol = currencySymbol(context);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) ...[
                      pw.Image(logoImage, width: 85, height: 85, fit: pw.BoxFit.contain),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(companyName.toUpperCase(),
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                          pw.Text(branchName,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                          if (cleanBranchAddress.isNotEmpty)
                            pw.Text(cleanBranchAddress, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchPhone.isNotEmpty)
                            pw.Text("Phone: $branchPhone", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchEmail.isNotEmpty)
                            pw.Text("Email: $branchEmail", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchGst.isNotEmpty && companyTrn.isEmpty)
                            pw.Text("GSTIN: $branchGst", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      (double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0) > 0
                          ? 'TAX INVOICE'
                          : (nonTaxTitle.isNotEmpty ? nonTaxTitle : 'PROFORMA INVOICE'),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  if (companyTrn.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('TRN: $companyTrn',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  ],
                  pw.SizedBox(height: 3),
                  pw.Text(inv['invoice_number'],
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  pw.Text(inv['invoice_type'] == 'creditinvoice' ? 'Credit Invoice' : 'Cash Invoice',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  if (dateStr.isNotEmpty)
                    pw.Text(_formatDisplayDate(context, dateStr), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Divider(height: 14),

          // Customer & Vehicle
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                  pw.SizedBox(height: 3),
                  pw.Text(inv['customer']?['name'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  if ((inv['customer']?['phone'] ?? '').toString().isNotEmpty)
                    pw.Text(inv['customer']['phone'].toString(), style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                  if ((inv['customer']?['address'] ?? '').toString().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, right: 10),
                      child: pw.Text(inv['customer']['address'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                    ),
                  if (custTrn.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text("TRN: $custTrn", style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold)),
                    ),
                ]),
              ),
              pw.SizedBox(width: 16),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('VEHICLE', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
                pw.SizedBox(height: 3),
                if (showVehicleNumber && (inv['vehicle']?['number'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']?['number'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (showVehicleMake || showVehicleModel) ...[
                  pw.Text(
                    [
                      if (showVehicleMake && (inv['vehicle']?['make'] ?? '').toString().isNotEmpty) inv['vehicle']['make'].toString(),
                      if (showVehicleModel && (inv['vehicle']?['model'] ?? '').toString().isNotEmpty) inv['vehicle']['model'].toString(),
                    ].join(' '),
                    style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                  ),
                ],
                if (showVehicleType && (inv['vehicle']?['type'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['type'].toString(), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (showVehicleSegment && (inv['vehicle']?['segment'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['segment'].toString(), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (showVehicleColor && (inv['vehicle']?['color'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['color'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleFuelType && (inv['vehicle']?['fuel_type'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['fuel_type'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleWheelType && (inv['vehicle']?['wheel_type'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['wheel_type'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleEmissionStd && (inv['vehicle']?['emission_standard'] ?? '').toString().isNotEmpty)
                  pw.Text(inv['vehicle']['emission_standard'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
              ]),
            ],
          ),
          pw.SizedBox(height: 12),

          // Services table
          pw.Text('SERVICES', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500)),
          pw.SizedBox(height: 4),
          pw.Table.fromTextArray(
            headers: ['Service / Item', 'Qty', 'Rate ($symbol)', 'Amount ($symbol)'],
            data: allItems.map((item) => [
              item['name'] ?? '',
              item['qty'] ?? '1',
              item['rate'] ?? '',
              item['net'] ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            cellHeight: 22,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 10),

          // Totals
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Subtotal:  $symbol${_fmt(inv['subtotal'])}', style: pw.TextStyle(fontSize: 9.5)),
              if ((double.tryParse(inv['discount']?.toString() ?? '0') ?? 0) > 0)
                pw.Text('Discount:  -$symbol${_fmt(inv['discount'])}', style: pw.TextStyle(fontSize: 9.5, color: PdfColors.green700)),
              pw.Text('Tax:       $symbol${_fmt(inv['tax_amount'])}', style: pw.TextStyle(fontSize: 9.5)),
              if (paymentMode.isNotEmpty)
                pw.Text('Payment Mode:  $paymentMode', style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
              pw.Container(width: 160, child: pw.Divider()),
              pw.Text('Total:     $symbol${_fmt(inv['total'])}',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 3),
              pw.Text('Collected: $symbol${_fmt(inv['amount_collected'])}',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.green700)),
            ]),
          ),
          // Remarks / Notes
          if ((inv['remarks']?.toString() ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.indigo900, width: 3),
                  top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('REMARKS / NOTES',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                          letterSpacing: 0.5)),
                  pw.SizedBox(height: 3),
                  pw.Text(inv['remarks'].toString().trim(),
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                ],
              ),
            ),
          ],
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Thank you for choosing $branchName',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 3),
                  pw.Text('Powered by Mobiz Technologies',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey500)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (sealImage != null) ...[
                    pw.Image(sealImage, width: 95, height: 95, fit: pw.BoxFit.contain),
                    pw.SizedBox(height: 4),
                  ],
                  pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 2),
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    ));
    return pdf;
  }

  String _getCleanedWhatsAppNumber(Map<String, dynamic> customer) {
    String phone = (customer['whatsapp_number']?.toString().isNotEmpty == true)
        ? customer['whatsapp_number'].toString()
        : (customer['phone']?.toString() ?? '');
    
    return CountryConfig.formatPhoneForWhatsapp(phone);
  }


  void _shareInvoice(BuildContext context, Map<String, dynamic> inv) {
    _showShareOptions(context, inv);
  }

  Future<void> _shareViaWhatsApp(BuildContext context, Map<String, dynamic> inv) async {
    try {
      final token = context.read<AuthProvider>().token;
      final invoiceId = inv['id']?.toString() ?? '';

      if (token != null && invoiceId.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF000080)),
            ),
          ),
        );

        try {
          final res = await ApiService.sendInvoiceWhatsApp(invoiceId, token);
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loading dialog
          }

          if (res['success'] == true && res['action'] == 'auto') {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('Invoice sent automatically via WhatsApp API')),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        } catch (_) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loading dialog
          }
        }
      }

      final customer = inv['customer'] as Map<String, dynamic>? ?? {};
      final vehicle = inv['vehicle'] as Map<String, dynamic>? ?? {};
      final services = inv['services'] as List<dynamic>? ?? [];
      final symbol = currencySymbol(context);
      final total = _fmt(inv['total']);
      final collected = _fmt(inv['amount_collected']);
      final invoiceNumber = inv['invoice_number'] as String? ?? '';

      final servicesStr = services.map((s) {
        final qty = _toDouble(s['qty'], 1.0);
        final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
        return "- ${s['name']}$qtyStr: $symbol${_fmt(s['rate'])}";
      }).join("\n");

      final branchName = inv['branch']?.toString() ?? context.read<AuthProvider>().branchName ?? 'our branch';
      final companyName = context.read<AuthProvider>().companyName ?? 'Mobiz Autocare Pro';

      final doubleTot = double.tryParse(total.toString()) ?? 0.0;
      final doubleColl = double.tryParse(collected.toString()) ?? 0.0;
      final balanceVal = doubleTot - doubleColl;

      final bool hasTax = (double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0) > 0;
      final invTypeLower = hasTax ? context.tr('tax invoice') : context.tr('proforma invoice');
      final invTypeTitle = hasTax ? context.tr('Tax Invoice Details') : context.tr('Proforma Invoice Details');

      final messageText =
          "${context.tr('Dear')} ${customer['name']},\n\n"
          "${context.tr('Your')} $invTypeLower *$invoiceNumber* ${context.tr('has been generated successfully at')} $companyName.\n\n"
          "*$invTypeTitle:*\n"
          "${context.tr('Vehicle')}: ${vehicle['number'] ?? vehicle['no'] ?? ''}\n"
          "${context.tr('Services')}:\n$servicesStr\n"
          "${context.tr('Total')}: $symbol$total\n"
          "${context.tr('Paid')}: $symbol$collected\n"
          "${context.tr('Balance')}: $symbol${_fmt(balanceVal)}\n\n"
          "${context.tr('Thank you for choosing')} $branchName!\n"
          "${context.tr('Powered by')} Mobiz Technologies";

      final cleanedPhone = _getCleanedWhatsAppNumber(customer);
      if (cleanedPhone.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('No phone number available for this customer')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final whatsappUrl = Uri.parse(
        "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(messageText)}"
      );

      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error launching WhatsApp: $e')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sharePdfFile(BuildContext context, Map<String, dynamic> inv) async {
    try {
      final customer = inv['customer'] as Map<String, dynamic>? ?? {};
      final vehicle = inv['vehicle'] as Map<String, dynamic>? ?? {};
      final services = inv['services'] as List<dynamic>? ?? [];
      final symbol = currencySymbol(context);
      final total = _fmt(inv['total']);
      final collected = _fmt(inv['amount_collected']);
      final invoiceNumber = inv['invoice_number'] as String? ?? '';

      final servicesStr = services.map((s) {
        final qty = _toDouble(s['qty'], 1.0);
        final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
        return "- ${s['name']}$qtyStr: $symbol${_fmt(s['rate'])}";
      }).join("\n");

      final branchName = inv['branch']?.toString() ?? context.read<AuthProvider>().branchName ?? 'our branch';
      final companyName = context.read<AuthProvider>().companyName ?? 'Mobiz Autocare Pro';

      final doubleTot = double.tryParse(total.toString()) ?? 0.0;
      final doubleColl = double.tryParse(collected.toString()) ?? 0.0;
      final balanceVal = doubleTot - doubleColl;

      final messageText = 
          "${context.tr('Dear')} ${customer['name']},\n\n"
          "${context.tr('Your proforma invoice')} *$invoiceNumber* ${context.tr('has been generated successfully at')} $companyName.\n\n"
          "*${context.tr('Proforma Invoice Details')}:*\n"
          "${context.tr('Vehicle')}: ${vehicle['number'] ?? vehicle['no'] ?? ''}\n"
          "${context.tr('Services')}:\n$servicesStr\n"
          "${context.tr('Total')}: $symbol$total\n"
          "${context.tr('Paid')}: $symbol$collected\n"
          "${context.tr('Balance')}: $symbol${_fmt(balanceVal)}\n\n"
          "${context.tr('Thank you for choosing')} $branchName!\n"
          "${context.tr('Powered by')} Mobiz Technologies";

      final pdfBytes = await _getInvoicePdfBytes(context, inv);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${inv['invoice_number'].replaceAll('/', '_')}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: messageText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error: $e')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showShareOptions(BuildContext context, Map<String, dynamic> inv) {
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
                    bc.tr('Share Invoice'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: Color(0xFF000080),
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                  ),
                  title: Text(
                    bc.tr('Share via WhatsApp (Direct Chat)'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    bc.tr('Opens chat with pre-filled summary'),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _shareViaWhatsApp(context, inv);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                  ),
                  title: Text(
                    bc.tr('Share PDF Document'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    bc.tr('Generates PDF and opens sharing menu'),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _sharePdfFile(context, inv);
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

  Future<void> _downloadInvoice(BuildContext context, Map<String, dynamic> inv) async {
    try {
      final pdfBytes = await _getInvoicePdfBytes(context, inv);
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        throw Exception(context.tr('Could not find download directory'));
      }

      final filename = '${inv['invoice_number'].replaceAll('/', '_')}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('Invoice downloaded successfully')}: $filename'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('Failed to download invoice')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context, Map<String, dynamic> inv) async {
    try {
      final pdfBytes = await _getInvoicePdfBytes(context, inv);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${inv['invoice_number'].replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('Failed to print invoice')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final invoices = invoiceProvider.invoices;
    final isLoading = invoiceProvider.isLoadingList;
    final errorMessage = invoiceProvider.listErrorMessage ?? '';
    final symbol = currencySymbol(context);

    final totalAmount = invoices.fold<double>(
      0, (sum, inv) => sum + (double.tryParse(inv['total'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(context.tr('Bills'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => _fetchInvoices(context)),
        ],
      ),
      body: Column(
        children: [
          // Date Filter
          Container(
            color: const Color(0xFF000080),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<DateTime?>(
                        valueListenable: _fromDateNotifier,
                        builder: (context, fromDate, child) {
                          return _datePicker(context, label: 'From', date: fromDate, isFrom: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<DateTime?>(
                        valueListenable: _toDateNotifier,
                        builder: (context, toDate, child) {
                          return _datePicker(context, label: 'To', date: toDate, isFrom: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _fetchInvoices(context),
                      child: Container(
                        height: 48, width: 48,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.search, color: Color(0xFF000080)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _paymentModeDropdown(context),
              ],
            ),
          ),

          // Summary bar
          if (!isLoading && invoices.isNotEmpty)
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.receipt_long, size: 16, color: Colors.grey.shade500),
                    SizedBox(width: 8),
                    Text(context.tr('${invoices.length} invoice${invoices.length == 1 ? '' : 's'}'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13.sp)),
                  ]),
                  Text(context.tr('Total: $symbol${totalAmount.toStringAsFixed(2)}'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Color(0xFF000080), fontSize: 14.sp)),
                ],
              ),
            ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? _buildError(context, errorMessage)
                    : invoices.isEmpty
                        ? _buildEmpty(context)
                        : RefreshIndicator(
                            onRefresh: () => _fetchInvoices(context),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: invoices.length,
                              itemBuilder: (ctx, i) => _invoiceCard(ctx, invoices[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker(BuildContext context, {required String label, required DateTime? date, required bool isFrom}) {
    return GestureDetector(
      onTap: () => _pickDate(context, isFrom: isFrom),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.calendar_today, size: 15, color: Color(0xFF000080)),
          SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              Text(date != null ? _displayDate(context, date) : 'Select',
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Color(0xFF1e293b))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _invoiceCard(BuildContext context, Map<String, dynamic> inv) {
    final services = inv['services'] as List<dynamic>? ?? [];
    final total = double.tryParse(inv['total'].toString()) ?? 0;
    final collected = double.tryParse(inv['amount_collected'].toString()) ?? 0;
    final creditNoteAmount = double.tryParse(inv['credit_note_amount']?.toString() ?? '0') ?? 0;
    final remainingOutstanding = (total - collected - creditNoteAmount).clamp(0.0, double.infinity);
    final isFullyPaid = (collected + creditNoteAmount) >= (total - 0.001);
    final symbol = currencySymbol(context);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF000080).withValues(alpha: 0.04),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inv['invoice_number'],
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15.sp, color: Color(0xFF000080))),
                    SizedBox(height: 2),
                    Text(_formatDisplayDate(context, inv['date']),
                        style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500)),
                  ]),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: inv['invoice_type'] == 'creditinvoice' ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: inv['invoice_type'] == 'creditinvoice' ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Text(inv['invoice_type'] == 'creditinvoice' ? context.tr('Credit') : context.tr('Cash'),
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: inv['invoice_type'] == 'creditinvoice' ? Colors.red.shade700 : Colors.green.shade700)),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isFullyPaid ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isFullyPaid ? Colors.green.shade200 : Colors.orange.shade200),
                      ),
                      child: Text(isFullyPaid ? '✓ ${context.tr('Paid')}' : '⏳ ${context.tr('Partial')}',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: isFullyPaid ? Colors.green.shade700 : Colors.orange.shade700)),
                    ),
                    if (creditNoteAmount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text('CN: $symbol${creditNoteAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer & Vehicle row
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(Icons.person_outline, inv['customer']['name'], inv['customer']['phone']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoChip(Icons.directions_car_outlined, inv['vehicle']['number'], inv['vehicle']['model']),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Services List
                ...services.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr(s['name']), style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade700)),
                          Text(context.tr('$symbol${s['rate']}'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                        ],
                      ),
                    )),
                const Divider(height: 20),

                // Totals
                _totalRow(context, 'Subtotal', inv['subtotal']),
                _totalRow(context, 'Discount', inv['discount'], isNegative: true),
                _totalRow(context, 'Tax', inv['tax_amount']),
                Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Total'), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16.sp)),
                    Text(context.tr('$symbol${inv['total']}'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18.sp, color: Color(0xFF000080))),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Collected'), style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12.sp)),
                    Text(context.tr('$symbol${inv['amount_collected']}'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.sp, color: Colors.green.shade700)),
                  ],
                ),
                if (creditNoteAmount > 0) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('Credit Note'), style: GoogleFonts.inter(color: Colors.amber.shade900, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                      Text(context.tr('-$symbol${creditNoteAmount.toStringAsFixed(2)}'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp, color: Colors.amber.shade900)),
                    ],
                  ),
                ],
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Balance Due'), style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12.sp)),
                    Text(context.tr('$symbol${remainingOutstanding.toStringAsFixed(2)}'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp, color: remainingOutstanding > 0 ? Colors.red.shade700 : Colors.grey.shade700)),
                  ],
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadInvoice(context, inv),
                        icon: Icon(Icons.download, size: 16),
                        label: Text(context.tr('Download'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF000080),
                          side: BorderSide(color: Color(0xFF000080)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printInvoice(context, inv),
                        icon: Icon(Icons.print, size: 16),
                        label: Text(context.tr('Print'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF000080),
                          side: BorderSide(color: Color(0xFF000080)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareInvoice(context, inv),
                        icon: Icon(Icons.share, size: 16),
                        label: Text(context.tr('Share'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoiceCreateScreen(
                                customer: inv['customer'],
                                vehicle: inv['vehicle'],
                                invoiceToEdit: inv,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            _fetchInvoices(context);
                          }
                        },
                        icon: Icon(Icons.edit_note, size: 16),
                        label: Text(context.tr('Edit Invoice'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF000080).withValues(alpha: 0.1),
                          foregroundColor: Color(0xFF000080),
                          side: BorderSide(color: Color(0xFF000080).withValues(alpha: 0.3)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteInvoice(context, inv),
                        icon: Icon(Icons.delete_outline, size: 16),
                        label: Text(context.tr('Delete Invoice'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreditNoteModal(context, inv),
                    icon: Icon(Icons.assignment_return_outlined, size: 16),
                    label: Text(
                      context.tr('Credit Note'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade400),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: Color(0xFF1e293b)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _totalRow(BuildContext context, String label, dynamic value, {bool isNegative = false}) {
    final symbol = currencySymbol(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(context.tr(label), style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13.sp)),
        Text(context.tr('${isNegative ? '-' : ''}$symbol$value'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp,
                color: isNegative ? Colors.red.shade400 : Colors.grey.shade800)),
      ]),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade200),
      SizedBox(height: 16),
      Text(context.tr('No invoices found'), style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16.sp, fontWeight: FontWeight.w600)),
      Text(context.tr('for the selected date range.'), style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13.sp)),
    ]));
  }

  Widget _buildError(BuildContext context, [String? message]) {
    final msg = message ?? '';
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 60, color: Colors.red.shade200),
      SizedBox(height: 16),
      Text(context.tr(msg), textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red, fontSize: 14.sp)),
    ]));
  }

  Widget _paymentModeDropdown(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _paymentModeNotifier,
      builder: (context, selectedPaymentMode, child) {
        return DropdownButtonFormField<String>(
          value: selectedPaymentMode,
          isExpanded: true,
          menuMaxHeight: 350,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(context.tr('All payment modes')),
          items: [
            DropdownMenuItem<String>(value: '', child: Text(context.tr('All payment modes'))),
            DropdownMenuItem<String>(value: 'cash', child: Text(context.tr('Cash'))),
            DropdownMenuItem<String>(value: 'card', child: Text(context.tr('Card'))),
            if (!CountryConfig.isUAE)
              DropdownMenuItem<String>(value: 'digital_payments', child: Text(context.tr('Digital payments'))),
          ],
          onChanged: (value) {
            _paymentModeNotifier.value = value == null || value.isEmpty ? null : value;
            _fetchInvoices(context);
          },
        );
      },
    );
  }
}


class _CreditNoteBottomSheet extends StatefulWidget {
  final Map<String, dynamic> inv;
  final String currencySymbol;
  final Function(String message) onSuccess;

  const _CreditNoteBottomSheet({
    required this.inv,
    required this.currencySymbol,
    required this.onSuccess,
  });

  @override
  State<_CreditNoteBottomSheet> createState() => _CreditNoteBottomSheetState();
}

class _CreditNoteBottomSheetState extends State<_CreditNoteBottomSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  String _nextCnNumber = '';
  Map<String, dynamic>? _invoiceInfo;
  double _maxCreditable = 0.0;
  double _currentOutstanding = 0.0;

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _selectedReason = 'Defective / Unsatisfactory Service';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Defective / Unsatisfactory Service',
    'Billing / Rate Correction',
    'Cancellation of Service',
    'Customer Goodwill / Discount',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token missing';
      });
      return;
    }

    try {
      final res = await ApiService.getCreditNoteInfo(
        widget.inv['id'].toString(),
        token,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final invData = res['invoice'] as Map<String, dynamic>? ?? {};
        final maxCred = double.tryParse(invData['max_creditable']?.toString() ?? '0') ?? 0.0;
        final outstanding = double.tryParse(invData['current_outstanding']?.toString() ?? '0') ?? 0.0;

        setState(() {
          _isLoading = false;
          _nextCnNumber = res['next_credit_note_number'] ?? '';
          _invoiceInfo = invData;
          _maxCreditable = maxCred;
          _currentOutstanding = outstanding;
          _amountController.text = maxCred > 0 ? maxCred.toStringAsFixed(2) : '0.00';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res['message'] ?? 'Failed to load credit note details';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _submitCreditNote() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Credit amount must be greater than zero')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (amount > _maxCreditable + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Amount cannot exceed max creditable ${widget.currencySymbol}${_maxCreditable.toStringAsFixed(2)}')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'invoice_id': widget.inv['id'].toString(),
        'credit_amount': amount,
        'reason': _selectedReason,
        'remarks': _remarksController.text.trim(),
      };

      final res = await ApiService.createCreditNote(payload, token);
      if (!mounted) return;

      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess(res['message'] ?? 'Credit note created successfully');
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(res['message'] ?? 'Failed to create credit note')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Error: $e')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.currencySymbol;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final newOutstanding = (_currentOutstanding - enteredAmount).clamp(0.0, double.infinity);
    final prevCreditNotes = widget.inv['credit_notes'] as List<dynamic>? ?? [];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Icon(Icons.assignment_return_outlined, color: Colors.amber.shade900, size: 22),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Credit Note'),
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          Text(
                            '${context.tr('Invoice')} #${widget.inv['invoice_number']}',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_nextCnNumber.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF000080).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF000080).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _nextCnNumber,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ),
                ],
              ),
              Divider(height: 24),

              // Body content
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF000080)),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
                      SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13.sp),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF000080),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(context.tr('Retry')),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Cards Row
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _summaryColumn(
                                  context,
                                  'Invoice Total',
                                  '$symbol${widget.inv['total']}',
                                  Color(0xFF1e293b),
                                ),
                              ),
                              Container(width: 1, height: 32, color: Colors.grey.shade300),
                              Expanded(
                                child: _summaryColumn(
                                  context,
                                  'Collected',
                                  '$symbol${widget.inv['amount_collected']}',
                                  Colors.green.shade700,
                                ),
                              ),
                              Container(width: 1, height: 32, color: Colors.grey.shade300),
                              Expanded(
                                child: _summaryColumn(
                                  context,
                                  'Credited',
                                  '$symbol${_invoiceInfo?['credit_note_amount'] ?? '0.00'}',
                                  Colors.amber.shade900,
                                ),
                              ),
                              Container(width: 1, height: 32, color: Colors.grey.shade300),
                              Expanded(
                                child: _summaryColumn(
                                  context,
                                  'Max Credit',
                                  '$symbol${_maxCreditable.toStringAsFixed(2)}',
                                  Color(0xFF000080),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // If previous credit notes exist
                        if (prevCreditNotes.isNotEmpty) ...[
                          Text(
                            context.tr('Previous Credit Notes'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 6),
                          ...prevCreditNotes.map((cn) => Container(
                            margin: EdgeInsets.only(bottom: 6),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.receipt, size: 14, color: Colors.amber.shade900),
                                    SizedBox(width: 6),
                                    Text(
                                      cn['credit_note_number'] ?? '',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp, color: Colors.amber.shade900),
                                    ),
                                    if (cn['date'] != null) ...[
                                      SizedBox(width: 6),
                                      Text('• ${cn['date']}', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600)),
                                    ],
                                  ],
                                ),
                                Text(
                                  '-$symbol${cn['total']}',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.sp, color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          )),
                          SizedBox(height: 12),
                        ],

                        if (_maxCreditable <= 0)
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr('This invoice has already been fully credited.'),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // Quick selection full credit
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _amountController.text = _maxCreditable.toStringAsFixed(2);
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Color(0xFF000080)),
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    '${context.tr('Full Credit')} ($symbol${_maxCreditable.toStringAsFixed(2)})',
                                    style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Color(0xFF000080)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          // Amount input
                          Text(
                            context.tr('Credit Amount'),
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 6),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixText: '$symbol ',
                              prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Color(0xFF1e293b)),
                              hintText: '0.00',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFF000080), width: 1.5)),
                            ),
                            style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 12),

                          // Reason Dropdown
                          Text(
                            context.tr('Reason for Credit Note'),
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReason,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                items: _reasons.map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(context.tr(r), style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedReason = val);
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Remarks
                          Text(
                            context.tr('Remarks (Optional)'),
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 6),
                          TextField(
                            controller: _remarksController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: context.tr('Enter additional notes or details...'),
                              hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade400),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFF000080), width: 1.5)),
                            ),
                            style: GoogleFonts.inter(fontSize: 13.sp),
                          ),
                          SizedBox(height: 16),

                          // Calculation Live Preview
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(context.tr('Current Outstanding'), style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600)),
                                    Text('$symbol${_currentOutstanding.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(context.tr('Credit Adjustment'), style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.amber.shade900)),
                                    Text('-$symbol${enteredAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.amber.shade900)),
                                  ],
                                ),
                                Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(context.tr('New Balance Due'), style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Color(0xFF1e293b))),
                                    Text(
                                      '$symbol${newOutstanding.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w800,
                                        color: newOutstanding > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitCreditNote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF000080),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    '${context.tr('Create Credit Note')} (${_nextCnNumber.isNotEmpty ? _nextCnNumber : ""})',
                                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryColumn(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          context.tr(label),
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
