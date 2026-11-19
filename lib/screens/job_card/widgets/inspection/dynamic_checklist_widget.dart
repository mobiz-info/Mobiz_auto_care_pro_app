import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../common/section_card.dart';

class DynamicChecklistWidget extends StatelessWidget {
  final JobCardInspectionController controller;
  final Map<String, dynamic> category;
  final void Function(Map<String, dynamic> serviceData)? onAddService;

  const DynamicChecklistWidget({
    super.key,
    required this.controller,
    required this.category,
    this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = (category['name'] ?? 'Inspection').toString();
    final items = List<Map<String, dynamic>>.from(
      (category['items'] as List? ?? []).map((i) => Map<String, dynamic>.from(i as Map)),
    );

    return SectionCard(
      title: context.tr(categoryName),
      fields: [
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: Text(
                context.tr('No checklist items in this category.'),
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 13.sp,
                ),
              ),
            ),
          )
        else
          ...items.map((item) => _buildChecklistItem(context, item, categoryName)),
      ],
    );
  }

  Widget _buildChecklistItem(BuildContext context, Map<String, dynamic> item, String categoryName) {
    final itemId = (item['id'] ?? item['name']).toString();
    final title = (item['name'] ?? '').toString();
    final inputType = (item['input_type'] ?? 'rag').toString();
    final unit = (item['unit'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final service = item['service'] as Map?;

    final currentStatus = controller.getChecklistStatus(itemId);
    final currentValue = controller.getChecklistValue(itemId);

    final isCritical = currentStatus == 'critical' || currentStatus == 'fail';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: REdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCritical ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
          width: isCritical ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Measurement Input if required
          if (inputType == 'measurement') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('measure-$itemId'),
                    initialValue: currentValue,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: unit.isNotEmpty ? 'Enter reading ($unit)' : 'Enter value',
                      suffixText: unit.isNotEmpty ? unit : null,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) => controller.setChecklistValue(
                      itemId,
                      val,
                      name: title,
                      category: categoryName,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],

          // Status Selector (RAG or Yes/No)
          if (inputType == 'yes_no')
            Row(
              children: [
                _statusButton(
                  context,
                  label: 'Pass / OK',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF10B981),
                  isSelected: currentStatus == 'pass',
                  onTap: () => controller.setChecklistStatus(
                    itemId,
                    'pass',
                    name: title,
                    category: categoryName,
                  ),
                ),
                SizedBox(width: 8.w),
                _statusButton(
                  context,
                  label: 'Fail / Defect',
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFEF4444),
                  isSelected: currentStatus == 'fail',
                  onTap: () => controller.setChecklistStatus(
                    itemId,
                    'fail',
                    name: title,
                    category: categoryName,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                _statusButton(
                  context,
                  label: 'Good',
                  icon: Icons.check_circle,
                  color: const Color(0xFF10B981),
                  isSelected: currentStatus == 'good',
                  onTap: () => controller.setChecklistStatus(
                    itemId,
                    'good',
                    name: title,
                    category: categoryName,
                  ),
                ),
                SizedBox(width: 6.w),
                _statusButton(
                  context,
                  label: 'Attention',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFF59E0B),
                  isSelected: currentStatus == 'attention',
                  onTap: () => controller.setChecklistStatus(
                    itemId,
                    'attention',
                    name: title,
                    category: categoryName,
                  ),
                ),
                SizedBox(width: 6.w),
                _statusButton(
                  context,
                  label: 'Critical',
                  icon: Icons.error_outline,
                  color: const Color(0xFFEF4444),
                  isSelected: currentStatus == 'critical',
                  onTap: () => controller.setChecklistStatus(
                    itemId,
                    'critical',
                    name: title,
                    category: categoryName,
                  ),
                ),
              ],
            ),

          // Upsell Banner when Critical
          if (isCritical && service != null && onAddService != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 16.sp,
                    color: const Color(0xFFB45309),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Action: ${service['name']}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      onAddService!(
                        {
                          'name': service['name'],
                          'service': {
                            'id': service['id'],
                            'name': service['name'],
                            'category_id': service['category_id'],
                          },
                          'category': {
                            'id': service['category_id'],
                            'name': service['category_name'] ?? 'General',
                          },
                          'rate': service['rate'] ?? '',
                        },
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '+ Add to Services',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: isSelected ? Colors.white : color,
              ),
              SizedBox(width: 4.w),
              Text(
                context.tr(label),
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
