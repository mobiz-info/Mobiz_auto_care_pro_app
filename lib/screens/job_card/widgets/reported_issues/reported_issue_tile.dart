import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_issues_controller.dart';
import 'issue_photo_viewer.dart';

class ReportedIssueTile extends StatelessWidget {
  final int index;
  final JobCardIssuesController controller;

  const ReportedIssueTile({
    super.key,
    required this.index,
    required this.controller,
  });

  List<Widget> _jobActivitySuggestions(
    BuildContext context,
    Map<String, dynamic> row,
  ) {
    final query = controller
        .activityDraftController(row, index)
        .text
        .trim()
        .toLowerCase();
    if (query.isEmpty) return const [];
    final serviceId = row['service']?['id']?.toString();
    final matches = controller.jobActivityChoices
        .where((option) {
          return option['service_id']?.toString() == serviceId &&
              option['name'].toString().toLowerCase().contains(query);
        })
        .take(6)
        .toList();
    if (matches.isEmpty) return const [];
    return [
      Container(
        constraints: BoxConstraints(maxHeight: 180.h),
        margin: EdgeInsets.only(top: 4.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: matches.length,
          itemBuilder: (context, matchIndex) {
            final option = matches[matchIndex];
            return ListTile(
              dense: true,
              title: Text(option['name'].toString()),
              onTap: () {
                controller.activityDraftController(row, index).text =
                    option['name'].toString();
                controller.notify();
                controller.activityDraftFocusNode(row, index).requestFocus();
              },
            );
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final row = controller.reportedIssues[index];
    final localPhotos = List<XFile>.from(row['photos'] as List? ?? []);
    final remotePhotos = List<Map<String, dynamic>>.from(
      row['existing_photos'] as List? ?? [],
    );
    final token = context.watch<AuthProvider>().token ?? '';

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: REdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['category']['name'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      row['service']['name'].toString(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    if ((row['issue_text'] ?? '').toString().isNotEmpty &&
                        row['issue_text'].toString().toLowerCase() !=
                            row['service']['name'].toString().toLowerCase()) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '${context.tr('Complaint')}: ${row['issue_text']}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.editReportedIssue(index),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF000080)),
              ),
              IconButton(
                onPressed: () => controller.deleteReportedIssue(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          if (localPhotos.isNotEmpty || remotePhotos.isNotEmpty)
            Wrap(
              spacing: 8.w,
              children: [
                ...remotePhotos.map(
                  (photo) => JobRemoteIssuePhotoWidget(
                    photo: photo,
                    onRemove: () {},
                    showRemove: false,
                  ),
                ),
                ...localPhotos.map(
                  (photo) => JobLocalIssuePhotoWidget(
                    photo: photo,
                    onRemove: () {},
                    showRemove: false,
                  ),
                ),
              ],
            ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey(
                    'activity-draft-${controller.activityDraftKey(row, index)}',
                  ),
                  controller: controller.activityDraftController(row, index),
                  focusNode: controller.activityDraftFocusNode(row, index),
                  decoration: InputDecoration(
                    labelText: context.tr('Activity'),
                    hintText: context.tr('Enter activity'),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  onChanged: (value) {
                    row['activity_draft'] = value;
                    controller.notify();
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton.filled(
                tooltip: context.tr('Add activity'),
                onPressed: () => controller.appendJobActivity(
                  index,
                  token,
                  onMessage: (msg) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  ),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          ..._jobActivitySuggestions(context, row),
          if ((row['activities'] as List? ?? []).isNotEmpty)
            ...List.generate((row['activities'] as List).length, (displayIndex) {
              final activityIndex =
                  (row['activities'] as List).length - 1 - displayIndex;
              final activity =
                  (row['activities'] as List)[activityIndex] as Map;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 11.r,
                  backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
                  child: Text(
                    '${displayIndex + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                title: Text(activity['name'].toString()),
                trailing: IconButton(
                  tooltip: context.tr('Remove activity'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    (row['activities'] as List).removeAt(activityIndex);
                    controller.notify();
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              );
            }),
        ],
      ),
    );
  }
}
