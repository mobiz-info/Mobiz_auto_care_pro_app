import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_issues_controller.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../../models/job_card_model.dart';
import '../common/job_item_widgets.dart';
import '../common/section_card.dart';

class LabourCard extends StatelessWidget {
  final JobCardPricingController pricingCtrl;
  final JobCardIssuesController issuesCtrl;
  final List<Map<String, dynamic>> staffList;

  const LabourCard({
    super.key,
    required this.pricingCtrl,
    required this.issuesCtrl,
    this.staffList = const [],
  });

  Widget _jobItemInput(
    BuildContext context,
    Map<String, dynamic> row,
    String field,
    String label, {
    bool numeric = true,
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
                initialValue: (row[field] ?? '').toString(),
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: jobQuoteLikeDecoration(),
                onChanged: (value) {
                  row[field] = value;
                  pricingCtrl.recalculateJobItem(row);
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
              '${context.tr('Total')} ${pricingCtrl.rowTotal(row).toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

  String _calculateDuration(Map<String, dynamic> activity) {
    final startStr = (activity['started_at'] ?? '').toString();
    final endStr = (activity['completed_at'] ?? '').toString();
    if (startStr.isEmpty || endStr.isEmpty) return '';

    try {
      final start = DateTime.tryParse(startStr);
      final end = DateTime.tryParse(endStr);
      if (start != null && end != null) {
        final diff = end.difference(start);
        if (diff.isNegative) return '';
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
        if (hours > 0) return '${hours}h';
        if (mins > 0) return '${mins}m';
        return '< 1m';
      }
    } catch (_) {}
    return '';
  }

  void _syncActivityLabour(
    Map<String, dynamic> activity,
    List<Map<String, dynamic>> staffLabour,
  ) {
    double totalCost = 0;
    double totalDiscount = 0;
    for (final s in staffLabour) {
      totalCost += JobCardConstants.numberOrZero(s['cost']);
      totalDiscount += JobCardConstants.numberOrZero(s['discount']);
    }
    activity['cost'] = totalCost;
    activity['discount'] = totalDiscount;
    activity['staff_labour'] = staffLabour;
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();

    return AnimatedBuilder(
      animation: Listenable.merge([pricingCtrl, issuesCtrl]),
      builder: (context, _) {
        final reportedIssues = issuesCtrl.reportedIssues;
        final labourSubtotal = pricingCtrl.calculateLabourSubtotal(reportedIssues);

        return SectionCard(
          title: context.tr('Labour Charge'),
          fields: [
            ...reportedIssues.expand((report) {
              final activities = report['activities'] as List? ?? [];
              final serviceName = report['service']?['name'] ?? report['issue_text'] ?? '';

              return activities.map((raw) {
                final activity = raw as Map<String, dynamic>;
                final activityKey = activity['id'] ??
                    '${report['issue_text']}-${activity['name']}';

                final assignedStaffIds = List<String>.from(
                  (activity['assigned_staff_ids'] as List? ?? [])
                      .map((id) => id.toString())
                      .where((id) => id.isNotEmpty),
                );
                if (assignedStaffIds.isEmpty && (activity['staff_id'] ?? '').toString().isNotEmpty) {
                  assignedStaffIds.add(activity['staff_id'].toString());
                }

                final autoDuration = _calculateDuration(activity);

                // Prepare staff labour rows
                List<Map<String, dynamic>> staffLabour = [];
                final existingStaffLabour = activity['staff_labour'];
                if (existingStaffLabour is List && existingStaffLabour.isNotEmpty) {
                  staffLabour = existingStaffLabour
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();
                }

                if (assignedStaffIds.isNotEmpty) {
                  final existingIds = staffLabour.map((e) => e['staff_id']?.toString()).toSet();
                  for (final staffId in assignedStaffIds) {
                    if (!existingIds.contains(staffId)) {
                      String sName = '';
                      if (staffList.isNotEmpty) {
                        final found = staffList.firstWhere(
                          (s) => s['id']?.toString() == staffId,
                          orElse: () => {},
                        );
                        sName = (found['name'] ?? '').toString();
                      }
                      if (sName.isEmpty) {
                        sName = (activity['staff_name'] ?? '').toString();
                      }
                      staffLabour.add({
                        'staff_id': staffId,
                        'staff_name': sName.isNotEmpty ? sName : 'Staff #$staffId',
                        'cost': staffLabour.isEmpty && assignedStaffIds.length == 1
                            ? (activity['cost']?.toString() ?? '0')
                            : '0',
                        'discount': staffLabour.isEmpty && assignedStaffIds.length == 1
                            ? (activity['discount']?.toString() ?? '0')
                            : '0',
                        'time': autoDuration,
                      });
                    }
                  }
                  // Clean up removed staff
                  staffLabour.removeWhere(
                    (e) => !assignedStaffIds.contains(e['staff_id']?.toString()),
                  );
                } else {
                  // Fallback when no specific staff assigned
                  if (staffLabour.isEmpty) {
                    staffLabour.add({
                      'staff_id': '',
                      'staff_name': (activity['staff_name'] ?? '').toString().isNotEmpty
                          ? activity['staff_name'].toString()
                          : context.tr('Unassigned'),
                      'cost': activity['cost']?.toString() ?? '0',
                      'discount': activity['discount']?.toString() ?? '0',
                      'time': autoDuration,
                    });
                  }
                }

                activity['staff_labour'] = staffLabour;
                final net = JobCardPricingController.activityLabourNet(activity);

                return Container(
                  key: ValueKey('activity-labour-$activityKey'),
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: REdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$serviceName · ${activity['name']}',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF000080).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '$currencySymbol ${net.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF000080),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Staff Rows
                      ...staffLabour.asMap().entries.map((entry) {
                        final sIndex = entry.key;
                        final sRow = entry.value;
                        final sStaffName = (sRow['staff_name'] ?? '').toString();
                        final sCost = JobCardConstants.numberOrZero(sRow['cost']);
                        final sDisc = JobCardConstants.numberOrZero(sRow['discount']);
                        final sNet = (sCost - sDisc).clamp(0, double.infinity);
                        final sStaffId = sRow['staff_id'] ?? '$sIndex';

                        return Container(
                          key: ValueKey('staff-labour-row-$activityKey-$sStaffId-$sIndex'),
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 11.r,
                                    backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      size: 13.sp,
                                      color: const Color(0xFF000080),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      sStaffName.isNotEmpty ? sStaffName : context.tr('Staff'),
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${context.tr('Total')}: $currencySymbol ${sNet.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF000080),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  // Cost
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('staff-cost-$activityKey-$sStaffId'),
                                      initialValue: (sRow['cost'] ?? '').toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: GoogleFonts.inter(fontSize: 12.sp),
                                      decoration: InputDecoration(
                                        labelText: context.tr('Cost'),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                      ),
                                      onChanged: (val) {
                                        sRow['cost'] = val;
                                        _syncActivityLabour(activity, staffLabour);
                                        pricingCtrl.notify();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // Discount
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('staff-disc-$activityKey-$sStaffId'),
                                      initialValue: (sRow['discount'] ?? '').toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: GoogleFonts.inter(fontSize: 12.sp),
                                      decoration: InputDecoration(
                                        labelText: context.tr('Discount'),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                      ),
                                      onChanged: (val) {
                                        sRow['discount'] = val;
                                        _syncActivityLabour(activity, staffLabour);
                                        pricingCtrl.notify();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // Time
                                  Expanded(
                                    flex: 4,
                                    child: TextFormField(
                                      key: ValueKey('staff-time-$activityKey-$sStaffId'),
                                      initialValue: (sRow['time'] ?? '').toString(),
                                      style: GoogleFonts.inter(fontSize: 12.sp),
                                      decoration: InputDecoration(
                                        labelText: context.tr('Time'),
                                        hintText: 'e.g. 1.5h',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                      ),
                                      onChanged: (val) {
                                        sRow['time'] = val;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              });
            }),
            if (pricingCtrl.addedLabour.isEmpty &&
                reportedIssues.every(
                  (report) => (report['activities'] as List? ?? []).isEmpty,
                ))
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  context.tr('No activity or labour charges added.'),
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
            ...List.generate(pricingCtrl.addedLabour.length, (index) {
              final row = pricingCtrl.addedLabour[index];
              return JobItemCard(
                title: context.tr('Labour'),
                index: index,
                onDelete: () {
                  pricingCtrl.addedLabour.removeAt(index);
                  pricingCtrl.notify();
                },
                showTitle: false,
                children: [
                  _jobItemInput(
                    context,
                    row,
                    'labour_particulars',
                    'Labour',
                    numeric: false,
                    fullWidth: true,
                  ),
                  _jobItemInput(context, row, 'rate', 'Cost'),
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
                onPressed: pricingCtrl.addLabourToTable,
                icon: const Icon(Icons.add),
                label: Text(context.tr('Add labour')),
              ),
            ),
            SizedBox(height: 10.h),

            // Labour Subtotal banner before Extras
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
                    context.tr('Labour Subtotal'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${labourSubtotal.toStringAsFixed(2)}',
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
