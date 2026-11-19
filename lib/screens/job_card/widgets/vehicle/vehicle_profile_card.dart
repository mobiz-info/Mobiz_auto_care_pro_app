import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/job_card_vehicle_controller.dart';
import '../common/section_card.dart';

class VehicleProfileCard extends StatelessWidget {
  final JobCardVehicleController controller;

  const VehicleProfileCard({
    super.key,
    required this.controller,
  });

  Widget _profileInput(
    String label,
    TextEditingController textController,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: textController,
            style: GoogleFonts.inter(fontSize: 14.sp),
            decoration: const InputDecoration(),
          ),
        ],
      );

  Widget _masterDropdown(
    String label,
    List<dynamic> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    final valid = options.any((item) => item['id'].toString() == selected)
        ? selected
        : null;
    return DropdownButtonFormField<String>(
      value: valid,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['id'].toString(),
              child: Text(
                item['name'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filteredModels = controller.models
            .where(
              (item) =>
                  controller.makeId.isEmpty ||
                  item['make_id'].toString() == controller.makeId,
            )
            .toList();

        return SectionCard(
          title: 'Vehicle Details',
          fields: [
            _profileInput('Vehicle Number', controller.vehicleNumber),
            _profileInput('Engine Number', controller.engineNumberController),
            _profileInput('Chassis Number', controller.chassisNumberController),
            _masterDropdown(
              'Vehicle Type',
              controller.vehicleTypes,
              controller.vehicleTypeId,
              (v) => controller.vehicleTypeId = v,
            ),
            _masterDropdown(
              'Segment',
              controller.segments,
              controller.segmentId,
              (v) => controller.segmentId = v,
            ),
            _masterDropdown(
              'Make',
              controller.makes,
              controller.makeId,
              (v) => controller.makeId = v,
            ),
            _masterDropdown(
              'Model',
              filteredModels,
              controller.modelId,
              (v) => controller.onModelSelected(v),
            ),
            _masterDropdown(
              'Color',
              controller.colors,
              controller.colorId,
              (v) => controller.colorId = v,
            ),
            _masterDropdown(
              'Emission Standard',
              controller.emissions,
              controller.emissionId,
              (v) => controller.emissionId = v,
            ),
            _masterDropdown(
              'Fuel Type',
              controller.fuelTypes,
              controller.fuelType,
              (v) => controller.fuelType = v,
            ),
            _masterDropdown(
              'Wheel Type',
              controller.wheelTypes,
              controller.wheelType,
              (v) => controller.wheelType = v,
            ),
          ],
        );
      },
    );
  }
}
