import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../common/section_card.dart';

class InspectionSummaryTabView extends StatelessWidget {
  final JobCardInspectionController controller;

  const InspectionSummaryTabView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final marks = controller.damageMarks;

        // Count checklist items
        int checklistInspected = 0;
        int checklistAttention = 0;
        int checklistDamage = 0;
        controller.checklistValues.forEach((key, val) {
          final status = (val['status'] ?? '').toString().toLowerCase();
          final value = (val['value'] ?? '').toString();
          if (status.isNotEmpty || value.isNotEmpty) {
            checklistInspected++;
            if (status == 'attention') checklistAttention++;
            if (status == 'damage' || status == 'failed' || status == 'replace') checklistDamage++;
          }
        });

        final hasTyre = controller.tyrePressure.isNotEmpty ||
            controller.tyreTreadDepth.isNotEmpty ||
            controller.tyreWearIndicators.isNotEmpty ||
            controller.tyreDotYear.isNotEmpty ||
            controller.tyreServices.isNotEmpty ||
            controller.tyreWheelAssessment.isNotEmpty ||
            controller.tyreSurfaceDamage.isNotEmpty ||
            controller.tyreStructuralDamage.isNotEmpty;

        final hasOil = controller.oilInspectionValues.isNotEmpty ||
            controller.legacyOilInspectionValues.isNotEmpty;

        final hasAlignment = controller.wheelAlignmentValues.isNotEmpty;
        final hasBrake = controller.brakeInspectionValues.isNotEmpty;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Inspection Health Header Banner ─────────────────────────
              _buildHeaderBanner(
                context,
                damageCount: marks.length,
                checklistCount: checklistInspected,
                attentionCount: checklistAttention + checklistDamage,
              ),
              SizedBox(height: 14.h),

              // ── 2. Damage Inspection Details ───────────────────────────────
              _buildDamageSection(context, marks),
              SizedBox(height: 14.h),

              // ── 3. Checklist Items Summary ─────────────────────────────────
              _buildChecklistSummary(context),
              SizedBox(height: 14.h),

              // ── 4. Tyre & Wheel Assessment ─────────────────────────────────
              if (hasTyre) ...[
                _buildTyreSection(context),
                SizedBox(height: 14.h),
              ],

              // ── 5. Wheel Alignment ─────────────────────────────────────────
              if (hasAlignment) ...[
                _buildAlignmentSection(context),
                SizedBox(height: 14.h),
              ],

              // ── 6. Oil & Fluid Inspection ──────────────────────────────────
              if (hasOil) ...[
                _buildOilSection(context),
                SizedBox(height: 14.h),
              ],

