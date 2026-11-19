import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../../../config/country_config.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_customer_controller.dart';
import 'add_customer_modal.dart';

class CustomerSearchCard extends StatelessWidget {
  final JobCardCustomerController controller;

  const CustomerSearchCard({
    super.key,
    required this.controller,
  });

  void _openAddCustomerModal(BuildContext context, {String? initialPhoneOrPlate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddCustomerModal(
        customerTypes: controller.customerTypes,
        initialQuery: initialPhoneOrPlate,
        onCustomerCreated: (newCustomer) {
          controller.setSelectedCustomerDirectly(newCustomer);
        },
      ),
    );
  }

  void _showCustomerNotFoundDialog(BuildContext context, String searchedText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Customer Not Found')),
        content: Text(
          '${context.tr('No customer matching')} "$searchedText". ${context.tr('Would you like to register a new customer?')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openAddCustomerModal(context, initialPhoneOrPlate: searchedText);
            },
            child: Text(
              context.tr('Add Customer'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token ?? '';

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  Text(
                    context.tr('1. Customer Information'),
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddCustomerModal(
                      context,
                      initialPhoneOrPlate: controller.mobileController.text.trim(),
                    ),
                    icon: const Icon(
                      Icons.person_add,
                      size: 16,
                      color: Color(0xFF000080),
                    ),
                    label: Text(
                      context.tr('+ Add Customer'),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Search Type Radios: Owner Number vs Vehicle Number
              ValueListenableBuilder<String>(
                valueListenable: controller.searchTypeNotifier,
                builder: (context, searchType, child) {
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Radio<String>(
                        value: 'number',
                        groupValue: searchType,
                        activeColor: const Color(0xFF000080),
                        onChanged: (val) {
                          if (val != null) {
                            controller.searchTypeNotifier.value = val;
                            controller.mobileController.clear();
                            controller.customerSuggestionsNotifier.value = [];
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.searchTypeNotifier.value = 'number';
                          controller.mobileController.clear();
                          controller.customerSuggestionsNotifier.value = [];
                        },
                        child: Text(
                          context.tr('Owner Number'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                            color: searchType == 'number'
                                ? const Color(0xFF000080)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'vehicle',
                        groupValue: searchType,
                        activeColor: const Color(0xFF000080),
                        onChanged: (val) {
                          if (val != null) {
                            controller.searchTypeNotifier.value = val;
                            controller.mobileController.clear();
                            controller.customerSuggestionsNotifier.value = [];
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.searchTypeNotifier.value = 'vehicle';
                          controller.mobileController.clear();
                          controller.customerSuggestionsNotifier.value = [];
                        },
                        child: Text(
                          context.tr('Vehicle Number'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                            color: searchType == 'vehicle'
                                ? const Color(0xFF000080)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              // Live Search Input with Suggestions
              ValueListenableBuilder<String>(
                valueListenable: controller.searchTypeNotifier,
                builder: (context, searchType, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: searchType == 'vehicle'
                            ? TextField(
                                controller: controller.mobileController,
                                textCapitalization: TextCapitalization.characters,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: context.tr('Enter Vehicle Number'),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  prefixIcon: const Icon(
                                    Icons.directions_car,
                                    color: Color(0xFF000080),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF000080),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => controller.fetchSuggestions(token),
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                  controller.searchCustomer(
                                    token,
                                    onNotFound: (q) =>
                                        _showCustomerNotFoundDialog(context, q),
                                  );
                                },
                              )
                            : IntlPhoneField(
                                controller: controller.mobileController,
                                keyboardType: TextInputType.phone,
                                initialCountryCode: CountryConfig.phoneIsoCode,
                                dropdownTextStyle: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
                                disableLengthCheck: true,
                                onCountryChanged: (country) {
                                  controller.selectedCountryCodeNotifier.value =
                                      '+${country.dialCode}';
                                  controller.selectedCountryIsoNotifier.value =
                                      country.code;
                                },
                                decoration: InputDecoration(
                                  hintText: context.tr('Enter Mobile Number'),
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF000080),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => controller.fetchSuggestions(token),
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                  controller.searchCustomer(
                                    token,
                                    onNotFound: (q) =>
                                        _showCustomerNotFoundDialog(context, q),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: controller.isSearchingCustomer
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                controller.searchCustomer(
                                  token,
                                  onNotFound: (q) =>
                                      _showCustomerNotFoundDialog(context, q),
                                );
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: controller.isSearchingCustomer
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Live Suggestions Dropdown
              ValueListenableBuilder<List<dynamic>>(
                valueListenable: controller.customerSuggestionsNotifier,
                builder: (context, suggestions, child) {
                  if (suggestions.isEmpty) return const SizedBox.shrink();

                  final isVehicle = controller.searchTypeNotifier.value == 'vehicle';
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = suggestions[index] as Map<String, dynamic>;
                        if (isVehicle) {
                          final vNum = item['vehicle_number'] ?? '';
                          final vModel = item['vehicle_model'] ?? '';
                          final cName = item['customer_name'] ?? '';
                          final cPhone = item['customer_phone'] ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.directions_car,
                              color: Color(0xFF000080),
                            ),
                            title: Text(
                              vNum,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            subtitle: Text(
                              [
                                vModel,
                                cName,
                                cPhone,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () =>
                                controller.selectCustomerFromVehicleSuggestion(item, token),
                          );
                        } else {
                          final name = item['name'] ?? '';
                          final phone = item['phone'] ?? '';
                          final type = item['customer_type'] ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.person,
                              color: Color(0xFF000080),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            subtitle: Text(
                              '$phone ${type.isNotEmpty ? '• $type' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () =>
                                controller.selectCustomerFromSuggestion(item, token),
                          );
                        }
                      },
                    ),
                  );
                },
              ),

              // Selected Customer Details Box
              if (controller.selectedCustomer != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF000080),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  controller.selectedCustomer!['name'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    controller.selectedCustomer!['type'] ?? 'Individual',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${controller.selectedCustomer!['phone']} | WhatsApp: ${controller.selectedCustomer!['whatsapp'] ?? controller.selectedCustomer!['phone']}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if ((controller.selectedCustomer!['address'] ?? '').isNotEmpty)
                              Text(
                                controller.selectedCustomer!['address'],
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF000080),
                        ),
                        onPressed: () => _openAddCustomerModal(context),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
