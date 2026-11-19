import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_issues_controller.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../common/section_card.dart';

class IssuePricingCard extends StatelessWidget {
  final JobCardIssuesController issuesCtrl;
  final JobCardPricingController pricingCtrl;

  const IssuePricingCard({
    super.key,
    required this.issuesCtrl,
    required this.pricingCtrl,
  });

  Widget _issuePriceInput(
    BuildContext context,
    int index,
    String key,
    String label, {
    bool decimal = false,
    int maxLines = 1,
    String? hintText,
  }) =>
      TextFormField(
        key: ValueKey(
          'job-issue-field-$index-$key-${issuesCtrl.reportedIssues[index]['report_id'] ?? issuesCtrl.reportedIssues[index]['issue_text']}',
        ),
        initialValue: issuesCtrl.reportedIssues[index][key]?.toString() ?? '',
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 13.sp),
        onChanged: (value) {
          issuesCtrl.reportedIssues[index][key] = value;
          pricingCtrl.notify();
        },
        decoration: InputDecoration(
          labelText: context.tr(label),
          hintText: hintText != null ? context.tr(hintText) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
    return AnimatedBuilder(
      animation: Listenable.merge([issuesCtrl, pricingCtrl]),
      builder: (context, _) {
        final issues = issuesCtrl.reportedIssues;
        final legacyServices = pricingCtrl.addedServices;
        final subtotal = pricingCtrl.calculateServicesSubtotal(issues);

        return SectionCard(
          title: context.tr('Services & Repairs Pricing'),
          fields: [
            if (issues.isEmpty && legacyServices.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20.sp,
                      color: const Color(0xFF000080),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        context.tr(
                          'No services added yet. Add services in Tab 3 (Services & Issues) to set pricing.',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // ── Tab 3 Services / Issues ──
              ...List.generate(issues.length, (index) {
                final row = issues[index];
                final rate = double.tryParse(row['rate']?.toString() ?? '') ?? 0;
                final quantity =
                    double.tryParse(row['quantity']?.toString() ?? '') ?? 1;
                final discount =
                    double.tryParse(row['discount']?.toString() ?? '') ?? 0;
                final total =
                    (rate * quantity - discount).clamp(0, double.infinity);
                final serviceName = (row['service']?['name'] ?? 'Service').toString();
                final categoryName = (row['category']?['name'] ?? '').toString();
                final issueText = (row['issue_text'] ?? '').toString();
                final hasSpecificComplaint = issueText.isNotEmpty &&
                    issueText.toLowerCase() != serviceName.toLowerCase();

                return Container(
                  key: ValueKey(
                    'job-issue-pricing-$index-${row['report_id'] ?? row['issue_text']}',
                  ),
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: REdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (categoryName.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    margin: EdgeInsets.only(bottom: 3.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E7FF),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3730A3),
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${index + 1}. $serviceName',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (hasSpecificComplaint)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.h),
                                    child: Text(
                                      '${context.tr('Complaint')}: $issueText',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFFD97706),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '$currencySymbol ${total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5.sp,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _issuePriceInput(
                              context,
                              index,
                              'rate',
                              'Rate',
                              decimal: true,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            flex: 2,
                            child: _issuePriceInput(
                              context,
                              index,
                              'quantity',
                              'Qty',
                              decimal: true,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            flex: 3,
                            child: _issuePriceInput(
                              context,
                              index,
                              'discount',
                              'Discount',
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _issuePriceInput(
                              context,
                              index,
                              'warranty',
                              'Warranty (Optional)',
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _issuePriceInput(
                              context,
                              index,
                              'remarks',
                              'Remarks (Optional)',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // ── Any Legacy / Additional Services (without duplicate form) ──
              if (legacyServices.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Text(
                    context.tr('Additional Services'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ...List.generate(legacyServices.length, (lIndex) {
                  final s = legacyServices[lIndex];
                  final totalAmt = (s['total_amount'] as num?)?.toDouble() ?? 0;
                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (s['service_name'] ?? s['name'] ?? 'Service').toString(),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                        Text(
                          '$currencySymbol ${totalAmt.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000080),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          onPressed: () {
                            pricingCtrl.addedServices.removeAt(lIndex);
                            pricingCtrl.notify();
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],

              SizedBox(height: 6.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${context.tr('Services Subtotal')}: $currencySymbol ${subtotal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000080),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
