import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../common/section_card.dart';

class BrakeInspectionWidget extends StatelessWidget {
  final JobCardInspectionController controller;

  const BrakeInspectionWidget({
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

  Widget _inspectionTextField(
    BuildContext context,
    String label,
    Map<String, String> values,
    String key,
  ) =>
      TextFormField(
        key: ValueKey('inspection-$key'),
        initialValue: values[key] ?? '',
        onChanged: (value) => values[key] = value,
        decoration: _inspectionDecoration(context, label),
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

  Widget _inspectionOptionChecks(
    BuildContext context,
    String title,
    Map<String, String> values,
    String key,
  ) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Row(
          children: [
            Text(context.tr(title)),
            SizedBox(width: 12.w),
            Expanded(
              child: _inspectionCheckbox(context, 'New', values, '${key}_new'),
            ),
            Expanded(
              child: _inspectionCheckbox(
                context,
                'Polish',
                values,
                '${key}_polish',
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SectionCard(
          title: context.tr('Brake Service'),
          fields: [
            Row(
              children: [
                Expanded(
                  child: _inspectionTextField(
                    context,
                    'Front',
                    controller.brakeInspectionValues,
                    'front',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _inspectionCheckbox(
                    context,
                    'Pad',
                    controller.brakeInspectionValues,
                    'front_pad',
                  ),
                ),
              ],
            ),
            _inspectionOptionChecks(
              context,
              'Front Disc',
              controller.brakeInspectionValues,
              'front_disc',
            ),
            Row(
              children: [
                Expanded(
                  child: _inspectionTextField(
                    context,
                    'Rear',
                    controller.brakeInspectionValues,
                    'rear',
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _inspectionCheckbox(
                    context,
                    'Pad',
                    controller.brakeInspectionValues,
                    'rear_pad',
                  ),
                ),
              ],
            ),
            _inspectionOptionChecks(
              context,
              'Rear Disc',
              controller.brakeInspectionValues,
              'rear_disc',
            ),
          ],
        );
      },
    );
  }
}
