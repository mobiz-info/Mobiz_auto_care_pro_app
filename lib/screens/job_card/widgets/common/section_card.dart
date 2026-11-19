import 'package:car_wash_mobile/providers/language_provider.dart';
import 'package:car_wash_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

IconData getSectionIcon(String title) {
  final normalizedTitle = title.toLowerCase();
  if (normalizedTitle.contains('added issue') || normalizedTitle.contains('added')) {
    return Icons.list_alt;
  }
  if (normalizedTitle.contains('customer')) {
    return Icons.person_outline;
  }
  if (normalizedTitle.contains('vehicle')) {
    return Icons.directions_car_outlined;
  }
  if (normalizedTitle.contains('reported issue') || normalizedTitle.contains('issue')) {
    return Icons.build_circle_outlined;
  }
  if (normalizedTitle.contains('service')) return Icons.price_change_outlined;
  if (normalizedTitle.contains('accessor')) {
    return Icons.inventory_2_outlined;
  }
  if (normalizedTitle.contains('labour')) return Icons.handyman_outlined;
  if (normalizedTitle.contains('extra')) return Icons.add_circle_outline;
  if (normalizedTitle.contains('schedule') || normalizedTitle.contains('sign-off')) {
    return Icons.fact_check_outlined;
  }
  if (normalizedTitle.contains('inspection')) {
    return Icons.fact_check_outlined;
  }
  return Icons.receipt_long_outlined;
}

Widget overviewTextLine(BuildContext context, String label, String value) =>
    Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112.w,
            child: Text(
              context.tr(label),
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

Widget overviewAmountLine(
  BuildContext context,
  String label,
  num amount, {
  bool emphasized = false,
}) {
  final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.tr(label),
            style: GoogleFonts.inter(
              fontSize: emphasized ? 15.sp : 13.sp,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              color: emphasized ? const Color(0xFF000080) : Colors.black87,
            ),
          ),
        ),
        Text(
          '$currencySymbol ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: emphasized ? 16.sp : 13.sp,
            fontWeight: FontWeight.w700,
            color: emphasized ? const Color(0xFF000080) : Colors.black87,
          ),
        ),
      ],
    ),
  );
}

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.fields,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(18),
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
          if (title.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  getSectionIcon(title),
                  color: const Color(0xFF000080),
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 14.h),
          ],
          ...fields.map(
            (field) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: field,
            ),
          ),
        ],
      ),
    );
  }
}
