import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

/// Lightweight, ultra-compatible ESC/POS Builder.
///
/// Sends ONLY standard binary ESC/POS commands that work on 100% of Bluetooth
/// thermal printers (POS-58, PT-210, MPT-II, GOOJPRT, Xprinter, Epson, etc.).
///
/// CRITICAL:
/// - NEVER sends `FS .` (Kanji cancel) which prints as `.` on non-Kanji portable printers.
/// - NEVER sends `ESC $` (absolute position) which desyncs portable printers.
/// - Uses binary `0x00`, `0x01`, `0x02` for alignment (NEVER ASCII digits '0','1','2').
class EscPosBuilder {
  final List<int> _buffer = [];

  EscPosBuilder() {
    reset();
  }

  void reset() {
    _buffer.addAll([0x1B, 0x40]); // ESC @ (Initialize)
    _buffer.addAll([0x1B, 0x74, 0x00]); // ESC t 0 (PC437 / Standard)
  }

  void setBold(bool enable) {
    _buffer.addAll([0x1B, 0x45, enable ? 0x01 : 0x00]); // ESC E n
  }

  void setAlign(int align) {
    // 0: Left, 1: Center, 2: Right (binary 0x00, 0x01, 0x02)
    _buffer.addAll([0x1B, 0x61, align]);
  }

  void setTextSize({bool doubleHeight = false, bool doubleWidth = false}) {
    int n = 0;
    if (doubleHeight) n |= 0x01;
    if (doubleWidth) n |= 0x10;
    _buffer.addAll([0x1D, 0x21, n]); // GS ! n
  }

  void writeLine(
    String text, {
    int align = 0,
    bool bold = false,
    bool doubleHeight = false,
    bool doubleWidth = false,
  }) {
    setAlign(align);
    if (doubleHeight || doubleWidth) setTextSize(doubleHeight: doubleHeight, doubleWidth: doubleWidth);
    if (bold) setBold(true);

    final clean = _sanitize(text);
    _buffer.addAll(latin1.encode(clean));
    _buffer.add(0x0A); // \n

    if (bold) setBold(false);
    if (doubleHeight || doubleWidth) setTextSize();
  }

  void writeTwoCol(String left, String right, int lineLen, {bool bold = false, bool doubleHeight = false}) {
    setAlign(0);
    if (doubleHeight) setTextSize(doubleHeight: true);
    if (bold) setBold(true);

    final l = _sanitize(left).trim();
    final r = _sanitize(right).trim();

    if (l.isEmpty) {
      final line = r.padLeft(lineLen);
      _buffer.addAll(latin1.encode(line));
      _buffer.add(0x0A);
    } else if (r.isEmpty) {
      _buffer.addAll(latin1.encode(l));
      _buffer.add(0x0A);
    } else if (l.length + r.length + 1 > lineLen) {
      final avail = lineLen - r.length - 1;
      if (avail >= 4) {
        final cutL = l.substring(0, avail).trim();
        final spaces = lineLen - cutL.length - r.length;
        final line = '$cutL${' ' * (spaces > 0 ? spaces : 1)}$r';
        _buffer.addAll(latin1.encode(line));
        _buffer.add(0x0A);
      } else {
        _buffer.addAll(latin1.encode(l));
        _buffer.add(0x0A);
        final line = r.padLeft(lineLen);
        _buffer.addAll(latin1.encode(line));
        _buffer.add(0x0A);
      }
    } else {
      final spaces = lineLen - l.length - r.length;
      final line = '$l${' ' * spaces}$r';
      _buffer.addAll(latin1.encode(line));
      _buffer.add(0x0A);
    }

    if (bold) setBold(false);
    if (doubleHeight) setTextSize();
  }

  void feed(int n) {
    for (int i = 0; i < n; i++) {
      _buffer.add(0x0A);
    }
  }

