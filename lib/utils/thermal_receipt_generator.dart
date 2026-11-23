import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class ThermalReceiptGenerator {
  static Future<List<int>> generateBillReceipt({
    required Map<String, dynamic> inv,
    required String paperSize, // '3inch' (80mm) or '4inch' (100mm)
    String companyName = 'Mobiz Autocare Pro',
    String currency = 'AED',
  }) async {
    final profile = await CapabilityProfile.load();
    // Use PaperSize.mm80 as base ESC/POS generator
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final bool is4Inch = paperSize == '4inch';
    final int lineLength = is4Inch ? 64 : 48;
    final String divider = '-' * lineLength;
    final String doubleDivider = '=' * lineLength;

    // Reset printer
    bytes += generator.reset();

    // ── 1. HEADER ────────────────────────────────────────────────────────
    final String branchName = (inv['branch'] ?? '').toString().trim();
    final String branchAddress = (inv['branch_address'] ?? '').toString().trim();
    final String branchPhone = (inv['branch_phone'] ?? '').toString().trim();
    final String branchEmail = (inv['branch_email'] ?? '').toString().trim();
    final String rawTrn = (inv['company_trn'] ?? inv['branch_gst'] ?? '').toString().trim();
    final String trn = rawTrn.replaceAll(RegExp(r'^(TRN\s*:\s*|TRN\s*|GSTIN\s*:\s*)', caseSensitive: false), '').trim();

    // Company Name (Centered, Bold, Double Height)
    bytes += generator.text(
      companyName.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    if (branchName.isNotEmpty) {
      bytes += generator.text(
        branchName,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    if (branchAddress.isNotEmpty) {
      // Clean up multiline address
      for (final line in branchAddress.split('\n')) {
        final clean = line.trim();
        if (clean.isNotEmpty) {
          bytes += generator.text(clean, styles: const PosStyles(align: PosAlign.center));
        }
      }
    }

    if (branchPhone.isNotEmpty) {
      bytes += generator.text('Tel: $branchPhone', styles: const PosStyles(align: PosAlign.center));
    }
    if (branchEmail.isNotEmpty) {
      bytes += generator.text('Email: $branchEmail', styles: const PosStyles(align: PosAlign.center));
    }
    if (trn.isNotEmpty) {
      bytes += generator.text(
        'TRN / GSTIN: $trn',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.text(doubleDivider, styles: const PosStyles(align: PosAlign.center));

    // ── 2. INVOICE META ──────────────────────────────────────────────────
    final double taxAmount = double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0;
    final String invoiceTitle = taxAmount > 0 ? 'TAX INVOICE' : 'CASH INVOICE';
    final String invoiceNumber = (inv['invoice_number'] ?? 'N/A').toString();
    final String invoiceDate = (inv['date'] ?? '').toString();

    bytes += generator.text(
      invoiceTitle,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size1),
    );
    bytes += generator.feed(1);

    bytes += generator.row([
      PosColumn(text: 'Invoice No:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: invoiceNumber, width: 8, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    if (invoiceDate.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Date & Time:', width: 4),
        PosColumn(text: invoiceDate, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    // Customer Info
    final cust = inv['customer'] is Map ? (inv['customer'] as Map) : null;
    final String custName = (cust?['name'] ?? inv['customer_name'] ?? '').toString().trim();
    final String custPhone = (cust?['phone'] ?? inv['customer_phone'] ?? '').toString().trim();
    if (custName.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Customer:', width: 4),
        PosColumn(
          text: custPhone.isNotEmpty ? '$custName ($custPhone)' : custName,
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    // Vehicle Info
    final veh = inv['vehicle'] is Map ? (inv['vehicle'] as Map) : null;
    final String vehNum = (veh?['number'] ?? inv['vehicle_number'] ?? '').toString().trim();
    final String vehModel = (veh?['model'] ?? veh?['name'] ?? '').toString().trim();
    if (vehNum.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Vehicle No:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: vehModel.isNotEmpty ? '$vehNum - $vehModel' : vehNum,
          width: 8,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    // Payment Mode
    String paymentMode = (inv['payment_mode'] ?? '').toString().trim();
    if (paymentMode.isEmpty) {
      paymentMode = inv['invoice_type'] == 'creditinvoice' ? 'Credit' : 'Cash';
    } else {
      paymentMode = paymentMode.replaceAll('_', ' ').toUpperCase();
    }
    bytes += generator.row([
      PosColumn(text: 'Payment Mode:', width: 5),
      PosColumn(text: paymentMode, width: 7, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

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
        'raw_rate': rate,
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
        'raw_rate': rate,
      });
    }

    // Header Row
    if (is4Inch) {
      // 4-Inch Wide Layout: Description (5), Qty (2), Rate (2), Amount (3)
      bytes += generator.row([
        PosColumn(text: 'Item Description', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'Rate', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(text: 'Amount', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    } else {
      // 3-Inch Standard Layout: Description (6), Qty (2), Total (4)
      bytes += generator.row([
        PosColumn(text: 'Item Description', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'Total', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Item Rows
    for (final item in allItems) {
      final name = item['name'] as String;
      final qty = item['qty'] as String;
      final rate = item['rate'] as String;
      final net = item['net'] as String;

      if (is4Inch) {
        bytes += generator.row([
          PosColumn(text: name, width: 5),
          PosColumn(text: qty, width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: rate, width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: net, width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: name, width: 6),
          PosColumn(text: qty, width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: net, width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // ── 4. TOTALS & TAX ──────────────────────────────────────────────────
    final double subtotal = double.tryParse(inv['subtotal']?.toString() ?? '0') ?? 0.0;
    final double discount = double.tryParse(inv['discount']?.toString() ?? '0') ?? 0.0;
    final double total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
    final double paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
    final double balance = double.tryParse(inv['balance_amount']?.toString() ?? '0') ?? (total - paid);

    // Clean currency label (avoid unicode symbols that break on thermal hardware fonts)
    final String currLabel = _cleanCurrency(currency);

    if (subtotal > 0) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(text: '$currLabel ${subtotal.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 6),
        PosColumn(text: '-$currLabel ${discount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (taxAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'VAT / Tax:', width: 6),
        PosColumn(text: '$currLabel ${taxAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // GRAND TOTAL (Double Height & Bold)
    bytes += generator.row([
      PosColumn(text: 'TOTAL AMOUNT:', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: '$currLabel ${total.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]);

    bytes += generator.text(doubleDivider, styles: const PosStyles(align: PosAlign.center));

    if (paid > 0) {
      bytes += generator.row([
        PosColumn(text: 'Paid Amount:', width: 6),
        PosColumn(text: '$currLabel ${paid.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (balance > 0.01) {
      bytes += generator.row([
        PosColumn(text: 'Balance Due:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: '$currLabel ${balance.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));
    }

    // ── 5. QR CODE & FOOTER ──────────────────────────────────────────────
    bytes += generator.feed(1);
    try {
      // Print QR code with invoice number or payload
      final String qrData = 'INVOICE:$invoiceNumber|DATE:$invoiceDate|TOTAL:$total|TRN:$trn';
      bytes += generator.qrcode(qrData, align: PosAlign.center);
    } catch (_) {}

    bytes += generator.feed(1);
    bytes += generator.text(
      'Thank you for your visit!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Drive Safe & Have a Great Day',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  static Future<List<int>> generateTestReceipt({
    required String paperSize,
    String companyName = 'Mobiz Autocare Pro',
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final bool is4Inch = paperSize == '4inch';
    final int lineLength = is4Inch ? 64 : 48;
    final String divider = '-' * lineLength;
    final String doubleDivider = '=' * lineLength;

    bytes += generator.reset();
    bytes += generator.text(
      companyName.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'BLUETOOTH PRINTER TEST',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Paper Size: ${is4Inch ? "4 Inch (100mm)" : "3 Inch (80mm)"}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(doubleDivider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Item Name', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(text: 'Amount', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'Car Wash & Wax', width: 6),
      PosColumn(text: '1', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(text: '50.00', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Interior Vacuum', width: 6),
      PosColumn(text: '1', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(text: '30.00', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: 'TOTAL TEST:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '80.00', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text(doubleDivider, styles: const PosStyles(align: PosAlign.center));

    bytes += generator.feed(1);
    bytes += generator.text('SUCCESS: Printer Connected & Working!', styles: const PosStyles(align: PosAlign.center, bold: true));
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
