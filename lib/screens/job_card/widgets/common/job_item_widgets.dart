import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';

class JobItemInputWidget extends StatelessWidget {
  final bool fullWidth;
  final Widget child;

  const JobItemInputWidget({
    super.key,
    required this.fullWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}

class JobItemTotalWidget extends StatelessWidget {
  final Widget child;

  const JobItemTotalWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => child;
}

InputDecoration jobQuoteLikeDecoration() => InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );

class JobItemCard extends StatelessWidget {
  final String title;
  final int index;
  final VoidCallback onDelete;
  final List<Widget> children;
  final bool showTitle;

  const JobItemCard({
    super.key,
    required this.title,
    required this.index,
    required this.onDelete,
    required this.children,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h),
      padding: REdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: showTitle
                    ? Text(
                        title.isEmpty
                            ? '${context.tr('Item')} ${index + 1}'
                            : title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: context.tr('Remove'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const slots = 3;
              final width = (constraints.maxWidth - 8.w * (slots - 1)) / slots;
              return Wrap(
                spacing: 8.w,
                runSpacing: 0,
                children: [
                  ...children.map((child) {
                    if (child is JobItemTotalWidget) {
                      return SizedBox(width: constraints.maxWidth, child: child);
                    }
                    final fullWidth =
                        child is JobItemInputWidget && child.fullWidth;
                    return SizedBox(
                      width: fullWidth ? constraints.maxWidth : width,
                      child: child,
                    );
                  }),
                ],
              );
            },
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class ItemsTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(int index) onDelete;
  final String particularKey;

  const ItemsTableWidget({
    super.key,
    required this.items,
    required this.onDelete,
    required this.particularKey,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    context.tr('Particulars'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr('Qty x Rate'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr('Total'),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final particular = (item[particularKey] ?? '').toString();
            final qty = item['quantity'] ?? 1;
            final rate = item['rate'] ?? 0;
            final total = item['total_amount'] ?? 0;
            final remark = item['remarks'] ?? '';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          particular,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$qty x $rate',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$currencySymbol ${(total as num).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => onDelete(idx),
                        ),
                      ),
                    ],
                  ),
                  if (remark.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Text(
                        'Note: $remark',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
