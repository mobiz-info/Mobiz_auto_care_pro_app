import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../../services/job_card_service.dart';

class VehicleBeforeAfterPhotosCard extends StatefulWidget {
  final JobCardController? controller;
  final String? jobCardId;
  final String? token;
  final List<dynamic>? initialBeforePhotos;
  final List<dynamic>? initialAfterPhotos;
  final VoidCallback? onPhotosChanged;

  const VehicleBeforeAfterPhotosCard({
    super.key,
    this.controller,
    this.jobCardId,
    this.token,
    this.initialBeforePhotos,
    this.initialAfterPhotos,
    this.onPhotosChanged,
  });

  @override
  State<VehicleBeforeAfterPhotosCard> createState() =>
      _VehicleBeforeAfterPhotosCardState();
}

class _VehicleBeforeAfterPhotosCardState
    extends State<VehicleBeforeAfterPhotosCard> {
  final ImagePicker _picker = ImagePicker();
  int _selectedSegment = 0; // 0 = Before Service, 1 = After Service
  bool _isUploading = false;

  // Local state for standalone mode (when controller is null)
  late List<Map<String, dynamic>> _standaloneBefore;
  late List<Map<String, dynamic>> _standaloneAfter;

  @override
  void initState() {
    super.initState();
    _standaloneBefore = (widget.initialBeforePhotos ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _standaloneAfter = (widget.initialAfterPhotos ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  void didUpdateWidget(VehicleBeforeAfterPhotosCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null) {
      if (widget.initialBeforePhotos != oldWidget.initialBeforePhotos) {
        _standaloneBefore = (widget.initialBeforePhotos ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (widget.initialAfterPhotos != oldWidget.initialAfterPhotos) {
        _standaloneAfter = (widget.initialAfterPhotos ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        );
        if (file != null) {
          await _handlePhotoAdded(file);
        }
      } else {
        final List<XFile> files = await _picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        );
        for (final f in files) {
          await _handlePhotoAdded(f);
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

  Future<void> _handlePhotoAdded(XFile file) async {
    final isBefore = _selectedSegment == 0;

    if (widget.controller != null) {
      // Controlled mode
      if (isBefore) {
        widget.controller!.addBeforePhotos([file]);
      } else {
        widget.controller!.addAfterPhotos([file]);
      }
      setState(() {});
      widget.onPhotosChanged?.call();
      return;
    }

    // Standalone mode: upload directly via API
    if (widget.jobCardId != null && widget.token != null) {
      setState(() => _isUploading = true);
      try {
        final res = await JobCardService.uploadJobCardVehiclePhoto(
          jobCardId: widget.jobCardId!,
          photo: file,
          photoType: isBefore ? 'before' : 'after',
          token: widget.token!,
        );
        if (mounted) {
          if (res['success'] == true) {
            final before = (res['before_photos'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            final after = (res['after_photos'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            setState(() {
              _standaloneBefore = before;
              _standaloneAfter = after;
            });
            widget.onPhotosChanged?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Failed to upload photo')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deletePhoto({
    required bool isBefore,
    required bool isLocal,
    required int index,
    String? photoId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Delete Photo?')),
        content: Text(context.tr('Are you sure you want to remove this photo?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (widget.controller != null) {
      if (isBefore) {
        if (isLocal) {
          widget.controller!.removeBeforePhoto(index);
        } else {
          widget.controller!.removeExistingBeforePhoto(index);
        }
      } else {
        if (isLocal) {
          widget.controller!.removeAfterPhoto(index);
        } else {
          widget.controller!.removeExistingAfterPhoto(index);
        }
      }
      setState(() {});
      widget.onPhotosChanged?.call();
      return;
    }

    // Standalone mode: API call
    if (widget.jobCardId != null && widget.token != null && photoId != null) {
      setState(() => _isUploading = true);
      try {
        final res = await JobCardService.deleteJobCardVehiclePhoto(
          jobCardId: widget.jobCardId!,
          photoId: photoId,
          token: widget.token!,
        );
        if (mounted) {
          if (res['success'] == true) {
            setState(() {
              if (isBefore) {
                _standaloneBefore.removeWhere((p) => p['id']?.toString() == photoId);
              } else {
                _standaloneAfter.removeWhere((p) => p['id']?.toString() == photoId);
              }
            });
            widget.onPhotosChanged?.call();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Failed to delete photo')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showImagePreview({String? url, XFile? file}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: file != null
                    ? (kIsWeb
                        ? Image.network(file.path, fit: BoxFit.contain)
                        : Image.file(File(file.path), fit: BoxFit.contain))
                    : (url != null && url.isNotEmpty
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white70,
                              size: 48,
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 16.w,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedSegment == 0
                    ? context.tr('Add Before Service Photo')
                    : context.tr('Add After Service Photo'),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000080),
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF000080)),
                ),
                title: Text(
                  context.tr('Take Photo (Camera)'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.teal),
                ),
                title: Text(
                  context.tr('Choose from Gallery'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBefore = _selectedSegment == 0;

    final existingList = widget.controller != null
        ? (isBefore
            ? widget.controller!.existingBeforePhotos
            : widget.controller!.existingAfterPhotos)
        : (isBefore ? _standaloneBefore : _standaloneAfter);

    final localList = widget.controller != null
        ? (isBefore
            ? widget.controller!.beforePhotos
            : widget.controller!.afterPhotos)
        : <XFile>[];

    final beforeCount = widget.controller != null
        ? (widget.controller!.existingBeforePhotos.length +
            widget.controller!.beforePhotos.length)
        : _standaloneBefore.length;

    final afterCount = widget.controller != null
        ? (widget.controller!.existingAfterPhotos.length +
            widget.controller!.afterPhotos.length)
        : _standaloneAfter.length;

    final totalCurrentCount = existingList.length + localList.length;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  color: const Color(0xFF000080),
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr('Vehicle Before & After Photos'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                if (_isUploading)
                  SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.add_a_photo_outlined,
                      color: const Color(0xFF000080),
                      size: 20.r,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr('Add Photo'),
                    onPressed: _showAddPhotoSheet,
                  ),
              ],
            ),
          ),

          // Segment Selector: Before / After
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildSegmentButton(
                    index: 0,
                    title: context.tr('Before Service'),
                    count: beforeCount,
                    isSelected: _selectedSegment == 0,
                    badgeColor: const Color(0xFF2563EB),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildSegmentButton(
                    index: 1,
                    title: context.tr('After Service'),
                    count: afterCount,
                    isSelected: _selectedSegment == 1,
                    badgeColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          // Photos Grid or Empty State
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: totalCurrentCount == 0
                ? _buildEmptyState(isBefore)
                : _buildPhotosGrid(
                    isBefore: isBefore,
                    existingPhotos: existingList,
                    localPhotos: localList,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String title,
    required int count,
    required bool isSelected,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedSegment = index),
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF000080)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF000080)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isBefore) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(
            isBefore ? Icons.car_crash_outlined : Icons.auto_awesome,
            size: 36.r,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 8.h),
          Text(
            isBefore
                ? context.tr('No "Before Service" photos added yet')
                : context.tr('No "After Service" photos added yet'),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          OutlinedButton.icon(
            onPressed: _showAddPhotoSheet,
            icon: Icon(Icons.add_a_photo, size: 16.r),
            label: Text(
              isBefore
                  ? context.tr('Capture Before Photo')
                  : context.tr('Capture After Photo'),
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF000080),
              side: const BorderSide(color: Color(0xFF000080)),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid({
    required bool isBefore,
    required List<Map<String, dynamic>> existingPhotos,
    required List<XFile> localPhotos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            // 1. Existing remote photos
            ...List.generate(existingPhotos.length, (idx) {
              final photo = existingPhotos[idx];
              final url = (photo['url'] ?? '').toString();
              final photoId = (photo['id'] ?? '').toString();

              return _buildPhotoTile(
                imageProvider: url.isNotEmpty ? NetworkImage(url) : null,
                onTap: () => _showImagePreview(url: url),
                onDelete: () => _deletePhoto(
                  isBefore: isBefore,
                  isLocal: false,
                  index: idx,
                  photoId: photoId,
                ),
                isPendingUpload: false,
              );
            }),

            // 2. Local newly picked photos
            ...List.generate(localPhotos.length, (idx) {
              final file = localPhotos[idx];
              return _buildPhotoTile(
                imageProvider: kIsWeb
                    ? NetworkImage(file.path)
                    : FileImage(File(file.path)) as ImageProvider,
                onTap: () => _showImagePreview(file: file),
                onDelete: () => _deletePhoto(
                  isBefore: isBefore,
                  isLocal: true,
                  index: idx,
                ),
                isPendingUpload: true,
              );
            }),

            // 3. Add more button tile
            InkWell(
              onTap: _showAddPhotoSheet,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFF000080).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: const Color(0xFF000080),
                      size: 26.r,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.tr('Add More'),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
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
    );
  }

  Widget _buildPhotoTile({
    required ImageProvider? imageProvider,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required bool isPendingUpload,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageProvider == null
                ? const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                : null,
          ),
        ),
        // Badge if new / pending upload
        if (isPendingUpload)
          Positioned(
            bottom: 4.h,
            left: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Delete button
        Positioned(
          top: 3.h,
          right: 3.w,
          child: InkWell(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(3.r),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 13.r,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

