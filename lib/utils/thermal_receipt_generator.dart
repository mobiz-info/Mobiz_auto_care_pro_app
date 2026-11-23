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

  /// Two columns (Left and Right aligned) formatted with pure spaces (NO ESC $).
  /// This prevents garbage characters on all Bluetooth thermal printers.
  static String _twoCol(String left, String right, int lineLen) {
    final l = left.trim();
    final r = right.trim();
    if (l.isEmpty) {
      if (r.length >= lineLen) return r;
      return r.padLeft(lineLen);
    }
    if (r.isEmpty) {
      return l;
    }
    if (l.length + r.length + 1 > lineLen) {
      final avail = lineLen - r.length - 1;
      if (avail >= 4) {
        final cutL = l.substring(0, avail).trim();
        final spaces = lineLen - cutL.length - r.length;
        return '$cutL${' ' * (spaces > 0 ? spaces : 1)}$r';
      }
      return '$l\n${r.padLeft(lineLen)}';
    }
    final spaces = lineLen - l.length - r.length;
    return '$l${' ' * spaces}$r';
  }

  /// Four columns table row (Item, Qty, Price, Total) formatted with spaces.
  static List<String> _formatTableRow({
    required String col1,
    required String col2,
    required String col3,
    required String col4,
    required int lineLen,
  }) {
    final bool is2Inch = lineLen <= 32;
    final bool is4Inch = lineLen >= 64;

    final int w1 = is2Inch ? 14 : (is4Inch ? 34 : 22);
    final int w2 = is2Inch ? 3 : (is4Inch ? 5 : 4);
    final int w3 = is2Inch ? 6 : (is4Inch ? 11 : 9);
    final int w4 = is2Inch ? 6 : (is4Inch ? 11 : 10);

    final s2 = col2.padLeft(w2);
    final s3 = col3.padLeft(w3);
    final s4 = col4.padLeft(w4);
    final suffix = ' $s2 $s3 $s4';

    final lines = <String>[];
    if (col1.length <= w1) {
      final s1 = col1.padRight(w1);
      lines.add('$s1$suffix');
    } else {
      final part1 = col1.substring(0, w1).trim().padRight(w1);
      lines.add('$part1$suffix');
      String remaining = col1.substring(w1).trim();
      while (remaining.isNotEmpty) {
        if (remaining.length <= lineLen) {
          lines.add(remaining);
          break;
        } else {
          lines.add(remaining.substring(0, lineLen).trim());
          remaining = remaining.substring(lineLen).trim();
        }
      }
    }
    return lines;
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
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    if (trn.isNotEmpty) {
      bytes += generator.text(
        'TRN: $trn',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.feed(1);

    // ── 2. INVOICE META & ADDRESS (Side-by-side using space padding) ──────
    final String branchAddress = (inv['branch_address'] ?? '').toString().trim();
    final List<String> addressLines = [];
    if (branchAddress.isNotEmpty) {
      for (final l in branchAddress.split('\n')) {
        final clean = l.trim();
        if (clean.isNotEmpty &&
            !clean.toUpperCase().contains('TRN') &&
            !clean.toUpperCase().contains('GSTIN') &&
            !clean.contains('@') &&
            !clean.contains('www.')) {
          addressLines.add(clean);
        }
      }
    }
    if (addressLines.isEmpty && inv['branch'] != null) {
      addressLines.add(inv['branch'].toString());
    }

    final double taxAmount = double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0;
    final String invoiceTitle = taxAmount > 0 ? 'TAX INVOICE' : 'CASH INVOICE';
    final String invoiceNumber = (inv['invoice_number'] ?? 'N/A').toString();

    final String addr0 = addressLines.isNotEmpty ? addressLines[0] : '';
    final String addr1 = addressLines.length > 1 ? addressLines[1] : '';

    bytes += generator.text(_twoCol(invoiceTitle, addr0, lineLength), styles: const PosStyles(bold: true));
    bytes += generator.text(_twoCol('# $invoiceNumber', addr1, lineLength), styles: const PosStyles(bold: true));

    for (int i = 2; i < addressLines.length; i++) {
      bytes += generator.text(_twoCol('', addressLines[i], lineLength));
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

    // Header row
    final headerLines = _formatTableRow(
      col1: 'Item',
      col2: 'Qty',
      col3: 'Price',
      col4: 'Total',
      lineLen: lineLength,
    );
    for (final hl in headerLines) {
      bytes += generator.text(hl, styles: const PosStyles(bold: true));
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Item rows
    for (final item in allItems) {
      final name = item['name'] as String;
      final qty = item['qty'] as String;
      final rate = item['rate'] as String;
      final net = item['net'] as String;

      final rows = _formatTableRow(
        col1: name.toUpperCase(),
        col2: qty,
        col3: rate,
        col4: net,
        lineLen: lineLength,
      );
      for (final r in rows) {
        bytes += generator.text(r);
      }
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
    bytes += generator.text(
      _twoCol('(Tax Included) Sub Total', displaySubtotal.toStringAsFixed(2), lineLength),
    );

    if (discount > 0) {
      bytes += generator.text(
        _twoCol('Discount', '-${discount.toStringAsFixed(2)}', lineLength),
      );
    }

    if (taxAmount > 0) {
      final String taxLabel = (inv['tax_rate'] != null && inv['tax_rate'].toString().isNotEmpty)
          ? 'VAT@${inv['tax_rate']}%'
          : 'VAT@5%';
      bytes += generator.text(
        _twoCol(taxLabel, taxAmount.toStringAsFixed(2), lineLength),
      );
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Grand Total (Bold)
    bytes += generator.text(
      _twoCol('Total', '$currLabel ${total.toStringAsFixed(2)}', lineLength),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Total Paid
    final double displayPaid = paid > 0 ? paid : total;
    bytes += generator.text(
      _twoCol('Total Paid', '$currLabel ${displayPaid.toStringAsFixed(2)}', lineLength),
    );

    if (balance > 0.01) {
      bytes += generator.text(
        _twoCol('Balance Due', '$currLabel ${balance.toStringAsFixed(2)}', lineLength),
        styles: const PosStyles(bold: true),
      );
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

    bytes += generator.text(
      _twoCol('TAX INVOICE', 'Industrial Area 4', lineLength),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      _twoCol('# TEST-001', 'Sharjah, UAE', lineLength),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.feed(1);

    bytes += generator.text('Date : 13/11/2026');
    bytes += generator.text('To : 29330 MAZDA');
    bytes += generator.text('Phone : 29930 MAZDA');
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    final headerLines = _formatTableRow(
      col1: 'Item',
      col2: 'Qty',
      col3: 'Price',
      col4: 'Total',
      lineLen: lineLength,
    );
    for (final hl in headerLines) {
      bytes += generator.text(hl, styles: const PosStyles(bold: true));
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    final rows = _formatTableRow(
      col1: 'BODY WASH-SALOON',
      col2: '1',
      col3: '25.00',
      col4: '25.00',
      lineLen: lineLength,
    );
    for (final r in rows) {
      bytes += generator.text(r);
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(
      _twoCol('(Tax Included) Sub Total', '25.00', lineLength),
    );
    bytes += generator.text(
      _twoCol('VAT@5%', '1.19', lineLength),
    );
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(
      _twoCol('Total', 'AED 25.00', lineLength),
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text(
      _twoCol('Total Paid', 'AED 25.00', lineLength),
    );

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
