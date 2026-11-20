import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../widgets/automotive_card.dart';
import '../../controllers/job_card_controller.dart';
import '../../models/job_card_model.dart';
import '../vehicle/vehicle_before_after_photos_card.dart';

class OverviewTabView extends StatelessWidget {
  final JobCardController controller;

  const OverviewTabView({
    super.key,
    required this.controller,
  });

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF000080), size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr(title),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool isBadge = false, Color? badgeColor}) {
    final cleanVal = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              context.tr(label),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? const Color(0xFF000080)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: (badgeColor ?? const Color(0xFF000080)).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        cleanVal,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: badgeColor ?? const Color(0xFF000080),
                        ),
                      ),
                    ),
                  )
                : Text(
                    cleanVal,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _specChip(String label, String value) {
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildDamageMarksSection(BuildContext context) {
    final marks = controller.inspectionCtrl.damageMarks;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: marks.isEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: marks.isEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                marks.isEmpty ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 16.r,
                color: marks.isEmpty ? const Color(0xFF166534) : const Color(0xFFB45309),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  context.tr('Vehicle Damage Inspection'),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: marks.isEmpty ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: marks.isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  marks.isEmpty
                      ? context.tr('No Damages')
                      : '${marks.length} ${context.tr('Marked')}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: marks.isEmpty ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          if (marks.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Divider(height: 1, color: Colors.orange.shade200),
            SizedBox(height: 8.h),
            ...List.generate(marks.length, (idx) {
              final mark = marks[idx];
              final view = (mark['view'] ?? '').toString();
              final part = (mark['part'] ?? '').toString();
              final remarks = (mark['remarks'] ?? '').toString().trim();
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        view,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        part,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (remarks.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          remarks,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInspectionSubsection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
  }) {
    final cleanEntries = data.entries.where((e) {
      final v = e.value;
      if (v == null) return false;
      if (v is String) return v.trim().isNotEmpty && v != '-' && v != 'No';
      if (v is List) return v.isNotEmpty;
      if (v is bool) return v;
      return true;
    }).toList();

    if (cleanEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.r, color: const Color(0xFF000080)),
              SizedBox(width: 6.w),
              Text(
                context.tr(title),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF000080),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: cleanEntries.map((e) {
              final valStr = e.value is List ? (e.value as List).join(', ') : e.value.toString();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '${context.tr(e.key)}: ',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                      TextSpan(
                        text: valStr,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF000080)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final custCtrl = controller.customerCtrl;
        final vehCtrl = controller.vehicleCtrl;
        final pricingCtrl = controller.pricingCtrl;
        final issues = controller.issuesCtrl.reportedIssues;

        final customerName = controller.snapshotMode
            ? custCtrl.profileName.text
            : (custCtrl.selectedCustomer?['name'] ?? '').toString();
        final customerPhone = controller.snapshotMode
            ? custCtrl.profilePhone.text
            : (custCtrl.selectedCustomer?['phone'] ?? '').toString();
        final customerWa = controller.snapshotMode
            ? custCtrl.profileWhatsapp.text
            : (custCtrl.selectedCustomer?['whatsapp'] ?? '').toString();
        final customerEmail = controller.snapshotMode
            ? custCtrl.profileEmail.text
            : (custCtrl.selectedCustomer?['email'] ?? '').toString();
        final customerType = controller.snapshotMode
            ? JobCardConstants.lookupName(custCtrl.customerTypes, custCtrl.customerTypeId)
            : (custCtrl.selectedCustomer?['customer_type'] ?? '').toString();
        final customerState = controller.snapshotMode
            ? custCtrl.profileState.text
            : (custCtrl.selectedCustomer?['state'] ?? '').toString();

        final vehiclePlate = controller.snapshotMode
            ? vehCtrl.vehicleNumber.text
            : (vehCtrl.selectedVehicle?['vehicle_number'] ?? '').toString();
        final vehicleMake = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.makes, vehCtrl.makeId)
            : (vehCtrl.selectedVehicle?['make'] ?? '').toString();
        final vehicleModel = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.models, vehCtrl.modelId)
            : (vehCtrl.selectedVehicle?['model'] ?? '').toString();
        final vehicleType = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.vehicleTypes, vehCtrl.vehicleTypeId)
            : (vehCtrl.selectedVehicle?['vehicle_type'] ?? '').toString();
        final vehicleSegment = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.segments, vehCtrl.segmentId)
            : (vehCtrl.selectedVehicle?['segment'] ?? '').toString();
        final vehicleColor = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.colors, vehCtrl.colorId)
            : (vehCtrl.selectedVehicle?['color'] ?? '').toString();
        final vehicleFuel = controller.snapshotMode
            ? vehCtrl.fuelType
            : (vehCtrl.selectedVehicle?['fuel_type'] ?? '').toString();
        final vehicleWheel = controller.snapshotMode
            ? vehCtrl.wheelType
            : (vehCtrl.selectedVehicle?['wheel_type'] ?? '').toString();
        final vehicleEmission = controller.snapshotMode
            ? JobCardConstants.lookupName(vehCtrl.emissions, vehCtrl.emissionId)
            : (vehCtrl.selectedVehicle?['emission_standard'] ?? '').toString();

        final issuePricingSubtotal = pricingCtrl.calculateIssuePricingSubtotal(issues);
        final servicesSubtotal = pricingCtrl.calculateServicesSubtotal(issues);
        final labourSubtotal = pricingCtrl.calculateLabourSubtotal(issues);
        final grandTotal = pricingCtrl.calculateGrandEstimatedTotal(issues);

        final realJobNumber = controller.jobNumber;
        final jobCardNumber = (realJobNumber != null && realJobNumber.isNotEmpty)
            ? realJobNumber
            : (controller.savedJobCardId != null
                ? 'JOB #${controller.savedJobCardId}'
                : (controller.existingJobCardId != null
                    ? 'JOB #${controller.existingJobCardId}'
                    : 'JOB ORDER DRAFT'));

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Job Card Banner ──────────────────────────────────
              Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: AutomotiveIdBadge(
                            idText: jobCardNumber,
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AutomotiveStatusPill(
                          status: 'in_progress',
                          label: context.tr('Job Order Overview'),
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (vehiclePlate.isNotEmpty) ...[
                          VehiclePlateBadge(plateNumber: vehiclePlate, fontSize: 13.sp),
                          SizedBox(width: 10.w),
                        ],
                        Expanded(
                          child: Text(
                            '$vehicleMake $vehicleModel'.trim().isNotEmpty
                                ? '$vehicleMake $vehicleModel'
                                : (customerName.isNotEmpty ? customerName : 'Job Order'),
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (controller.leadTimeController.text.trim().isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      const Divider(color: Colors.white24, height: 1),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14.r, color: Colors.white70),
                          SizedBox(width: 6.w),
                          Text(
                            '${context.tr("Days Needed")}: ${controller.leadTimeController.text.trim()}',
                            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── 2. Customer & Vehicle Summary Cards ───────────────────────
              _sectionCard(
                context: context,
                title: 'Customer Details',
                icon: Icons.person_outline,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customerName.isNotEmpty ? customerName : context.tr('No Customer Selected'),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ),
                      if (customerType.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            customerType,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _infoRow(context, 'Mobile', customerPhone),
                  if (customerWa.isNotEmpty) _infoRow(context, 'WhatsApp Number', customerWa),
                  if (customerEmail.isNotEmpty) _infoRow(context, 'Email', customerEmail),
                  if (customerState.isNotEmpty) _infoRow(context, 'State / Emirate', customerState),
                ],
              ),

              _sectionCard(
                context: context,
                title: 'Vehicle Details',
                icon: Icons.directions_car_outlined,
                children: [
                  Row(
                    children: [
                      VehiclePlateBadge(plateNumber: vehiclePlate),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          '$vehicleMake $vehicleModel'.trim().isNotEmpty ? '$vehicleMake $vehicleModel' : '-',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _specChip('Type', vehicleType),
                      _specChip('Segment', vehicleSegment),
                      _specChip('Color', vehicleColor),
                      _specChip('Fuel', vehicleFuel),
                      _specChip('Wheel', vehicleWheel),
                      _specChip('Emission', vehicleEmission),
                    ],
                  ),
                ],
              ),

              // ── Vehicle Before & After Photos ──────────────────────────────
              VehicleBeforeAfterPhotosCard(controller: controller),

              // ── 3. Inspection Details (Full Breakdown + Damage Marks) ──────
              _sectionCard(
                context: context,
                title: 'Inspection Details',
                icon: Icons.fact_check_outlined,
                children: [
                  _buildDamageMarksSection(context),
                  _buildInspectionSubsection(
                    context: context,
                    title: 'Oil Service',
                    icon: Icons.oil_barrel_outlined,
                    data: {
                      ...controller.inspectionCtrl.oilInspectionValues,
                      ...controller.inspectionCtrl.legacyOilInspectionValues,
                    },
                  ),
                  _buildInspectionSubsection(
                    context: context,
                    title: 'Tyre Services & Inspection',
                    icon: Icons.tire_repair_outlined,
                    data: {
                      if (controller.inspectionCtrl.tyrePressure.isNotEmpty)
                        'Pressure': controller.inspectionCtrl.tyrePressure,
                      if (controller.inspectionCtrl.tyreTreadDepth.isNotEmpty)
                        'Tread Depth': controller.inspectionCtrl.tyreTreadDepth,
                      if (controller.inspectionCtrl.tyreWearIndicators.isNotEmpty)
                        'Wear Indicators': controller.inspectionCtrl.tyreWearIndicators,
                      if (controller.inspectionCtrl.tyreDotYear.isNotEmpty)
                        'DOT Year': controller.inspectionCtrl.tyreDotYear,
                      ...controller.inspectionCtrl.tyreServices,
                      ...controller.inspectionCtrl.tyreWheelAssessment,
                    },
                  ),
                  _buildInspectionSubsection(
                    context: context,
                    title: 'Wheel Alignment & Balancing',
                    icon: Icons.tune,
                    data: controller.inspectionCtrl.wheelAlignmentValues,
                  ),
                  _buildInspectionSubsection(
                    context: context,
                    title: 'Brake Service',
                    icon: Icons.settings_outlined,
                    data: controller.inspectionCtrl.brakeInspectionValues,
                  ),
                ],
              ),

              // ── 4. Services & Pricing ───────────────────────────────
              _sectionCard(
                context: context,
                title: '${context.tr('Services & Repairs')} (${issues.length})',
                icon: Icons.build_circle_outlined,
                children: issues.isEmpty
                    ? [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Text(
                            context.tr('No services reported'),
                            style: GoogleFonts.inter(color: Colors.grey.shade600),
                          ),
                        ),
                      ]
                    : [
                        ...List.generate(issues.length, (index) {
                          final row = issues[index];
                          final sName = row['service']?['name']?.toString() ?? 'Service';
                          final issueText = (row['issue_text'] ?? '').toString();
                          final qty = row['quantity'] ?? '1';
                          final rate = JobCardConstants.numberOrZero(row['rate']);
                          final discount = JobCardConstants.numberOrZero(row['discount']);
                          final warranty = (row['warranty'] ?? row['warranty_years'] ?? '').toString();
                          final rowTot = controller.pricingCtrl.rowTotal(row);

                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. $sName',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.sp,
                                          color: const Color(0xFF000080),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$currencySymbol ${rowTot.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.sp,
                                        color: const Color(0xFF000080),
                                      ),
                                    ),
                                  ],
                                ),
                                if (issueText.isNotEmpty &&
                                    issueText.toLowerCase() != sName.toLowerCase()) ...[
                                  SizedBox(height: 3.h),
                                  Text(
                                    '${context.tr('Complaint')}: $issueText',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Text(
                                      'Qty: $qty · Rate: $currencySymbol ${rate.toStringAsFixed(2)} · Disc: $currencySymbol ${discount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (warranty.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Text(
                                          warranty,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
              ),

              // ── 5. Additional Services, Parts, Labour, Extras ──────────────
              if (pricingCtrl.addedServices.isNotEmpty)
                _sectionCard(
                  context: context,
                  title: 'Additional Services (${pricingCtrl.addedServices.length})',
                  icon: Icons.miscellaneous_services_outlined,
                  children: [
                    ...pricingCtrl.addedServices.map((row) => _infoRow(
                          context,
                          (row['service_name'] ?? 'Service').toString(),
                          '$currencySymbol ${controller.pricingCtrl.rowTotal(row).toStringAsFixed(2)}',
                        )),
                  ],
                ),

              if (pricingCtrl.addedParts.isNotEmpty)
                _sectionCard(
                  context: context,
                  title: 'Accessories (${pricingCtrl.addedParts.length})',
                  icon: Icons.extension_outlined,
                  children: [
                    ...pricingCtrl.addedParts.map((row) => _infoRow(
                          context,
                          (row['product_name'] ?? 'Part').toString(),
                          '$currencySymbol ${controller.pricingCtrl.rowTotal(row).toStringAsFixed(2)}',
                        )),
                  ],
                ),

              if (pricingCtrl.addedLabour.isNotEmpty)
                _sectionCard(
                  context: context,
                  title: 'Labour Charges (${pricingCtrl.addedLabour.length})',
                  icon: Icons.engineering_outlined,
                  children: [
                    ...pricingCtrl.addedLabour.map((row) => _infoRow(
                          context,
                          (row['labour_particulars'] ?? 'Labour').toString(),
                          '$currencySymbol ${controller.pricingCtrl.rowTotal(row).toStringAsFixed(2)}',
                        )),
                  ],
                ),

              if (pricingCtrl.addedExtras.isNotEmpty)
                _sectionCard(
                  context: context,
                  title: 'Extras (${pricingCtrl.addedExtras.length})',
                  icon: Icons.add_circle_outline,
                  children: [
                    ...pricingCtrl.addedExtras.map((row) => _infoRow(
                          context,
                          (row['extra_details'] ?? 'Extra').toString(),
                          '$currencySymbol ${controller.pricingCtrl.rowTotal(row).toStringAsFixed(2)}',
                        )),
                  ],
                ),

              // ── 6. Cost Overview & Grand Total ────────────────────────────
              _sectionCard(
                context: context,
                title: 'Cost Overview',
                icon: Icons.receipt_long_outlined,
                children: [
                  _infoRow(context, 'Issue Pricing', '$currencySymbol ${issuePricingSubtotal.toStringAsFixed(2)}'),
                  if (servicesSubtotal > issuePricingSubtotal)
                    _infoRow(
                      context,
                      'Additional Services',
                      '$currencySymbol ${(servicesSubtotal - issuePricingSubtotal).clamp(0, double.infinity).toStringAsFixed(2)}',
                    ),
                  if (pricingCtrl.partsSubtotal > 0)
                    _infoRow(context, 'Accessories', '$currencySymbol ${pricingCtrl.partsSubtotal.toStringAsFixed(2)}'),
                  if (labourSubtotal > 0)
                    _infoRow(context, 'Labour', '$currencySymbol ${labourSubtotal.toStringAsFixed(2)}'),
                  if (pricingCtrl.extrasSubtotal > 0)
                    _infoRow(context, 'Extras', '$currencySymbol ${pricingCtrl.extrasSubtotal.toStringAsFixed(2)}'),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000080),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('Grand Total'),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$currencySymbol ${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFDE047),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── 7. Schedule & Notes ───────────────────────────────────────
              _sectionCard(
                context: context,
                title: 'Sign-off',
                icon: Icons.check_circle_outline,
                children: [
                  if (controller.expectedDeliveryDate != null)
                    _infoRow(
                      context,
                      'Expected Delivery Date',
                      '${DateFormat('dd-MM-yyyy').format(controller.expectedDeliveryDate!)}${controller.expectedDeliveryTime != null ? ' ${controller.expectedDeliveryTime!.format(context)}' : ''}',
                      isBadge: true,
                      badgeColor: const Color(0xFF166534),
                    ),
                  if (controller.additionalRemarksController.text.trim().isNotEmpty)
                    _infoRow(context, 'Comment to Client', controller.additionalRemarksController.text),
                  if (controller.internalNotesController.text.trim().isNotEmpty)
                    _infoRow(context, 'Internal Notes', controller.internalNotesController.text),
                  _infoRow(
                    context,
                    'Prepared By',
                    controller.staff
                        .where((item) => item['id']?.toString() == controller.preparedById)
                        .map((item) => (item['name'] ?? '').toString())
                        .join(),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}
