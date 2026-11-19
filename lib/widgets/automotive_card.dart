import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class VehiclePlateBadge extends StatelessWidget {
  final String plateNumber;
  final double? fontSize;

  const VehiclePlateBadge({
    super.key,
    required this.plateNumber,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final text = plateNumber.trim().isEmpty ? '-' : plateNumber.trim();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car, size: 14.r, color: const Color(0xFFB45309)),
          SizedBox(width: 5.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: fontSize ?? 12.sp,
              letterSpacing: 0.5,
              color: const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}

class AutomotiveIdBadge extends StatelessWidget {
  final String idText;
  final Color? color;

  const AutomotiveIdBadge({
    super.key,
    required this.idText,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF000080),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        idText,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12.sp,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class AutomotiveStatusPill extends StatelessWidget {
  final String status;
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showDropdownArrow;

  const AutomotiveStatusPill({
    super.key,
    required this.status,
    this.label,
    this.color,
    this.backgroundColor,
    this.onTap,
    this.showDropdownArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color textCol = color ?? const Color(0xFF000080);
    Color bgCol = backgroundColor ?? const Color(0xFFE0E7FF);
    IconData icon = Icons.circle;

    if (color == null || backgroundColor == null) {
      if (s.contains('progress') || s.contains('started') || s.contains('sent')) {
        textCol = const Color(0xFF1E40AF);
        bgCol = const Color(0xFFDBEAFE);
        icon = Icons.sync;
      } else if (s.contains('complet') ||
          s.contains('accept') ||
          s.contains('done') ||
          s.contains('ready') ||
          s.contains('paid')) {
        textCol = const Color(0xFF166534);
        bgCol = const Color(0xFFDCFCE7);
        icon = Icons.check_circle_outline;
      } else if (s.contains('cancel') ||
          s.contains('reject') ||
          s.contains('overdue')) {
        textCol = const Color(0xFF991B1B);
        bgCol = const Color(0xFFFEE2E2);
        icon = Icons.cancel_outlined;
      } else if (s.contains('draft') ||
          s.contains('pending') ||
          s.contains('new') ||
          s.contains('follow')) {
        textCol = const Color(0xFF92400E);
        bgCol = const Color(0xFFFEF3C7);
        icon = Icons.schedule;
      }
    }

    final displayText = label ?? status;

    Widget pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: textCol.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: textCol),
          SizedBox(width: 5.w),
          Text(
            displayText,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: textCol,
            ),
          ),
          if (showDropdownArrow) ...[
            SizedBox(width: 2.w),
            Icon(Icons.arrow_drop_down, size: 15.r, color: textCol),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: pill,
      );
    }
    return pill;
  }
}

class AutomotiveCardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AutomotiveCardContainer({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: child,
        ),
      ),
    );
  }
}
