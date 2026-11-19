import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../../models/job_card_inspection_model.dart';
import '../common/section_card.dart';

class OilInspectionWidget extends StatelessWidget {
  final JobCardInspectionController controller;

  const OilInspectionWidget({
    super.key,
    required this.controller,
  });

  InputDecoration _inspectionDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: context.tr(label),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      );

  Widget _inspectionSelect(
    BuildContext context,
    String label,
    Map<String, String> values,
    String key,
    List<String> options,
  ) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: values[key]?.isNotEmpty == true ? values[key] : null,
          decoration: _inspectionDecoration(context, label),
          items: options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(context.tr(option))))
              .toList(),
          onChanged: (value) {
            values[key] = value ?? '';
            controller.notify();
          },
        ),
      );

  Widget _inspectionTextField(
    BuildContext context,
    String label,
    Map<String, String> values,
    String key, {
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: TextFormField(
          key: ValueKey('inspection-$key'),
          initialValue: values[key] ?? '',
          keyboardType: keyboardType,
          onChanged: (value) => values[key] = value,
          decoration: _inspectionDecoration(context, label),
        ),
      );

  Widget _inspectionCheckbox(
    BuildContext context,
    String label,
    Map<String, String> values,
    String key,
  ) =>
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(context.tr(label),
            style: GoogleFonts.inter(fontSize: 12.sp)),
        value: values[key] == 'Yes',
        onChanged: (checked) {
          values[key] = checked == true ? 'Yes' : '';
          controller.notify();
        },
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SectionCard(
          title: context.tr('Oil'),
          fields: [
            _inspectionSelect(
              context,
              'Select Type',
              controller.oilInspectionValues,
              'oil_type',
              JobCardInspectionConfig.oilTypes,
            ),
            _inspectionTextField(
              context,
              'Brand',
              controller.oilInspectionValues,
              'brand',
            ),
            _inspectionTextField(
              context,
              'Grade',
              controller.oilInspectionValues,
              'grade',
            ),
            _inspectionTextField(
              context,
              'Litres',
              controller.oilInspectionValues,
              'litres',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            _inspectionCheckbox(
              context,
              'Filter Change',
              controller.oilInspectionValues,
              'filter_change',
            ),
            _inspectionCheckbox(
              context,
              'Engine Flush',
              controller.oilInspectionValues,
              'engine_flush',
            ),
          ],
        );
      },
    );
  }
}
