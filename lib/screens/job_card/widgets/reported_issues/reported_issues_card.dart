import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../../controllers/job_card_issues_controller.dart';
import '../common/section_card.dart';
import 'issue_photo_viewer.dart';

class ReportedIssuesCard extends StatelessWidget {
  final JobCardController rootController;

  const ReportedIssuesCard({
    super.key,
    required this.rootController,
  });

  JobCardIssuesController get controller => rootController.issuesCtrl;

  Future<bool> _confirmDiscardIssueDraft(BuildContext context) async {
    final hasDraft = controller.jobIssueService != null ||
        controller.reportedIssueTextController.text.trim().isNotEmpty ||
        controller.draftIssuePhotos.isNotEmpty ||
        controller.currentExistingIssuePhotos.isNotEmpty;
    if (!hasDraft) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.tr('Discard current issue entry?')),
            content: Text(
              context.tr(
                'Changing the selection will clear this unsaved entry.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('Keep editing')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr('Discard')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<Map<String, dynamic>?> _pickJobMaster(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> options,
  ) async {
    if (controller.isPickingJobMaster) return null;
    controller.isPickingJobMaster = true;
    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        builder: (sheetContext) {
          var query = '';
          return StatefulBuilder(
            builder: (ctx, refresh) {
              final filtered = options
                  .where(
                    (item) => item['name'].toString().toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                  )
                  .toList();
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    16.h,
                    16.w,
                    MediaQuery.viewInsetsOf(ctx).bottom + 16.h,
                  ),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(ctx).height * .65,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr(title),
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          autofocus: true,
                          onChanged: (value) =>
                              refresh(() => query = value.trim()),
                          decoration: InputDecoration(
                            hintText: context.tr('Search'),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, index) => ListTile(
                              key: ValueKey(
                                '${title}_${filtered[index]['id']}',
                              ),
                              title: Text(filtered[index]['name'].toString()),
                              onTap: () => Navigator.of(
                                sheetContext,
                              ).pop(filtered[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.isPickingJobMaster = false;
    }
  }

  Widget _jobIssueSuggestions(BuildContext context) {
    if (controller.jobIssueChoice != null) return const SizedBox.shrink();
    final query =
        controller.reportedIssueTextController.text.trim().toLowerCase();
    final matches = controller.serviceJobIssues
        .where((item) => item['name'].toString().toLowerCase().contains(query))
        .take(5)
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(maxHeight: 180.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ListView(
        shrinkWrap: true,
        children: matches
            .map(
              (issue) => ListTile(
                dense: true,
                title: Text(issue['name'].toString()),
                onTap: () {
                  controller.setJobIssueChoiceDirectly(issue);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token ?? '';

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final addedServices = rootController.pricingCtrl.addedServices;

        return SectionCard(
          title: context.tr('Services & Complaints'),
          fields: [
            if (addedServices.isNotEmpty)
              ...List.generate(addedServices.length, (index) {
                final service = addedServices[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          (service['service_name'] ?? service['name'] ?? 'Service')
                              .toString(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (controller.isLoadingJobIssueOptions)
              const Center(child: CircularProgressIndicator())
            else if (controller.jobIssueOptionsError.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.jobIssueOptionsError,
                    style: GoogleFonts.inter(color: Colors.red.shade700),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        controller.isLoadingJobIssueOptions = true;
                        controller.jobIssueOptionsError = '';
                        controller.notify();
                        rootController.loadMetadata(token);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(context.tr('Retry')),
                    ),
                  ),
                ],
              )
            else if (controller.jobIssueCategories.isEmpty)
              Text(
                context.tr('No Job Card categories are available.'),
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: Colors.grey.shade700),
              )
            else ...[
              SizedBox(
                height: 42.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.jobIssueCategories.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final category = controller.jobIssueCategories[index];
                    final selected = category['id']?.toString() ==
                        controller.jobIssueCategory?['id']?.toString();
                    return ChoiceChip(
                      label: Text(category['name']?.toString() ?? ''),
                      selected: selected,
                      onSelected: (_) async {
                        if (category['id']?.toString() ==
                            controller.jobIssueCategory?['id']?.toString()) {
                          return;
                        }
                        if (!await _confirmDiscardIssueDraft(context)) return;
                        controller.setJobIssueCategoryDirectly(category);
                      },
                      selectedColor: const Color(0xFF000080),
                      labelStyle: GoogleFonts.inter(
                        color: selected ? Colors.white : const Color(0xFF334155),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF000080)
                            : Colors.grey.shade300,
                      ),
                    );
                  },
                ),
              ),
              InkWell(
                onTap: controller.categoryJobServices.isEmpty
                    ? null
                    : () async {
                        final value = await _pickJobMaster(
                          context,
                          'Select Service',
                          controller.categoryJobServices,
                        );
                        if (value != null && context.mounted) {
                          if (value['id']?.toString() ==
                              controller.jobIssueService?['id']?.toString()) {
                            return;
                          }
                          if (!await _confirmDiscardIssueDraft(context)) return;
                          controller.setJobIssueServiceDirectly(value);
                        }
                      },
                borderRadius: BorderRadius.circular(10.r),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('Service Name *'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    controller.jobIssueService?['name']?.toString() ??
                        context.tr('Select an option'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: controller.jobIssueService == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (controller.jobIssueCategory != null &&
                  controller.categoryJobServices.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    context.tr('No services are available in this category.'),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              TextField(
                controller: controller.reportedIssueTextController,
                onChanged: (value) {
                  controller.jobIssueChoice = controller.serviceJobIssues
                      .where(
                        (item) =>
                            item['name'].toString().toLowerCase() ==
                            value.trim().toLowerCase(),
                      )
                      .firstOrNull;
                  controller.notify();
                },
                style: GoogleFonts.inter(fontSize: 14.sp),
                decoration: InputDecoration(
                  labelText: context.tr('Complaint / Issue (Optional)'),
                  hintText: controller.jobIssueService == null
                      ? context.tr('Select a service first')
                      : context.tr('Specific complaint (defaults to service name)'),
                  prefixIcon: const Icon(Icons.build_circle_outlined),
                  suffixIcon: controller.serviceJobIssues.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('Search issues'),
                          onPressed: () async {
                            final value = await _pickJobMaster(
                              context,
                              'Select Issue',
                              controller.serviceJobIssues,
                            );
                            if (value != null) {
                              controller.setJobIssueChoiceDirectly(value);
                            }
                          },
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                ),
              ),
              if (controller.jobIssueService != null &&
                  controller.reportedIssueTextController.text.trim().isNotEmpty)
                _jobIssueSuggestions(context),
              Row(
                children: [
                  Text(
                    context.tr('Photos ${controller.issuePhotoCount}/3'),
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr('Take photo'),
                    onPressed: controller.issuePhotoCount < 3
                        ? () => controller.pickJobIssuePhotos(
                              ImageSource.camera,
                              onMessage: (msg) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(msg))),
                            )
                        : null,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                  IconButton(
                    tooltip: context.tr('Choose from gallery'),
                    onPressed: controller.issuePhotoCount < 3
                        ? () => controller.pickJobIssuePhotos(
                              ImageSource.gallery,
                              onMessage: (msg) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(msg))),
                            )
                        : null,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              if (controller.issuePhotoCount > 0)
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    ...controller.currentExistingIssuePhotos
                        .asMap()
                        .entries
                        .map(
                          (entry) => JobRemoteIssuePhotoWidget(
                            photo: entry.value,
                            onRemove: () =>
                                controller.removeExistingPhoto(entry.key),
                          ),
                        ),
                    ...controller.draftIssuePhotos.asMap().entries.map(
                          (entry) => JobLocalIssuePhotoWidget(
                            photo: entry.value,
                            onRemove: () =>
                                controller.removeDraftPhoto(entry.key),
                          ),
                        ),
                  ],
                ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: controller.isSubmitting
                      ? null
                      : () => controller.addReportedIssue(
                            token,
                            onMessage: (msg) => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg))),
                          ),
                  icon: Icon(
                    controller.editingReportedIssueIndex == null
                        ? Icons.add
                        : Icons.check,
                  ),
                  label: Text(
                    context.tr(
                      controller.editingReportedIssueIndex == null
                          ? 'Add Service'
                          : 'Update Service',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
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
