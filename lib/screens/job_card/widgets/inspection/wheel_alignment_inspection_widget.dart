import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../common/section_card.dart';

class WheelAlignmentInspectionWidget extends StatelessWidget {
  final JobCardInspectionController controller;

  const WheelAlignmentInspectionWidget({
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
    String key, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: TextFormField(
          key: ValueKey('inspection-$key'),
          initialValue: values[key] ?? '',
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: (value) => values[key] = value,
          decoration: _inspectionDecoration(context, label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SectionCard(
          title: context.tr('Wheel Alignment and Balancing'),
          fields: [
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                for (final wheel in ['FL', 'FR', 'RL', 'RR'])
                  SizedBox(
                    width: 135.w,
                    child: _inspectionTextField(
                      context,
                      wheel,
                      controller.wheelAlignmentValues,
                      wheel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            _inspectionTextField(
              context,
              'Remarks',
              controller.wheelAlignmentValues,
              'remarks',
              maxLines: 3,
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 10.h,
              children: [
                SizedBox(
                  width: 125.w,
                  child: _inspectionTextField(
                    context,
                    'Next Due Days',
                    controller.wheelAlignmentValues,
                    'next_due_days',
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: _inspectionTextField(
                    context,
                    'KMs',
                    controller.wheelAlignmentValues,
                    'next_due_kms',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
