import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/language_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/country_config.dart';
import 'package:http/http.dart' as http;


class InvoiceViewScreen extends StatelessWidget {
  final String invoiceId;
  final String invoiceNumber;
  final Map<String, dynamic> invoiceData;
  final Map<String, dynamic> customer;
  final Map<String, dynamic> vehicle;

  const InvoiceViewScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceData,
    required this.customer,
    required this.vehicle,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────
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

  String _getServiceDetailText(Map<String, dynamic> svc, String currencySymbol) {
    final detail = svc['service_detail'] as Map<String, dynamic>?;
    if (detail == null) return '';

    final cat = detail['service_category']?.toString() ?? '';
    if (cat == 'oil_change') {
      final parts = <String>[];
      
      final prod = detail['oil_product'] as Map<String, dynamic>?;
      if (prod != null && prod.isNotEmpty) {
        final brand = prod['brand']?.toString() ?? prod['oil_brand']?['name']?.toString() ?? '';
        final name = prod['name']?.toString() ?? '';
        final grade = prod['grade']?.toString() ?? prod['oil_grade']?['name']?.toString() ?? '';
        final prodStr = [if (brand.isNotEmpty) brand, if (name.isNotEmpty) name, if (grade.isNotEmpty) '($grade)'].join(' ');
        if (prodStr.isNotEmpty) parts.add('Oil: $prodStr');
      }
      
      final litres = detail['oil_litres_used']?.toString();
      if (litres != null && litres.isNotEmpty && litres != '0') {
        parts.add('Litres: ${litres}L');
      }

      final filterChanged = detail['oil_filter_changed'] == true || detail['oil_filter_id'] != null || detail['oil_filter'] != null;
      if (filterChanged) {
        final filter = detail['oil_filter'] as Map<String, dynamic>?;
        final fBrand = filter?['brand_name']?.toString() ?? filter?['brand']?['name']?.toString() ?? '';
        final fName = filter?['name']?.toString() ?? '';
        final fPriceVal = detail['oil_filter_price'] ?? filter?['price'];
        final fPriceDouble = (fPriceVal is num) ? fPriceVal.toDouble() : double.tryParse(fPriceVal?.toString() ?? '0') ?? 0.0;
        final priceStr = fPriceDouble > 0 ? '$currencySymbol${fPriceDouble.toStringAsFixed(2)}' : '';
        final fLabel = [if (fBrand.isNotEmpty) fBrand, if (fName.isNotEmpty) fName].join(' ');
        final filterText = fLabel.isNotEmpty ? fLabel : 'Oil Filter';
        parts.add('Filter: $filterText${priceStr.isNotEmpty ? " ($priceStr)" : ""}');
      }

      return parts.join(' | ');
    } else if (cat == 'tyre_change') {
      final parts = <String>[];
      final items = detail['tyre_items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        for (final item in items) {
          final brand = item['brand']?.toString() ?? '';
          final tSize = item['size']?.toString() ?? '';
          final qty = item['quantity']?.toString() ?? '1';
          final lineTot = item['line_total'];
          final lineTotVal = (lineTot is num) ? lineTot.toDouble() : double.tryParse(lineTot?.toString() ?? '0') ?? 0.0;
          final priceStr = lineTotVal > 0 ? ' ($currencySymbol${lineTotVal.toStringAsFixed(0)})' : '';
          final labelParts = [if (brand.isNotEmpty) brand, if (tSize.isNotEmpty) tSize].join(' ');
          parts.add('Tyre: $labelParts x$qty$priceStr');
        }
      }
      return parts.join(' | ');
    } else if (cat == 'wheel_alignment') {
      final parts = <String>[];
      final notes = detail['alignment_notes']?.toString();
      if (notes != null && notes.isNotEmpty) parts.add('Notes: $notes');
      return parts.join(' | ');
    } else if (cat == 'car_detailing' || cat == 'detailing') {
      return '';
    }
    return '';
  }

  // ── PDF helper widgets ───────────────────────────────────────────────────
  pw.Widget _pdfCell(
    String text, {
    bool isHeader = false,
    pw.Alignment align = pw.Alignment.centerRight,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 11,
            fontWeight: (isHeader || bold)
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            color: isHeader ? PdfColors.white : (color ?? PdfColors.grey900),
          )),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor ?? PdfColors.grey900)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getInvoiceMap() {
    final inv = Map<String, dynamic>.from(invoiceData);
    if (!inv.containsKey('customer') || inv['customer'] == null) {
      inv['customer'] = customer;
    }
    if (!inv.containsKey('vehicle') || inv['vehicle'] == null) {
      inv['vehicle'] = vehicle;
    }
    if (!inv.containsKey('invoice_number') || inv['invoice_number'] == null) {
      inv['invoice_number'] = invoiceNumber;
    }
    return inv;
  }

  // ── PDF generation ────────────────────────────────────────────────────────
  Future<Uint8List> _getInvoicePdfBytes(BuildContext context) async {
    final inv = _getInvoiceMap();
    final invNo = (inv['invoice_number'] ?? invoiceNumber).toString();
    final cleanInvoiceNo = invNo.replaceAll('/', '_');
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

    final localPdf = await _generateInvoicePdf(context);
    return localPdf.save();
  }

  Future<pw.Document> _generateInvoicePdf(BuildContext context) async {
    final inv = _getInvoiceMap();
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoFont = pw.Font.ttf(fontData);

    final invNo = (inv['invoice_number'] ?? invoiceNumber).toString();
    final pdf = pw.Document(
      title: invNo,
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
      final logoUrl = inv['company_logo'] as String? ?? context.read<AuthProvider>().companyLogo ?? '';
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

    final String customerBranch = customer['branch']?.toString() ?? '';
    final String invoiceBranch = inv['branch']?.toString() ?? '';
    final String authBranch = context.read<AuthProvider>().branchName ?? '';
    final String branchName = customerBranch.isNotEmpty
        ? customerBranch
        : (invoiceBranch.isNotEmpty
            ? invoiceBranch
            : (authBranch.isNotEmpty ? authBranch : 'our service'));

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

    final String companyTrn = (inv['company_trn'] ?? inv['branch_gst'] ?? branchGst).toString().trim();
    final String custTrn = (customer['tax_number'] ?? customer['tin_number'] ?? customer['trn'] ?? inv['customer_tax_number'] ?? inv['customer_tin_number'] ?? '').toString().trim();

    String paymentMode = (inv['payment_mode'] ?? '').toString().trim();
    if (paymentMode.isEmpty) {
      if (inv['invoice_type'] == 'creditinvoice' || inv['sales_type'] == 'credit') {
        paymentMode = 'Credit';
      } else if (inv['invoice_type'] == 'cashinvoice' || inv['sales_type'] == 'cash') {
        paymentMode = 'Cash';
      }
    } else {
      paymentMode = paymentMode.replaceAll('_', ' ');
      paymentMode = paymentMode.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }

    final symbol = context.read<AuthProvider>().currencySymbol;

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
                          if (branchAddress.isNotEmpty)
                            pw.Text(branchAddress, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchPhone.isNotEmpty)
                            pw.Text("Phone: $branchPhone", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchEmail.isNotEmpty)
                            pw.Text("Email: $branchEmail", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          if (branchGst.isNotEmpty)
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
                      ((double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0) > 0 || (inv['taxes'] is List && (inv['taxes'] as List).isNotEmpty))
                          ? 'TAX INVOICE'
                          : (nonTaxTitle.isNotEmpty ? nonTaxTitle : 'PROFORMA INVOICE'),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  if (companyTrn.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('TRN: $companyTrn',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  ],
                  pw.SizedBox(height: 3),
                  pw.Text(invNo,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  pw.Text(inv['invoice_type'] == 'creditinvoice' ? 'Credit Invoice' : 'Cash Invoice',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  if (paymentMode.isNotEmpty)
                    pw.Text('Payment Mode: $paymentMode',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  if (dateStr.isNotEmpty)
                    pw.Text(dateStr, style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
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
                  pw.Text(customer['name'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  if ((customer['phone'] ?? '').toString().isNotEmpty)
                    pw.Text(customer['phone'].toString(), style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                  if ((customer['address'] ?? '').toString().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, right: 10),
                      child: pw.Text(customer['address'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
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
                if (showVehicleNumber && (vehicle['number'] ?? vehicle['no'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['number'] ?? vehicle['no'] ?? '', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                if (showVehicleMake || showVehicleModel) ...[
                  pw.Text(
                    [
                      if (showVehicleMake && (vehicle['make'] ?? '').toString().isNotEmpty) vehicle['make'].toString(),
                      if (showVehicleModel && (vehicle['model'] ?? '').toString().isNotEmpty) vehicle['model'].toString(),
                    ].join(' '),
                    style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                  ),
                ],
                if (showVehicleType && (vehicle['type'] ?? vehicle['vehicle_type'] ?? '').toString().isNotEmpty)
                  pw.Text((vehicle['type'] ?? vehicle['vehicle_type']).toString(), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (showVehicleSegment && (vehicle['segment'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['segment'].toString(), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (showVehicleColor && (vehicle['color'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['color'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleFuelType && (vehicle['fuel_type'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['fuel_type'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleWheelType && (vehicle['wheel_type'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['wheel_type'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                if (showVehicleEmissionStd && (vehicle['emission_standard'] ?? '').toString().isNotEmpty)
                  pw.Text(vehicle['emission_standard'].toString(), style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
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


  // ── Share Invoice ────────────────────────────────────────────────────────
  void _shareInvoice(BuildContext context) {
    _showShareOptions(context);
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null && invoiceId.isNotEmpty) {
        // Show loading progress
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('Invoice sent automatically via WhatsApp API')),
                backgroundColor: Colors.green,
              ),
            );
            return; // Finished!
          }
        } catch (_) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loading dialog
          }
        }
      }

      final currencySymbol = context.read<AuthProvider>().currencySymbol;
      final services     = invoiceData['services']      as List<dynamic>? ?? [];
      final tradingItems = invoiceData['trading_items']  as List<dynamic>? ?? [];
      final total        = invoiceData['total']         ?? '0.00';
      final collected    = invoiceData['amount_collected'] ?? '0.00';

      final itemLines = <String>[];
      for (final s in services) {
        final qty = _toDouble(s['qty'], 1.0);
        final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
        itemLines.add("- ${s['name']}$qtyStr: $currencySymbol${_fmt(s['rate'])}");
      }
      for (final t in tradingItems) {
        if (t['is_operational'] != true) {
          final qty = _toDouble(t['qty'], 1.0);
          final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
          itemLines.add("- ${t['item_name']}$qtyStr: $currencySymbol${_fmt(t['net_taxable'] ?? t['rate'])}");
        }
      }
      final servicesStr = itemLines.join("\n");

      final branchName = invoiceData['branch']?.toString() ?? context.read<AuthProvider>().branchName ?? 'our branch';
      final companyName = context.read<AuthProvider>().companyName ?? 'Mobiz Autocare Pro';

      final doubleTot = double.tryParse(total.toString()) ?? 0.0;
      final doubleColl = double.tryParse(collected.toString()) ?? 0.0;
      final balanceVal = doubleTot - doubleColl;

      final bool hasTax = (double.tryParse(invoiceData['tax_amount']?.toString() ?? '0') ?? 0.0) > 0 ||
          (invoiceData['taxes'] is List && (invoiceData['taxes'] as List).isNotEmpty);
      final invTypeLower = hasTax ? context.tr('tax invoice') : context.tr('proforma invoice');
      final invTypeTitle = hasTax ? context.tr('Tax Invoice Details') : context.tr('Proforma Invoice Details');

      final messageText =
          "${context.tr('Dear')} ${customer['name']},\n\n"
          "${context.tr('Your')} $invTypeLower *$invoiceNumber* ${context.tr('has been generated successfully at')} $companyName.\n\n"
          "*$invTypeTitle:*\n"
          "${context.tr('Vehicle')}: ${vehicle['no'] ?? vehicle['number'] ?? ''}\n"
          "${context.tr('Services')}:\n$servicesStr\n"
          "${context.tr('Total')}: $currencySymbol$total\n"
          "${context.tr('Paid')}: $currencySymbol$collected\n"
          "${context.tr('Balance')}: $currencySymbol${_fmt(balanceVal)}\n\n"
          "${context.tr('Thank you for choosing')} $branchName!\n"
          "${context.tr('Powered by')} Mobiz Technologies";

      final cleanedPhone = _getCleanedWhatsAppNumber(customer);
      if (cleanedPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('No phone number available for this customer')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final whatsappUrl = Uri.parse(
        "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(messageText)}"
      );

      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error launching WhatsApp: $e'))),
        );
      }
    }
  }

  Future<void> _sharePdfFile(BuildContext context) async {
    try {
      final currencySymbol = context.read<AuthProvider>().currencySymbol;
      final services     = invoiceData['services']      as List<dynamic>? ?? [];
      final tradingItems = invoiceData['trading_items']  as List<dynamic>? ?? [];
      final total        = invoiceData['total']         ?? '0.00';
      final collected    = invoiceData['amount_collected'] ?? '0.00';

      final itemLines = <String>[];
      for (final s in services) {
        final qty = _toDouble(s['qty'], 1.0);
        final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
        itemLines.add("- ${s['name']}$qtyStr: $currencySymbol${_fmt(s['rate'])}");
      }
      for (final t in tradingItems) {
        if (t['is_operational'] != true) {
          final qty = _toDouble(t['qty'], 1.0);
          final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
          itemLines.add("- ${t['item_name']}$qtyStr: $currencySymbol${_fmt(t['net_taxable'] ?? t['rate'])}");
        }
      }
      final servicesStr = itemLines.join("\n");
      final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');

      final branchName = invoiceData['branch']?.toString() ?? context.read<AuthProvider>().branchName ?? 'our branch';
      final companyName = context.read<AuthProvider>().companyName ?? 'Mobiz Autocare Pro';

      final doubleTot = double.tryParse(total.toString()) ?? 0.0;
      final doubleColl = double.tryParse(collected.toString()) ?? 0.0;
      final balanceVal = doubleTot - doubleColl;

      final messageText = 
          "${context.tr('Dear')} ${customer['name']},\n\n"
          "${context.tr('Your proforma invoice')} *$invoiceNumber* ${context.tr('has been generated successfully at')} $companyName.\n\n"
          "*${context.tr('Proforma Invoice Details')}:*\n"
          "${context.tr('Vehicle')}: ${vehicle['no'] ?? vehicle['number'] ?? ''}\n"
          "${context.tr('Services')}:\n$servicesStr\n"
          "${context.tr('Total')}: $currencySymbol$total\n"
          "${context.tr('Paid')}: $currencySymbol$collected\n"
          "${context.tr('Balance')}: $currencySymbol${_fmt(balanceVal)}\n\n"
          "${context.tr('Thank you for choosing')} $branchName!\n"
          "${context.tr('Powered by')} Mobiz Technologies";

      final pdfBytes = await _getInvoicePdfBytes(context);
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$cleanInvoiceNo.pdf');
      await file.writeAsBytes(pdfBytes);
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: messageText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error generating PDF: $e'))),
        );
      }
    }
  }

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
                    context.tr('Share Invoice'),
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
                    context.tr('Share via WhatsApp (Direct Chat)'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('Opens chat with pre-filled summary'),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _shareViaWhatsApp(context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                  ),
                  title: Text(
                    context.tr('Share PDF Document'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    context.tr('Generates PDF and opens sharing menu'),
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                  onTap: () {
                    Navigator.pop(bc);
                    _sharePdfFile(context);
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



  // ── Screen UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final taxes          = invoiceData['taxes']          as List<dynamic>? ?? [];
    final services       = invoiceData['services']       as List<dynamic>? ?? [];
    final tradingItems   = invoiceData['trading_items']  as List<dynamic>? ?? [];
    final currencySymbol = context.watch<AuthProvider>().currencySymbol;

    final allItems = <Map<String, dynamic>>[];
    for (final s in services) {
      final qty = _toDouble(s['qty'], 1.0);
      final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
      allItems.add({
        'name': '${s['name'] ?? ''}$qtyStr',
        'rate': _toDouble(s['rate']),
        'discount': _toDouble(s['discount']),
        'raw_service': s,
        'is_operational': false,
      });
    }
    for (final t in tradingItems) {
      final isOp = t['is_operational'] == true;
      final qty = _toDouble(t['qty'], 1.0);
      final qtyStr = qty > 1 ? ' (x${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)})' : '';
      final name = isOp ? '${t['item_name'] ?? 'Stock Item'}$qtyStr' : '${t['item_name'] ?? 'Stock Item'}$qtyStr';
      allItems.add({
        'name': name,
        'rate': isOp ? 0.0 : _toDouble(t['rate']),
        'discount': isOp ? 0.0 : _toDouble(t['discount']),
        'is_operational': isOp,
      });
    }

    // Sort services & items by price high to low
    allItems.sort((a, b) {
      final rateA = _toDouble(a['rate']);
      final rateB = _toDouble(b['rate']);
      return rateB.compareTo(rateA);
    });

    final bool hasAnyDiscount =
        allItems.any((s) => _toDouble(s['discount']) > 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(context.tr('Invoice Details'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Color(0xFF000080),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareInvoice(context),
            tooltip: context.tr('Share Invoice'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Invoice header ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('INVOICE'),
                      style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF000080),
                          letterSpacing: 1)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(context.tr('PAID'),
                        style: GoogleFonts.inter(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(invoiceNumber,
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider()),

              // ── Customer & Vehicle ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('BILLED TO'),
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text(customer['name'] ?? '',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 15.sp)),
                        if ((customer['phone'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(customer['phone'].toString(),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade600, fontSize: 13.sp)),
                        ],
                        if ((customer['address'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(customer['address'].toString(),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade600, fontSize: 12.sp)),
                        ],
                        if ((customer['tax_number'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text("Tax/TRN: ${customer['tax_number']}",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                  fontSize: 12.sp)),
                        ],
                        if ((customer['tin_number'] ?? '').toString().isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text("TIN: ${customer['tin_number']}",
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade600, fontSize: 12.sp)),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(context.tr('VEHICLE'),
                          style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.5)),
                      SizedBox(height: 6),
                       Text(vehicle['no'] ?? vehicle['number'] ?? '',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 15.sp)),
                      SizedBox(height: 2),
                      Text(
                          (vehicle['vehicle_type'] != null && vehicle['vehicle_type'].toString().isNotEmpty)
                              ? "${vehicle['vehicle_type']} - ${vehicle['type']}"
                              : (vehicle['type'] ?? ''),
                          style: GoogleFonts.inter(
                              color: Colors.grey.shade600, fontSize: 13.sp)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Services ─────────────────────────────────────────────────
              Text(context.tr('SERVICES'),
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),

              // Column headers when discounts exist
              if (hasAnyDiscount)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Expanded(
                        child: Text(context.tr('Service'),
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 68,
                        child: Text(context.tr('Rate'),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 68,
                        child: Text(context.tr('Disc.'),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600))),
                    SizedBox(
                        width: 76,
                        child: Text(context.tr('Net'),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600))),
                  ]),
                ),

              // Items rows
              for (int i = 0; i < allItems.length; i++) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: i.isEven
                        ? Colors.grey.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      hasAnyDiscount
                          ? Row(children: [
                              Expanded(
                                child: Text(allItems[i]['name'] ?? '',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                        color: Color(0xFF1e293b))),
                              ),
                              SizedBox(
                                width: 68,
                                child: Text(
                                  context.tr('$currencySymbol${_fmt(allItems[i]['rate'])}'),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade700),
                                ),
                              ),
                              SizedBox(
                                width: 68,
                                child: Text(
                                  _toDouble(allItems[i]['discount']) > 0
                                      ? '-$currencySymbol${_fmt(allItems[i]['discount'])}'
                                      : '—',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: _toDouble(allItems[i]['discount']) > 0
                                        ? Colors.green.shade600
                                        : Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 76,
                                child: Text(
                                  context.tr('$currencySymbol${_fmt(
                                    _toDouble(allItems[i]['rate']) -
                                        _toDouble(allItems[i]['discount']),
                                  )}'),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                      color: Color(0xFF000080)),
                                ),
                              ),
                            ])
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(allItems[i]['name'] ?? '',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                          color: Color(0xFF1e293b))),
                                ),
                                if (allItems[i]['is_operational'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      context.tr('Operational'),
                                      style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                  )
                                else
                                  Text(
                                    context.tr('$currencySymbol${_fmt(allItems[i]['rate'])}'),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.sp,
                                        color: Color(0xFF000080)),
                                  ),
                              ],
                            ),
                      if (allItems[i]['raw_service'] != null && _getServiceDetailText(allItems[i]['raw_service'], currencySymbol).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getServiceDetailText(allItems[i]['raw_service'], currencySymbol),
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider()),

              // ── Totals summary ────────────────────────────────────────────
              _summaryRow('Subtotal',
                  '$currencySymbol${_fmt(invoiceData['subtotal'])}'),
              if ((double.tryParse(
                          invoiceData['discount']?.toString() ?? '0') ??
                      0) >
                  0) ...[
                const SizedBox(height: 8),
                _summaryRow(
                  'Total Discount',
                  '-$currencySymbol${_fmt(invoiceData['discount'])}',
                  valueColor: Colors.green.shade600,
                ),
              ],
              if (taxes.isNotEmpty)
                for (final tax in taxes) ...[
                  const SizedBox(height: 8),
                  _summaryRow(
                    tax['name']?.toString() ?? 'Tax',
                    '$currencySymbol${_fmt(tax['amount'])}',
                  ),
                ]
              else if ((double.tryParse(
                          invoiceData['tax_amount']?.toString() ?? '0') ??
                      0) >
                  0) ...[
                const SizedBox(height: 8),
                _summaryRow(
                    'Tax', '$currencySymbol${_fmt(invoiceData['tax_amount'])}'),
              ],
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF000080).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Total'),
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, fontSize: 17.sp)),
                    Text(context.tr('$currencySymbol${_fmt(invoiceData['total'])}'),
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 20.sp,
                            color: Color(0xFF000080))),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Buttons ───────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => _shareInvoice(context),
                icon: const Icon(Icons.share),
                label: Text(context.tr('Share Invoice'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('Back to Dashboard'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.grey.shade600, fontSize: 13.sp)),
        Text(value,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: valueColor ?? Color(0xFF1e293b))),
      ],
    );
  }
}
