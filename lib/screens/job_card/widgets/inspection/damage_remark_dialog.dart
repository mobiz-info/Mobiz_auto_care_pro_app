import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../providers/language_provider.dart';
import '../../models/job_card_damage_model.dart';

Future<Map<String, dynamic>?> showDamageRemarkDialog({
  required BuildContext context,
  required String view,
  String? detectedPart,
  String initialPart = 'Front bumper',
  String initialType = 'Scratch',
  String initialSeverity = 'Minor',
  String initialRemark = '',
  XFile? initialPhoto,
  String? initialPhotoUrl,
}) {
  final availableParts = JobCardDamageConfig.partsForView(view);
  final fallbackPart = availableParts.contains('Other interior part')
      ? 'Other interior part'
      : availableParts.first;
  var selectedPart = availableParts.contains(detectedPart)
      ? detectedPart!
      : (availableParts.contains(initialPart) ? initialPart : fallbackPart);

  var selectedType = JobCardDamageConfig.damageTypes.contains(initialType)
      ? initialType
      : JobCardDamageConfig.damageTypes.first;
  var selectedSeverity = JobCardDamageConfig.damageSeverities.contains(initialSeverity)
      ? initialSeverity
      : JobCardDamageConfig.damageSeverities.first;

  final remarkController = TextEditingController(text: initialRemark);
  XFile? selectedPhoto = initialPhoto;
  String? photoUrl = initialPhotoUrl;
  Uint8List? photoBytes;
  bool isPickingImage = false;

  final picker = ImagePicker();

  Future<void> pickPhoto(ImageSource source, StateSetter setDialogState) async {
    try {
      setDialogState(() => isPickingImage = true);
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setDialogState(() {
          selectedPhoto = picked;
          photoBytes = bytes;
          photoUrl = b64;
          isPickingImage = false;
        });
      } else {
        setDialogState(() => isPickingImage = false);
      }
    } catch (e) {
      setDialogState(() => isPickingImage = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  InputDecoration inspectionDecoration(String label) => InputDecoration(
    labelText: context.tr(label),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
  );

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w, maxHeight: 680.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: const BoxDecoration(
                    color: Color(0xFF000080),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.car_crash_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          context.tr('Record Vehicle Damage'),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          view,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(18.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Part Dropdown
                        Text(
                          context.tr('Vehicle Part'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        DropdownButtonFormField<String>(
                          value: selectedPart,
                          decoration: inspectionDecoration('Select part'),
                          items: availableParts
                              .map(
                                (part) => DropdownMenuItem(
                                  value: part,
                                  child: Text(context.tr(part)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setDialogState(() => selectedPart = value ?? 'Other'),
                        ),
                        SizedBox(height: 14.h),

                        // Damage Type ChoiceChips
                        Text(
                          context.tr('Damage Type'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          children: [
                            for (final type in JobCardDamageConfig.damageTypes)
                              ChoiceChip(
                                label: Text(context.tr(type)),
                                selected: selectedType == type,
                                onSelected: (sel) {
                                  if (sel) setDialogState(() => selectedType = type);
                                },
                                selectedColor: JobCardDamageConfig.damageTypeBgColor(type),
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: selectedType == type ? FontWeight.w700 : FontWeight.w500,
                                  color: selectedType == type
                                      ? JobCardDamageConfig.damageTypeColor(type)
                                      : const Color(0xFF475569),
                                ),
                                side: BorderSide(
                                  color: selectedType == type
                                      ? JobCardDamageConfig.damageTypeColor(type)
                                      : const Color(0xFFCBD5E1),
                                  width: selectedType == type ? 1.5 : 1.0,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // Damage Severity ChoiceChips
                        Text(
                          context.tr('Damage Severity'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          children: [
                            for (final severity in JobCardDamageConfig.damageSeverities)
                              ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: JobCardDamageConfig.severityColor(severity),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(context.tr(severity)),
                                  ],
                                ),
                                selected: selectedSeverity == severity,
                                onSelected: (sel) {
                                  if (sel) setDialogState(() => selectedSeverity = severity);
                                },
                                selectedColor: JobCardDamageConfig.severityBgColor(severity),
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: selectedSeverity == severity ? FontWeight.w700 : FontWeight.w500,
                                  color: selectedSeverity == severity
                                      ? JobCardDamageConfig.severityColor(severity)
                                      : const Color(0xFF475569),
                                ),
                                side: BorderSide(
                                  color: selectedSeverity == severity
                                      ? JobCardDamageConfig.severityColor(severity)
                                      : const Color(0xFFCBD5E1),
                                  width: selectedSeverity == severity ? 1.5 : 1.0,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 14.h),

                        // Remarks TextField
                        Text(
                          context.tr('Remarks / Description'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: remarkController,
                          maxLines: 2,
                          decoration: inspectionDecoration('Describe damage (optional)').copyWith(
                            hintText: context.tr('e.g. Deep scratch along edge'),
                            hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black38),
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // Damage Photo Section
                        Text(
                          context.tr('Damage Photo'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        if (isPickingImage)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (photoBytes != null || (photoUrl != null && photoUrl!.isNotEmpty))
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: SizedBox(
                                    width: 72.w,
                                    height: 72.w,
                                    child: photoBytes != null
                                        ? Image.memory(photoBytes!, fit: BoxFit.cover)
                                        : (photoUrl!.startsWith('data:image')
                                            ? Image.memory(
                                                base64Decode(photoUrl!.split(',').last),
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(photoUrl!, fit: BoxFit.cover)),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('Photo attached'),
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        selectedPhoto?.name ?? 'damage_photo.jpg',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.tr('Remove photo'),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedPhoto = null;
                                      photoBytes = null;
                                      photoUrl = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => pickPhoto(ImageSource.camera, setDialogState),
                                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                  label: Text(context.tr('Camera'), style: GoogleFonts.inter(fontSize: 12.sp)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => pickPhoto(ImageSource.gallery, setDialogState),
                                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                                  label: Text(context.tr('Gallery'), style: GoogleFonts.inter(fontSize: 12.sp)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, null),
                        child: Text(
                          context.tr('Cancel'),
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        ),
                        onPressed: () {
                          final remarks = remarkController.text.trim();
                          Navigator.pop(dialogContext, {
                            'part': selectedPart,
                            'damage_type': selectedType,
                            'severity': selectedSeverity,
                            'remarks': remarks.isNotEmpty ? remarks : selectedType,
                            'photo': selectedPhoto,
                            'photo_url': photoUrl ?? '',
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          context.tr('Save Damage'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
