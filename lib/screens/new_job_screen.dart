import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../config/country_config.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';
import 'add_customer_screen.dart';
import 'add_vehicle_screen.dart';
import 'invoice_create_screen.dart';
import 'vehicle_service_history_screen.dart';
import 'quotation_create_screen.dart';
import '../widgets/quick_sale_sheet.dart';

class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final ValueNotifier<String> _selectedCountryCodeNotifier = ValueNotifier(CountryConfig.phoneDialCode);
  final ValueNotifier<String> _selectedCountryIsoNotifier = ValueNotifier(CountryConfig.phoneIsoCode);
  final ValueNotifier<String> _searchTypeNotifier = ValueNotifier('number');
  final ValueNotifier<List<dynamic>> _customerSuggestionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingSuggestionsNotifier = ValueNotifier(false);

  final ValueNotifier<List<dynamic>> _branchesNotifier = ValueNotifier([]);
  final ValueNotifier<String?> _selectedBranchIdNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isLoadingBranchesNotifier = ValueNotifier(false);

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerProvider>().clearData();
      _loadBranches();
    });
  }

  @override
  void dispose() {
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    _debounce?.cancel();
    _selectedCountryCodeNotifier.dispose();
    _selectedCountryIsoNotifier.dispose();
    _searchTypeNotifier.dispose();
    _customerSuggestionsNotifier.dispose();
    _isSearchingSuggestionsNotifier.dispose();
    _branchesNotifier.dispose();
    _selectedBranchIdNotifier.dispose();
    _isLoadingBranchesNotifier.dispose();
    super.dispose();
  }

  void _onMobileChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final text = _mobileController.text.trim();
    if (text.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _fetchCustomerSuggestions(text);
      });
    } else {
      _customerSuggestionsNotifier.value = [];
      if (text.isEmpty && mounted) {
        context.read<CustomerProvider>().clearData();
      }
    }
  }

  Future<void> _loadBranches() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isCompanyAdmin) return;

    _isLoadingBranchesNotifier.value = true;

    try {
      final token = auth.token;
      if (token != null) {
        final res = await ApiService.getCompanyBranches(token);
        if (res['success'] == true) {
          final list = res['branches'] as List<dynamic>;
          _branchesNotifier.value = list;
          if (list.isNotEmpty) {
            _selectedBranchIdNotifier.value = list[0]['id']?.toString();
          }
        }
      }
    } catch (_) {} finally {
      if (mounted) {
        _isLoadingBranchesNotifier.value = false;
      }
    }
  }

  Future<void> _fetchCustomerSuggestions(String query) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _isSearchingSuggestionsNotifier.value = true;

    try {
      final res = _searchTypeNotifier.value == 'vehicle'
          ? await ApiService.searchVehicleList(query, token)
          : await ApiService.searchCustomerList(query, token, branchId: _selectedBranchIdNotifier.value);
      if (res['success'] == true) {
        _customerSuggestionsNotifier.value = (_searchTypeNotifier.value == 'vehicle' ? res['vehicles'] : res['customers']) as List<dynamic>;
      } else {
        _customerSuggestionsNotifier.value = [];
      }
    } catch (e) {
      _customerSuggestionsNotifier.value = [];
    } finally {
      _isSearchingSuggestionsNotifier.value = false;
    }
  }

  void _selectCustomerFromSuggestion(Map<String, dynamic> suggestion) {
    _customerSuggestionsNotifier.value = [];
    final rawPhone = suggestion['phone']?.toString() ?? '';
    if (rawPhone.isEmpty) return;

    // Try to match any known dial code from CountryConfig
    String strippedPhone = rawPhone;
    String phoneCode = _selectedCountryCodeNotifier.value; // keep current if no match
    String countryIso = _selectedCountryIsoNotifier.value;

    // Sort all country settings by dial-code length descending (match longest prefix first)
    final allCountries = CountryConfig.all
      ..sort((a, b) => b.phoneDialCode.length.compareTo(a.phoneDialCode.length));

    for (final country in allCountries) {
      final cleanCode = country.phoneDialCode.replaceAll('+', '');
      if (rawPhone.startsWith(cleanCode) && rawPhone.length > cleanCode.length) {
        phoneCode = country.phoneDialCode;
        countryIso = country.phoneIsoCode;
        strippedPhone = rawPhone.substring(cleanCode.length);
        break;
      }
    }

    _selectedCountryCodeNotifier.value = phoneCode;
    _selectedCountryIsoNotifier.value = countryIso;
    _mobileController.text = strippedPhone;

    _searchCustomer(unfocus: true);
  }

  void _selectCustomerFromVehicleSuggestion(Map<String, dynamic> suggestion) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _customerSuggestionsNotifier.value = [];
    final vNumber = (suggestion['vehicle_number'] ?? '').toString().trim();
    _mobileController.text = vNumber;
    _searchCustomer(unfocus: true, targetVehicleNumber: vNumber);
  }

  Future<void> _searchCustomer({bool unfocus = true, String? targetVehicleNumber}) async {
    if (unfocus) {
      FocusScope.of(context).unfocus();
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final token = context.read<AuthProvider>().token;
    if (token != null) {
      final queryText = (targetVehicleNumber ?? _mobileController.text).trim();
      if (queryText.isNotEmpty) {
        final customerProvider = context.read<CustomerProvider>();
        if (_searchTypeNotifier.value == 'vehicle') {
          await customerProvider.searchCustomer(
            queryText,
            token,
            branchId: _selectedBranchIdNotifier.value,
            isVehicle: true,
          );
          if (!mounted) return;
          if (customerProvider.customerData != null) {
            final data = customerProvider.customerData!;
            final vehicles = (data['vehicles'] as List<dynamic>? ?? []);
            final target = queryText.replaceAll(' ', '').replaceAll('-', '').toLowerCase();
            Map<String, dynamic>? matchedVehicle;
            for (final v in vehicles) {
              if (v is Map) {
                final vMap = Map<String, dynamic>.from(v);
                final no = (vMap['no'] ?? vMap['vehicle_number'] ?? '').toString().replaceAll(' ', '').replaceAll('-', '').toLowerCase();
                if (no == target) {
                  matchedVehicle = vMap;
                  break;
                }
              }
            }
            matchedVehicle ??= (vehicles.isNotEmpty && vehicles.first is Map) ? Map<String, dynamic>.from(vehicles.first as Map) : null;
            if (matchedVehicle != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceCreateScreen(
                    customer: data,
                    vehicle: matchedVehicle!,
                  ),
                ),
              );
            }
          }
        } else {
          final formattedMobile = CountryConfig.formatPhoneWithCountryCode(queryText, _selectedCountryCodeNotifier.value);
          await customerProvider.searchCustomer(
            formattedMobile,
            token,
            branchId: _selectedBranchIdNotifier.value,
            isVehicle: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('New Job'), style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => showQuickSaleSheet(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.flash_on, size: 16),
              label: Text(
                context.tr('Quick Sale'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isLoadingBranchesNotifier,
              builder: (context, isLoadingBranches, child) {
                if (isLoadingBranches) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _branchesNotifier,
                  builder: (context, branches, child) {
                    if (context.read<AuthProvider>().isCompanyAdmin && branches.isNotEmpty) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: _selectedBranchIdNotifier,
                        builder: (context, selectedBranchId, child) {
                          return DropdownButtonFormField<String>(
                            value: selectedBranchId,
                            decoration: InputDecoration(
                              labelText: context.tr('Select Branch'),
                              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Color(0xFF000080)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF000080)),
                              ),
                            ),
                            items: branches.map((b) {
                              return DropdownMenuItem<String>(
                                value: b['id']?.toString(),
                                child: Text(b['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              _selectedBranchIdNotifier.value = val;
                              _customerSuggestionsNotifier.value = [];
                              context.read<CustomerProvider>().clearData();
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Search Type Radios
            ValueListenableBuilder<String>(
              valueListenable: _searchTypeNotifier,
              builder: (context, searchType, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio<String>(
                      value: 'number',
                      groupValue: searchType,
                      activeColor: const Color(0xFF000080),
                      onChanged: (val) {
                        if (val != null) {
                          _searchTypeNotifier.value = val;
                          _mobileController.clear();
                          _customerSuggestionsNotifier.value = [];
                          context.read<CustomerProvider>().clearData();
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        _searchTypeNotifier.value = 'number';
                        _mobileController.clear();
                        _customerSuggestionsNotifier.value = [];
                        context.read<CustomerProvider>().clearData();
                      },
                      child: Text(
                        context.tr('Owner Number'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: searchType == 'number' ? Color(0xFF000080) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Radio<String>(
                      value: 'vehicle',
                      groupValue: searchType,
                      activeColor: const Color(0xFF000080),
                      onChanged: (val) {
                        if (val != null) {
                          _searchTypeNotifier.value = val;
                          _mobileController.clear();
                          _customerSuggestionsNotifier.value = [];
                          context.read<CustomerProvider>().clearData();
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        _searchTypeNotifier.value = 'vehicle';
                        _mobileController.clear();
                        _customerSuggestionsNotifier.value = [];
                        context.read<CustomerProvider>().clearData();
                      },
                      child: Text(
                        context.tr('Vehicle Number'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: searchType == 'vehicle' ? Color(0xFF000080) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Search Section
            ValueListenableBuilder<String>(
              valueListenable: _searchTypeNotifier,
              builder: (context, searchType, child) {
                return Row(
                  children: [
                    Expanded(
                      child: searchType == 'vehicle'
                          ? TextField(
                              controller: _mobileController,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              onSubmitted: (_) => _searchCustomer(unfocus: true),
                              decoration: InputDecoration(
                                hintText: context.tr('Enter Vehicle Number'),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.directions_car, color: Color(0xFF000080)),
                                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF000080)),
                                ),
                              ),
                            )
                          : IntlPhoneField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              initialCountryCode: CountryConfig.phoneIsoCode,
                              dropdownTextStyle: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14.sp),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                              disableLengthCheck: true,
                              onCountryChanged: (country) {
                                _selectedCountryCodeNotifier.value = '+' + country.dialCode;
                                _selectedCountryIsoNotifier.value = country.code;
                              },
                              decoration: InputDecoration(
                                hintText: context.tr('Enter Mobile Number'),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF000080)),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _searchCustomer(unfocus: true);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: Color(0xFF000080),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.search, color: Colors.white),
                      ),
                    )
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Consumer to watch Provider state
            Expanded(
              child: Consumer<CustomerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage.isNotEmpty) {
                    final isNotFound = provider.errorMessage.toLowerCase().contains('not found');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNotFound ? Icons.person_search : Icons.error_outline,
                            size: 72,
                            color: isNotFound ? Colors.orange.shade300 : Colors.red.shade300,
                          ),
                          SizedBox(height: 16),
                          Text(
                            provider.errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isNotFound ? Colors.orange.shade700 : Colors.red,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isNotFound) ...[
                            SizedBox(height: 24),
                            Text(
                              context.tr('No customer found with this number.'),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                 final rawMobile = _mobileController.text.trim();
                                 final formattedMobile = CountryConfig.formatPhoneWithCountryCode(rawMobile, _selectedCountryCodeNotifier.value);

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddCustomerScreen(
                                      phoneNumber: formattedMobile,
                                      initialCountryIso: _selectedCountryIsoNotifier.value,
                                      initialDialCode: _selectedCountryCodeNotifier.value,
                                      branchId: _selectedBranchIdNotifier.value,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  final token = context.read<AuthProvider>().token;
                                  if (token != null) {
                                    context.read<CustomerProvider>().searchCustomer(
                                      formattedMobile,
                                      token,
                                      branchId: _selectedBranchIdNotifier.value,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.person_add),
                              label: Text(context.tr('Add New Customer')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF000080),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  if (provider.customerData != null) {
                    final data = provider.customerData!;
                    final vehicles = data['vehicles'] as List<dynamic>;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Details Card
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFF000080).withValues(alpha: 0.1),
                                  child: Icon(Icons.person, color: Color(0xFF000080)),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'],
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.tr('Type: ${data['type']}  •  ${data['phone']}'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      if (data['branch'] != null && data['branch'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${context.tr("Branch")}: ${data['branch']}',
                                          style: TextStyle(
                                            color: Color(0xFF000080),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('Customer Vehicles'),
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddVehicleDialog(context, data),
                                icon: Icon(Icons.add_circle_outline, size: 16),
                                label: Text(
                                  context.tr('Add Vehicle'),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF000080).withValues(alpha: 0.08),
                                  foregroundColor: Color(0xFF000080),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFF000080), width: 1.2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Vehicle List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vehicles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final v = vehicles[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InvoiceCreateScreen(
                                        customer: data,
                                        vehicle: v,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Color(0xFF000080).withValues(alpha: 0.15),
                                      width: 1.7,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF000080).withValues(alpha: 0.04),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                v['no'],
                                                style: GoogleFonts.inter(
                                                  fontSize: 19.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF000080),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_circle_right, size: 18, color: Color(0xFF000080)),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF000080).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Color(0xFF000080).withValues(alpha: 0.15),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              (v['vehicle_type'] != null && v['vehicle_type'].toString().isNotEmpty)
                                                  ? "${v['vehicle_type']} - ${v['type']}"
                                                  : v['type'],
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF000080),
                                                fontSize: 11.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.0),
                                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey.shade600),
                                                const SizedBox(width: 6),
                                                Text(
                                                  context.tr('No. of visits: ${v['visits'] ?? 0}'),
                                                  style: GoogleFonts.inter(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () => _navigateToQuotationCreate(context, data, v),
                                                icon: const Icon(Icons.request_quote_outlined, size: 14),
                                                label: Text(
                                                  context.tr('Quotation'),
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF000080).withValues(alpha: 0.08),
                                                  foregroundColor: const Color(0xFF000080),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: const BorderSide(color: Color(0xFF000080), width: 1),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _navigateToVehicleHistory(context, v),
                                                icon: const Icon(Icons.history, size: 14),
                                                label: Text(
                                                  context.tr('History'),
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF000080).withValues(alpha: 0.08),
                                                  foregroundColor: const Color(0xFF000080),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: const BorderSide(color: Color(0xFF000080), width: 1),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.0),
                                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      ),
                                      Row(
                                        children: [
                                          _msgButton(
                                            context,
                                            label: context.tr('Welcome'),
                                            icon: Icons.chat_bubble_outline,
                                            color: Colors.blue.shade700,
                                            onPressed: () => _sendGenericMessage(
                                              context,
                                              type: 'welcome',
                                              customer: data,
                                              vehicle: v,
                                            ),
                                          ),
                                          _msgButton(
                                            context,
                                            label: context.tr('Ready Alert'),
                                            icon: Icons.notifications_none,
                                            color: Colors.orange.shade700,
                                            onPressed: () => _sendGenericMessage(
                                              context,
                                              type: 'ready',
                                              customer: data,
                                              vehicle: v,
                                            ),
                                          ),
                                          _msgButton(
                                            context,
                                            label: context.tr('Thank You'),
                                            icon: Icons.favorite_border,
                                            color: Colors.green.shade700,
                                            onPressed: () => _sendGenericMessage(
                                              context,
                                              type: 'thanks',
                                              customer: data,
                                              vehicle: v,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    );
                  }

                  return ValueListenableBuilder<List<dynamic>>(
                    valueListenable: _customerSuggestionsNotifier,
                    builder: (context, customerSuggestions, child) {
                      if (customerSuggestions.isNotEmpty) {
                        return _buildCustomerSuggestionsList(context, customerSuggestions);
                      }

                      return ValueListenableBuilder<bool>(
                        valueListenable: _isSearchingSuggestionsNotifier,
                        builder: (context, isSearchingSuggestions, child) {
                          if (isSearchingSuggestions) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('Search for a customer\nto start a new job'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSuggestionsList(BuildContext context, List<dynamic> customerSuggestions) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: customerSuggestions.length,
      itemBuilder: (context, index) {
        final c = customerSuggestions[index];
        final isVehicleSuggestion = _searchTypeNotifier.value == 'vehicle';
        
        final String name = isVehicleSuggestion 
            ? (c['customer_name'] ?? '') 
            : (c['name'] ?? '');
            
        final String subtitle = isVehicleSuggestion
            ? '${c['vehicle_number']} · ${c['vehicle_model']} · ${c['customer_phone']}'
            : '${c['phone']} · ${c['customer_type']}${(c['branch_name'] != null && c['branch_name'].toString().isNotEmpty) ? ' · ${c['branch_name']}' : ''}';

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () {
              if (isVehicleSuggestion) {
                _selectCustomerFromVehicleSuggestion(c);
              } else {
                _selectCustomerFromSuggestion(c);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF000080).withValues(alpha: 0.1),
                    child: Icon(
                      isVehicleSuggestion ? Icons.directions_car : Icons.person,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddVehicleDialog(BuildContext context, Map<String, dynamic> customerData) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(
          customerData: customerData,
          token: token,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Vehicle added successfully!')),
          backgroundColor: Colors.green,
        ),
      );
      context.read<CustomerProvider>().searchCustomer(
        customerData['phone'],
        token,
      );
    }
  }

  void _navigateToQuotationCreate(BuildContext context, Map<String, dynamic> customer, Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationCreateScreen(
          customer: customer,
          vehicle: vehicle,
        ),
      ),
    );
  }

  void _navigateToVehicleHistory(BuildContext context, Map<String, dynamic> vehicle) {
    final vehicleId = vehicle['id']?.toString() ?? '';
    final vehicleNo = vehicle['no']?.toString() ?? vehicle['number']?.toString() ?? '';

    if (vehicleId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleServiceHistoryScreen(
          vehicleId: vehicleId,
          vehicleNumber: vehicleNo,
        ),
      ),
    );
  }

  Widget _msgButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendGenericMessage(
    BuildContext context, {
    required String type,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> vehicle,
  }) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final phone = customer['phone']?.toString() ?? '';
    final customerName = customer['name']?.toString() ?? 'Customer';
    final vehicleNumber = vehicle['no']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      if (type == 'welcome') {
        res = await ApiService.sendVehicleWelcomeMessageGeneric(
          phone: phone,
          vehicleNumber: vehicleNumber,
          customerName: customerName,
          token: token,
        );
      } else if (type == 'ready') {
        res = await ApiService.sendVehicleReadyAlertGeneric(
          phone: phone,
          vehicleNumber: vehicleNumber,
          customerName: customerName,
          token: token,
        );
      } else {
        res = await ApiService.sendVehicleThanksMessageGeneric(
          phone: phone,
          vehicleNumber: vehicleNumber,
          customerName: customerName,
          token: token,
        );
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      final isAuto = res['action'] == 'auto';
      if (isAuto && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(res['message'] ?? 'Message sent successfully!')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final String branchName = context.read<AuthProvider>().branchName ?? '';
        final String effectiveBranch = (branchName.isNotEmpty && branchName != 'Our') ? branchName : 'our branch';

        String messageText = (res['message_text'] != null && res['message_text'].toString().isNotEmpty)
            ? res['message_text'].toString()
            : '';

        if (messageText.isEmpty) {
          if (type == 'welcome') {
            messageText = "Hi $customerName Welcome to Our $effectiveBranch.Your vehicle $vehicleNumber has arrived safely and is in expert hands.We will keep you posted!";
          } else if (type == 'ready') {
            messageText = "Hi $customerName Great news! Your vehicle $vehicleNumber is ready for pickup. Please collect at your earliest convenience.\n$effectiveBranch Support team.";
          } else {
            messageText = "Dear $customerName 🙏 Thank you for trusting us with your vehicle $vehicleNumber. We hope you had a great experience. Looking forward to seeing you again!\n$effectiveBranch support team.";
          }
        }

        final String cleanedPhone = CountryConfig.formatPhoneForWhatsapp(phone);

        final whatsappUrl = Uri.parse(
          "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(messageText)}"
        );

        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('Error sending message')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
