import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';

class ExpectedDeliveryDateCard extends StatelessWidget {
  final JobCardController controller;

  const ExpectedDeliveryDateCard({
    super.key,
    required this.controller,
  });

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = controller.expectedDeliveryDate ?? now.add(const Duration(hours: 4));

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now.subtract(const Duration(days: 1))) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: controller.expectedDeliveryTime ?? TimeOfDay.fromDateTime(initial),
      );

      controller.expectedDeliveryDate = date;
      if (time != null) {
        controller.expectedDeliveryTime = time;
      }
      controller.notify();
    }
  }

  void _setPresetDays(int days) {
    final target = DateTime.now().add(Duration(days: days));
    controller.expectedDeliveryDate = DateTime(target.year, target.month, target.day);
    controller.expectedDeliveryTime ??= const TimeOfDay(hour: 17, minute: 0);
    controller.notify();
  }

  Widget _presetChip(BuildContext context, String label, int days) {
    return InkWell(
      onTap: () => _setPresetDays(days),
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFF000080).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: const Color(0xFF000080).withValues(alpha: 0.2)),
        ),
        child: Text(
          context.tr(label),
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF000080),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasDate = controller.expectedDeliveryDate != null;
        String formatted = '';
        if (hasDate) {
          formatted = DateFormat('dd-MM-yyyy').format(controller.expectedDeliveryDate!);
          if (controller.expectedDeliveryTime != null) {
            formatted += ' ${controller.expectedDeliveryTime!.format(context)}';
          }
        }

        return Container(
          margin: EdgeInsets.only(top: 14.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(7.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000080).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.event_available_outlined,
                          size: 18.sp,
                          color: const Color(0xFF000080),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('Expected Delivery Date'),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  if (hasDate)
                    InkWell(
                      onTap: () {
                        controller.expectedDeliveryDate = null;
                        controller.expectedDeliveryTime = null;
                        controller.notify();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Text(
                          context.tr('Clear'),
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),

              // Date-Time selection input
              InkWell(
                onTap: () => _pickDateTime(context),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: hasDate ? const Color(0xFF000080).withValues(alpha: 0.3) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 20.sp,
                        color: hasDate ? const Color(0xFF000080) : Colors.grey.shade500,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          hasDate ? formatted : context.tr('Select expected delivery date & time'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: hasDate ? FontWeight.w700 : FontWeight.w500,
                            color: hasDate ? const Color(0xFF0F172A) : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Quick preset buttons
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  _presetChip(context, 'Today', 0),
                  _presetChip(context, 'Tomorrow', 1),
                  _presetChip(context, 'In 2 Days', 2),
                  _presetChip(context, 'In 3 Days', 3),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

