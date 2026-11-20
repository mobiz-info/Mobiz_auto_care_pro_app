import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../config/country_config.dart';
import '../../controllers/job_card_controller.dart';
import '../../models/job_card_model.dart';
import '../common/section_card.dart';

class BillingTabView extends StatefulWidget {
  final JobCardController controller;

  const BillingTabView({
    super.key,
    required this.controller,
  });

  @override
  State<BillingTabView> createState() => _BillingTabViewState();
}

class _BillingTabViewState extends State<BillingTabView> {
  Future<Uint8List> _getInvoicePdfBytes(Map<String, dynamic> inv) async {
    final invoiceNumber = (inv['invoice_number'] ?? '').toString();
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
    return Uint8List(0);
  }

  Future<void> _viewInvoicePdf(Map<String, dynamic> inv) async {
    final invoiceNumber = (inv['invoice_number'] ?? '').toString();
    final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final pdfUrl = "$baseUrl/media/invoices/invoice-$cleanInvoiceNo.pdf";
    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final bytes = await _getInvoicePdfBytes(inv);
      if (bytes.isNotEmpty) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'invoice-$cleanInvoiceNo.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printInvoice(Map<String, dynamic> inv) async {
    try {
      final invoiceNumber = (inv['invoice_number'] ?? '').toString();
      final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');
      final bytes = await _getInvoicePdfBytes(inv);
      if (bytes.isNotEmpty) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'invoice-$cleanInvoiceNo.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareInvoicePdf(Map<String, dynamic> inv) async {
    try {
      final invoiceNumber = (inv['invoice_number'] ?? '').toString();
      final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');
      final bytes = await _getInvoicePdfBytes(inv);
      if (bytes.isNotEmpty) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/invoice-$cleanInvoiceNo.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Invoice $invoiceNumber');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareOnWhatsApp(Map<String, dynamic> inv) async {
    final currencySymbol = context.read<AuthProvider>().currencySymbol.trim();
    final customer = widget.controller.customerCtrl.selectedCustomer;
    String phone = (customer?['whatsapp_number'] ?? customer?['whatsapp'] ?? customer?['phone'] ?? '').toString();
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceNumber = (inv['invoice_number'] ?? '').toString();
    final cleanInvoiceNo = invoiceNumber.replaceAll('/', '_');
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final pdfUrl = "$baseUrl/media/invoices/invoice-$cleanInvoiceNo.pdf";
    final message = "Dear ${customer?['name'] ?? 'Customer'},\nYour invoice *$invoiceNumber* has been generated.\nTotal: $currencySymbol ${inv['total']}\nBalance: $currencySymbol ${inv['balance']}\nView/Download PDF: $pdfUrl\nThank you!";
    final waUrl = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    try {
      final uri = Uri.parse(waUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final billingCtrl = widget.controller.billingCtrl;
      final jobCardId = widget.controller.savedJobCardId ?? widget.controller.existingJobCardId;
      if (jobCardId != null && !billingCtrl.loadingJobCardInvoice && billingCtrl.jobCardInvoice == null) {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          billingCtrl.loadJobCardInvoice(jobCardId, token);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.controller.billingCtrl]),
      builder: (context, _) {
        final billingCtrl = widget.controller.billingCtrl;
        final pricingCtrl = widget.controller.pricingCtrl;
        final issues = widget.controller.issuesCtrl.reportedIssues;
        final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();

        final issuePricingSubtotal = pricingCtrl.calculateIssuePricingSubtotal(issues);
        final servicesSubtotal = pricingCtrl.calculateServicesSubtotal(issues);
        final labourSubtotal = pricingCtrl.calculateLabourSubtotal(issues);
        final billingTotal = pricingCtrl.calculateBillingTotal(issues);
        final discountAmount = billingCtrl.calculateDiscount(billingTotal);
        final effectiveTotal = billingCtrl.calculateEffectiveTotal(billingTotal);

        if (billingCtrl.loadingJobCardInvoice) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  context.tr('Loading billing details...'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (billingCtrl.jobCardInvoice != null) {
          final invoice = billingCtrl.jobCardInvoice!;
          final isPaid = numberOrZero(invoice['balance']) <= 0;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: context.tr('Invoice Created'),
                  fields: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${invoice['invoice_number'] ?? 'INVOICE'}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isPaid ? const Color(0xFF166534) : const Color(0xFFB45309),
                            ),
                          ),
                          child: Text(
                            context.tr(isPaid ? 'Paid' : 'Partially Paid'),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: isPaid ? const Color(0xFF166534) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    overviewAmountLine(
                      context,
                      'Invoice Total',
                      numberOrZero(invoice['total']),
                      emphasized: true,
                    ),
                    overviewAmountLine(
                      context,
                      'Amount Collected',
                      numberOrZero(invoice['amount_collected']),
                    ),
                    overviewAmountLine(
                      context,
                      'Balance Due',
                      numberOrZero(invoice['balance']),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () => _viewInvoicePdf(invoice),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: Text(
                        context.tr('View / Download Invoice PDF'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printInvoice(invoice),
                            icon: const Icon(Icons.print, size: 18),
                            label: Text(context.tr('Print PDF')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF000080),
                              side: const BorderSide(color: Color(0xFF000080)),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareOnWhatsApp(invoice),
                            icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                            label: Text(context.tr('WhatsApp')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          tooltip: context.tr('Share PDF'),
                          onPressed: () => _shareInvoicePdf(invoice),
                          icon: const Icon(Icons.share, color: Color(0xFF000080)),
                          style: IconButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          );
        }

        if (billingCtrl.billingAmountController.text.isEmpty) {
          billingCtrl.billingAmountController.text = effectiveTotal.toStringAsFixed(2);
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: context.tr('Billing Summary'),
                fields: [
                  overviewAmountLine(
                    context,
                    'Issue Pricing',
                    issuePricingSubtotal,
                  ),
                  overviewAmountLine(
                    context,
                    'Additional Services',
                    (servicesSubtotal - issuePricingSubtotal).clamp(0, double.infinity),
                  ),
                  overviewAmountLine(
                    context,
                    'Accessories',
                    pricingCtrl.partsSubtotal,
                  ),
                  overviewAmountLine(
                    context,
                    'Labour',
                    labourSubtotal,
                  ),
                  overviewAmountLine(
                    context,
                    'Extras',
                    pricingCtrl.extrasSubtotal,
                  ),
                  const Divider(),
                  overviewAmountLine(
                    context,
                    discountAmount > 0 ? 'Subtotal' : 'Invoice Total (including item taxes)',
                    billingTotal,
                    emphasized: discountAmount <= 0,
                  ),
                  if (discountAmount > 0) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${context.tr('Discount')} (${billingCtrl.discountType == 'percent' ? '${billingCtrl.discountController.text}%' : currencySymbol})',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            '- $currencySymbol ${discountAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    overviewAmountLine(
                      context,
                      'Net Payable Total',
                      effectiveTotal,
                      emphasized: true,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14.h),
              SectionCard(
                title: context.tr('Invoice Discount'),
                fields: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'amount',
                        label: Text(context.tr('Amount ($currencySymbol)')),
                        icon: const Icon(Icons.attach_money, size: 16),
                      ),
                      ButtonSegment(
                        value: 'percent',
                        label: Text(context.tr('Percentage (%)')),
                        icon: const Icon(Icons.percent, size: 16),
                      ),
                    ],
                    selected: {billingCtrl.discountType},
                    onSelectionChanged: (selection) {
                      billingCtrl.setDiscountType(selection.first, billingTotal);
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: billingCtrl.discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: billingCtrl.discountType == 'percent'
                          ? context.tr('Discount Percentage (%)')
                          : context.tr('Discount Amount ($currencySymbol)'),
                      prefixIcon: Icon(
                        billingCtrl.discountType == 'percent' ? Icons.percent : Icons.discount_outlined,
                        size: 18.r,
                      ),
                      suffixText: billingCtrl.discountType == 'percent' && discountAmount > 0
                          ? '≈ $currencySymbol ${discountAmount.toStringAsFixed(2)}'
                          : null,
                      suffixStyle: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    onChanged: (_) {
                      billingCtrl.updateTotals(billingTotal);
                    },
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              SectionCard(
                title: context.tr('Payment'),
                fields: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'cash', label: Text(context.tr('Cash Invoice'))),
                      ButtonSegment(value: 'credit', label: Text(context.tr('Credit Invoice'))),
                    ],
                    selected: {billingCtrl.billingSaleType},
                    onSelectionChanged: (selection) {
                      billingCtrl.setBillingSaleType(
                        selection.first,
                        billingTotal,
                      );
                    },
                  ),
                  if (billingCtrl.billingSaleType == 'cash') ...[
                    SizedBox(height: 12.h),
                    TextField(
                      controller: billingCtrl.billingAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: context.tr('Amount Collected'),
                        prefixText: '${context.watch<AuthProvider>().currencySymbol.trim()} ',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      value: (CountryConfig.isUAE && billingCtrl.billingPaymentMode == 'digital_payments')
                          ? 'cash'
                          : billingCtrl.billingPaymentMode,
                      decoration: InputDecoration(labelText: context.tr('Payment Mode')),
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text(context.tr('Cash'))),
                        DropdownMenuItem(value: 'card', child: Text(context.tr('Card'))),
                        if (!CountryConfig.isUAE)
                          DropdownMenuItem(
                            value: 'digital_payments',
                            child: Text(context.tr('Digital Payment')),
                          ),
                      ],
                      onChanged: (value) => billingCtrl.setBillingPaymentMode(value ?? 'cash'),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: widget.controller.isSubmitting
                    ? null
                    : () {
                        final token = context.read<AuthProvider>().token;
                        if (token != null) {
                          widget.controller.submitJobCard(token: token);
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: Text(context.tr('Save Job Card Without Invoice')),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
