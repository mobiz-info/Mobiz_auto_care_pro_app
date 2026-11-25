import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/country_config.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../common/section_card.dart';

class LocalPurchaseCard extends StatefulWidget {
  final JobCardPricingController controller;

  const LocalPurchaseCard({
    super.key,
    required this.controller,
  });

  @override
  State<LocalPurchaseCard> createState() => _LocalPurchaseCardState();
}

class _LocalPurchaseCardState extends State<LocalPurchaseCard> {
  final TextEditingController _itemNameCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _billNoCtrl = TextEditingController();
  final TextEditingController _costPriceCtrl = TextEditingController(text: '0.00');
  final TextEditingController _rateCtrl = TextEditingController(text: '0.00');
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _discCtrl = TextEditingController(text: '0.00');
  final TextEditingController _remarksCtrl = TextEditingController();

  int? _editingIndex;

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _supplierCtrl.dispose();
    _billNoCtrl.dispose();
    _costPriceCtrl.dispose();
    _rateCtrl.dispose();
    _qtyCtrl.dispose();
    _discCtrl.dispose();
    _remarksCtrl.dispose();
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
      _itemNameCtrl.clear();
      _supplierCtrl.clear();
      _billNoCtrl.clear();
      _costPriceCtrl.text = '0.00';
      _rateCtrl.text = '0.00';
      _qtyCtrl.text = '1';
      _discCtrl.text = '0.00';
      _remarksCtrl.clear();
      _editingIndex = null;
    });
  }

  void _onAddOrUpdateItem() {
    final name = _itemNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please enter item name')),
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

    final costPrice = double.tryParse(_costPriceCtrl.text.trim()) ?? 0.0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0.0;
    final disc = double.tryParse(_discCtrl.text.trim()) ?? 0.0;
    final supplier = _supplierCtrl.text.trim();
    final billNo = _billNoCtrl.text.trim();
    final remarks = _remarksCtrl.text.trim();

    if (_editingIndex != null && _editingIndex! < widget.controller.addedLocalPurchases.length) {
      widget.controller.updateLocalPurchase(_editingIndex!, {
        'item_name': name,
        'supplier_name': supplier,
        'bill_number': billNo,
        'cost_price': costPrice,
        'rate': rate,
        'quantity': qty,
        'discount': disc,
        'unit': 'Pcs',
        'vat_percentage': 0.0,
        'remarks': remarks,
      });
    } else {
      widget.controller.addLocalPurchase(
        itemName: name,
        supplierName: supplier,
        billNumber: billNo,
        costPrice: costPrice,
        rate: rate,
        quantity: qty,
        discount: disc,
        remarks: remarks,
      );
    }

    _clearEntryBar();
  }

  void _onEditRow(int index) {
    if (index >= widget.controller.addedLocalPurchases.length) return;
    final row = widget.controller.addedLocalPurchases[index];
    setState(() {
      _editingIndex = index;
      _itemNameCtrl.text = (row['item_name'] ?? '').toString();
      _supplierCtrl.text = (row['supplier_name'] ?? '').toString();
      _billNoCtrl.text = (row['bill_number'] ?? '').toString();
      _costPriceCtrl.text = (row['cost_price'] ?? '0.00').toString();
      _rateCtrl.text = (row['rate'] ?? '0.00').toString();
      _qtyCtrl.text = (row['quantity'] ?? '1').toString();
      _discCtrl.text = (row['discount'] ?? '0.00').toString();
      _remarksCtrl.text = (row['remarks'] ?? '').toString();
    });
  }

  Widget _buildQuickAddEntryBar(BuildContext context) {
    final currencySymbol = CountryConfig.currencySymbol;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Edit indicator
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: const Color(0xFF15803D),
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                _editingIndex != null
                    ? context.tr('Edit Local Purchase Item')
                    : context.tr('Add Local Purchase Item'),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
              const Spacer(),
              if (_editingIndex != null)
                InkWell(
                  onTap: _clearEntryBar,
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Text(
                      context.tr('Cancel'),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),

          // Row 1: Item Name (Full width)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.tr("Item Name")} *',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4.h),
              TextField(
                controller: _itemNameCtrl,
                style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.tr('Enter item name / description'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Row 2: Supplier / Shop Name & Bill / Ref No
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Supplier / Shop Name'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _supplierCtrl,
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.tr('e.g. Al Madina Auto'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Bill / Ref No'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _billNoCtrl,
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: context.tr('e.g. INV-1024'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Row 3: Purchase Cost | Selling Rate | Qty | Discount
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cost Price (Purchase Rate)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Cost Price'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _costPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Selling Rate
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr("Selling Rate")} *',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000080),
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

              // Quantity
              Expanded(
                flex: 2,
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Disc'),
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
            ],
          ),
          SizedBox(height: 10.h),

          // Total & Action Button Bar
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${context.tr("Total")}: ',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$currencySymbol ${_entryTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _onAddOrUpdateItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  elevation: 0,
                ),
                icon: Icon(
                  _editingIndex != null ? Icons.check : Icons.add,
                  size: 16.sp,
                ),
                label: Text(
                  _editingIndex != null
                      ? context.tr('Update Item')
                      : context.tr('Add Item'),
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.inter(
          fontSize: 11.5.sp,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: textColor ?? const Color(0xFF1E293B),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableDivider() {
    return Container(width: 1, height: 38.h, color: const Color(0xFFE2E8F0));
  }

  Widget _buildScrollableTable() {
    if (widget.controller.addedLocalPurchases.isEmpty) {
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
            Icon(Icons.shopping_bag_outlined, size: 36.sp, color: Colors.grey.shade400),
            SizedBox(height: 8.h),
            Text(
              context.tr('No local purchase items added yet'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context.tr('Enter item name, rates, and tap Add Item above'),
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
    final subtotal = widget.controller.addedLocalPurchases.fold<double>(
      0.0,
      (sum, row) {
        final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0.0;
        final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
        return sum + (rate * qty);
      },
    );
    final totalDiscount = widget.controller.addedLocalPurchases.fold<double>(
      0.0,
      (sum, row) => sum + (double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0),
    );
    final grandTotal = widget.controller.localPurchasesSubtotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      _tableCell('#', 36.w, textAlign: TextAlign.center, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Item Name'), 140.w, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Supplier / Bill'), 110.w, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Cost'), 70.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Rate'), 70.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Qty'), 50.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Disc'), 60.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Total'), 80.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(context.tr('Action'), 65.w, textAlign: TextAlign.center, isBold: true),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xFFE2E8F0)),

                // Table Rows
                ...widget.controller.addedLocalPurchases.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final name = (row['item_name'] ?? '-').toString();
                  final supplier = (row['supplier_name'] ?? '').toString();
                  final bill = (row['bill_number'] ?? '').toString();
                  final cost = double.tryParse((row['cost_price'] ?? '0').toString()) ?? 0.0;
                  final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0.0;
                  final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
                  final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0;
                  final total = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
                  final isEven = index % 2 == 0;
                  final isEditing = _editingIndex == index;

                  String supplierBillText = supplier;
                  if (bill.isNotEmpty) {
                    supplierBillText = supplier.isNotEmpty ? '$supplier ($bill)' : bill;
                  }
                  if (supplierBillText.isEmpty) supplierBillText = '-';

                  return Container(
                    height: 40.h,
                    color: isEditing
                        ? const Color(0xFFFEF3C7)
                        : (isEven ? Colors.white : const Color(0xFFF8FAFC)),
                    child: Row(
                      children: [
                        _tableCell('${index + 1}', 36.w, textAlign: TextAlign.center, textColor: Colors.grey.shade600),
                        _tableDivider(),
                        _tableCell(name, 140.w, isBold: true, textColor: const Color(0xFF000080)),
                        _tableDivider(),
                        _tableCell(supplierBillText, 110.w),
                        _tableDivider(),
                        _tableCell(cost.toStringAsFixed(2), 70.w, textAlign: TextAlign.right, textColor: const Color(0xFFB45309)),
                        _tableDivider(),
                        _tableCell(rate.toStringAsFixed(2), 70.w, textAlign: TextAlign.right),
                        _tableDivider(),
                        _tableCell(qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2), 50.w, textAlign: TextAlign.right),
                        _tableDivider(),
                        _tableCell(discount.toStringAsFixed(2), 60.w, textAlign: TextAlign.right),
                        _tableDivider(),
                        _tableCell(
                          total.toStringAsFixed(2),
                          80.w,
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
                                  widget.controller.removeLocalPurchase(index);
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
                  );
                }),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Summary Card
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return SectionCard(
          title: context.tr('Local Purchases'),
          fields: [
            _buildQuickAddEntryBar(context),
            SizedBox(height: 14.h),
            _buildScrollableTable(),
          ],
        );
      },
    );
  }
}
