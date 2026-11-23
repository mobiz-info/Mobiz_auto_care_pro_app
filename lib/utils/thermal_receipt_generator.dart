import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class ThermalReceiptGenerator {
  static Future<img.Image?> _loadLogoImage(String? logoUrl, int maxWidth) async {
    try {
      Uint8List? imageBytes;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        String fullUrl = logoUrl;
        if (!fullUrl.startsWith('http')) {
          if (!fullUrl.startsWith('/')) fullUrl = '/$fullUrl';
          fullUrl = 'http://68.183.94.11:78$fullUrl';
        } else if (fullUrl.contains('68.183.94.11') && !fullUrl.contains(':78')) {
          fullUrl = fullUrl.replaceFirst('68.183.94.11', '68.183.94.11:78');
        }
        try {
          final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            imageBytes = res.bodyBytes;
          }
        } catch (_) {}
      }
      if (imageBytes == null) {
        try {
          final byteData = await rootBundle.load('assets/icons/mobiz_autocare_mark_blue.png');
          imageBytes = byteData.buffer.asUint8List();
        } catch (_) {}
      }
      if (imageBytes == null) return null;

      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: maxWidth);
      return img.grayscale(resized);
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>> generateBillReceipt({
    required Map<String, dynamic> inv,
    required String paperSize, // '2inch' (58mm), '3inch' (80mm) or '4inch' (100mm)
    String companyName = 'AL BAB AL ABYAD AUTO SERVICES L.L.C',
    String currency = 'AED',
  }) async {
    final profile = await CapabilityProfile.load();
    final bool is2Inch = paperSize == '2inch';
    final bool is4Inch = paperSize == '4inch';
    final PaperSize pSize = is2Inch ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(pSize, profile);
    List<int> bytes = [];

    final int lineLength = is2Inch ? 32 : (is4Inch ? 64 : 48);
    final String divider = '-' * lineLength;

    // Reset printer
    bytes += generator.reset();

    // ── 0. LOGO BANNER (Centered) ─────────────────────────────────────────
    final String? logoUrl = inv['company_logo'] as String?;
    final int logoWidth = is2Inch ? 260 : (is4Inch ? 400 : 320);
    final logoImage = await _loadLogoImage(logoUrl, logoWidth);
    if (logoImage != null) {
      try {
        bytes += generator.imageRaster(logoImage, align: PosAlign.center);
        bytes += generator.feed(1);
      } catch (_) {}
    }

    // ── 1. COMPANY NAME & TRN (Centered) ──────────────────────────────────
    final String authCompanyName = companyName.isNotEmpty ? companyName : 'AL BAB AL ABYAD AUTO SERVICES L.L.C';
    final String rawTrn = (inv['company_trn'] ?? inv['branch_gst'] ?? '').toString().trim();
    final String trn = rawTrn.replaceAll(RegExp(r'^(TRN\s*:\s*|TRN\s*|GSTIN\s*:\s*)', caseSensitive: false), '').trim();

    bytes += generator.text(
      authCompanyName.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
      ),
    );

    if (trn.isNotEmpty) {
      bytes += generator.text(
        'TRN: $trn',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.feed(1);

    // ── 2. INVOICE META & ADDRESS (Left: TAX INVOICE | Right: Address) ─────
    final String branchAddress = (inv['branch_address'] ?? '').toString().trim();
    final List<String> addressLines = [];
    if (branchAddress.isNotEmpty) {
      for (final l in branchAddress.split('\n')) {
        final clean = l.trim();
        if (clean.isNotEmpty) addressLines.add(clean);
      }
    }
    if (addressLines.isEmpty && inv['branch'] != null) {
      addressLines.add(inv['branch'].toString());
    }

    final double taxAmount = double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0;
    final String invoiceTitle = taxAmount > 0 ? 'TAX INVOICE' : 'CASH INVOICE';
    final String invoiceNumber = (inv['invoice_number'] ?? 'N/A').toString();

    final String line0 = addressLines.isNotEmpty ? addressLines[0] : '';
    final String line1 = addressLines.length > 1 ? addressLines[1] : '';
    final String line2 = addressLines.length > 2 ? addressLines[2] : '';

    bytes += generator.row([
      PosColumn(text: invoiceTitle, width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: line0, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '# $invoiceNumber', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: line1, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (line2.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: '', width: 6),
        PosColumn(text: line2, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    for (int i = 3; i < addressLines.length; i++) {
      bytes += generator.row([
        PosColumn(text: '', width: 6),
        PosColumn(text: addressLines[i], width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.feed(1);

    // ── 3. DATE, TO, PHONE ────────────────────────────────────────────────
    String dateDisplay = (inv['date'] ?? '').toString();
    try {
      final dt = DateTime.parse(dateDisplay);
      dateDisplay = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {}
    bytes += generator.text('Date : $dateDisplay');

    final veh = inv['vehicle'] is Map ? (inv['vehicle'] as Map) : null;
    final String vehNum = (veh?['number'] ?? inv['vehicle_number'] ?? '').toString().trim();
    final String vehModel = (veh?['model'] ?? veh?['name'] ?? '').toString().trim();
    final cust = inv['customer'] is Map ? (inv['customer'] as Map) : null;
    final String custName = (cust?['name'] ?? inv['customer_name'] ?? '').toString().trim();
    final String custPhone = (cust?['phone'] ?? inv['customer_phone'] ?? '').toString().trim();

    String toText = '';
    if (vehNum.isNotEmpty) {
      toText = vehModel.isNotEmpty ? '$vehNum $vehModel' : vehNum;
      if (custName.isNotEmpty && custName != vehNum) {
        toText += ' ($custName)';
      }
    } else if (custName.isNotEmpty) {
      toText = custName;
    }
    if (toText.isNotEmpty) {
      bytes += generator.text('To : $toText');
    }

    if (custPhone.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text('Phone : $custPhone');
    }

    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // ── 4. ITEMS TABLE (Item | Qty | Price | Total) ───────────────────────
    final services = inv['services'] as List<dynamic>? ?? [];
    final tradingItems = inv['trading_items'] as List<dynamic>? ?? [];
    final allItems = <Map<String, dynamic>>[];

    for (final s in services) {
      final double qty = double.tryParse(s['qty']?.toString() ?? '1') ?? 1.0;
      final double rate = double.tryParse(s['rate']?.toString() ?? '0') ?? 0.0;
      final double net = double.tryParse(s['net_taxable_amount']?.toString() ?? '') ?? (qty * rate);
      allItems.add({
        'name': (s['name'] ?? 'Service').toString(),
        'qty': qty > 1 ? (qty.truncateToDouble() == qty ? qty.toInt().toString() : qty.toStringAsFixed(1)) : '1',
        'rate': rate.toStringAsFixed(2),
        'net': net.toStringAsFixed(2),
      });
    }

    for (final t in tradingItems) {
      if (t['is_operational'] == true) continue;
      final double qty = double.tryParse(t['qty']?.toString() ?? '1') ?? 1.0;
      final double rate = double.tryParse(t['rate']?.toString() ?? '0') ?? 0.0;
      final double disc = double.tryParse(t['discount']?.toString() ?? '0') ?? 0.0;
      final double net = (qty * rate) - disc;
      allItems.add({
        'name': (t['item_name'] ?? 'Stock Item').toString(),
        'qty': qty > 1 ? (qty.truncateToDouble() == qty ? qty.toInt().toString() : qty.toStringAsFixed(1)) : '1',
        'rate': rate.toStringAsFixed(2),
        'net': net.toStringAsFixed(2),
      });
    }

    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Total', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    for (final item in allItems) {
      final name = item['name'] as String;
      final qty = item['qty'] as String;
      final rate = item['rate'] as String;
      final net = item['net'] as String;

      bytes += generator.row([
        PosColumn(text: name.toUpperCase(), width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: qty, width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: rate, width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: net, width: 2, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // ── 5. TOTALS & TAX (Sub Total, VAT, Grand Total) ─────────────────────
    final double subtotal = double.tryParse(inv['subtotal']?.toString() ?? '0') ?? 0.0;
    final double discount = double.tryParse(inv['discount']?.toString() ?? '0') ?? 0.0;
    final double total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
    final double paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
    final double balance = double.tryParse(inv['balance_amount']?.toString() ?? '0') ?? (total - paid);

    final String currLabel = _cleanCurrency(currency);
    final double displaySubtotal = subtotal > 0 ? subtotal : total;

    // (Tax Included) Sub Total
    bytes += generator.row([
      PosColumn(text: '(Tax Included) Sub Total', width: 8),
      PosColumn(text: displaySubtotal.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-${discount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (taxAmount > 0) {
      final String taxLabel = (inv['tax_rate'] != null && inv['tax_rate'].toString().isNotEmpty)
          ? 'VAT@${inv['tax_rate']}%'
          : 'VAT@5%';
      bytes += generator.row([
        PosColumn(text: taxLabel, width: 8),
        PosColumn(text: taxAmount.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Grand Total (Large font, bold)
    bytes += generator.row([
      PosColumn(
        text: 'Total',
        width: 4,
        styles: PosStyles(bold: true, height: is2Inch ? PosTextSize.size1 : PosTextSize.size2),
      ),
      PosColumn(
        text: '$currLabel ${total.toStringAsFixed(2)}',
        width: 8,
        styles: PosStyles(align: PosAlign.right, bold: true, height: is2Inch ? PosTextSize.size1 : PosTextSize.size2),
      ),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Total Paid
    final double displayPaid = paid > 0 ? paid : total;
    bytes += generator.row([
      PosColumn(text: 'Total Paid', width: 6),
      PosColumn(text: '$currLabel ${displayPaid.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (balance > 0.01) {
      bytes += generator.row([
        PosColumn(text: 'Balance Due', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: '$currLabel ${balance.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static Future<List<int>> generateTestReceipt({
    required String paperSize,
    String companyName = 'AL BAB AL ABYAD AUTO SERVICES L.L.C',
  }) async {
    final profile = await CapabilityProfile.load();
    final bool is2Inch = paperSize == '2inch';
    final bool is4Inch = paperSize == '4inch';
    final PaperSize pSize = is2Inch ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(pSize, profile);
    List<int> bytes = [];

    final int lineLength = is2Inch ? 32 : (is4Inch ? 64 : 48);
    final String divider = '-' * lineLength;

    bytes += generator.reset();
    bytes += generator.text(
      companyName.toUpperCase(),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'TRN: 104092571900003',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(text: 'TAX INVOICE', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Industrial Area 4', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '# TEST-001', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Sharjah, UAE', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.feed(1);

    bytes += generator.text('Date : 13/11/2026');
    bytes += generator.text('To : 29330 MAZDA');
    bytes += generator.text('Phone : 29930 MAZDA');
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Total', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'BODY WASH-SALOON', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '1', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(text: '25.00', width: 2, styles: const PosStyles(align: PosAlign.right)),
      PosColumn(text: '25.00', width: 2, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: '(Tax Included) Sub Total', width: 8),
      PosColumn(text: '25.00', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'VAT@5%', width: 8),
      PosColumn(text: '1.19', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Total', width: 4, styles: PosStyles(bold: true, height: is2Inch ? PosTextSize.size1 : PosTextSize.size2)),
      PosColumn(
        text: 'AED 25.00',
        width: 8,
        styles: PosStyles(align: PosAlign.right, bold: true, height: is2Inch ? PosTextSize.size1 : PosTextSize.size2),
      ),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Total Paid', width: 6),
      PosColumn(text: 'AED 25.00', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static String _cleanCurrency(String curr) {
    if (curr.contains('₹') || curr.toUpperCase() == 'INR') {
      return 'Rs.';
    }
    if (curr.toUpperCase() == 'AED') return 'AED';
    if (curr.toUpperCase() == 'SAR') return 'SAR';
    if (curr.contains('\$')) return '\$';
    return curr.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
  }
}
