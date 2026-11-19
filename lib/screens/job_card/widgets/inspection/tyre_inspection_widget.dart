import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../../models/job_card_inspection_model.dart';
import '../common/section_card.dart';

class TyreInspectionWidget extends StatelessWidget {
  final JobCardInspectionController controller;

  const TyreInspectionWidget({
    super.key,
    required this.controller,
  });

  Widget _inspectionSingleChoice(
    BuildContext context,
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(label),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: 8.w,
              children: options
                  .map(
                    (option) => ChoiceChip(
                      label: Text(context.tr(option)),
                      selected: selected == option,
                      onSelected: (_) => onChanged(option),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

  Widget _inspectionServiceOptions(
    BuildContext context,
    String label,
    String key,
    List<String> options, {
    bool multiple = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(label),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8.w,
              children: options.map((option) {
                final current = controller.tyreServices[key];
                final selected = multiple
                    ? (current is List && current.contains(option))
                    : current == option;
                return multiple
                    ? FilterChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (checked) {
                          final values = List<String>.from(
                            current is List ? current : const [],
                          );
                          checked ? values.add(option) : values.remove(option);
                          controller.tyreServices[key] = values;
                          controller.notify();
                        },
                      )
                    : ChoiceChip(
                        label: Text(option),
                        selected: selected,
                        onSelected: (_) {
                          controller.tyreServices[key] = option;
                          controller.notify();
                        },
                      );
              }).toList(),
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
          title: context.tr('Tyre Services'),
          fields: [
            _inspectionSingleChoice(
              context,
              'Wheel Alignment',
              JobCardInspectionConfig.wheelAlignmentChoices,
              (controller.tyreServices['wheel_alignment'] ?? '').toString(),
              (value) {
                controller.tyreServices['wheel_alignment'] = value;
                controller.notify();
              },
            ),
            _inspectionServiceOptions(
              context,
              'Wheel Balancing',
              'wheel_balancing',
              JobCardInspectionConfig.tyreWheelOptions,
              multiple: true,
            ),
            _inspectionServiceOptions(
              context,
              'Nitrogen Filling',
              'nitrogen_filling',
              JobCardInspectionConfig.nitrogenFillingOptions,
              multiple: true,
            ),
            _inspectionServiceOptions(
              context,
              'Tyre Repair',
              'tyre_repair',
              JobCardInspectionConfig.tyreRepairOptions,
              multiple: true,
            ),
            _inspectionServiceOptions(
              context,
              'Wheel Repair',
              'wheel_repair',
              JobCardInspectionConfig.wheelRepairOptions,
              multiple: true,
            ),
            _inspectionServiceOptions(
              context,
              'Tyre Rotation',
              'tyre_rotation',
              JobCardInspectionConfig.tyreWheelOptions,
              multiple: true,
            ),
          ],
        );
      },
    );
  }
}
