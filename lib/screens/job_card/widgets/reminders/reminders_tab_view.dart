import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../../controllers/job_card_reminders_controller.dart';

class RemindersTabView extends StatefulWidget {
  final JobCardController controller;
  final VoidCallback? onSwitchToServicesTab;

  const RemindersTabView({
    super.key,
    required this.controller,
    this.onSwitchToServicesTab,
  });

  @override
  State<RemindersTabView> createState() => _RemindersTabViewState();
}

class _RemindersTabViewState extends State<RemindersTabView> {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _syncServices();
  }

  void _syncServices() {
    widget.controller.remindersCtrl.syncWithServices(
      widget.controller.pricingCtrl.addedServices,
      widget.controller.issuesCtrl.reportedIssues,
    );
  }

  Widget _buildReminderRow({
    required TextEditingController controller,
    required VoidCallback onDelete,
    required VoidCallback onChanged,
  }) {
    final days = int.tryParse(controller.text.trim()) ?? 0;
    final scheduledDate = DateTime.now().add(Duration(days: days));
    final dateStr = days > 0
        ? '${scheduledDate.day} ${_monthNames[scheduledDate.month - 1]} ${scheduledDate.year}'
        : 'Invalid days';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: context.tr('Reminder Days'),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String key, ServiceReminderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.isEnabled ? const Color(0xFF000080).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: item.isEnabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: item.isEnabled
                      ? const Color(0xFF000080).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.build_circle_outlined,
                  size: 20.sp,
                  color: item.isEnabled ? const Color(0xFF000080) : Colors.grey.shade500,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.serviceName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (item.categoryName != null && item.categoryName!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        item.categoryName!,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: item.isEnabled,
                activeColor: const Color(0xFF000080),
                onChanged: (val) {
                  widget.controller.remindersCtrl.toggleServiceReminder(key, val);
                },
              ),
            ],
          ),
          if (item.isEnabled) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
            for (int i = 0; i < item.daysControllers.length; i++)
              _buildReminderRow(
                controller: item.daysControllers[i],
                onDelete: () => widget.controller.remindersCtrl.removeDaysFromService(key, i),
                onChanged: () => widget.controller.remindersCtrl.notify(),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => widget.controller.remindersCtrl.addDaysToService(key),
                icon: const Icon(Icons.add_alarm, size: 16),
                label: Text(
                  context.tr('+ Add Reminder Days'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF000080),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.controller.remindersCtrl,
        widget.controller.pricingCtrl,
        widget.controller.issuesCtrl,
      ]),
      builder: (context, _) {
        _syncServices();
        final remindersCtrl = widget.controller.remindersCtrl;
        final services = remindersCtrl.serviceReminders;
        final customList = remindersCtrl.customReminders;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 24.sp,
                        color: const Color(0xFF000080),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Service Reminders'),
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF000080),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            context.tr('Enable reminders for specific services. Reminders will be scheduled and sent to the customer via WhatsApp.'),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Empty services notice
              if (services.isEmpty) ...[
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.build_circle_outlined, size: 40.sp, color: Colors.grey.shade400),
                      SizedBox(height: 8.h),
                      Text(
                        context.tr('No Services Added Yet'),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        context.tr('Add services or reported complaints first to configure their service reminders.'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
                      ),
                      if (widget.onSwitchToServicesTab != null) ...[
                        SizedBox(height: 12.h),
                        OutlinedButton.icon(
                          onPressed: widget.onSwitchToServicesTab,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: Text(context.tr('Go to Services & Complaints')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Service Cards
              for (final entry in services.entries)
                _buildServiceCard(entry.key, entry.value),

              // Custom Reminders
              if (customList.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    context.tr('Custom / Additional Reminders'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                for (int i = 0; i < customList.length; i++) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFF000080).withValues(alpha: 0.3), width: 1.5),
                    ),
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alarm, color: const Color(0xFF000080), size: 18.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                customList[i].serviceName,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => remindersCtrl.removeCustomReminder(i),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Divider(color: Colors.grey.shade200, height: 1),
                        ),
                        for (int d = 0; d < customList[i].daysControllers.length; d++)
                          _buildReminderRow(
                            controller: customList[i].daysControllers[d],
                            onDelete: () {
                              customList[i].removeDays(d);
                              remindersCtrl.notify();
                            },
                            onChanged: () => remindersCtrl.notify(),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              customList[i].addDays('120');
                              remindersCtrl.notify();
                            },
                            icon: const Icon(Icons.add_alarm, size: 16),
                            label: Text(
                              context.tr('+ Add Reminder Days'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.sp),
                            ),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF000080)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Button to add general custom reminder
              OutlinedButton.icon(
                onPressed: () => remindersCtrl.addCustomReminder(),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(context.tr('+ Add General Custom Reminder')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF000080),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}
