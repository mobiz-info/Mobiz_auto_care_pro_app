import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../common/job_item_widgets.dart';
import '../common/section_card.dart';

class ExtrasCard extends StatelessWidget {
  final JobCardPricingController controller;

  const ExtrasCard({
    super.key,
    required this.controller,
  });

  Widget _jobItemInput(
    BuildContext context,
    Map<String, dynamic> row,
    String field,
    String label, {
    bool numeric = true,
    String initial = '',
    bool fullWidth = false,
  }) =>
      JobItemInputWidget(
        fullWidth: fullWidth,
        child: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(label),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 5.h),
              TextFormField(
                key: ValueKey('${identityHashCode(row)}_$field'),
                initialValue: (row[field] ?? initial).toString(),
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: jobQuoteLikeDecoration(),
                onChanged: (value) {
                  row[field] = value;
                  controller.recalculateJobItem(row);
                },
              ),
            ],
          ),
        ),
      );

  Widget _jobItemTotal(BuildContext context, Map<String, dynamic> row) =>
      JobItemTotalWidget(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${context.tr('Total')} ${controller.rowTotal(row).toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SectionCard(
          title: context.tr('Extras'),
          fields: [
            if (controller.addedExtras.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  context.tr('No extras added.'),
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
            ...List.generate(controller.addedExtras.length, (index) {
              final row = controller.addedExtras[index];
              return JobItemCard(
                title: (row['extra_details'] ?? '').toString(),
                index: index,
                onDelete: () {
                  controller.addedExtras.removeAt(index);
                  controller.notify();
                },
                showTitle: false,
                children: [
                  _jobItemInput(
                    context,
                    row,
                    'extra_details',
                    'Extra name',
                    numeric: false,
                    fullWidth: true,
                  ),
                  _jobItemInput(context, row, 'rate', 'Rate'),
                  _jobItemInput(context, row, 'quantity', 'Qty', initial: '1'),
                  _jobItemInput(context, row, 'discount', 'Discount'),
                  _jobItemTotal(context, row),
                  _jobItemInput(
                    context,
                    row,
                    'remarks',
                    'Remarks',
                    numeric: false,
                    fullWidth: true,
                  ),
                ],
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: controller.addExtraToTable,
                icon: const Icon(Icons.add),
                label: Text(context.tr('Add extra')),
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('Extras Subtotal'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${controller.extrasSubtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
