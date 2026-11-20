import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../../models/job_card_quality_check_model.dart';

class QualityCheckTabView extends StatefulWidget {
  final JobCardController controller;
  final String? token;

  const QualityCheckTabView({
    super.key,
    required this.controller,
    this.token,
  });

  @override
  State<QualityCheckTabView> createState() => _QualityCheckTabViewState();
}

class _QualityCheckTabViewState extends State<QualityCheckTabView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhotoForService(
    String serviceName,
    ImageSource source,
  ) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        );
        if (file != null) {
          widget.controller.addQualityCheckPhoto(serviceName, file);
        }
      } else {
        final List<XFile> files = await _picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        );
        for (final f in files) {
          widget.controller.addQualityCheckPhoto(serviceName, f);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _showZoomPreview({String? networkUrl, XFile? localFile}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(12.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: localFile != null
                      ? (kIsWeb
                          ? Image.network(localFile.path, fit: BoxFit.contain)
                          : Image.file(File(localFile.path), fit: BoxFit.contain))
                      : Image.network(
                          networkUrl ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image,
                                size: 50, color: Colors.white54),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.controller.pricingCtrl,
        widget.controller.issuesCtrl,
      ]),
      builder: (context, _) {
        final qcs = widget.controller.qualityCheckList;
        final satisfiedCount = qcs.where((q) => q.isSatisfied).length;
        final notSatisfiedCount = qcs.where((q) => !q.isSatisfied).length;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF000080), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000080).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Quality Inspection Check'),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                context.tr(
                                  'Verify completed services and capture quality photos',
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11.5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (qcs.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Divider(color: Colors.white.withOpacity(0.2), height: 1),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          _buildStatBadge(
                            context.tr('Total Services'),
                            '${qcs.length}',
                            Colors.white.withOpacity(0.2),
                            Colors.white,
                          ),
                          SizedBox(width: 8.w),
                          _buildStatBadge(
                            context.tr('Satisfied'),
                            '$satisfiedCount',
                            const Color(0xFF10B981).withOpacity(0.3),
                            const Color(0xFF6EE7B7),
                          ),
                          SizedBox(width: 8.w),
                          _buildStatBadge(
                            context.tr('Not Satisfied'),
                            '$notSatisfiedCount',
                            notSatisfiedCount > 0
                                ? const Color(0xFFEF4444).withOpacity(0.35)
                                : Colors.white.withOpacity(0.1),
                            notSatisfiedCount > 0
                                ? const Color(0xFFFCA5A5)
                                : Colors.white70,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Empty State
              if (qcs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          size: 38.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        context.tr('No Services Added Yet'),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        context.tr(
                          'Services added in "Services & Complaints" or "Pricing" will appear here for quality checks.',
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Services QC List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: qcs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final item = qcs[index];
                    return _buildServiceQcCard(item, index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(
    String label,
    String value,
    Color bg,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceQcCard(JobCardQualityCheckItem item, int index) {
    final isSatisfied = item.isSatisfied;
    final totalPhotos = item.newPhotos.length + item.existingPhotos.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSatisfied
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFFCA5A5),
          width: isSatisfied ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSatisfied
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
              border: Border(
                bottom: BorderSide(
                  color: isSatisfied
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFEE2E2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isSatisfied
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : const Color(0xFFEF4444).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isSatisfied
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    item.serviceName,
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Status pill badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isSatisfied
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSatisfied
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 13.sp,
                        color: isSatisfied
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isSatisfied
                            ? context.tr('Satisfied')
                            : context.tr('Not Satisfied'),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isSatisfied
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Satisfied / Not-Satisfied Selector Buttons
                Text(
                  context.tr('Quality Status'),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    // Satisfied Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.controller.setQualityCheckStatus(
                            item.serviceName,
                            'satisfied',
                          );
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 9.h),
                          decoration: BoxDecoration(
                            color: isSatisfied
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isSatisfied
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFCBD5E1),
                              width: isSatisfied ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16.sp,
                                color: isSatisfied
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                context.tr('Satisfied'),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSatisfied
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // Not-Satisfied Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.controller.setQualityCheckStatus(
                            item.serviceName,
                            'not_satisfied',
                          );
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 9.h),
                          decoration: BoxDecoration(
                            color: !isSatisfied
                                ? const Color(0xFFDC2626)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: !isSatisfied
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFCBD5E1),
                              width: !isSatisfied ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.highlight_off,
                                size: 16.sp,
                                color: !isSatisfied
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                context.tr('Not Satisfied'),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: !isSatisfied
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                // Remarks Field
                Text(
                  context.tr('Notes / Remarks'),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  initialValue: item.remarks,
                  onChanged: (val) {
                    widget.controller.setQualityCheckRemarks(
                      item.serviceName,
                      val,
                    );
                  },
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: isSatisfied
                        ? context.tr('Optional inspection notes...')
                        : context.tr('Reason why service is not satisfied...'),
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF000080),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 14.h),

                // Photos Header & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.tr('Inspection Photos')} ($totalPhotos)',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _pickPhotoForService(
                            item.serviceName,
                            ImageSource.camera,
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14.sp,
                                  color: const Color(0xFF000080),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr('Camera'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF000080),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        InkWell(
                          onTap: () => _pickPhotoForService(
                            item.serviceName,
                            ImageSource.gallery,
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 14.sp,
                                  color: const Color(0xFF000080),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr('Gallery'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF000080),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Photos Grid / Row
                if (totalPhotos == 0)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        context.tr('No photos attached for this service'),
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      // Existing Photos
                      ...item.existingPhotos.map((photo) {
                        final photoId = photo['id']?.toString() ?? '';
                        final url = photo['url']?.toString() ?? '';
                        return _buildThumbnail(
                          onTap: () => _showZoomPreview(networkUrl: url),
                          onDelete: () {
                            widget.controller.removeQualityCheckExistingPhoto(
                              item.serviceName,
                              photoId,
                            );
                          },
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: 68.w,
                            height: 68.w,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(
                                Icons.broken_image,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        );
                      }),
                      // New Photos
                      ...item.newPhotos.asMap().entries.map((entry) {
                        final pIdx = entry.key;
                        final xfile = entry.value;
                        return _buildThumbnail(
                          onTap: () => _showZoomPreview(localFile: xfile),
                          onDelete: () {
                            widget.controller.removeQualityCheckNewPhoto(
                              item.serviceName,
                              pIdx,
                            );
                          },
                          child: kIsWeb
                              ? Image.network(
                                  xfile.path,
                                  fit: BoxFit.cover,
                                  width: 68.w,
                                  height: 68.w,
                                )
                              : Image.file(
                                  File(xfile.path),
                                  fit: BoxFit.cover,
                                  width: 68.w,
                                  height: 68.w,
                                ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail({
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required Widget child,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68.w,
            height: 68.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7.r),
              child: child,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
