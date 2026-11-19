import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_inspection_controller.dart';
import '../../models/job_card_inspection_model.dart';
import '../common/section_card.dart';
import 'vehicle_damage_inspection_widget.dart';
import 'dynamic_checklist_widget.dart';
import 'tyre_inspection_widget.dart';
import 'wheel_alignment_inspection_widget.dart';
import 'oil_inspection_widget.dart';
import 'brake_inspection_widget.dart';

class InspectionTabView extends StatelessWidget {
  final JobCardInspectionController controller;
  final void Function(Map<String, dynamic> serviceData)? onAddService;

  const InspectionTabView({
    super.key,
    required this.controller,
    this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dynamicCategories = controller.checklistCategories;
        final categoryNames = dynamicCategories.isNotEmpty
            ? dynamicCategories.map((c) => (c['name'] ?? '').toString()).toList()
            : JobCardInspectionConfig.inspectionCategories;

        if (controller.selectedInspectionCategory.isEmpty && categoryNames.isNotEmpty) {
          controller.selectedInspectionCategory = categoryNames.first;
        }

        final activeCategoryData = dynamicCategories.firstWhere(
          (c) =>
              c['name']?.toString().trim().toLowerCase() ==
              controller.selectedInspectionCategory.trim().toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VehicleDamageInspectionWidget(controller: controller),
              SizedBox(height: 12.h),
              SizedBox(
                height: 42.h,
                child: SingleChildScrollView(
                  key: const ValueKey('inspection-category-tabs'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in categoryNames) ...[
                        ChoiceChip(
                          label: Text(context.tr(category)),
                          selected: category.trim().toLowerCase() ==
                              controller.selectedInspectionCategory.trim().toLowerCase(),
                          onSelected: (_) =>
                              controller.selectInspectionCategory(category),
                          selectedColor: const Color(0xFFE2E8F0),
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF000080),
                            fontSize: 12.sp,
                            fontWeight: category.trim().toLowerCase() ==
                                    controller.selectedInspectionCategory.trim().toLowerCase()
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: category.trim().toLowerCase() ==
                                    controller.selectedInspectionCategory.trim().toLowerCase()
                                ? const Color(0xFF000080)
                                : Colors.black12,
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              if (activeCategoryData.isNotEmpty)
                DynamicChecklistWidget(
                  controller: controller,
                  category: activeCategoryData,
                  onAddService: onAddService,
                )
              else if (controller.selectedInspectionCategory == 'Tyre')
                TyreInspectionWidget(controller: controller)
              else if (controller.selectedInspectionCategory ==
                  'Wheel Alignment and Balancing')
                WheelAlignmentInspectionWidget(controller: controller)
              else if (controller.selectedInspectionCategory == 'Oil')
                OilInspectionWidget(controller: controller)
              else if (controller.selectedInspectionCategory == 'Brake')
                BrakeInspectionWidget(controller: controller)
              else
                SectionCard(
                  title: context.tr(controller.selectedInspectionCategory),
                  fields: const [],
                ),
            ],
          ),
        );
      },
    );
  }
}
