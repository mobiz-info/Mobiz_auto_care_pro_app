import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_pricing_controller.dart';

class ServiceRemindersCard extends StatelessWidget {
  final JobCardPricingController controller;

  const ServiceRemindersCard({
    super.key,
    required this.controller,
  });

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Widget _reminderRowWidget(BuildContext context, int index) {
    final textCtrl = controller.reminderDaysControllers[index];
    final days = int.tryParse(textCtrl.text.trim()) ?? 0;
    final scheduledDate = DateTime.now().add(Duration(days: days));
    final dateStr = days > 0
        ? '${scheduledDate.day} ${_monthNames[scheduledDate.month - 1]} ${scheduledDate.year}'
        : 'Invalid days';

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: context.tr('Reminder Days'),
                hintText: '',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
              ),
              onChanged: (_) => controller.notify(),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFF000080).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Send Date'),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000080),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => controller.removeReminderDays(index),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
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
                  Checkbox(
                    value: controller.addCustomReminders,
                    activeColor: const Color(0xFF000080),
                    onChanged: (val) => controller.toggleCustomReminders(val),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('Add Custom Reminders'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF000080),
                    size: 20,
                  ),
                ],
              ),
              if (controller.addCustomReminders) ...[
                SizedBox(height: 10.h),
                for (int i = 0; i < controller.reminderDaysControllers.length; i++) ...[
                  _reminderRowWidget(context, i),
                  SizedBox(height: 10.h),
                ],
                ElevatedButton.icon(
                  onPressed: () => controller.addReminderDays('120'),
                  icon: const Icon(Icons.add_alarm, size: 16),
                  label: Text(context.tr('+ Add Reminder Days')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
