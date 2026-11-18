import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../config/country_config.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../common/section_card.dart';
import 'accessory_picker_dialog.dart';

class AccessoriesCard extends StatefulWidget {
  final JobCardPricingController controller;

  const AccessoriesCard({
    super.key,
    required this.controller,
  });

  @override
  State<AccessoriesCard> createState() => _AccessoriesCardState();
}

class _AccessoriesCardState extends State<AccessoriesCard> {
  Map<String, dynamic>? _entryItem;
  final TextEditingController _rateCtrl = TextEditingController(text: '0.00');
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _discCtrl = TextEditingController(text: '0.00');
  int? _editingIndex;

  @override
  void dispose() {
    _rateCtrl.dispose();
    _qtyCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  double get _entryTotal {
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
    final discount = double.tryParse(_discCtrl.text.trim()) ?? 0.0;
    return ((rate * qty) - discount).clamp(0.0, double.infinity);
  }

  void _clearEntryBar() {
    setState(() {
      _entryItem = null;
      _rateCtrl.text = '0.00';
      _qtyCtrl.text = '1';
      _discCtrl.text = '0.00';
      _editingIndex = null;
    });
  }

  void _onAddOrUpdateItem() {
    if (_entryItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select a stock item first')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Quantity must be greater than 0')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final rate = _rateCtrl.text.trim();
    final disc = _discCtrl.text.trim();

    if (_editingIndex != null && _editingIndex! < widget.controller.addedParts.length) {
      final row = widget.controller.addedParts[_editingIndex!];
      row['rate'] = rate;
      row['rate_with_tax'] = rate;
      row['quantity'] = qty.toString();
      row['discount'] = disc;
      if (_entryItem != null) {
        row['stock_item_id'] = _entryItem!['id'] ?? row['stock_item_id'];
        row['product_name'] = _entryItem!['product_name'] ?? _entryItem!['name'] ?? row['product_name'];
        row['product_code'] = _entryItem!['product_code'] ?? _entryItem!['part_number'] ?? row['product_code'];
        row['part_number'] = _entryItem!['part_number'] ?? _entryItem!['product_code'] ?? row['part_number'];
      }
      widget.controller.recalculateJobItem(row);
      widget.controller.notify();
    } else {
      widget.controller.addPart(
        _entryItem!,
        rate: rate,
        quantity: qty.toString(),
        discount: disc,
      );
    }

    _clearEntryBar();
  }

  void _onEditRow(int index) {
    if (index >= widget.controller.addedParts.length) return;
    final row = widget.controller.addedParts[index];
    setState(() {
      _editingIndex = index;
      _entryItem = {
        'id': row['stock_item_id'],
        'product_name': row['product_name'],
        'product_code': row['product_code'] ?? row['part_number'],
        'part_number': row['part_number'],
        'current_stock': row['current_stock'] ?? 0,
        'unit': row['unit'] ?? 'Pcs',
      };
      _rateCtrl.text = (row['rate'] ?? row['rate_with_tax'] ?? '0.00').toString();
      _qtyCtrl.text = (row['quantity'] ?? '1').toString();
      _discCtrl.text = (row['discount'] ?? '0.00').toString();
    });
  }

  Widget _buildQuickAddEntryBar(BuildContext context, String token) {
    final hasItem = _entryItem != null;
    final itemCode = (_entryItem?['product_code'] ?? _entryItem?['part_number'] ?? '').toString();
    final itemName = (_entryItem?['product_name'] ?? _entryItem?['name'] ?? '').toString();
    final brand = (_entryItem?['brand_name'] ?? _entryItem?['brand'] ?? '').toString();
    final stockVal = _entryItem?['current_stock'] ?? _entryItem?['stock'] ?? 0;
    final stockQty = (stockVal is num) ? stockVal.toDouble() : (double.tryParse(stockVal.toString()) ?? 0.0);
    final unit = (_entryItem?['unit'] ?? _entryItem?['unit_name'] ?? 'Pcs').toString();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Selector Header Bar
          InkWell(
            onTap: () async {
              final selected = await showAccessoryPickerDialog(
                context: context,
                token: token,
              );
              if (selected != null) {
                setState(() {
                  _entryItem = selected;
                  final defaultRate = selected['rate'] ?? selected['sales_rate'] ?? selected['price'] ?? 0.0;
                  final rateNum = (defaultRate is num) ? defaultRate.toDouble() : (double.tryParse(defaultRate.toString()) ?? 0.0);
                  if (rateNum > 0) {
                    _rateCtrl.text = rateNum.toStringAsFixed(2);
                  }
                  if (_qtyCtrl.text.isEmpty || _qtyCtrl.text == '0') {
                    _qtyCtrl.text = '1';
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: hasItem ? Colors.white : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: hasItem ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: const Color(0xFFD97706),
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: hasItem
                        ? Row(
                            children: [
                              if (itemCode.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    itemCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                              Expanded(
                                child: Text(
                                  brand.isNotEmpty ? '$itemName ($brand)' : itemName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  '${context.tr('Stock')}: ${stockQty.toStringAsFixed(1)} $unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            context.tr('product code/ part no/alternate no/product name'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  SizedBox(width: 4.w),
                  if (hasItem)
                    InkWell(
                      onTap: _clearEntryBar,
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    )
                  else
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ── Row with Rate | Qty | Discount | Total | [Add/Update] Button ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rate
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Rate'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Qty
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Qty'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Discount
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Discount'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _discCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Total preview
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Total'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 38.h,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _entryTotal.toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF000080),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // [ Add / Update ] Button
              ElevatedButton(
                onPressed: _onAddOrUpdateItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingIndex != null ? Colors.green.shade800 : const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  elevation: 1,
                ),
                child: Text(
                  _editingIndex != null ? context.tr('Update') : context.tr('Add'),
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.grey.shade300,
    );
  }

  Widget _tableHeaderCell(
    String text,
    double width, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : (textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E293B),
        ),
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(
    String text,
    double width, {
    TextAlign textAlign = TextAlign.left,
    bool isBold = false,
    Color? textColor,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : (textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.5.sp,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableDataRow(Map<String, dynamic> row, int index) {
    final isEven = index % 2 == 0;
    final isEditing = _editingIndex == index;
    final partNumber = (row['part_number'] ?? row['product_code'] ?? '-').toString();
    final name = (row['product_name'] ?? context.tr('Accessory')).toString();
    final rate = double.tryParse((row['rate'] ?? row['rate_with_tax'] ?? '0').toString()) ?? 0.0;
    final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
    final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0;
    final total = widget.controller.rowTotal(row);

    return InkWell(
      onTap: () => _onEditRow(index),
      child: Container(
        height: 40.h,
        color: isEditing
            ? const Color(0xFFFEF3C7)
            : (isEven ? Colors.white : const Color(0xFFF8FAFC)),
        child: Row(
          children: [
            _tableCell('${index + 1}', 36.w, textAlign: TextAlign.center, textColor: Colors.grey.shade600),
            _tableDivider(),
            _tableCell(partNumber.isNotEmpty ? partNumber : '-', 100.w, isBold: true, textColor: const Color(0xFF000080)),
            _tableDivider(),
            _tableCell(name, 145.w),
            _tableDivider(),
            _tableCell(rate.toStringAsFixed(2), 75.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2), 55.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(discount.toStringAsFixed(2), 70.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(
              total.toStringAsFixed(2),
              85.w,
              textAlign: TextAlign.right,
              isBold: true,
              textColor: const Color(0xFF000080),
            ),
            _tableDivider(),
            Container(
              width: 65.w,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _onEditRow(index),
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(Icons.edit_outlined, size: 16.sp, color: const Color(0xFF000080)),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  InkWell(
                    onTap: () {
                      if (_editingIndex == index) {
                        _clearEntryBar();
                      } else if (_editingIndex != null && _editingIndex! > index) {
                        _editingIndex = _editingIndex! - 1;
                      }
                      widget.controller.addedParts.removeAt(index);
                      widget.controller.notify();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(Icons.delete_outline, size: 16.sp, color: Colors.red),
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

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 12.5.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 12.5.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? const Color(0xFF000080) : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableTable(double totalAccessories) {
    if (widget.controller.addedParts.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36.sp, color: Colors.grey.shade400),
            SizedBox(height: 8.h),
            Text(
              context.tr('No stock items added yet'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context.tr('Select product code or item above and tap Add'),
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final currencySymbol = CountryConfig.currencySymbol;
    final subtotal = widget.controller.addedParts.fold<double>(
      0.0,
      (sum, row) {
        final rate = double.tryParse((row['rate'] ?? row['rate_with_tax'] ?? '0').toString()) ?? 0.0;
        final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
        return sum + (rate * qty);
      },
    );
    final totalDiscount = widget.controller.addedParts.fold<double>(
      0.0,
      (sum, row) => sum + (double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0),
    );
    final grandTotal = (subtotal - totalDiscount).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Container(
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      _tableHeaderCell('#', 36.w, textAlign: TextAlign.center),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Part Number'), 100.w),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Item'), 145.w),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Rate'), 75.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Qty'), 55.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Discount'), 70.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Total'), 85.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell('', 65.w, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // Data Rows
                for (int i = 0; i < widget.controller.addedParts.length; i++) ...[
                  _tableDataRow(widget.controller.addedParts[i], i),
                  if (i < widget.controller.addedParts.length - 1)
                    Container(height: 1, color: Colors.grey.shade200),
                ],
                // Footer Total Row
                Container(
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      _tableCell('', 36.w),
                      _tableDivider(),
                      _tableCell('', 100.w),
                      _tableDivider(),
                      _tableCell('', 145.w),
                      _tableDivider(),
                      _tableCell('', 75.w),
                      _tableDivider(),
                      _tableCell('', 55.w),
                      _tableDivider(),
                      _tableCell(context.tr('Total:'), 70.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(
                        grandTotal.toStringAsFixed(2),
                        85.w,
                        textAlign: TextAlign.right,
                        isBold: true,
                        textColor: const Color(0xFF000080),
                      ),
                      _tableDivider(),
                      _tableCell('', 65.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Subtotal, Discount, Grand Total Summary Card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSummaryLine(
                context.tr('Subtotal'),
                '$currencySymbol ${subtotal.toStringAsFixed(2)}',
              ),
              if (totalDiscount > 0) ...[
                SizedBox(height: 6.h),
                _buildSummaryLine(
                  context.tr('Discount'),
                  '- $currencySymbol ${totalDiscount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFDC2626),
                ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const Divider(height: 1, thickness: 1, color: Color(0xFFCBD5E1)),
              ),
              _buildSummaryLine(
                context.tr('Grand Total'),
                '$currencySymbol ${grandTotal.toStringAsFixed(2)}',
                isBold: true,
                valueColor: const Color(0xFF000080),
                fontSize: 14.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token ?? '';

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final totalAccessories = widget.controller.addedParts.fold<double>(
          0.0,
          (sum, row) => sum + widget.controller.rowTotal(row),
        );

        return SectionCard(
          title: context.tr('Accessories & Spare Parts'),
          fields: [
            _buildQuickAddEntryBar(context, token),
            SizedBox(height: 14.h),
            _buildScrollableTable(totalAccessories),
          ],
        );
      },
    );
  }
}
