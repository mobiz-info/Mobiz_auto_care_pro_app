import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/country_config.dart';
import '../services/job_card_service.dart';

class JobCardCustomerController extends ChangeNotifier {
  final TextEditingController mobileController = TextEditingController();
  final ValueNotifier<String> selectedCountryCodeNotifier = ValueNotifier(
    CountryConfig.phoneDialCode,
  );
  final ValueNotifier<String> selectedCountryIsoNotifier = ValueNotifier(
    CountryConfig.phoneIsoCode,
  );
  final ValueNotifier<String> searchTypeNotifier = ValueNotifier('number');
  final ValueNotifier<List<dynamic>> customerSuggestionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isSearchingSuggestionsNotifier = ValueNotifier(false);
  Timer? _debounce;

  bool isSearchingCustomer = false;
  Map<String, dynamic>? selectedCustomer;
  List<dynamic> customerTypes = [];

  // Snapshot / manual profile fields
  final TextEditingController profileName = TextEditingController();
  final TextEditingController profilePhone = TextEditingController();
  final TextEditingController profileWhatsapp = TextEditingController();
  final TextEditingController profileEmail = TextEditingController();
  final TextEditingController profileState = TextEditingController();
  final TextEditingController profileCity = TextEditingController();
  final TextEditingController profileTax = TextEditingController();
  final TextEditingController profileTin = TextEditingController();
  final TextEditingController profilePan = TextEditingController();
  String customerTypeId = '';

  VoidCallback? onCustomerChanged;

  void init() {
    mobileController.addListener(_onSearchInputChanged);
  }

  void _onSearchInputChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final text = mobileController.text.trim();
    if (text.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        // Will be called with token via fetchSuggestions
        notifyListeners();
      });
    } else {
      customerSuggestionsNotifier.value = [];
    }
  }

  Future<void> fetchSuggestions(String token) async {
    final text = mobileController.text.trim();
    if (text.length < 2) {
      customerSuggestionsNotifier.value = [];
      return;
    }
    isSearchingSuggestionsNotifier.value = true;
    try {
      final isVeh = searchTypeNotifier.value == 'vehicle';
      final res = isVeh
          ? await JobCardService.searchVehicleList(text, token)
          : await JobCardService.searchCustomerList(text, token);
      if (res['success'] == true) {
        customerSuggestionsNotifier.value =
            (isVeh ? res['vehicles'] : res['customers']) as List<dynamic>;
      } else {
        customerSuggestionsNotifier.value = [];
      }
    } catch (_) {
      customerSuggestionsNotifier.value = [];
    } finally {
      isSearchingSuggestionsNotifier.value = false;
    }
  }

  void selectCustomerFromSuggestion(Map<String, dynamic> suggestion, String token) {
    customerSuggestionsNotifier.value = [];
    final rawPhone = suggestion['phone']?.toString() ?? '';
    if (rawPhone.isEmpty) return;

    String strippedPhone = rawPhone;
    String phoneCode = selectedCountryCodeNotifier.value;
    String countryIso = selectedCountryIsoNotifier.value;

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

    selectedCountryCodeNotifier.value = phoneCode;
    selectedCountryIsoNotifier.value = countryIso;
    mobileController.text = strippedPhone;

    searchCustomer(token);
  }

  void selectCustomerFromVehicleSuggestion(Map<String, dynamic> suggestion, String token) {
    customerSuggestionsNotifier.value = [];
    mobileController.text = suggestion['vehicle_number'] ?? '';
    searchCustomer(token);
  }

  Future<bool> searchCustomer(
    String token, {
    void Function(String searchedText)? onNotFound,
  }) async {
    final queryText = mobileController.text.trim();
    if (queryText.isEmpty) return false;

    isSearchingCustomer = true;
    selectedCustomer = null;
    customerSuggestionsNotifier.value = [];
    notifyListeners();

    final isVeh = searchTypeNotifier.value == 'vehicle';
    final queryToSearch = isVeh
        ? queryText
        : CountryConfig.formatPhoneWithCountryCode(
            queryText,
            selectedCountryCodeNotifier.value,
          );

    try {
      final res = await JobCardService.searchCustomer(
        queryToSearch,
        token,
        isVehicle: isVeh,
      );
      isSearchingCustomer = false;
      if (res['success'] == true && res['customer'] != null) {
        selectedCustomer = res['customer'] as Map<String, dynamic>;
        notifyListeners();
        onCustomerChanged?.call();
        return true;
      } else {
        notifyListeners();
        onNotFound?.call(queryText);
        return false;
      }
    } catch (_) {
      isSearchingCustomer = false;
      notifyListeners();
      onNotFound?.call(queryText);
      return false;
    }
  }

  void setSelectedCustomerDirectly(Map<String, dynamic>? customer) {
    selectedCustomer = customer;
    notifyListeners();
    onCustomerChanged?.call();
  }

  void applyLead(Map<String, dynamic> lead) {
    profileName.text = (lead['customer_name'] ?? '').toString();
    profilePhone.text = (lead['phone_number'] ?? '').toString();
    profileWhatsapp.text = (lead['whatsapp_number'] ?? '').toString();
    profileEmail.text = (lead['email'] ?? '').toString();
    profileState.text = (lead['state'] ?? '').toString();
    profileCity.text = (lead['city'] ?? '').toString();
    customerTypeId = (lead['customer_type_id'] ?? '').toString();
    selectedCustomer = {
      'id': lead['customer_id'] ?? '',
      'name': lead['customer_name'],
      'phone': lead['phone_number'],
    };
    notifyListeners();
  }

  void loadExistingJobCard(Map<String, dynamic> customer) {
    profileName.text = (customer['name'] ?? '').toString();
    profilePhone.text = (customer['phone'] ?? '').toString();
    profileWhatsapp.text = (customer['whatsapp'] ?? '').toString();
    profileEmail.text = (customer['email'] ?? '').toString();
    profileState.text = (customer['state'] ?? '').toString();
    profileCity.text = (customer['city'] ?? '').toString();
    profileTax.text = (customer['tax_number'] ?? '').toString();
    profileTin.text = (customer['tin_number'] ?? '').toString();
    profilePan.text = (customer['pan_number'] ?? '').toString();
    customerTypeId = (customer['customer_type_id'] ?? '').toString();
    selectedCustomer = customer;
    notifyListeners();
  }

  Map<String, dynamic> getCustomerProfilePayload() {
    return {
      'name': profileName.text.trim(),
      'phone': profilePhone.text.trim(),
      'whatsapp': profileWhatsapp.text.trim(),
      'email': profileEmail.text.trim(),
      'state': profileState.text.trim(),
      'city': profileCity.text.trim(),
      'customer_type_id': customerTypeId,
      'tax_number': profileTax.text.trim(),
      'tin_number': profileTin.text.trim(),
      'pan_number': profilePan.text.trim(),
    };
  }

  @override
  void dispose() {
    mobileController.removeListener(_onSearchInputChanged);
    mobileController.dispose();
    _debounce?.cancel();
    selectedCountryCodeNotifier.dispose();
    selectedCountryIsoNotifier.dispose();
    searchTypeNotifier.dispose();
    customerSuggestionsNotifier.dispose();
    isSearchingSuggestionsNotifier.dispose();

    profileName.dispose();
    profilePhone.dispose();
    profileWhatsapp.dispose();
    profileEmail.dispose();
    profileState.dispose();
    profileCity.dispose();
    profileTax.dispose();
    profileTin.dispose();
    profilePan.dispose();

    super.dispose();
  }

  void notify() => notifyListeners();
}