              // ── 7. Brake Inspection ────────────────────────────────────────
              if (hasBrake) ...[
                _buildBrakeSection(context),
                SizedBox(height: 14.h),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context, {
    required int damageCount,
    required int checklistCount,
    required int attentionCount,
  }) {
    final isClean = damageCount == 0 && attentionCount == 0;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isClean ? const Color(0xFF0F766E) : const Color(0xFF000080),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isClean ? Icons.verified_outlined : Icons.assessment_outlined,
                  color: Colors.white,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Vehicle Inspection Summary'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isClean
                          ? context.tr('All inspection points cleared with no reported damages')
                          : context.tr('Review findings and issues noted during inspection'),
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _metricPill(
                context,
                label: context.tr('Damages'),
                value: '$damageCount',
                color: damageCount > 0 ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                icon: damageCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              ),
              SizedBox(width: 8.w),
              _metricPill(
                context,
                label: context.tr('Checklist'),
                value: '$checklistCount',
                color: Colors.white,
                icon: Icons.checklist_rounded,
              ),
              if (attentionCount > 0) ...[
                SizedBox(width: 8.w),
                _metricPill(
                  context,
                  label: context.tr('Attention'),
                  value: '$attentionCount',
                  color: const Color(0xFFFBBF24),
                  icon: Icons.priority_high_rounded,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.r, color: color),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Damage Inspection ──────────────────────────────────────────────────
  Widget _buildDamageSection(BuildContext context, List<Map<String, dynamic>> marks) {
    if (marks.isEmpty) {
      return SectionCard(
        title: context.tr('Vehicle Damage Inspection'),
        fields: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF166534), size: 22),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    context.tr('No vehicle damages marked. Exterior & interior body verified.'),
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SectionCard(
      title: '${context.tr('Vehicle Damage Inspection')} (${marks.length})',
      fields: [
        ...List.generate(marks.length, (index) {
          final mark = marks[index];
          final view = (mark['view'] ?? 'Damage').toString();
          final part = (mark['part'] ?? 'Other').toString();
          final damageType = (mark['damage_type'] ?? 'Scratch').toString();
          final severity = (mark['severity'] ?? 'Minor').toString();
          final remarks = (mark['remarks'] ?? '').toString();
          final photoUrl = (mark['photo_url'] ?? '').toString();

          Color severityColor = const Color(0xFF1D4ED8);
          Color severityBg = const Color(0xFFEFF6FF);
          if (severity.toLowerCase().contains('mod')) {
            severityColor = const Color(0xFFD97706);
            severityBg = const Color(0xFFFEF3C7);
          } else if (severity.toLowerCase().contains('sev')) {
            severityColor = const Color(0xFFDC2626);
            severityBg = const Color(0xFFFEE2E2);
          }

          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index Badge
                Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF000080),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$view · $part',
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
                              color: severityBg,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              severity,
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: severityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              damageType,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (remarks.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          remarks,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Thumbnail photo if available
                if (photoUrl.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => _showPhotoPreview(context, photoUrl, '$view · $part'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        width: 52.r,
                        height: 52.r,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            photoUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(photoUrl.split(',').last),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                  ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.zoom_in, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400.h),
                child: photoUrl.startsWith('data:image')
                    ? Image.memory(base64Decode(photoUrl.split(',').last), fit: BoxFit.contain)
                    : Image.network(photoUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Checklist Items Summary ────────────────────────────────────────────
  Widget _buildChecklistSummary(BuildContext context) {
    final values = controller.checklistValues;
    if (values.isEmpty) {
      return SectionCard(
        title: context.tr('Checklist Assessment'),
        fields: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              context.tr('No dynamic checklist items evaluated yet.'),
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
          ),
        ],
      );
    }

    // Group items by category if available
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    values.forEach((key, val) {
      final category = (val['category'] ?? 'General').toString();
      grouped.putIfAbsent(category, () => []).add({
        'key': key,
        'name': val['name'] ?? key,
        'status': val['status'] ?? '',
        'value': val['value'] ?? '',
        'remarks': val['remarks'] ?? '',
      });
    });

    return SectionCard(
      title: context.tr('Checklist Assessment'),
      fields: [
        ...grouped.entries.map((entry) {
          final catName = entry.key;
          final items = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    catName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D4ED8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                ...items.map((item) {
                  final name = item['name'].toString();
                  final status = item['status'].toString();
                  final val = item['value'].toString();
                  final remarks = item['remarks'].toString();

                  Color statusColor = const Color(0xFF166534);
                  Color statusBg = const Color(0xFFDCFCE7);
                  String statusLabel = status.toUpperCase();

                  if (status == 'attention') {
                    statusColor = const Color(0xFFB45309);
                    statusBg = const Color(0xFFFEF3C7);
                  } else if (status == 'damage' || status == 'failed' || status == 'replace') {
                    statusColor = const Color(0xFFDC2626);
                    statusBg = const Color(0xFFFEE2E2);
                  } else if (status == 'na') {
                    statusColor = const Color(0xFF64748B);
                    statusBg = const Color(0xFFF1F5F9);
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (val.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Text(
                                  val,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF000080),
                                  ),
                                ),
                              ),
                            if (status.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (remarks.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Note: $remarks',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── 4. Tyre & Wheel Assessment ────────────────────────────────────────────
  Widget _buildTyreSection(BuildContext context) {
    final Map<String, String> data = {
      if (controller.tyrePressure.isNotEmpty) 'Pressure': controller.tyrePressure,
      if (controller.tyreTreadDepth.isNotEmpty) 'Tread Depth': controller.tyreTreadDepth,
      if (controller.tyreWearIndicators.isNotEmpty) 'Wear Indicators': controller.tyreWearIndicators,
      if (controller.tyreDotYear.isNotEmpty) 'DOT Year': controller.tyreDotYear,
      ...controller.tyreServices.map((k, v) => MapEntry(k, v.toString())),
      ...controller.tyreWheelAssessment,
    };

    return SectionCard(
      title: context.tr('Tyre & Wheel Assessment'),
      fields: [
        ...data.entries.map((e) => _keyValueRow(context, e.key, e.value)),
        if (controller.tyreWearDistribution.isNotEmpty)
          _tagGroupRow(context, 'Wear Distribution', controller.tyreWearDistribution.toList()),
        if (controller.tyreSurfaceDamage.isNotEmpty)
          _tagGroupRow(context, 'Surface Damage', controller.tyreSurfaceDamage.toList(), isAlert: true),
        if (controller.tyreStructuralDamage.isNotEmpty)
          _tagGroupRow(context, 'Structural Damage', controller.tyreStructuralDamage.toList(), isAlert: true),
      ],
    );
  }

  // ── 5. Wheel Alignment ───────────────────────────────────────────────────
  Widget _buildAlignmentSection(BuildContext context) {
    return SectionCard(
      title: context.tr('Wheel Alignment & Balancing'),
      fields: [
        ...controller.wheelAlignmentValues.entries.map((e) => _keyValueRow(context, e.key, e.value)),
      ],
    );
  }

  // ── 6. Oil & Fluid Section ────────────────────────────────────────────────
  Widget _buildOilSection(BuildContext context) {
    final Map<String, String> allOil = {
      ...controller.oilInspectionValues,
      ...controller.legacyOilInspectionValues,
    };

    return SectionCard(
      title: context.tr('Oil & Fluid Inspection'),
      fields: [
        ...allOil.entries.map((e) => _keyValueRow(context, e.key, e.value)),
      ],
    );
  }

  // ── 7. Brake Inspection ───────────────────────────────────────────────────
  Widget _buildBrakeSection(BuildContext context) {
    return SectionCard(
      title: context.tr('Brake Service & Inspection'),
      fields: [
        ...controller.brakeInspectionValues.entries.map((e) => _keyValueRow(context, e.key, e.value)),
      ],
    );
  }

  Widget _keyValueRow(BuildContext context, String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr(key),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagGroupRow(BuildContext context, String label, List<String> tags, {bool isAlert = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(label),
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: tags.map((t) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isAlert ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
