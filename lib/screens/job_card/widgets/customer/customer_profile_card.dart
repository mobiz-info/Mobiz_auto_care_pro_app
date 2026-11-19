import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/job_card_customer_controller.dart';
import '../common/section_card.dart';

class CustomerProfileCard extends StatelessWidget {
  final JobCardCustomerController controller;

  const CustomerProfileCard({
    super.key,
    required this.controller,
  });

  Widget _profileInput(
    String label,
    TextEditingController textController, {
    TextInputType? keyboard,
  }) =>
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
            keyboardType: keyboard,
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
        return SectionCard(
          title: 'Customer Details',
          fields: [
            _profileInput('Customer / Business Name', controller.profileName),
            _masterDropdown(
              'Customer Type',
              controller.customerTypes,
              controller.customerTypeId,
              (v) => controller.customerTypeId = v,
            ),
            _profileInput(
              'Mobile Number',
              controller.profilePhone,
              keyboard: TextInputType.phone,
            ),
            _profileInput(
              'WhatsApp Number',
              controller.profileWhatsapp,
              keyboard: TextInputType.phone,
            ),
            _profileInput(
              'Email',
              controller.profileEmail,
              keyboard: TextInputType.emailAddress,
            ),
            _profileInput('State / Emirate', controller.profileState),
            _profileInput('City', controller.profileCity),
            _profileInput('Tax Registration No', controller.profileTax),
            _profileInput('TIN', controller.profileTin),
            _profileInput('PAN', controller.profilePan),
          ],
        );
      },
    );
  }
}
