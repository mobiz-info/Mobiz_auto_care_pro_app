import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_controller.dart';
import '../common/section_card.dart';

class ScheduleSignoffCard extends StatelessWidget {
  final JobCardController controller;

  const ScheduleSignoffCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SectionCard(
          title: '',
          fields: [
            TextField(
              controller: controller.additionalRemarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('Comment to Client'),
                hintText: context.tr('Comment to include for the client...'),
                hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            TextField(
              controller: controller.internalNotesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('Internal Notes'),
                hintText: context.tr('Internal notes...'),
                hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            DropdownButtonFormField<String>(
              value: controller.staff
                      .any((item) => item['id']?.toString() == controller.preparedById)
                  ? controller.preparedById
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Prepared By'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: controller.staff
                  .map(
                    (staff) => DropdownMenuItem(
                      value: staff['id'].toString(),
                      child: Text(
                        staff['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                controller.preparedById = value;
                controller.notify();
              },
            ),
            if (controller.companySealUrl.isNotEmpty) ...[
              Text(
                context.tr('Company Seal'),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Image.network(
                controller.companySealUrl,
                height: 76.h,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  context.tr('Company seal unavailable'),
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
            ],
            Container(
              height: 90.h,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  context.tr('Signature'),
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
