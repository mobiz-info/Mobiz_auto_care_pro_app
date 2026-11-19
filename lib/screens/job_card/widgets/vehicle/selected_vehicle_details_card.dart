import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_vehicle_controller.dart';

class SelectedVehicleDetailsCard extends StatelessWidget {
  final JobCardVehicleController controller;

  const SelectedVehicleDetailsCard({
    super.key,
    required this.controller,
  });

  Widget _buildVehicleSpecChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF000080)),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInput(
    BuildContext context,
    String label,
    TextEditingController textController,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(label),
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

  @override
  Widget build(BuildContext context) {
    final v = controller.selectedVehicle;
    if (v == null) return const SizedBox.shrink();

    final plate = (v['no'] ?? v['vehicle_number'] ?? '-').toString();
    final make = (v['make'] ?? v['make_name'] ?? '').toString();
    final model = (v['model'] ??
            v['brand_model_name'] ??
            v['vehicle_model_name'] ??
            v['type'] ??
            '')
        .toString();
    final segment = (v['segment'] ?? v['vehicle_model_name'] ?? v['type'] ?? '').toString();
    final vehicleType = (v['vehicle_type'] ?? '').toString();
    final fuel = (v['fuel_type_display'] ?? v['fuel_type'] ?? '').toString();
    final transmission = (v['transmission_type'] ?? '').toString();
    final color = (v['color'] ?? v['color_name'] ?? '').toString();
    final year = (v['model_year'] ?? '').toString();
    final trim = (v['variant_trim'] ?? '').toString();
    final wheel = v['wheel_type'] != null
        ? v['wheel_type'].toString().replaceAll('_', ' ').toUpperCase()
        : '';
    final odometer = (v['current_odometer_km'] ?? '').toString();

    final fullName = [make, model, trim].where((s) => s.isNotEmpty).join(' ');

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF000080).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plate,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : context.tr('Selected Vehicle'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      context.tr('Selected Vehicle Details'),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (year.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    year,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (segment.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.category_outlined,
                  context.tr('Segment'),
                  segment,
                ),
              if (vehicleType.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.directions_car_outlined,
                  context.tr('Type'),
                  vehicleType,
                ),
              if (fuel.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.local_gas_station_outlined,
                  context.tr('Fuel'),
                  fuel,
                ),
              if (transmission.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.settings_outlined,
                  context.tr('Transmission'),
                  transmission,
                ),
              if (color.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.palette_outlined,
                  context.tr('Color'),
                  color,
                ),
              if (wheel.isNotEmpty)
                _buildVehicleSpecChip(
                  Icons.adjust_outlined,
                  context.tr('Wheel'),
                  wheel,
                ),
              if (odometer.isNotEmpty && odometer != '0')
                _buildVehicleSpecChip(
                  Icons.speed_outlined,
                  context.tr('Odometer'),
                  '$odometer KM',
                ),
            ],
          ),
          SizedBox(height: 12.h),
          _profileInput(context, 'Engine Number', controller.engineNumberController),
          SizedBox(height: 8.h),
          _profileInput(context, 'Chassis Number', controller.chassisNumberController),
        ],
      ),
    );
  }
}
