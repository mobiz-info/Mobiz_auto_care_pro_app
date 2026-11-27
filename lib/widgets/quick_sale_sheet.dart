import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(text: initialPhone);
  final trnCtrl = TextEditingController();
  bool isSearching = false;

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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Quick Sale'),
                            style: GoogleFonts.inter(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            context.tr(
                              'Bill services or products without vehicle',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.tr('Customer Name'),
                    hintText: context.tr('e.g. Walk-in Customer'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        '${context.tr('Phone Number')} (${context.tr('Optional')})',
                    hintText: context.tr('Enter mobile number'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trnCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText:
                        '${context.tr('TRN Number')} (${context.tr('Optional')})',
                    hintText: context.tr('e.g. 100234567800003'),
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                            final name = nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim()
                                : 'Walk-in Customer';
                            final rawPhone = phoneCtrl.text.trim();
                            final trn = trnCtrl.text.trim();

                            Map<String, dynamic> customerData = {
                              'id': null,
                              'name': name,
                              'phone': rawPhone,
                              'tax_number': trn,
                            };

                            if (rawPhone.isNotEmpty) {
                              setModalState(() => isSearching = true);
                              try {
                                final token =
                                    context.read<AuthProvider>().token;
                                if (token != null) {
                                  final formattedPhone =
                                      CountryConfig.formatPhoneWithCountryCode(
                                        rawPhone,
                                        CountryConfig.phoneDialCode,
                                      );
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
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
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
