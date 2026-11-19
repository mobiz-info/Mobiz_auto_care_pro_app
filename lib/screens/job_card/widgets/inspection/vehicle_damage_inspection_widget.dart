import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../../models/job_card_damage_model.dart';
import 'damage_remark_dialog.dart';
import 'vehicle_damage_painter.dart';
import '../common/section_card.dart';

class VehicleDamageInspectionWidget extends StatelessWidget {
  final JobCardInspectionController controller;

  const VehicleDamageInspectionWidget({super.key, required this.controller});

  Widget _damageThumbnail(Map<String, dynamic> mark) {
    final view = (mark['view'] ?? 'Front').toString();
    final asset = JobCardDamageConfig.damageViewAssets[view];
    if (asset == null) {
      return const CircleAvatar(child: Icon(Icons.airline_seat_recline_extra));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 52.w,
        height: 52.w,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover),
            CustomPaint(
              painter: VehicleDamagePainter(
                strokes: [
                  JobCardDamageConfig.parseDamagePoints(mark['points']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoThumbnail(BuildContext context, Map<String, dynamic> mark) {
    final photoUrl = (mark['photo_url'] ?? '').toString();
    if (photoUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showPhotoPreview(
        context,
        photoUrl,
        '${mark['part']} (${mark['damage_type'] ?? 'Damage'})',
      ),
      child: Tooltip(
        message: context.tr('Tap to view photo'),
        child: Container(
          margin: EdgeInsets.only(left: 6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.r),
            child: SizedBox(
              width: 52.w,
              height: 52.w,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  photoUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(photoUrl.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : Image.network(photoUrl, fit: BoxFit.cover),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                color: Colors.black87,
                constraints: BoxConstraints(maxHeight: 500.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      color: const Color(0xFF000080),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 3.0,
                        child: photoUrl.startsWith('data:image')
                            ? Image.memory(base64Decode(photoUrl.split(',').last))
                            : Image.network(photoUrl),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerDamageRemarkDialog(
    BuildContext context,
    List<Offset> points, {
    String? view,
    String? detectedPart,
  }) async {
    final entryView = view ?? controller.selectedDamageView;
    if (points.isEmpty && !entryView.startsWith('Interior')) {
      controller.clearDamageStroke();
      return;
    }

    final result = await showDamageRemarkDialog(
      context: context,
      view: entryView,
      detectedPart: detectedPart,
      initialPart: controller.selectedDamagePart,
    );

    if (result != null) {
      controller.addDamageMark(
        view: entryView,
        part: result['part'] ?? 'Other',
        damageType: result['damage_type'] ?? 'Scratch',
        severity: result['severity'] ?? 'Minor',
        remarks: result['remarks'] ?? '',
        photo: result['photo'],
        photoUrl: result['photo_url'] ?? '',
        points: points,
      );
    } else {
      controller.clearDamageStroke();
    }
  }

  void _editDamageMark(BuildContext context, int index) async {
    final mark = controller.damageMarks[index];
    final result = await showDamageRemarkDialog(
      context: context,
      view: mark['view'] ?? controller.selectedDamageView,
      initialPart: mark['part'] ?? 'Other',
      initialType: mark['damage_type'] ?? 'Scratch',
      initialSeverity: mark['severity'] ?? 'Minor',
      initialRemark: mark['remarks'] ?? '',
      initialPhoto: mark['photo'],
      initialPhotoUrl: mark['photo_url'],
    );

    if (result != null) {
      controller.updateDamageMark(
        index,
        part: result['part'],
        damageType: result['damage_type'],
        severity: result['severity'],
        remarks: result['remarks'],
        photo: result['photo'],
        photoUrl: result['photo_url'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentViewMarks = controller.damageMarks
            .where((m) => m['view'] == controller.selectedDamageView)
            .toList();
        final hasCurrentViewMarks = currentViewMarks.isNotEmpty;

        return SectionCard(
          title: context.tr('Vehicle Damage Inspection'),
          fields: [
            // Exterior views
            Text(
              context.tr('Exterior'),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            Wrap(
              spacing: 7.w,
              runSpacing: 4.h,
              children: [
                for (final view in JobCardDamageConfig.damageViews)
                  _viewChip(context, view),
              ],
            ),
            SizedBox(height: 8.h),

            // Interior views
            Text(
              context.tr('Interior'),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            Wrap(
              spacing: 7.w,
              runSpacing: 4.h,
              children: [
                for (final view in JobCardDamageConfig.interiorDamageViews)
                  _viewChip(context, view),
              ],
            ),
            SizedBox(height: 10.h),

            // Drawing Toolbar: View title, Undo, Clear, Add mark
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 16,
                    color: Color(0xFF000080),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      '${context.tr(controller.selectedDamageView)} (${currentViewMarks.length})',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000080),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Undo button
                  TextButton.icon(
                    onPressed: hasCurrentViewMarks ||
                            controller.currentDamageStroke.isNotEmpty
                        ? () => controller.undoDamageMark(
                              view: controller.selectedDamageView,
                            )
                        : null,
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(
                      context.tr('Undo'),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  // Clear view button
                  TextButton.icon(
                    onPressed: hasCurrentViewMarks
                        ? () => controller.clearDamageMarksForView(
                              controller.selectedDamageView,
                            )
                        : null,
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: Text(
                      context.tr('Clear'),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),

            // Instruction prompt
            Text(
              context.tr(
                'Tap a part or drag to draw over the damaged area. Set damage type, severity, and optional photo.',
              ),
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8.h),

            // Vehicle drawing canvas
            AspectRatio(
              aspectRatio:
                  JobCardDamageConfig.damageViewAspectRatios[controller
                      .selectedDamageView] ??
                  1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: const Color(0xFFF7F8FA),
                          child: Image.asset(
                            JobCardDamageConfig.damageViewAssets[controller
                                .selectedDamageView]!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            final point = Offset(
                              (details.localPosition.dx / size.width).clamp(
                                0.0,
                                1.0,
                              ),
                              (details.localPosition.dy / size.height).clamp(
                                0.0,
                                1.0,
                              ),
                            );
                            _triggerDamageRemarkDialog(
                              context,
                              [point],
                              view: controller.selectedDamageView,
                              detectedPart:
                                  JobCardDamageConfig.findPartAtHotspot(
                                controller.selectedDamageView,
                                point,
                              ),
                            );
                          },
                          onPanStart: (details) {
                            controller.setCurrentDamageStroke([
                              Offset(
                                details.localPosition.dx / size.width,
                                details.localPosition.dy / size.height,
                              ),
                            ]);
                          },
                          onPanUpdate: (details) {
                            controller.addPointToCurrentStroke(
                              Offset(
                                (details.localPosition.dx / size.width).clamp(
                                  0.0,
                                  1.0,
                                ),
                                (details.localPosition.dy / size.height).clamp(
                                  0.0,
                                  1.0,
                                ),
                              ),
                            );
                          },
                          onPanEnd: (_) {
                            final points = List<Offset>.from(
                              controller.currentDamageStroke,
                            );
                            final center =
                                JobCardDamageConfig.calculateStrokeCenter(
                              points,
                            );
                            _triggerDamageRemarkDialog(
                              context,
                              points,
                              view: controller.selectedDamageView,
                              detectedPart:
                                  JobCardDamageConfig.findPartAtHotspot(
                                controller.selectedDamageView,
                                center,
                              ),
                            );
                          },
                          child: CustomPaint(
                            painter: VehicleDamagePainter(
                              strokes: [
                                ...controller.damageMarks
                                    .where(
                                      (mark) =>
                                          mark['view'] ==
                                          controller.selectedDamageView,
                                    )
                                    .map(
                                      (mark) =>
                                          JobCardDamageConfig.parseDamagePoints(
                                        mark['points'],
                                      ),
                                    ),
                                controller.currentDamageStroke,
                              ],
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                context.tr(controller.selectedDamageView),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (controller.currentDamageStroke.isEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF000080,
                                  ).withValues(alpha: .92),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.gesture,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        context.tr(
                                          'Drag to draw · Tap to mark',
                                        ),
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Recorded Damage List
            if (controller.damageMarks.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.tr('Recorded Damages')} (${controller.damageMarks.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.clearAllDamageMarks(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      context.tr('Clear All'),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              for (
                var index = 0;
                index < controller.damageMarks.length;
                index++
              )
                _buildDamageMarkCard(context, index),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDamageMarkCard(BuildContext context, int index) {
    final mark = controller.damageMarks[index];
    final part = (mark['part'] ?? 'Other').toString();
    final view = (mark['view'] ?? 'Front').toString();
    final damageType = (mark['damage_type'] ?? 'Scratch').toString();
    final severity = (mark['severity'] ?? 'Minor').toString();
    final remarks = (mark['remarks'] ?? '').toString();

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnails: Vehicle view + Photo thumbnail
          _damageThumbnail(mark),
          _photoThumbnail(context, mark),
          SizedBox(width: 10.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$part · $view',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    // Damage Type Chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: JobCardDamageConfig.damageTypeBgColor(damageType),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: JobCardDamageConfig.damageTypeColor(damageType)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        context.tr(damageType),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: JobCardDamageConfig.damageTypeColor(damageType),
                        ),
                      ),
                    ),
                    // Severity Chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: JobCardDamageConfig.severityBgColor(severity),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: JobCardDamageConfig.severityColor(severity)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: JobCardDamageConfig.severityColor(severity),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            context.tr(severity),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: JobCardDamageConfig.severityColor(severity),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (remarks.isNotEmpty && remarks != damageType) ...[
                  SizedBox(height: 4.h),
                  Text(
                    remarks,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions: Edit and Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.tr('Edit damage details'),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF000080)),
                onPressed: () => _editDamageMark(context, index),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 8.w),
              IconButton(
                tooltip: context.tr('Delete damage mark'),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => controller.removeDamageMark(index),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewChip(BuildContext context, String view) {
    return ChoiceChip(
      label: Text(context.tr(view.replaceFirst('Interior - ', ''))),
      selected: controller.selectedDamageView == view,
      onSelected: (_) => controller.selectDamageView(view),
    );
  }
}
