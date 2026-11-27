import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../screens/invoice_create_screen.dart';

Future<void> showQuickSaleSheet(
  BuildContext context, {
  String initialPhone = '',
}) async {
  const navyBlue = Color(0xFF000080);
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: initialPhone);
  final trnCtrl = TextEditingController();
  String selectedDialCode = CountryConfig.phoneDialCode;
  bool isSearching = false;
  String? nameError;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: navyBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: navyBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Quick Sale'),
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: navyBlue,
                            ),
                          ),
                          Text(
                            context.tr(
                              'Bill services or products without vehicle',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  onChanged: (_) {
                    if (nameError != null) {
                      setModalState(() => nameError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '${context.tr('Customer Name')} *',
                    hintText: context.tr('Enter Customer Name'),
                    errorText: nameError,
                    prefixIcon: const Icon(Icons.person_outline, color: navyBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: navyBlue, width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                IntlPhoneField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  initialCountryCode: CountryConfig.phoneIsoCode,
                  dropdownTextStyle: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  disableLengthCheck: true,
                  onCountryChanged: (country) {
                    selectedDialCode = '+${country.dialCode}';
                  },
                  decoration: InputDecoration(
                    labelText:
                        '${context.tr('Phone Number')} (${context.tr('Optional')})',
                    hintText: context.tr('Enter Mobile Number'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: navyBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trnCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText:
                        '${context.tr('TRN Number')} (${context.tr('Optional')})',
                    hintText: context.tr('e.g. 100234567800003'),
                    prefixIcon:
                        const Icon(Icons.receipt_long_outlined, color: navyBlue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: navyBlue, width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isSearching
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              setModalState(() {
                                nameError = context.tr(
                                  'Customer name is required',
                                );
                              });
                              return;
                            }
                            final rawPhone = phoneCtrl.text.trim();
                            final trn = trnCtrl.text.trim();

                            String formattedPhone = '';
                            if (rawPhone.isNotEmpty) {
                              formattedPhone =
                                  CountryConfig.formatPhoneWithCountryCode(
                                    rawPhone,
                                    selectedDialCode,
                                  );
                            }

                            Map<String, dynamic> customerData = {
                              'id': null,
                              'name': name,
                              'phone': formattedPhone,
                              'tax_number': trn,
                            };

                            if (formattedPhone.isNotEmpty) {
                              setModalState(() => isSearching = true);
                              try {
                                final token =
                                    context.read<AuthProvider>().token;
                                if (token != null) {
                                  final res = await ApiService.searchCustomer(
                                    formattedPhone,
                                    token,
                                  );
                                  if (res['success'] == true &&
                                      res['customer'] != null) {
                                    customerData = Map<String, dynamic>.from(
                                      res['customer'],
                                    );
                                    if (nameCtrl.text.trim().isNotEmpty) {
                                      customerData['name'] =
                                          nameCtrl.text.trim();
                                    }
                                    if (trn.isNotEmpty) {
                                      customerData['tax_number'] = trn;
                                    }
                                  }
                                }
                              } catch (_) {}
                            }

                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceCreateScreen(
                                    customer: customerData,
                                    vehicle: null,
                                    isDirectSale: true,
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                      context.tr('Proceed to Invoice'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
