import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import 'accessories_card.dart';
import 'issue_pricing_card.dart';
import 'labour_card.dart';
import 'extras_card.dart';
import 'schedule_signoff_card.dart';

class PricingTabView extends StatelessWidget {
  final JobCardController controller;
  final VoidCallback? onSwitchToLocalPurchaseTab;

  const PricingTabView({
    super.key,
    required this.controller,
    this.onSwitchToLocalPurchaseTab,
  });

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? color,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 13.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 13.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
    return AnimatedBuilder(
      animation: Listenable.merge([controller, controller.pricingCtrl]),
      builder: (context, _) {
        final issues = controller.issuesCtrl.reportedIssues;
        final servicesTotal = controller.pricingCtrl.calculateServicesSubtotal(issues);
        final partsTotal = controller.pricingCtrl.partsSubtotal;
        final labourTotal = controller.pricingCtrl.calculateLabourSubtotal(issues);
        final extrasTotal = controller.pricingCtrl.extrasSubtotal;
        final localPurchasesTotal = controller.pricingCtrl.localPurchasesSubtotal;
        final localPurchases = controller.pricingCtrl.addedLocalPurchases;
        final grandTotal = controller.pricingCtrl.calculateGrandEstimatedTotal(issues);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IssuePricingCard(
                issuesCtrl: controller.issuesCtrl,
                pricingCtrl: controller.pricingCtrl,
              ),
              SizedBox(height: 14.h),
              AccessoriesCard(controller: controller.pricingCtrl),
              SizedBox(height: 14.h),

              // Local Purchases Section in Pricing Tab
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15803D).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 18.sp,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Local Purchases'),
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                localPurchases.isEmpty
                                    ? context.tr('No local purchases added')
                                    : '${localPurchases.length} ${context.tr("items added")} • $currencySymbol ${localPurchasesTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onSwitchToLocalPurchaseTab != null)
                          TextButton.icon(
                            onPressed: onSwitchToLocalPurchaseTab,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF000080).withValues(alpha: 0.08),
                              foregroundColor: const Color(0xFF000080),
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                            ),
                            icon: Icon(Icons.add, size: 14.sp),
                            label: Text(
                              localPurchases.isEmpty ? context.tr('Add') : context.tr('Manage'),
                              style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    if (localPurchases.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      SizedBox(height: 8.h),
                      ...localPurchases.map((lp) {
                        final name = (lp['item_name'] ?? '-').toString();
                        final supplier = (lp['supplier_name'] ?? '').toString();
                        final bill = (lp['bill_number'] ?? '').toString();
                        final qty = double.tryParse((lp['quantity'] ?? '1').toString()) ?? 1.0;
                        final rate = double.tryParse((lp['rate'] ?? '0').toString()) ?? 0.0;
                        final total = (lp['total_amount'] as num?)?.toDouble() ?? (qty * rate);

                        String subtitle = supplier;
                        if (bill.isNotEmpty) {
                          subtitle = subtitle.isNotEmpty ? '$subtitle ($bill)' : bill;
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty)
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5.sp,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} × $currencySymbol ${rate.toStringAsFixed(2)} = $currencySymbol ${total.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF000080),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              LabourCard(
                pricingCtrl: controller.pricingCtrl,
                issuesCtrl: controller.issuesCtrl,
                staffList: controller.staff,
              ),
              SizedBox(height: 14.h),
              ExtrasCard(controller: controller.pricingCtrl),
              SizedBox(height: 14.h),
              ScheduleSignoffCard(controller: controller),
              SizedBox(height: 16.h),

              // Comprehensive Pricing Summary Card (Section totals + Grand Total)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xFF000080).withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 18.sp,
                          color: const Color(0xFF000080),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Pricing Summary'),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    _buildSummaryRow(
                      label: context.tr('Services Total'),
                      value: '$currencySymbol ${servicesTotal.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 8.h),
                    _buildSummaryRow(
                      label: context.tr('Accessories Total'),
                      value: '$currencySymbol ${partsTotal.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 8.h),
                    _buildSummaryRow(
                      label: context.tr('Labour Total'),
                      value: '$currencySymbol ${labourTotal.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 8.h),
                    _buildSummaryRow(
                      label: context.tr('Extras Total'),
                      value: '$currencySymbol ${extrasTotal.toStringAsFixed(2)}',
                    ),
                    if (localPurchasesTotal > 0) ...[
                      SizedBox(height: 8.h),
                      _buildSummaryRow(
                        label: context.tr('Local Purchases Total'),
                        value: '$currencySymbol ${localPurchasesTotal.toStringAsFixed(2)}',
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('Grand Total'),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF000080),
                          ),
                        ),
                        Text(
                          '$currencySymbol ${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}
