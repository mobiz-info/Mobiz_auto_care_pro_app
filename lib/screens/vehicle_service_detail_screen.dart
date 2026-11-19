import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class VehicleServiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final String vehicleNumber;
  final String? vehicleModel;

  const VehicleServiceDetailScreen({
    super.key,
    required this.job,
    required this.vehicleNumber,
    this.vehicleModel,
  });

  String _formatDateStr(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3 && parts[0].length == 4) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<AuthProvider>().currencySymbol;
    final category = job['category']?.toString() ?? 'washing';
    final serviceName = job['service_name']?.toString() ?? 'Car Wash';
    final invoiceNumber = job['invoice_number']?.toString() ?? '';
    final rawDate = job['date']?.toString() ?? '';
    final formattedDate = _formatDateStr(rawDate);
    final rate = (job['rate'] as num?)?.toDouble() ?? 0.0;
    final qty = (job['qty'] as num?)?.toDouble() ?? 1.0;
    final itemDiscount = (job['item_discount'] as num?)?.toDouble() ?? 0.0;
    final branchName = job['branch_name']?.toString() ?? '';
    final customerName = job['customer_name']?.toString() ?? '';
    final customerPhone = job['customer_phone']?.toString() ?? '';
    final assignedStaffs = job['assigned_staffs'] as List<dynamic>? ?? [];
    final reminders = job['reminders'] as List<dynamic>? ?? [];
    final allItems = job['all_items'] as List<dynamic>? ?? [];
    final stockItems = job['stock_items'] as List<dynamic>? ?? [];
    final extras = job['extras'] as List<dynamic>? ?? [];
    final itemRemarks = (job['remarks'] ?? '').toString().trim();
    final invoiceRemarks = (job['invoice_remarks'] ?? '').toString().trim();

    Color categoryColor = const Color(0xFF000080);
    IconData categoryIcon = Icons.local_car_wash;
    String categoryLabel = 'Washing';

    if (category == 'oil_change') {
      categoryColor = Colors.amber.shade800;
      categoryIcon = Icons.oil_barrel;
      categoryLabel = 'Oil Change';
    } else if (category == 'tyre_change') {
      categoryColor = Colors.red.shade700;
      categoryIcon = Icons.circle_outlined;
      categoryLabel = 'Tyre Change';
    } else if (category == 'wheel_alignment') {
      categoryColor = Colors.green.shade700;
      categoryIcon = Icons.build_circle_outlined;
      categoryLabel = 'Wheel Alignment';
    } else if (category == 'smoke_test' || category == 'pollution_test') {
      categoryColor = Colors.purple.shade700;
      categoryIcon = Icons.speed_outlined;
      categoryLabel = 'Smoke / Pollution Test';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          context.tr('Service Details'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Service Card ──
            Container(
              padding: REdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000080).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon, size: 14.r, color: categoryColor),
                            SizedBox(width: 5.w),
                            Text(
                              context.tr(categoryLabel),
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$currency${rate.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF000080),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(serviceName),
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (qty > 1)
                        Text(
                          'x${qty % 1 == 0 ? qty.toInt() : qty.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  if (itemDiscount > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      '${context.tr("Discount")}: -$currency${itemDiscount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.receipt_outlined, size: 14.r, color: Colors.grey.shade600),
                      SizedBox(width: 4.w),
                      Text(
                        invoiceNumber,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.calendar_today_outlined, size: 14.r, color: Colors.grey.shade600),
                      SizedBox(width: 4.w),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // ── Vehicle & Customer Info Card ──
            Container(
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Color(0xFF000080), size: 18),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr('Vehicle & Customer Details'),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20.h, color: Colors.grey.shade200),
                  _infoRow(context, 'Vehicle Number', vehicleNumber, isBold: true),
                  if (vehicleModel != null && vehicleModel!.isNotEmpty)
                    _infoRow(context, 'Model', vehicleModel!),
                  if (customerName.isNotEmpty)
                    _infoRow(context, 'Customer', customerName),
                  if (customerPhone.isNotEmpty)
                    _infoRow(context, 'Phone', customerPhone),
                  if (branchName.isNotEmpty)
                    _infoRow(context, 'Branch', branchName),
                  if (assignedStaffs.isNotEmpty)
                    _infoRow(context, 'Assigned Staff', assignedStaffs.join(', ')),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // ── Remarks Section ──
            if (itemRemarks.isNotEmpty || invoiceRemarks.isNotEmpty) ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment_outlined, color: Color(0xFF000080), size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Remarks & Notes'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.blue.shade100),
                    if (itemRemarks.isNotEmpty) ...[
                      Text(
                        context.tr('Service Item Remarks:'),
                        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        itemRemarks,
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                      ),
                      if (invoiceRemarks.isNotEmpty) SizedBox(height: 10.h),
                    ],
                    if (invoiceRemarks.isNotEmpty) ...[
                      Text(
                        context.tr('Invoice Remarks:'),
                        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        invoiceRemarks,
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── Stock Items / Parts Section ──
            if (stockItems.isNotEmpty) ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: Colors.teal.shade800, size: 18),
                            SizedBox(width: 8.w),
                            Text(
                              context.tr('Stock Items / Parts Used'),
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            '${stockItems.length} ${context.tr("items")}',
                            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.teal.shade100),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stockItems.length,
                      separatorBuilder: (_, __) => Divider(height: 14.h, color: Colors.grey.shade100),
                      itemBuilder: (context, idx) {
                        final st = stockItems[idx];
                        final stName = st['stock_item_name'] ?? st['name'] ?? 'Stock Item';
                        final stQty = (st['qty'] as num?)?.toDouble() ?? 1.0;
                        final stRate = (st['rate'] as num?)?.toDouble() ?? 0.0;
                        final stTotal = (st['total'] as num?)?.toDouble() ?? (stRate * stQty);
                        final stRemarks = (st['remarks'] ?? '').toString().trim();
                        final isOp = st['is_operational'] == true;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          stName,
                                          style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                        ),
                                      ),
                                      if (isOp) ...[
                                        SizedBox(width: 6.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4.r),
                                            border: Border.all(color: Colors.orange.shade300, width: 0.8),
                                          ),
                                          child: Text(
                                            context.tr('Operational'),
                                            style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (stRemarks.isNotEmpty)
                                    Text(
                                      stRemarks,
                                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
                                    ),
                                  Text(
                                    '${context.tr("Qty")}: ${stQty % 1 == 0 ? stQty.toInt() : stQty.toStringAsFixed(1)}  •  ${context.tr("Rate")}: $currency${stRate.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isOp ? context.tr('Free') : '$currency${stTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isOp ? Colors.green.shade700 : const Color(0xFF000080)),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── Extras / Particulars Section ──
            if (extras.isNotEmpty) ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_list_bulleted, color: Color(0xFF000080), size: 18),
                            SizedBox(width: 8.w),
                            Text(
                              context.tr('Particulars & Extras'),
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF000080),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Text(
                            '${extras.length} ${context.tr("items")}',
                            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF000080)),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.indigo.shade100),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: extras.length,
                      separatorBuilder: (_, __) => Divider(height: 14.h, color: Colors.grey.shade100),
                      itemBuilder: (context, idx) {
                        final ex = extras[idx];
                        final exName = ex['extra_name'] ?? ex['name'] ?? 'Extra';
                        final exQty = (ex['qty'] as num?)?.toDouble() ?? 1.0;
                        final exRate = (ex['rate'] as num?)?.toDouble() ?? 0.0;
                        final exDisc = (ex['discount'] as num?)?.toDouble() ?? 0.0;
                        final exTotal = (ex['total'] as num?)?.toDouble() ?? (exRate * exQty - exDisc);
                        final exRemarks = (ex['remarks'] ?? '').toString().trim();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exName,
                                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                  if (exRemarks.isNotEmpty)
                                    Text(
                                      exRemarks,
                                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
                                    ),
                                  Text(
                                    '${context.tr("Qty")}: ${exQty % 1 == 0 ? exQty.toInt() : exQty.toStringAsFixed(1)}  •  ${context.tr("Rate")}: $currency${exRate.toStringAsFixed(2)}${exDisc > 0 ? "  •  Disc: -$currency${exDisc.toStringAsFixed(2)}" : ""}',
                                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$currency${exTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF000080)),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── Category Technical Details Card ──
            if (category == 'oil_change') ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.oil_barrel, color: Colors.amber.shade800, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Oil Change Specifications'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.amber.shade100),
                    _infoRow(context, 'Oil Product', job['oil_product']),
                    _infoRow(context, 'Litres Used', job['oil_litres'] != null && (job['oil_litres'] as num) > 0 ? '${job['oil_litres']} L' : null),
                    _infoRow(context, 'Filter Replaced', job['oil_filter_changed'] == true ? 'Yes' : 'No'),
                    if (job['oil_filter_name'] != null && job['oil_filter_name'].toString().isNotEmpty)
                      _infoRow(context, 'Filter Model', job['oil_filter_name']),
                    if (job['oil_filter_price'] != null && (job['oil_filter_price'] as num) > 0)
                      _infoRow(context, 'Filter Price', '$currency${(job['oil_filter_price'] as num).toDouble().toStringAsFixed(2)}'),
                    _infoRow(context, 'Odometer Reading', job['odometer'] != null ? '${job['odometer']} km' : null),
                    _infoRow(context, 'Next Oil Change Due', job['next_oil_change_km'] != null ? 'at ${job['next_oil_change_km']} km' : null, highlightColor: Colors.amber.shade800),
                    if (job['next_oil_change_date'] != null && job['next_oil_change_date'].toString().isNotEmpty)
                      _infoRow(context, 'Next Oil Change Date', _formatDateStr(job['next_oil_change_date'].toString()), highlightColor: Colors.amber.shade800),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ] else if (category == 'tyre_change') ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle_outlined, color: Colors.red.shade700, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Tyre Change Specifications'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.red.shade100),
                    _infoRow(context, 'Brand', job['tyre_brand']),
                    _infoRow(context, 'Size', job['tyre_size']),
                    _infoRow(context, 'Quantity Changed', job['tyres_count'] != null && (job['tyres_count'] as num) > 0 ? '${job['tyres_count']}' : null),
                    _infoRow(context, 'Odometer Reading', job['odometer'] != null ? '${job['odometer']} km' : null),
                    _infoRow(context, 'Next Tyre Change Due', job['next_tyre_change_km'] != null ? 'at ${job['next_tyre_change_km']} km' : null, highlightColor: Colors.red.shade700),
                    if (job['next_tyre_change_date'] != null && job['next_tyre_change_date'].toString().isNotEmpty)
                      _infoRow(context, 'Next Tyre Change Date', _formatDateStr(job['next_tyre_change_date'].toString()), highlightColor: Colors.red.shade700),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ] else if (category == 'wheel_alignment') ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build_circle_outlined, color: Colors.green.shade700, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Wheel Alignment Specifications'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.green.shade100),
                    _infoRow(context, 'Alignment Done', job['alignment_done'] == true ? 'Yes' : 'No'),
                    _infoRow(context, 'Balancing Done', job['balancing_done'] == true ? 'Yes' : 'No'),
                    _infoRow(context, 'Odometer Reading', job['odometer'] != null ? '${job['odometer']} km' : null),
                    _infoRow(context, 'Next Alignment Due', job['next_alignment_km'] != null ? 'at ${job['next_alignment_km']} km' : null, highlightColor: Colors.green.shade800),
                    if (job['alignment_notes'] != null && job['alignment_notes'].toString().isNotEmpty)
                      _infoRow(context, 'Remarks', job['alignment_notes']),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── All Services in Invoice Card ──
            if (allItems.isNotEmpty) ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt, color: Color(0xFF000080), size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('All Invoice Items'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.grey.shade200),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allItems.length,
                      separatorBuilder: (_, __) => Divider(height: 16.h, color: Colors.grey.shade100),
                      itemBuilder: (context, idx) {
                        final it = allItems[idx];
                        final itName = it['name'] ?? it['service_name'] ?? 'Service';
                        final itRate = (it['rate'] as num?)?.toDouble() ?? 0.0;
                        final itQty = (it['qty'] as num?)?.toDouble() ?? 1.0;
                        final itDisc = (it['discount'] as num?)?.toDouble() ?? 0.0;
                        final itRemarks = it['remarks']?.toString() ?? '';
                        final isOp = it['is_operational'] == true;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(itName),
                                    style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                  if (itRemarks.isNotEmpty)
                                    Text(
                                      itRemarks,
                                      style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500),
                                    ),
                                  Text(
                                    '${context.tr("Qty")}: ${itQty % 1 == 0 ? itQty.toInt() : itQty.toStringAsFixed(1)}  •  $currency${itRate.toStringAsFixed(2)}${itDisc > 0 ? "  •  Disc: -$currency${itDisc.toStringAsFixed(2)}" : ""}',
                                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isOp ? context.tr('Free') : '$currency${((itRate * itQty) - itDisc).toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF000080)),
                            ),
                          ],
                        );
                      },
                    ),
                    if (job['invoice_total'] != null && (job['invoice_total'] as num) > 0) ...[
                      Divider(height: 20.h, color: Colors.grey.shade200),
                      if (job['invoice_subtotal'] != null && (job['invoice_subtotal'] as num) > 0)
                        _summaryLine(context, 'Subtotal', '$currency${((job['invoice_subtotal'] as num).toDouble()).toStringAsFixed(2)}'),
                      if (job['invoice_discount'] != null && (job['invoice_discount'] as num) > 0)
                        _summaryLine(context, 'Discount', '-$currency${((job['invoice_discount'] as num).toDouble()).toStringAsFixed(2)}', color: Colors.green.shade700),
                      if (job['invoice_tax'] != null && (job['invoice_tax'] as num) > 0)
                        _summaryLine(context, 'Tax', '$currency${((job['invoice_tax'] as num).toDouble()).toStringAsFixed(2)}'),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('Total Invoice Amount'),
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                          ),
                          Text(
                            '$currency${((job['invoice_total'] as num).toDouble()).toStringAsFixed(2)}',
                            style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF000080)),
                          ),
                        ],
                      ),
                      if (job['amount_collected'] != null && (job['amount_collected'] as num) > 0) ...[
                        SizedBox(height: 4.h),
                        _summaryLine(context, 'Amount Collected', '$currency${((job['amount_collected'] as num).toDouble()).toStringAsFixed(2)}', color: Colors.green.shade800),
                      ],
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // ── Reminders & Follow-up Card ──
            if (_hasReminders(job)) ...[
              Container(
                padding: REdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: Colors.purple.shade700, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Scheduled Reminders'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20.h, color: Colors.purple.shade100),
                    if (job['next_smoke_test_date'] != null && job['next_smoke_test_date'].toString().isNotEmpty) ...[
                      _infoRow(context, 'Next Renewal Date', _formatDateStr(job['next_smoke_test_date'].toString()), highlightColor: Colors.purple.shade900),
                      if (job['reminder_1_date'] != null && job['reminder_1_date'].toString().isNotEmpty)
                        _infoRow(context, '1st Reminder (15 days before)', _formatDateStr(job['reminder_1_date'].toString()), highlightColor: Colors.purple.shade700),
                      if (job['reminder_2_date'] != null && job['reminder_2_date'].toString().isNotEmpty)
                        _infoRow(context, '2nd Reminder (3 days before)', _formatDateStr(job['reminder_2_date'].toString()), highlightColor: Colors.purple.shade700),
                    ],
                    for (final rem in reminders) ...[
                      if (rem['scheduled_date'] != null && rem['scheduled_date'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${context.tr("Reminder")} ${rem["reminder_no"] ?? 1}',
                                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade700),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatDateStr(rem['scheduled_date'].toString()),
                                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF000080)),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: rem['is_sent'] == true ? Colors.green.shade50 : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(
                                        color: rem['is_sent'] == true ? Colors.green.shade300 : Colors.amber.shade300,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      rem['is_sent'] == true ? context.tr('Sent') : context.tr('Pending'),
                                      style: GoogleFonts.inter(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w700,
                                        color: rem['is_sent'] == true ? Colors.green.shade800 : Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.tr(label), style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  bool _hasReminders(Map<String, dynamic> job) {
    final List<dynamic> reminders = job['reminders'] is List ? (job['reminders'] as List) : [];
    final String? nextSmokeDate = job['next_smoke_test_date']?.toString();
    return reminders.isNotEmpty || (nextSmokeDate != null && nextSmokeDate.isNotEmpty);
  }

  Widget _infoRow(BuildContext context, String label, dynamic val, {bool isBold = false, Color? highlightColor}) {
    if (val == null || val.toString().trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr(label),
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              context.tr(val.toString()),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: isBold || highlightColor != null ? FontWeight.bold : FontWeight.w600,
                color: highlightColor ?? (isBold ? const Color(0xFF000080) : const Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