  /// Print raster bitmap image (GS v 0) centered
  void printRasterImage(img.Image image) {
    try {
      setAlign(1); // Center

      // Ensure width is divisible by 8
      final int width = image.width;
      final int height = image.height;
      final int widthBytes = (width + 7) ~/ 8;

      final List<int> bytes = [];
      bytes.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0 m (m=0 normal)
      bytes.add(widthBytes % 256);
      bytes.add((widthBytes ~/ 256) % 256);
      bytes.add(height % 256);
      bytes.add((height ~/ 256) % 256);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < widthBytes; x++) {
          int byteVal = 0;
          for (int b = 0; b < 8; b++) {
            final int px = x * 8 + b;
            if (px < width) {
              final pixel = image.getPixel(px, y);
              // In grayscale, lower luminance means black (dot printed)
              final luminance = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
              if (luminance < 128) {
                byteVal |= (1 << (7 - b));
              }
            }
          }
          bytes.add(byteVal);
        }
      }

      _buffer.addAll(bytes);
      _buffer.add(0x0A);
    } catch (_) {}
  }

  List<int> toBytes() => List.unmodifiable(_buffer);

  static String _sanitize(String text) {
    return text.replaceAll(RegExp(r'[^\x20-\x7E]'), ' ').trimRight();
  }
}

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
          final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 3));
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

  static String _cleanCurrency(String curr) {
    if (curr.contains('₹') || curr.toUpperCase() == 'INR') {
      return 'Rs.';
    }
    if (curr.toUpperCase() == 'AED') return 'AED';
    if (curr.toUpperCase() == 'SAR') return 'SAR';
    if (curr.contains('\$')) return '\$';
    return curr.replaceAll(RegExp(r'[^\w\s\.]'), '').trim();
  }

  static Future<List<int>> generateBillReceipt({
    required Map<String, dynamic> inv,
    required String paperSize, // '2inch' (58mm), '3inch' (80mm) or '4inch' (100mm)
    String companyName = 'AL BAB AL ABYAD AUTO SERVICES L.L.C',
    String currency = 'AED',
  }) async {
    final bool is2Inch = paperSize == '2inch';
    final bool is4Inch = paperSize == '4inch';
    final int lineLen = is2Inch ? 32 : (is4Inch ? 64 : 48);
    final String divider = '-' * lineLen;

    final printer = EscPosBuilder();

    // ── 0. LOGO BANNER (Centered) ─────────────────────────────────────────
    final String? logoUrl = inv['company_logo'] as String?;
    final int logoWidth = is2Inch ? 200 : (is4Inch ? 320 : 256);
    final logoImage = await _loadLogoImage(logoUrl, logoWidth);
    if (logoImage != null) {
      printer.printRasterImage(logoImage);
      printer.feed(1);
    }

    // ── 1. COMPANY NAME & TRN (Centered) ──────────────────────────────────
    final String authName = companyName.isNotEmpty ? companyName : 'MOBIZ AUTOCARE';
    printer.writeLine(authName.toUpperCase(), align: 1, bold: true, doubleHeight: !is2Inch);

    final String rawTrn = (inv['company_trn'] ?? inv['branch_gst'] ?? '').toString().trim();
    final String trn = rawTrn.replaceAll(RegExp(r'^(TRN\s*:\s*|TRN\s*|GSTIN\s*:\s*)', caseSensitive: false), '').trim();
    if (trn.isNotEmpty) {
      printer.writeLine('TRN: $trn', align: 1);
    }

    // Branch address lines centered and cleanly wrapped
    final String branchAddress = (inv['branch_address'] ?? '').toString().trim();
    if (branchAddress.isNotEmpty) {
      for (final rawLine in branchAddress.split('\n')) {
        final clean = rawLine.trim();
        if (clean.isNotEmpty &&
            !clean.toUpperCase().contains('TRN') &&
            !clean.toUpperCase().contains('GSTIN') &&
            !clean.contains('@') &&
            !clean.contains('www.')) {
          String rem = clean;
          while (rem.isNotEmpty) {
            if (rem.length <= lineLen) {
              printer.writeLine(rem, align: 1);
              break;
            } else {
              int cut = rem.lastIndexOf(' ', lineLen);
              if (cut <= 0) cut = lineLen;
              printer.writeLine(rem.substring(0, cut).trim(), align: 1);
              rem = rem.substring(cut).trim();
            }
          }
        }
      }
    }
    printer.feed(1);

    // ── 2. INVOICE META ───────────────────────────────────────────────────
    final double taxAmount = double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0;
    final String invoiceTitle = taxAmount > 0 ? 'TAX INVOICE' : 'CASH INVOICE';
    final String invoiceNumber = (inv['invoice_number'] ?? 'N/A').toString();

    printer.writeLine(invoiceTitle, align: 1, bold: true);
    printer.writeLine('# $invoiceNumber', align: 1, bold: true);

    String dateDisplay = (inv['date'] ?? '').toString();
    try {
      final dt = DateTime.parse(dateDisplay);
      dateDisplay = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {}
    printer.writeLine('Date : $dateDisplay', align: 0);

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
      String rem = 'To   : $toText';
      while (rem.isNotEmpty) {
        if (rem.length <= lineLen) {
          printer.writeLine(rem, align: 0);
          break;
        } else {
          int cut = rem.lastIndexOf(' ', lineLen);
          if (cut <= 7) cut = lineLen;
          printer.writeLine(rem.substring(0, cut).trim(), align: 0);
          rem = '       ${rem.substring(cut).trim()}';
        }
      }
    }

    if (custPhone.isNotEmpty) {
      printer.writeLine('Phone: $custPhone', align: 0);
    }

    printer.writeLine(divider, align: 1);

    // ── 3. ITEMS TABLE ───────────────────────────────────────────────────
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

    if (is2Inch) {
      // ── 2-INCH ROLL: 2-line layout for maximum readability ──
      for (final item in allItems) {
        final name = (item['name'] as String).toUpperCase();
        final qty = item['qty'] as String;
        final rate = item['rate'] as String;
        final net = item['net'] as String;

        // Line 1: Full Item Name
        String rem = name;
        while (rem.isNotEmpty) {
          if (rem.length <= lineLen) {
            printer.writeLine(rem, align: 0, bold: true);
            break;
          } else {
            int cut = rem.lastIndexOf(' ', lineLen);
            if (cut <= 0) cut = lineLen;
            printer.writeLine(rem.substring(0, cut).trim(), align: 0, bold: true);
            rem = rem.substring(cut).trim();
          }
        }

        // Line 2: "  1 x 1.00                  1.00"
        final leftDesc = '  $qty x $rate';
        printer.writeTwoCol(leftDesc, net, lineLen);
      }
    } else {
      // ── 3-INCH & 4-INCH ROLL: 4-column table ───────────────
      final int w1 = is4Inch ? 34 : 22;
      final int w2 = is4Inch ? 5 : 4;
      final int w3 = is4Inch ? 11 : 9;
      final int w4 = is4Inch ? 11 : 10;

      final s1Header = 'Item Description'.padRight(w1);
      final s2Header = 'Qty'.padLeft(w2);
      final s3Header = 'Price'.padLeft(w3);
      final s4Header = 'Total'.padLeft(w4);
      printer.writeLine('$s1Header $s2Header $s3Header $s4Header', bold: true, align: 0);
      printer.writeLine(divider, align: 1);

      for (final item in allItems) {
        final name = (item['name'] as String).toUpperCase();
        final qty = (item['qty'] as String).padLeft(w2);
        final rate = (item['rate'] as String).padLeft(w3);
        final net = (item['net'] as String).padLeft(w4);

        if (name.length <= w1) {
          printer.writeLine('${name.padRight(w1)} $qty $rate $net', align: 0);
        } else {
          printer.writeLine('${name.substring(0, w1)} $qty $rate $net', align: 0);
          String rem = name.substring(w1).trim();
          while (rem.isNotEmpty) {
            if (rem.length <= w1) {
              printer.writeLine(rem, align: 0);
              break;
            } else {
              int cut = rem.lastIndexOf(' ', w1);
              if (cut <= 0) cut = w1;
              printer.writeLine(rem.substring(0, cut).trim(), align: 0);
              rem = rem.substring(cut).trim();
            }
          }
        }
      }
    }

    printer.writeLine(divider, align: 1);

    // ── 4. TOTALS & TAX BREAKDOWN ─────────────────────────────────────────
    final double subtotal = double.tryParse(inv['subtotal']?.toString() ?? '0') ?? 0.0;
    final double discount = double.tryParse(inv['discount']?.toString() ?? '0') ?? 0.0;
    final double total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
    final double paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
    final double balance = double.tryParse(inv['balance_amount']?.toString() ?? '0') ?? (total - paid);

    final String currLabel = _cleanCurrency(currency);
    final double displaySubtotal = subtotal > 0 ? subtotal : total;

    printer.writeTwoCol('(Tax Included) Sub Total', displaySubtotal.toStringAsFixed(2), lineLen);

    if (discount > 0) {
      printer.writeTwoCol('Discount', '-${discount.toStringAsFixed(2)}', lineLen);
    }

    if (taxAmount > 0) {
      final String taxLabel = (inv['tax_rate'] != null && inv['tax_rate'].toString().isNotEmpty)
          ? 'VAT@${inv['tax_rate']}%'
          : 'VAT@5%';
      printer.writeTwoCol(taxLabel, taxAmount.toStringAsFixed(2), lineLen);
    }

    printer.writeLine(divider, align: 1);

    // Grand Total (Bold + Double Height)
    printer.writeTwoCol('Total', '$currLabel ${total.toStringAsFixed(2)}', lineLen, bold: true, doubleHeight: true);
    printer.writeLine(divider, align: 1);

    // Paid & Balance Due
    final double displayPaid = paid > 0 ? paid : total;
    printer.writeTwoCol('Total Paid', '$currLabel ${displayPaid.toStringAsFixed(2)}', lineLen);

    if (balance > 0.01) {
      printer.writeTwoCol('Balance Due', '$currLabel ${balance.toStringAsFixed(2)}', lineLen, bold: true);
      printer.writeLine(divider, align: 1);
    }

    // 4 blank line feeds so receipt is easy to tear off from printer teeth
    printer.feed(4);

    return printer.toBytes();
  }

  static Future<List<int>> generateTestReceipt({
    required String paperSize,
    String companyName = 'AL BAB AL ABYAD AUTO SERVICES L.L.C',
  }) async {
    final bool is2Inch = paperSize == '2inch';
    final bool is4Inch = paperSize == '4inch';
    final int lineLen = is2Inch ? 32 : (is4Inch ? 64 : 48);
    final String divider = '-' * lineLen;

    final printer = EscPosBuilder();

    printer.writeLine(companyName.toUpperCase(), align: 1, bold: true, doubleHeight: !is2Inch);
    printer.writeLine('TRN: 104092571900003', align: 1);
    printer.writeLine('Industrial Area 4, Sharjah, UAE', align: 1);
    printer.feed(1);

    printer.writeLine('TAX INVOICE', align: 1, bold: true);
    printer.writeLine('# TEST-001', align: 1, bold: true);
    printer.writeLine('Date : 13/11/2026', align: 0);
    printer.writeLine('To   : 29330 MAZDA', align: 0);
    printer.writeLine('Phone: 29930 MAZDA', align: 0);
    printer.writeLine(divider, align: 1);

    if (is2Inch) {
      printer.writeLine('BODY WASH-SALOON', align: 0, bold: true);
      printer.writeTwoCol('  1 x 25.00', '25.00', lineLen);
    } else {
      final int w1 = is4Inch ? 34 : 22;
      final int w2 = is4Inch ? 5 : 4;
      final int w3 = is4Inch ? 11 : 9;
      final int w4 = is4Inch ? 11 : 10;
      printer.writeLine('${'Item Description'.padRight(w1)} ${'Qty'.padLeft(w2)} ${'Price'.padLeft(w3)} ${'Total'.padLeft(w4)}', bold: true, align: 0);
      printer.writeLine(divider, align: 1);
      printer.writeLine('${'BODY WASH-SALOON'.padRight(w1)} ${'1'.padLeft(w2)} ${'25.00'.padLeft(w3)} ${'25.00'.padLeft(w4)}', align: 0);
    }

    printer.writeLine(divider, align: 1);
    printer.writeTwoCol('(Tax Included) Sub Total', '25.00', lineLen);
    printer.writeTwoCol('VAT@5%', '1.19', lineLen);
    printer.writeLine(divider, align: 1);

    printer.writeTwoCol('Total', 'AED 25.00', lineLen, bold: true, doubleHeight: true);
    printer.writeLine(divider, align: 1);
    printer.writeTwoCol('Total Paid', 'AED 25.00', lineLen);

    printer.feed(4);
    return printer.toBytes();
  }
}
