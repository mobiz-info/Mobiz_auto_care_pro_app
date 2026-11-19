import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

void viewJobIssuePhoto(BuildContext context, Widget image) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(child: image),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  );
}

class JobLocalIssuePhotoWidget extends StatelessWidget {
  final XFile photo;
  final VoidCallback onRemove;
  final bool showRemove;

  const JobLocalIssuePhotoWidget({
    super.key,
    required this.photo,
    required this.onRemove,
    this.showRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => viewJobIssuePhoto(context, Image.file(File(photo.path))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              File(photo.path),
              width: 58.w,
              height: 58.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showRemove)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class JobRemoteIssuePhotoWidget extends StatelessWidget {
  final Map<String, dynamic> photo;
  final VoidCallback onRemove;
  final bool showRemove;

  const JobRemoteIssuePhotoWidget({
    super.key,
    required this.photo,
    required this.onRemove,
    this.showRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    final url = (photo['image_url'] ?? photo['photo_url'] ?? '').toString();
    return Stack(
      children: [
        GestureDetector(
          onTap: () => viewJobIssuePhoto(
            context,
            Image.network(url, fit: BoxFit.contain),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              url,
              width: 58.w,
              height: 58.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58.w,
                height: 58.w,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
        if (showRemove)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
