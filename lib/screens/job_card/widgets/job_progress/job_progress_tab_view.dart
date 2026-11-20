import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../common/section_card.dart';
import '../vehicle/vehicle_before_after_photos_card.dart';

class JobProgressTabView extends StatelessWidget {
  final JobCardController controller;

  const JobProgressTabView({
    super.key,
    required this.controller,
  });

  Widget _buildSummaryCard(
    BuildContext context, {
    required int total,
    required int pending,
    required int inProgress,
    required int parked,
    required int completed,
  }) {
    final percent = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final percentText = (percent * 100).toInt();

    return Container(
      padding: REdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: const Color(0xFF000080),
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr('Overall Progress'),
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: percent == 1.0
                      ? const Color(0xFFDEF7EC)
                      : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '$percentText% ${context.tr('Done')}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: percent == 1.0
                        ? const Color(0xFF03543F)
                        : const Color(0xFF3730A3),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent == 1.0
                    ? const Color(0xFF10B981)
                    : const Color(0xFF000080),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildCounterBadge(
                context,
                count: pending,
                label: 'Pending',
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
                icon: Icons.access_time_filled,
              ),
              _buildCounterBadge(
                context,
                count: inProgress,
                label: 'In Progress',
                bgColor: const Color(0xFFDBEAFE),
                textColor: const Color(0xFF1E40AF),
                icon: Icons.play_circle_filled,
              ),
              _buildCounterBadge(
                context,
                count: parked,
                label: 'Parked',
                bgColor: const Color(0xFFFEF3C7),
                textColor: const Color(0xFFB45309),
                icon: Icons.pause_circle_filled,
              ),
              _buildCounterBadge(
                context,
                count: completed,
                label: 'Completed',
                bgColor: const Color(0xFFDCFCE7),
                textColor: const Color(0xFF166534),
                icon: Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge(
    BuildContext context, {
    required int count,
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: textColor),
          SizedBox(width: 5.w),
          Text(
            '$count ${context.tr(label)}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bg;
    Color text;
    Color border;
    IconData icon;
    String label;

    if (status == 'completed') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF166534);
      border = const Color(0xFF86EFAC);
      icon = Icons.check_circle;
      label = 'Completed';
    } else if (status == 'started') {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF1E40AF);
      border = const Color(0xFF93C5FD);
      icon = Icons.play_circle_filled;
      label = 'In Progress';
    } else if (status == 'parked') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      border = const Color(0xFFFCD34D);
      icon = Icons.pause_circle_filled;
      label = 'Parked';
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
      border = const Color(0xFFCBD5E1);
      icon = Icons.access_time_filled;
      label = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.r, color: text),
          SizedBox(width: 4.w),
          Text(
            context.tr(label),
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final startedAtStr = (item['started_at'] ?? '').toString();
    final completedAtStr = (item['completed_at'] ?? '').toString();
    final parkedAtStr = (item['parked_at'] ?? '').toString();
    final status = (item['status'] ?? 'pending').toString();

    if (startedAtStr.isEmpty && parkedAtStr.isEmpty) return const SizedBox.shrink();

    final timeFormat = DateFormat('h:mm a');
    final startedAt = DateTime.tryParse(startedAtStr)?.toLocal();
    final startedText = startedAt != null ? timeFormat.format(startedAt) : '';

    if (status == 'completed' && completedAtStr.isNotEmpty) {
      final completedAt = DateTime.tryParse(completedAtStr)?.toLocal();
      final completedText = completedAt != null ? timeFormat.format(completedAt) : '';
      String durationText = '';
      if (completedAt != null && startedAt != null) {
        final diff = completedAt.difference(startedAt);
        if (diff.inHours > 0) {
          durationText = ' (${diff.inHours}h ${diff.inMinutes % 60}m)';
        } else {
          durationText = ' (${diff.inMinutes}m)';
        }
      }

      return Padding(
        padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
        child: Row(
          children: [
            Icon(Icons.history, size: 13.r, color: Colors.grey.shade600),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                '${context.tr('Started')}: $startedText · ${context.tr('Completed')}: $completedText$durationText',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'parked' && parkedAtStr.isNotEmpty) {
      final parkedAt = DateTime.tryParse(parkedAtStr)?.toLocal();
      final parkedText = parkedAt != null ? timeFormat.format(parkedAt) : '';
      return Padding(
        padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline, size: 13.r, color: const Color(0xFFB45309)),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                '${context.tr('Parked at')}: $parkedText${startedText.isNotEmpty ? ' (${context.tr('Started')}: $startedText)' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (startedAt != null) {
      final diff = DateTime.now().difference(startedAt);
      String elapsedText = diff.inHours > 0
          ? '${diff.inHours}h ${diff.inMinutes % 60}m ${context.tr('ago')}'
          : '${diff.inMinutes}m ${context.tr('ago')}';

      return Padding(
        padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 13.r,
              color: const Color(0xFF1E40AF),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                '${context.tr('Started')}: $startedText ($elapsedText)',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showParkedDialog(BuildContext context, Map<String, dynamic> item) {
    final remarkCtrl = TextEditingController(text: (item['parked_remark'] ?? '').toString());
    final quickRemarks = [
      'Waiting for parts',
      'Customer approval pending',
      'Bay / Lift occupied',
      'Technician on break',
      'Inspection needed',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.pause, color: const Color(0xFFB45309), size: 20.r),
              ),
              SizedBox(width: 10.w),
              Text(
                context.tr('Park Work'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Select or enter reason for parking this task:'),
                  style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade700),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: quickRemarks.map((qr) {
                    final isSelected = remarkCtrl.text == qr;
                    return ChoiceChip(
                      label: Text(
                        context.tr(qr),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF000080),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onSelected: (selected) {
                        setDialogState(() {
                          remarkCtrl.text = selected ? qr : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: remarkCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: context.tr('Remarks / Reason'),
                    hintText: context.tr('e.g. Waiting for oil filter delivery'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Cancel'), style: GoogleFonts.inter(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () {
                final now = DateTime.now().toUtc().toIso8601String();
                item['status'] = 'parked';
                item['parked_at'] = now;
                item['parked_remark'] = remarkCtrl.text.trim();
                controller.notify();
                Navigator.pop(ctx);
              },
              child: Text(context.tr('Park Work'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiStaffPicker(BuildContext context, Map<String, dynamic> item) {
    final currentStaffIds = List<String>.from(
      (item['assigned_staff_ids'] as List? ?? [])
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty),
    );
    if (currentStaffIds.isEmpty && (item['staff_id'] ?? '').toString().isNotEmpty) {
      currentStaffIds.add(item['staff_id'].toString());
    }

    final selected = Set<String>.from(currentStaffIds);
    var searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final allStaff = controller.staff;
          final filteredStaff = allStaff.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                14.h,
                16.w,
                MediaQuery.viewInsetsOf(ctx).bottom + 16.h,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('Assign Staff (Multiple)'),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF000080),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.tr('Search staff...'),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      onChanged: (val) => setSheetState(() => searchQuery = val),
                    ),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: filteredStaff.isEmpty
                          ? Center(
                              child: Text(
                                context.tr('No staff found'),
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredStaff.length,
                              itemBuilder: (ctx, idx) {
                                final s = filteredStaff[idx];
                                final sId = s['id'].toString();
                                final sName = (s['name'] ?? '').toString();
                                final isChecked = selected.contains(sId);

                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(
                                    sName,
                                    style: GoogleFonts.inter(
                                      fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                      color: isChecked ? const Color(0xFF000080) : Colors.black87,
                                    ),
                                  ),
                                  secondary: CircleAvatar(
                                    radius: 14.r,
                                    backgroundColor: isChecked ? const Color(0xFF000080) : const Color(0xFFE2E8F0),
                                    child: Text(
                                      sName.isNotEmpty ? sName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: isChecked ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  activeColor: const Color(0xFF000080),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selected.add(sId);
                                      } else {
                                        selected.remove(sId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        if (selected.isNotEmpty)
                          TextButton(
                            onPressed: () => setSheetState(() => selected.clear()),
                            child: Text(context.tr('Clear All'), style: const TextStyle(color: Colors.red)),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          onPressed: () {
                            final list = selected.toList();
                            item['assigned_staff_ids'] = list;
                            item['staff_id'] = list.isNotEmpty ? list.first : '';
                            controller.notify();
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            '${context.tr('Apply')} (${selected.length})',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffChipsAndBayRow(BuildContext context, Map<String, dynamic> item) {
    final staffIds = List<String>.from(
      (item['assigned_staff_ids'] as List? ?? [])
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty),
    );
    if (staffIds.isEmpty && (item['staff_id'] ?? '').toString().isNotEmpty) {
      staffIds.add(item['staff_id'].toString());
    }

    final staffNames = <String>[];
    for (final sid in staffIds) {
      final s = controller.staff.firstWhere(
        (st) => st['id']?.toString() == sid,
        orElse: () => {'name': ''},
      );
      if ((s['name'] ?? '').toString().isNotEmpty) {
        staffNames.add(s['name'].toString());
      }
    }

    final currentBay = item['bay']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Bay Dropdown (1 to 10)
            Expanded(
              flex: 4,
              child: Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: (currentBay != null && currentBay.isNotEmpty && int.tryParse(currentBay) != null)
                        ? currentBay
                        : null,
                    isDense: true,
                    hint: Row(
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 15.sp, color: Colors.grey.shade600),
                        SizedBox(width: 4.w),
                        Text(
                          context.tr('Bay'),
                          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          context.tr('No Bay'),
                          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade500),
                        ),
                      ),
                      ...List.generate(10, (i) {
                        final bayNum = (i + 1).toString();
                        return DropdownMenuItem<String?>(
                          value: bayNum,
                          child: Text(
                            'Bay $bayNum',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF000080),
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      item['bay'] = val != null ? int.tryParse(val) : null;
                      controller.notify();
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Multi-staff trigger
            Expanded(
              flex: 6,
              child: InkWell(
                onTap: () => _showMultiStaffPicker(context, item),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  height: 40.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16.sp, color: const Color(0xFF000080)),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          staffNames.isEmpty
                              ? context.tr('Assign Staff')
                              : staffNames.length == 1
                                  ? staffNames.first
                                  : '${staffNames.length} ${context.tr('Staff Assigned')}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: staffNames.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                            color: staffNames.isNotEmpty ? const Color(0xFF000080) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (staffNames.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: staffNames.map((name) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 12.sp, color: const Color(0xFF1E40AF)),
                    SizedBox(width: 3.w),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildParkedRemarkBanner(BuildContext context, String remark) {
    if (remark.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(top: 6.h, bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14.sp, color: const Color(0xFFB45309)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              '${context.tr('Reason')}: $remark',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required Map<String, dynamic> item,
    required String title,
    required String subtitle,
    required int orderNumber,
    required VoidCallback onMoveUp,
    required VoidCallback onMoveDown,
    required bool canMoveUp,
    required bool canMoveDown,
    String? categoryBadge,
  }) {
    final status = (item['status'] ?? 'pending').toString();
    final parkedRemark = (item['parked_remark'] ?? '').toString();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: REdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: status == 'completed'
              ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
              : status == 'started'
                  ? const Color(0xFF93C5FD).withValues(alpha: 0.6)
                  : status == 'parked'
                      ? const Color(0xFFFCD34D).withValues(alpha: 0.8)
                      : Colors.grey.shade200,
          width: status == 'started' || status == 'parked' ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number, Title, and Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Order Number Badge with reorder arrows
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '#$orderNumber',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              if (canMoveUp || canMoveDown) ...[
                SizedBox(width: 4.w),
                if (canMoveUp)
                  InkWell(
                    onTap: onMoveUp,
                    child: Padding(
                      padding: EdgeInsets.all(2.r),
                      child: Icon(Icons.arrow_upward, size: 14.sp, color: const Color(0xFF000080)),
                    ),
                  ),
                if (canMoveDown)
                  InkWell(
                    onTap: onMoveDown,
                    child: Padding(
                      padding: EdgeInsets.all(2.r),
                      child: Icon(Icons.arrow_downward, size: 14.sp, color: const Color(0xFF000080)),
                    ),
                  ),
              ],
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryBadge != null && categoryBadge.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: Text(
                          categoryBadge,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, status),
            ],
          ),
          SizedBox(height: 4.h),
          _buildTimeDetails(context, item),
          if (status == 'parked') _buildParkedRemarkBanner(context, parkedRemark),
          SizedBox(height: 6.h),
          _buildStaffChipsAndBayRow(context, item),
          SizedBox(height: 10.h),
          // Dynamic Action Buttons
          Row(
            children: [
              // Pending: [Start Work] + [Complete]
              if (status == 'pending') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final now = DateTime.now().toUtc().toIso8601String();
                      item['status'] = 'started';
                      item['started_at'] = now;
                      controller.notify();
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(context.tr('Start Work')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E40AF),
                      side: const BorderSide(color: Color(0xFF1E40AF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      final now = DateTime.now().toUtc().toIso8601String();
                      item['status'] = 'completed';
                      item['started_at'] ??= now;
                      item['completed_at'] = now;
                      controller.notify();
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(context.tr('Complete')),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDCFCE7),
                      foregroundColor: const Color(0xFF166534),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
              // Started: [Parked] + [Mark Done]
              if (status == 'started') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showParkedDialog(context, item),
                    icon: const Icon(Icons.pause, size: 16),
                    label: Text(context.tr('Parked')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFB45309)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now().toUtc().toIso8601String();
                      item['status'] = 'completed';
                      item['started_at'] ??= now;
                      item['completed_at'] = now;
                      controller.notify();
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(context.tr('Mark Done')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
              // Parked: [Resume Work]
              if (status == 'parked') ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      item['status'] = 'started';
                      controller.notify();
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(context.tr('Resume / Start Work')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
              // Completed: [Re-open Task]
              if (status == 'completed') ...[
                TextButton.icon(
                  onPressed: () {
                    item['status'] = 'started';
                    item['completed_at'] = null;
                    controller.notify();
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(
                    context.tr('Re-open Task'),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
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
        final issues = controller.issuesCtrl.reportedIssues;

        int totalCount = 0;
        int pendingCount = 0;
        int inProgressCount = 0;
        int parkedCount = 0;
        int completedCount = 0;

        for (final report in issues) {
          final acts = report['activities'] as List? ?? [];
          if (acts.isEmpty) {
            // Service without activities is itself a task
            totalCount++;
            final st = (report['status'] ?? 'pending').toString();
            if (st == 'completed') {
              completedCount++;
            } else if (st == 'started') {
              inProgressCount++;
            } else if (st == 'parked') {
              parkedCount++;
            } else {
              pendingCount++;
            }
          } else {
            for (final raw in acts) {
              totalCount++;
              final st = (raw['status'] ?? 'pending').toString();
              if (st == 'completed') {
                completedCount++;
              } else if (st == 'started') {
                inProgressCount++;
              } else if (st == 'parked') {
                parkedCount++;
              } else {
                pendingCount++;
              }
            }
          }
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VehicleBeforeAfterPhotosCard(controller: controller),
              if (issues.isEmpty)
                SectionCard(
                  title: context.tr('Job Progress'),
                  fields: [
                    Text(
                      context.tr(
                        'Add reported services and issues first.',
                      ),
                    ),
                  ],
                )
              else ...[
                if (totalCount > 0)
                  _buildSummaryCard(
                    context,
                    total: totalCount,
                    pending: pendingCount,
                    inProgress: inProgressCount,
                    parked: parkedCount,
                    completed: completedCount,
                  ),
                ...List.generate(issues.length, (reportIndex) {
                  final report = issues[reportIndex];
                  final activities = report['activities'] as List? ?? [];
                  final catName = report['category']?['name'] ?? '';
                  final svcName = report['service']?['name'] ?? report['issue_text'] ?? '';
                  final isServiceStandalone = activities.isEmpty;

                  if (isServiceStandalone) {
                    // Render standalone service without activities
                    return _buildTaskCard(
                      context,
                      item: report,
                      title: svcName.isNotEmpty ? svcName : context.tr('General Service'),
                      subtitle: catName,
                      categoryBadge: catName.isNotEmpty ? catName : null,
                      orderNumber: reportIndex + 1,
                      canMoveUp: reportIndex > 0,
                      canMoveDown: reportIndex < issues.length - 1,
                      onMoveUp: () {
                        if (reportIndex > 0) {
                          final prev = issues[reportIndex - 1];
                          issues[reportIndex - 1] = report;
                          issues[reportIndex] = prev;
                          report['sort_order'] = reportIndex - 1;
                          prev['sort_order'] = reportIndex;
                          controller.notify();
                        }
                      },
                      onMoveDown: () {
                        if (reportIndex < issues.length - 1) {
                          final next = issues[reportIndex + 1];
                          issues[reportIndex + 1] = report;
                          issues[reportIndex] = next;
                          report['sort_order'] = reportIndex + 1;
                          next['sort_order'] = reportIndex;
                          controller.notify();
                        }
                      },
                    );
                  }

                  // Service WITH activities
                  final allActivitiesDone = activities.isNotEmpty &&
                      activities.every(
                        (a) => (a['status'] ?? '').toString() == 'completed',
                      );

                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: SectionCard(
                      title: '$catName · $svcName',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reportIndex > 0)
                            InkWell(
                              onTap: () {
                                final prev = issues[reportIndex - 1];
                                issues[reportIndex - 1] = report;
                                issues[reportIndex] = prev;
                                report['sort_order'] = reportIndex - 1;
                                prev['sort_order'] = reportIndex;
                                controller.notify();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(4.r),
                                child: Icon(Icons.arrow_upward, size: 16.sp, color: const Color(0xFF000080)),
                              ),
                            ),
                          if (reportIndex < issues.length - 1)
                            InkWell(
                              onTap: () {
                                final next = issues[reportIndex + 1];
                                issues[reportIndex + 1] = report;
                                issues[reportIndex] = next;
                                report['sort_order'] = reportIndex + 1;
                                next['sort_order'] = reportIndex;
                                controller.notify();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(4.r),
                                child: Icon(Icons.arrow_downward, size: 16.sp, color: const Color(0xFF000080)),
                              ),
                            ),
                          SizedBox(width: 6.w),
                          allActivitiesDone
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        size: 13.r,
                                        color: const Color(0xFF166534),
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        context.tr('Done'),
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    final now = DateTime.now().toUtc().toIso8601String();
                                    for (final raw in activities) {
                                      final act = raw as Map<String, dynamic>;
                                      act['status'] = 'completed';
                                      act['started_at'] ??= now;
                                      act['completed_at'] = now;
                                    }
                                    controller.notify();
                                  },
                                  icon: Icon(
                                    Icons.done_all,
                                    size: 14.r,
                                    color: const Color(0xFF000080),
                                  ),
                                  label: Text(
                                    context.tr('Mark All Done'),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF000080),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      fields: [
                        ...List.generate(activities.length, (actIndex) {
                          final activity = activities[actIndex] as Map<String, dynamic>;
                          return _buildTaskCard(
                            context,
                            item: activity,
                            title: (activity['name'] ?? '').toString(),
                            subtitle: svcName,
                            orderNumber: actIndex + 1,
                            canMoveUp: actIndex > 0,
                            canMoveDown: actIndex < activities.length - 1,
                            onMoveUp: () {
                              if (actIndex > 0) {
                                final prev = activities[actIndex - 1];
                                activities[actIndex - 1] = activity;
                                activities[actIndex] = prev;
                                activity['sort_order'] = actIndex - 1;
                                prev['sort_order'] = actIndex;
                                controller.notify();
                              }
                            },
                            onMoveDown: () {
                              if (actIndex < activities.length - 1) {
                                final next = activities[actIndex + 1];
                                activities[actIndex + 1] = activity;
                                activities[actIndex] = next;
                                activity['sort_order'] = actIndex + 1;
                                next['sort_order'] = actIndex;
                                controller.notify();
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
