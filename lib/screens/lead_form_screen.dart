import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/job_card_responsive.dart';
import 'add_customer_screen.dart';
import 'add_vehicle_screen.dart';

/// Full-screen create / edit form for a Lead.
/// Returns `true` to the caller when saved successfully.
class LeadFormScreen extends StatefulWidget {
  /// Pass an existing lead map to edit; null = create mode.
  final Map<String, dynamic>? lead;
  final bool jobWorkflow;

  const LeadFormScreen({super.key, this.lead, this.jobWorkflow = false});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  // ── Loading state ──────────────────────────────────────────────────────────
  bool _isLoadingForm = true;
  bool _isSaving = false;
  String _errorMessage = '';

  // ── Vehicle master data ────────────────────────────────────────────────────
  List<dynamic> _vehicleTypes = [];
  List<dynamic> _vehicleTypeModels = [];
  List<dynamic> _makes = [];
  List<dynamic> _brandModels = [];
  List<dynamic> _colors = [];
  List<dynamic> _staffOptions = [];
  List<dynamic> _customerTypes = [];
  List<dynamic> _states = [];
  List<dynamic> _leadModes = [];
  List<dynamic> _serviceCategories = [];
  List<dynamic> _services = [];
  List<dynamic> _emissions = [];
  List<dynamic> _fuelTypes = [];
  List<dynamic> _wheelTypes = [];
  Map<String, dynamic>? _selectedStaff,
      _selectedCustomerType,
      _selectedEmission,
      _selectedFuel;
  Map<String, dynamic>? _selectedState;
  DateTime? _leadDate, _nextFollowUpDate;
  final List<Map<String, dynamic>> _serviceRows = [];
  final _cityCtrl = TextEditingController(),
      _emailCtrl = TextEditingController();
  final _customerSearchCtrl = TextEditingController();
  Timer? _customerSearchTimer;
  List<Map<String, dynamic>> _customerMatches = [];
  List<Map<String, dynamic>> _existingVehicles = [];
  String? _linkedCustomerId, _linkedVehicleId;
  bool _searchingCustomers = false;
  bool _customerSearchCompleted = false;
  bool _applyingCustomer = false;

  // ── Selected vehicle values ────────────────────────────────────────────────
  Map<String, dynamic>? _selectedVehicleType;
  Map<String, dynamic>? _selectedVehicleTypeModel;
  Map<String, dynamic>? _selectedMake;
  Map<String, dynamic>? _selectedBrandModel;
  Map<String, dynamic>? _selectedColor;
  String _wheelType = 'normal_wheel';

  // ── Text controllers ───────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();
  final _leadModeCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _serviceNameCtrl = TextEditingController();
  final _staffNameCtrl = TextEditingController();
  final _expectedValueCtrl = TextEditingController(text: '0');

  // ── Focus nodes ────────────────────────────────────────────────────────────
  final _phoneFocusNode = FocusNode();
  final _waFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _vehicleNumberFocusNode = FocusNode();
  final _referenceFocusNode = FocusNode();

  final ValueNotifier<double> _totalExpectedNotifier = ValueNotifier<double>(0.0);

  // ── Phone ──────────────────────────────────────────────────────────────────
  late String _phoneCode;
  late String _phoneIso;
  late String _waCode;
  late String _waIso;
  final _phoneCtrl = TextEditingController();
  final _waCtrl = TextEditingController();

  // ── Date ───────────────────────────────────────────────────────────────────
  DateTime? _renewalDate;

  bool get _isEditing => widget.lead != null;

  @override
  void initState() {
    super.initState();
    _phoneCode = CountryConfig.phoneDialCode;
    _phoneIso = CountryConfig.phoneIsoCode;
    _waCode = CountryConfig.phoneDialCode;
    _waIso = CountryConfig.phoneIsoCode;

    _fetchFormData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _waCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _leadModeCtrl.dispose();
    _referenceCtrl.dispose();
    _serviceNameCtrl.dispose();
    _staffNameCtrl.dispose();
    _expectedValueCtrl.dispose();
    _cityCtrl.dispose();
    _emailCtrl.dispose();
    _customerSearchCtrl.dispose();
    _customerSearchTimer?.cancel();
    _phoneFocusNode.dispose();
    _waFocusNode.dispose();
    _nameFocusNode.dispose();
    _cityFocusNode.dispose();
    _emailFocusNode.dispose();
    _vehicleNumberFocusNode.dispose();
    _referenceFocusNode.dispose();
    _totalExpectedNotifier.dispose();
    for (final row in _serviceRows) {
      (row['value_controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _fetchFormData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = widget.jobWorkflow
          ? await ApiService.getJobLeadFormData(token)
          : await ApiService.getFormData(token);
      if (res['success'] == true) {
        if (widget.jobWorkflow) {
          setState(() {
            _vehicleTypes = List<dynamic>.from(res['vehicle_types'] ?? []);
            _vehicleTypeModels = List<dynamic>.from(
              res['vehicle_segments'] ?? [],
            );
            _makes = List<dynamic>.from(res['makes'] ?? []);
            _brandModels = List<dynamic>.from(res['vehicle_models'] ?? []);
            _colors = List<dynamic>.from(res['colors'] ?? []);
            _staffOptions = List<dynamic>.from(res['staff'] ?? []);
            _customerTypes = List<dynamic>.from(res['customer_types'] ?? []);
            _states = List<dynamic>.from(res['states'] ?? []);
            _leadModes = List<dynamic>.from(res['lead_modes'] ?? []);
            _serviceCategories = List<dynamic>.from(
              res['service_categories'] ?? [],
            );
            _services = List<dynamic>.from(res['services'] ?? []);
            _emissions = List<dynamic>.from(res['emission_standards'] ?? []);
            _fuelTypes = List<dynamic>.from(res['fuel_types'] ?? []);
            _wheelTypes = List<dynamic>.from(res['wheel_types'] ?? []);
            _isLoadingForm = false;
            _selectedVehicleType = _vehicleTypes.isNotEmpty
                ? _vehicleTypes.first
                : null;
            final leadState = (widget.lead?['state'] ?? '')
                .toString()
                .toLowerCase();
            _selectedState = _states.cast<Map<String, dynamic>?>().firstWhere(
              (state) => state?['name']?.toString().toLowerCase() == leadState,
              orElse: () => null,
            );
            _leadDate = DateTime.now();
            _nextFollowUpDate = DateTime.now();
          });
          if (_isEditing) {
            _populateFromLead(widget.lead!);
          } else {
            setState(_addServiceRow);
          }
          return;
        }
        final vTypes = List<dynamic>.from(res['vehicle_types'] ?? []);
        final vTypeModels = List<dynamic>.from(
          res['vehicle_type_models'] ?? res['vehicle_models'] ?? [],
        );
        final makes = List<dynamic>.from(res['makes'] ?? []);
        final brandModels = List<dynamic>.from(res['brand_models'] ?? []);
        final colors = List<dynamic>.from(res['colors'] ?? []);

        final validVtIds = vTypeModels
            .map((m) => m['vehicle_type_id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .toSet();
        final filteredTypes = vTypes
            .where((vt) => validVtIds.contains(vt['id']?.toString()))
            .toList();

        setState(() {
          _vehicleTypes = filteredTypes.isNotEmpty ? filteredTypes : vTypes;
          _vehicleTypeModels = vTypeModels;
          _makes = makes;
          _brandModels = brandModels;
          _colors = colors;
          _isLoadingForm = false;
        });

        // Populate existing values when editing
        if (_isEditing) {
          _populateFromLead(widget.lead!);
        } else if (_vehicleTypes.isNotEmpty) {
          setState(
            () => _selectedVehicleType =
                _vehicleTypes.first as Map<String, dynamic>,
          );
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load form data';
          _isLoadingForm = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingForm = false;
      });
    }
  }

  void _populateFromLead(Map<String, dynamic> lead) {
    _nameCtrl.text = lead['customer_name'] ?? '';
    _phoneCtrl.text = lead['phone_number'] ?? '';
    _waCtrl.text = lead['whatsapp_number'] ?? '';
    _vehicleNumberCtrl.text = lead['vehicle_number'] ?? '';
    _leadModeCtrl.text = lead['lead_generation_mode'] ?? '';
    _referenceCtrl.text = lead['reference'] ?? '';
    _serviceNameCtrl.text = lead['service_name'] ?? '';
    _staffNameCtrl.text = lead['staff_name'] ?? '';
    _expectedValueCtrl.text = (lead['expected_value'] ?? 0).toString();
    _cityCtrl.text = lead['city'] ?? '';
    _emailCtrl.text = lead['email'] ?? '';
    _wheelType =
        (lead['vehicle_wheel_type'] ?? lead['wheel_type'] ?? 'normal_wheel')
            .toString();
    _selectedWheelId = _wheelType;
    _selectedFuel = _fuelTypes.cast<Map<String, dynamic>?>().firstWhere(
      (item) =>
          item?['id']?.toString() == lead['vehicle_fuel_type']?.toString(),
      orElse: () => null,
    );
    _selectedEmission = _emissions.cast<Map<String, dynamic>?>().firstWhere(
      (item) =>
          item?['id']?.toString() ==
          lead['vehicle_emission_standard_id']?.toString(),
      orElse: () => null,
    );

    final rd = lead['renewal_date'];
    if (rd != null && rd.toString().isNotEmpty) {
      try {
        _renewalDate = DateTime.parse(rd.toString());
      } catch (_) {}
    }

    // Match FKs against loaded master data
    final vtId = lead['vehicle_type_id']?.toString() ?? '';
    final vtmId =
        (lead['vehicle_segment_id'] ?? lead['vehicle_type_model_id'])
            ?.toString() ??
        '';
    final makeId = lead['vehicle_make_id']?.toString() ?? '';
    final bmId =
        (lead['vehicle_model_id'] ?? lead['vehicle_brand_model_id'])
            ?.toString() ??
        '';
    final colorId = lead['vehicle_color_id']?.toString() ?? '';

    _selectedVehicleType = _vehicleTypes
        .cast<Map<String, dynamic>>()
        .where((t) => t['id']?.toString() == vtId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;
    _selectedVehicleTypeModel = _vehicleTypeModels
        .cast<Map<String, dynamic>>()
        .where((t) => t['id']?.toString() == vtmId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;
    _selectedMake = _makes
        .cast<Map<String, dynamic>>()
        .where((t) => t['id']?.toString() == makeId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;
    _selectedBrandModel = _brandModels
        .cast<Map<String, dynamic>>()
        .where((t) => t['id']?.toString() == bmId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;
    _selectedColor = _colors
        .cast<Map<String, dynamic>>()
        .where((t) => t['id']?.toString() == colorId)
        .cast<Map<String, dynamic>?>()
        .firstOrNull;

    if (widget.jobWorkflow) {
      _selectedMake =
          _makes
              .cast<Map<String, dynamic>>()
              .where(
                (item) =>
                    item['name']?.toString() ==
                    lead['vehicle_make']?.toString(),
              )
              .cast<Map<String, dynamic>?>()
              .firstOrNull ??
          _selectedMake;
      _selectedBrandModel =
          _brandModels
              .cast<Map<String, dynamic>>()
              .where(
                (item) =>
                    item['name']?.toString() ==
                    lead['vehicle_model']?.toString(),
              )
              .cast<Map<String, dynamic>?>()
              .firstOrNull ??
          _selectedBrandModel;
    }

    if (_selectedVehicleType == null && _vehicleTypes.isNotEmpty) {
      _selectedVehicleType = _vehicleTypes.first as Map<String, dynamic>;
    }

    _linkedCustomerId = lead['customer_id']?.toString().isNotEmpty == true
        ? lead['customer_id'].toString()
        : null;
    _linkedVehicleId = lead['vehicle_id']?.toString().isNotEmpty == true
        ? lead['vehicle_id'].toString()
        : null;
    final leadDate = lead['lead_date']?.toString() ?? '';
    final followUpDate = lead['next_follow_up_date']?.toString() ?? '';
    if (leadDate.isNotEmpty) {
      _leadDate = DateTime.tryParse(leadDate);
    }
    if (followUpDate.isNotEmpty) {
      _nextFollowUpDate = DateTime.tryParse(followUpDate);
    }
    _selectedStaff = _staffOptions.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id']?.toString() == lead['staff_id']?.toString(),
      orElse: () => null,
    );
    _selectedCustomerType = _customerTypes
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) =>
              item?['id']?.toString() == lead['customer_type_id']?.toString(),
          orElse: () => null,
        );
    _selectedState = _states.cast<Map<String, dynamic>?>().firstWhere(
      (item) =>
          item?['name']?.toString().toLowerCase() ==
          (lead['state'] ?? '').toString().toLowerCase(),
      orElse: () => null,
    );
    for (final row in _serviceRows) {
      (row['value_controller'] as TextEditingController).dispose();
    }
    _serviceRows.clear();
    for (final raw in (lead['service_interests'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final service = _services.cast<Map<String, dynamic>?>().firstWhere(
        (s) => s?['id']?.toString() == item['service_id']?.toString(),
        orElse: () => null,
      );
      final category = _serviceCategories
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (c) => c?['id']?.toString() == service?['category_id']?.toString(),
            orElse: () => null,
          );
      final controller = TextEditingController(
        text: (item['expected_value'] ?? 0).toString(),
      );
      controller.addListener(_updateTotalExpected);
      _serviceRows.add({
        'category': category,
        'service': service,
        'value_controller': controller,
      });
    }
    if (_serviceRows.isEmpty) _addServiceRow();
    _updateTotalExpected();
  }

  void _updateTotalExpected() {
    double total = 0;
    for (final row in _serviceRows) {
      final ctrl = row['value_controller'] as TextEditingController?;
      if (ctrl != null) {
        total += double.tryParse(ctrl.text) ?? 0;
      }
    }
    _totalExpectedNotifier.value = total;
  }

  void _searchCustomers(String value) {
    _customerSearchTimer?.cancel();
    if (value.trim().length < 2) {
      if (_customerMatches.isNotEmpty ||
          _searchingCustomers ||
          _customerSearchCompleted) {
        setState(() {
          _customerSearchCompleted = false;
          _customerMatches = [];
          _searchingCustomers = false;
          _linkedCustomerId = null;
          _linkedVehicleId = null;
          _existingVehicles = [];
        });
      }
      return;
    }
    _customerSearchTimer = Timer(const Duration(milliseconds: 400), () async {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      if (mounted) setState(() => _searchingCustomers = true);
      try {
        final result = await ApiService.searchCustomerList(value.trim(), token);
        if (!mounted) return;
        setState(() {
          _customerMatches = result['success'] == true
              ? List<Map<String, dynamic>>.from(
                  (result['customers'] ?? []).map(
                    (e) => Map<String, dynamic>.from(e),
                  ),
                )
              : [];
          _searchingCustomers = false;
          _customerSearchCompleted = true;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _customerMatches = [];
            _searchingCustomers = false;
            _customerSearchCompleted = true;
          });
        }
      }
    });
  }

  Future<void> _selectExistingCustomer(Map<String, dynamic> suggestion) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final result = await ApiService.searchCustomer(
      (suggestion['phone'] ?? '').toString(),
      token,
    );
    if (!mounted || result['success'] != true || result['customer'] is! Map) {
      return;
    }
    final customer = Map<String, dynamic>.from(result['customer']);
    _applySelectedCustomer(customer);
  }

  void _applySelectedCustomer(
    Map<String, dynamic> customer, {
    String? preferredVehicleId,
  }) {
    final phoneInfo = _phoneParts(customer['phone']?.toString() ?? '');
    final waInfo = _phoneParts(
      customer['whatsapp']?.toString() ??
          customer['whatsapp_number']?.toString() ??
          '',
      fallbackCode: _waCode,
      fallbackIso: _waIso,
    );
    final vehicles = List<Map<String, dynamic>>.from(
      (customer['vehicles'] ?? []).whereType<Map>().map(
        (v) => Map<String, dynamic>.from(v),
      ),
    );
    final selectedVehicle =
        vehicles.cast<Map<String, dynamic>?>().firstWhere(
          (v) => v?['id']?.toString() == preferredVehicleId,
          orElse: () => null,
        ) ??
        (vehicles.isNotEmpty ? vehicles.first : null);
    setState(() {
      _linkedCustomerId = customer['id']?.toString();
      _applyingCustomer = true;
      _customerSearchCtrl.text =
          '${customer['name'] ?? ''} · ${customer['phone'] ?? ''}';
      _customerMatches = [];
      _customerSearchCompleted = false;
      _nameCtrl.text = customer['name']?.toString() ?? '';
      _phoneCode = phoneInfo.$1;
      _phoneIso = phoneInfo.$2;
      _phoneCtrl.text = phoneInfo.$3;
      _waCode = waInfo.$1;
      _waIso = waInfo.$2;
      _waCtrl.text = waInfo.$3;
      _emailCtrl.text = customer['email']?.toString() ?? '';
      _cityCtrl.text = customer['city']?.toString() ?? '';
      _selectedState = _states.cast<Map<String, dynamic>?>().firstWhere(
        (s) =>
            s?['name']?.toString().toLowerCase() ==
            customer['state']?.toString().toLowerCase(),
        orElse: () => null,
      );
      _selectedCustomerType = _customerTypes
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (t) =>
                t?['name']?.toString().toLowerCase() ==
                customer['type']?.toString().toLowerCase(),
            orElse: () => null,
          );
      _existingVehicles = List<Map<String, dynamic>>.from(vehicles);
      _linkedVehicleId = selectedVehicle?['id']?.toString();
      if (selectedVehicle != null) _applyExistingVehicle(selectedVehicle);
      _applyingCustomer = false;
    });
  }

  (String, String, String) _phoneParts(
    String value, {
    String? fallbackCode,
    String? fallbackIso,
  }) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final countries = CountryConfig.all
      ..sort(
        (a, b) => b.phoneDialCode.length.compareTo(a.phoneDialCode.length),
      );
    for (final country in countries) {
      final code = country.phoneDialCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith(code) && digits.length > code.length) {
        return (
          country.phoneDialCode,
          country.phoneIsoCode,
          digits.substring(code.length),
        );
      }
    }
    return (fallbackCode ?? _phoneCode, fallbackIso ?? _phoneIso, digits);
  }

  Future<void> _createCustomerFromLead() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          phoneNumber: CountryConfig.formatPhoneWithCountryCode(
            _phoneCtrl.text.trim(),
            _phoneCode,
          ),
          initialCountryIso: _phoneIso,
          initialDialCode: _phoneCode,
        ),
      ),
    );
    if (!mounted || result == null || result == false) return;
    Map<String, dynamic>? customer;
    if (result is Map) customer = Map<String, dynamic>.from(result);
    final customerId = customer?['id']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final full = await ApiService.getCustomer(customerId, token);
      if (!mounted) return;
      if (full['success'] == true && full['customer'] is Map) {
        customer = Map<String, dynamic>.from(full['customer']);
      }
    }
    if (customer == null || customer['id'] == null) {
      final phone = CountryConfig.formatPhoneWithCountryCode(
        _phoneCtrl.text.trim(),
        _phoneCode,
      );
      final found = await ApiService.searchCustomer(phone, token);
      if (!mounted || found['success'] != true || found['customer'] is! Map) {
        _showSnack(
          'Customer was saved, but could not be loaded. Search again.',
        );
        return;
      }
      customer = Map<String, dynamic>.from(found['customer']);
    }
    _applySelectedCustomer(customer);
  }

  Future<void> _addVehicleToSelectedCustomer() async {
    final token = context.read<AuthProvider>().token;
    final customerId = _linkedCustomerId;
    if (token == null || customerId == null) return;
    final current = await ApiService.getCustomer(customerId, token);
    if (!mounted || current['success'] != true || current['customer'] is! Map) {
      _showSnack('Could not load customer details. Please try again.');
      return;
    }
    final customer = Map<String, dynamic>.from(current['customer']);
    final previousIds = _existingVehicles
        .map((v) => v['id']?.toString())
        .toSet();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(customerData: customer, token: token),
      ),
    );
    if (!mounted || added != true) return;
    final refreshed = await ApiService.getCustomer(customerId, token);
    if (!mounted ||
        refreshed['success'] != true ||
        refreshed['customer'] is! Map) {
      _showSnack('Vehicle added, but the vehicle list could not be refreshed.');
      return;
    }
    final updated = Map<String, dynamic>.from(refreshed['customer']);
    final vehicles = List<Map<String, dynamic>>.from(
      (updated['vehicles'] ?? []).whereType<Map>().map(
        (v) => Map<String, dynamic>.from(v),
      ),
    );
    final newVehicle = vehicles.cast<Map<String, dynamic>?>().firstWhere(
      (v) => !previousIds.contains(v?['id']?.toString()),
      orElse: () => null,
    );
    _applySelectedCustomer(
      updated,
      preferredVehicleId: newVehicle?['id']?.toString(),
    );
  }

  void _applyExistingVehicle(Map<String, dynamic> v) {
    _linkedVehicleId = v['id']?.toString();
    _vehicleNumberCtrl.text = v['no']?.toString() ?? '';
    _selectedVehicleType =
        _vehicleTypes.cast<Map<String, dynamic>?>().firstWhere(
          (x) => x?['id']?.toString() == v['vehicle_type_id']?.toString(),
          orElse: () => null,
        ) ??
        _selectedVehicleType;
    _selectedVehicleTypeModel = _vehicleTypeModels
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (x) => x?['id']?.toString() == v['vehicle_type_model_id']?.toString(),
          orElse: () => null,
        );
    _selectedMake = _makes.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['id']?.toString() == v['make_id']?.toString(),
      orElse: () => null,
    );
    _selectedBrandModel = _brandModels.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['id']?.toString() == v['brand_model_id']?.toString(),
      orElse: () => null,
    );
    _selectedColor = _colors.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['id']?.toString() == v['color_id']?.toString(),
      orElse: () => null,
    );
    _selectedEmission = _emissions.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['id']?.toString() == v['emission_standard_id']?.toString(),
      orElse: () => null,
    );
    _selectedFuel = _fuelTypes.cast<Map<String, dynamic>?>().firstWhere(
      (x) => x?['id']?.toString() == v['fuel_type']?.toString(),
      orElse: () => null,
    );
    _selectedWheelId = v['wheel_type']?.toString() ?? _selectedWheelId;
  }

  // ── Vehicle filter helpers ─────────────────────────────────────────────────

  List<Map<String, dynamic>> _segmentsForType(String? vtId) {
    if (vtId == null || vtId.isEmpty) return _vehicleTypeModels.cast();
    return _vehicleTypeModels
        .where((m) => m['vehicle_type_id']?.toString() == vtId)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> _makesFor(String? vtId, String? segId) {
    Iterable<dynamic> list = _brandModels;
    if (segId != null && segId.isNotEmpty) {
      list = list.where((b) => b['vehicle_type_model_id']?.toString() == segId);
    } else if (vtId != null && vtId.isNotEmpty) {
      final segIds = _vehicleTypeModels
          .where((s) => s['vehicle_type_id']?.toString() == vtId)
          .map((s) => s['id']?.toString())
          .toSet();
      list = list.where(
        (b) => segIds.contains(b['vehicle_type_model_id']?.toString()),
      );
    } else {
      return _makes.cast();
    }
    final makeIds = list
        .map((b) => b['make_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();
    return _makes
        .where((m) => makeIds.contains(m['id']?.toString()))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> _brandModelsFor(String? segId, String? makeId) {
    Iterable<dynamic> list = _brandModels;
    if (segId != null && segId.isNotEmpty) {
      list = list.where((b) => b['vehicle_type_model_id']?.toString() == segId);
    }
    if (makeId != null && makeId.isNotEmpty) {
      list = list.where((b) => b['make_id']?.toString() == makeId);
    }
    return list.cast<Map<String, dynamic>>().toList();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final localPhone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter customer name.');
      return;
    }
    if (localPhone.isEmpty) {
      _showSnack('Please enter phone number.');
      return;
    }
    if (widget.jobWorkflow) {
      if (_leadDate == null ||
          _selectedStaff == null ||
          _leadModeCtrl.text.trim().isEmpty ||
          _selectedCustomerType == null ||
          _nextFollowUpDate == null) {
        _showSnack(
          'Complete lead date, staff, mode, customer type and next follow-up date.',
        );
        return;
      }
      if (_serviceRows.isEmpty ||
          _serviceRows.any(
            (r) =>
                r['service'] == null ||
                (double.tryParse(
                          (r['value_controller'] as TextEditingController).text
                              .trim(),
                        ) ??
                        -1) <
                    0,
          )) {
        _showSnack(
          'Select a service and enter a non-negative expected value for every row.',
        );
        return;
      }
    }

    final phone = CountryConfig.formatPhoneWithCountryCode(
      localPhone,
      _phoneCode,
    );
    final localWa = _waCtrl.text.trim();
    final wa = localWa.isNotEmpty
        ? CountryConfig.formatPhoneWithCountryCode(localWa, _waCode)
        : '';

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final data = <String, dynamic>{
        'customer_name': name,
        'phone_number': phone,
        'whatsapp_number': wa,
        'lead_generation_mode': _leadModeCtrl.text.trim(),
        'reference': _referenceCtrl.text.trim(),
        'service_name': _serviceNameCtrl.text.trim(),
        'staff_name': _staffNameCtrl.text.trim(),
        'expected_value': double.tryParse(_expectedValueCtrl.text.trim()) ?? 0,
        'vehicle_number': _vehicleNumberCtrl.text.trim(),
        if (widget.jobWorkflow) ...{
          'customer_id': _linkedCustomerId ?? '',
          'vehicle_id': _linkedVehicleId ?? '',
          'vehicle_make': _selectedMake?['name']?.toString() ?? '',
          'vehicle_model':
              _selectedBrandModel?['name']?.toString() ??
              _selectedVehicleTypeModel?['name']?.toString() ??
              '',
        },
        'vehicle_type_id': _selectedVehicleType?['id']?.toString() ?? '',
        'vehicle_type_model_id':
            _selectedVehicleTypeModel?['id']?.toString() ?? '',
        'vehicle_make_id': _selectedMake?['id']?.toString() ?? '',
        'vehicle_brand_model_id': _selectedBrandModel?['id']?.toString() ?? '',
        'vehicle_color_id': _selectedColor?['id']?.toString() ?? '',
        'wheel_type': _wheelType,
        'renewal_date': _renewalDate != null
            ? _renewalDate!.toIso8601String().split('T')[0]
            : '',
      };
      if (widget.jobWorkflow) {
        data.addAll({
          'lead_date': _dateValue(_leadDate),
          'next_follow_up_date': _dateValue(_nextFollowUpDate),
          'staff_id': _selectedStaff?['id'],
          'customer_type_id': _selectedCustomerType?['id'],
          'state': _selectedState?['name']?.toString() ?? '',
          'city': _cityCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'vehicle_type_id': _selectedVehicleType?['id'] ?? '',
          'vehicle_segment_id': _selectedVehicleTypeModel?['id'] ?? '',
          'vehicle_make_id': _selectedMake?['id'] ?? '',
          'vehicle_model_id': _selectedBrandModel?['id'] ?? '',
          'vehicle_color_id': _selectedColor?['id'] ?? '',
          'vehicle_emission_standard_id': _selectedEmission?['id'] ?? '',
          'vehicle_fuel_type': _selectedFuel?['id'] ?? '',
          'vehicle_wheel_type': _selectedWheelId,
          'service_interests': _serviceRows
              .map(
                (row) => {
                  'service_id': row['service']['id'],
                  'expected_value': double.parse(
                    (row['value_controller'] as TextEditingController).text
                        .trim(),
                  ),
                },
              )
              .toList(),
        });
      }

      Map<String, dynamic> res;
      if (_isEditing) {
        res = widget.jobWorkflow
            ? await ApiService.updateJobLead(
                token,
                widget.lead!['id'].toString(),
                data,
              )
            : await ApiService.editLead(
                token,
                widget.lead!['id'].toString(),
                data,
              );
      } else {
        res = widget.jobWorkflow
            ? await ApiService.createJobLead(token, data)
            : await ApiService.createLead(token, data);
      }

      if (!mounted) return;
      if (res['status'] == 'success') {
        Navigator.pop(context, true);
      } else {
        _showSnack(res['message'] ?? 'Failed to save lead.');
        setState(() => _isSaving = false);
      }
    } catch (e) {
      _showSnack('Error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _selectedWheelId = 'normal_wheel';
  bool _showMoreVehicle = false;
  String _dateValue(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _dateDisplay(DateTime? d) => d == null
      ? 'Select date'
      : '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().padLeft(4, '0')}';
  void _addServiceRow() {
    final controller = TextEditingController(text: '0');
    controller.addListener(_updateTotalExpected);
    _serviceRows.add({
      'category': null,
      'service': null,
      'value_controller': controller,
    });
    _updateTotalExpected();
  }

  Future<void> _chooseDate(bool followUp) async {
    final value = followUp ? _nextFollowUpDate : _leadDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (followUp) {
          _nextFollowUpDate = picked;
        } else {
          _leadDate = picked;
        }
      });
    }
  }

  Widget _selectMaster(
    String label,
    List<dynamic> items,
    Map<String, dynamic>? value,
    ValueChanged<Map<String, dynamic>?> onChanged,
  ) => _searchableField<Map<String, dynamic>>(
    label: label,
    title: label,
    value: value,
    items: items.cast<Map<String, dynamic>>(),
    labelOf: (item) => item['name']?.toString() ?? '',
    hint: 'Select $label',
    onChanged: onChanged,
  );

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey.shade700,
          ),
        ),
        subtitle: Text(
          _dateDisplay(date),
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
        ),
        trailing: const Icon(Icons.calendar_month),
        onTap: onTap,
      );

  void _showSnack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF000080)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _renewalDate = picked);
  }

  // ── Searchable modal ───────────────────────────────────────────────────────

  void _showSearchModal<T>(
    String title,
    List<T> items,
    String Function(T) labelOf,
    void Function(T?) onSelected,
  ) {
    final searchNotifier = ValueNotifier<String>('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select $title',
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000080),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search $title...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) => searchNotifier.value = v.toLowerCase().trim(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: searchNotifier,
                  builder: (_, query, __) {
                    final filtered = items
                        .where(
                          (item) => labelOf(item).toLowerCase().contains(query),
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No results found',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        return ListTile(
                          title: Text(
                            labelOf(item),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(ctx);
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
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _isEditing ? context.tr('Edit Lead') : context.tr('Create Lead'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    if (widget.jobWorkflow) {
      return JobCardContent(
        padding: EdgeInsets.zero,
        child: _buildJobLeadForm(),
      );
    }
    final segments = _segmentsForType(_selectedVehicleType?['id']?.toString());
    final makes = _makesFor(
      _selectedVehicleType?['id']?.toString(),
      _selectedVehicleTypeModel?['id']?.toString(),
    );
    final brands = _brandModelsFor(
      _selectedVehicleTypeModel?['id']?.toString(),
      _selectedMake?['id']?.toString(),
    );

    final renewalLabel = _renewalDate != null
        ? '${_renewalDate!.day.toString().padLeft(2, '0')}-'
              '${_renewalDate!.month.toString().padLeft(2, '0')}-'
              '${_renewalDate!.year}'
        : context.tr('Select Renewal Date');

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: REdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Customer Info Card ──────────────────────────────────────────
          _card(
            title: context.tr('Customer Info'),
            icon: Icons.person,
            children: [
              _textField(
                _nameCtrl,
                context.tr('Customer Name *'),
                Icons.person_outline,
                focusNode: _nameFocusNode,
              ),
              SizedBox(height: 14.h),
              _phoneField(
                ctrl: _phoneCtrl,
                focusNode: _phoneFocusNode,
                label: context.tr('Phone Number *'),
                iso: _phoneIso,
                onCountryChanged: (d, iso) => setState(() {
                  _phoneCode = d;
                  _phoneIso = iso;
                }),
              ),
              SizedBox(height: 14.h),
              _phoneField(
                ctrl: _waCtrl,
                focusNode: _waFocusNode,
                label: context.tr('WhatsApp Number (Optional)'),
                iso: _waIso,
                onCountryChanged: (d, iso) => setState(() {
                  _waCode = d;
                  _waIso = iso;
                }),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          _card(
            title: context.tr('Lead Details'),
            icon: Icons.assignment_outlined,
            children: [
              _textField(
                _leadModeCtrl,
                context.tr('Lead Generation Mode'),
                Icons.campaign_outlined,
              ),
              SizedBox(height: 12.h),
              _textField(
                _serviceNameCtrl,
                context.tr('Service'),
                Icons.build_outlined,
              ),
              SizedBox(height: 12.h),
              _textField(
                _staffNameCtrl,
                context.tr('Staff Name'),
                Icons.badge_outlined,
              ),
              SizedBox(height: 12.h),
              _textField(
                _referenceCtrl,
                context.tr('Reference'),
                Icons.person_search_outlined,
              ),
              SizedBox(height: 12.h),
              _textField(
                _expectedValueCtrl,
                context.tr('Expected Value'),
                Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── Vehicle Card ────────────────────────────────────────────────
          _card(
            title: context.tr('Vehicle Details'),
            icon: Icons.directions_car,
            children: [
              // 1. Vehicle Type
              _dropdown<Map<String, dynamic>>(
                label: context.tr('Vehicle Type'),
                value: _selectedVehicleType,
                items: _vehicleTypes.cast(),
                labelOf: (t) => t['name']?.toString() ?? '',
                hint: context.tr('Select vehicle type'),
                onChanged: (val) => setState(() {
                  _selectedVehicleType = val;
                  _selectedVehicleTypeModel = null;
                  _selectedMake = null;
                  _selectedBrandModel = null;
                }),
              ),
              SizedBox(height: 12.h),

              // 2. Make (searchable)
              _searchableField<Map<String, dynamic>>(
                label: context.tr('Vehicle Make'),
                title: 'Make',
                value: _selectedMake,
                items: makes,
                labelOf: (m) => m['name']?.toString() ?? '',
                hint: makes.isEmpty
                    ? context.tr('No makes available')
                    : context.tr('Select Make (e.g. Maruti, Hyundai)...'),
                onChanged: makes.isEmpty
                    ? null
                    : (val) => setState(() {
                        _selectedMake = val;
                        _selectedBrandModel = null;
                      }),
              ),
              SizedBox(height: 12.h),

              // 3. Brand / Model (searchable)
              _searchableField<Map<String, dynamic>>(
                label: context.tr('Brand / Model'),
                title: 'Brand Model',
                value: _selectedBrandModel,
                items: brands,
                labelOf: (b) => b['name']?.toString() ?? '',
                hint: brands.isEmpty
                    ? context.tr('No models available')
                    : context.tr('Select Model (e.g. Swift, Creta)...'),
                onChanged: brands.isEmpty
                    ? null
                    : (val) => setState(() {
                        _selectedBrandModel = val;
                        if (val != null) {
                          // Auto-fill Make
                          final makeId = val['make_id']?.toString();
                          if (makeId != null && makeId.isNotEmpty) {
                            _selectedMake = _makes
                                .cast<Map<String, dynamic>>()
                                .where((m) => m['id']?.toString() == makeId)
                                .cast<Map<String, dynamic>?>()
                                .firstOrNull;
                          }
                          // Auto-fill Segment
                          final vtmId = val['vehicle_type_model_id']
                              ?.toString();
                          if (vtmId != null && vtmId.isNotEmpty) {
                            final seg = _vehicleTypeModels
                                .cast<Map<String, dynamic>>()
                                .where((s) => s['id']?.toString() == vtmId)
                                .cast<Map<String, dynamic>?>()
                                .firstOrNull;
                            if (seg != null) {
                              _selectedVehicleTypeModel = seg;
                              final vtId = seg['vehicle_type_id']?.toString();
                              if (vtId != null && vtId.isNotEmpty) {
                                _selectedVehicleType = _vehicleTypes
                                    .cast<Map<String, dynamic>>()
                                    .where((vt) => vt['id']?.toString() == vtId)
                                    .cast<Map<String, dynamic>?>()
                                    .firstOrNull;
                              }
                            }
                          }
                        }
                      }),
              ),
              SizedBox(height: 12.h),

              // 4. Segment
              if (segments.isNotEmpty) ...[
                _dropdown<Map<String, dynamic>>(
                  label: context.tr('Segment'),
                  value: _selectedVehicleTypeModel,
                  items: segments,
                  labelOf: (m) => m['name']?.toString() ?? '',
                  hint: context.tr('Select segment'),
                  onChanged: (val) =>
                      setState(() => _selectedVehicleTypeModel = val),
                ),
                SizedBox(height: 12.h),
              ],

              // 5. Color
              if (_colors.isNotEmpty) ...[
                _dropdown<Map<String, dynamic>>(
                  label: context.tr('Color (Optional)'),
                  value: _selectedColor,
                  items: [
                    {'id': '', 'name': 'None'},
                    ..._colors.cast<Map<String, dynamic>>(),
                  ],
                  labelOf: (c) => c['name']?.toString() ?? '',
                  hint: context.tr('Select color'),
                  onChanged: (val) => setState(
                    () => _selectedColor = (val?['id'] == '') ? null : val,
                  ),
                ),
                SizedBox(height: 12.h),
              ],

              // 6. Vehicle Number
              _textField(
                _vehicleNumberCtrl,
                context.tr('Vehicle Number'),
                Icons.pin,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── Renewal Date Card ───────────────────────────────────────────
          _card(
            title: context.tr('Renewal Date'),
            icon: Icons.calendar_today,
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: REdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10.r),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 20.r,
                        color: const Color(0xFF000080),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          renewalLabel,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: _renewalDate != null
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (_renewalDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _renewalDate = null),
                          child: Icon(
                            Icons.clear,
                            size: 18.r,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // ── Save Button ─────────────────────────────────────────────────
          SizedBox(
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isEditing
                          ? context.tr('Update Lead')
                          : context.tr('Save Lead'),
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildJobLeadForm() {
    final segments = _segmentsForType(_selectedVehicleType?['id']?.toString());
    final makes = _makesFor(
      _selectedVehicleType?['id']?.toString(),
      _selectedVehicleTypeModel?['id']?.toString(),
    );
    final models = _brandModelsFor(
      _selectedVehicleTypeModel?['id']?.toString(),
      _selectedMake?['id']?.toString(),
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(
              title: 'Customer',
              icon: Icons.person_outline,
              children: [
                _phoneField(
                  ctrl: _phoneCtrl,
                  focusNode: _phoneFocusNode,
                  label: 'Search customer by mobile number *',
                  iso: _phoneIso,
                  onCountryChanged: (dialCode, iso) => setState(() {
                    _phoneCode = dialCode;
                    _phoneIso = iso;
                  }),
                  onChanged: (number) {
                    if (!_applyingCustomer && _linkedCustomerId != null) {
                      setState(() {
                        _nameCtrl.clear();
                        _waCtrl.clear();
                        _emailCtrl.clear();
                        _cityCtrl.clear();
                        _selectedState = null;
                        _selectedCustomerType = null;
                        _linkedCustomerId = null;
                        _linkedVehicleId = null;
                        _existingVehicles = [];
                        _vehicleNumberCtrl.clear();
                        _selectedVehicleTypeModel = null;
                        _selectedMake = null;
                        _selectedBrandModel = null;
                        _selectedColor = null;
                      });
                    }
                    final digits = number.replaceAll(RegExp(r'\D'), '');
                    _searchCustomers(
                      digits.length < 2
                          ? ''
                          : CountryConfig.formatPhoneWithCountryCode(
                              number,
                              _phoneCode,
                            ),
                    );
                  },
                  suffixIcon: _searchingCustomers
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Search customer',
                          icon: const Icon(Icons.search),
                          onPressed: () => _searchCustomers(
                            CountryConfig.formatPhoneWithCountryCode(
                              _phoneCtrl.text,
                              _phoneCode,
                            ),
                          ),
                        ),
                ),
                if (_customerMatches.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 220.h),
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _customerMatches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = _customerMatches[index];
                        return ListTile(
                          dense: true,
                          title: Text(customer['name']?.toString() ?? ''),
                          subtitle: Text(
                            '${customer['phone'] ?? ''}  ${customer['customer_type'] ?? ''}',
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _selectExistingCustomer(customer);
                          },
                        );
                      },
                    ),
                  ),
                if (_customerSearchCompleted &&
                    _customerMatches.isEmpty &&
                    _linkedCustomerId == null &&
                    _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length >=
                        6) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('No customer found for this number.'),
                      ),
                      TextButton.icon(
                        onPressed: _createCustomerFromLead,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Customer'),
                      ),
                    ],
                  ),
                ],
                if (_linkedCustomerId != null) ...[
                  SizedBox(height: 12.h),
                  if (_existingVehicles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value:
                          _existingVehicles.any(
                            (v) => v['id']?.toString() == _linkedVehicleId,
                          )
                          ? _linkedVehicleId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Select customer vehicle',
                      ),
                      items: _existingVehicles
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v['id']?.toString(),
                              child: Text(
                                '${v['no'] ?? ''} · ${v['make'] ?? ''} ${v['model'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        final vehicle = _existingVehicles
                            .cast<Map<String, dynamic>?>()
                            .firstWhere(
                              (v) => v?['id']?.toString() == id,
                              orElse: () => null,
                            );
                        if (vehicle != null) {
                          setState(() => _applyExistingVehicle(vehicle));
                        }
                      },
                    )
                  else
                    const Text('No vehicles saved for this customer yet.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addVehicleToSelectedCustomer,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Vehicle'),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                _textField(
                  _nameCtrl,
                  'Customer Name *',
                  Icons.person_outline,
                  focusNode: _nameFocusNode,
                ),
                SizedBox(height: 12.h),
                _phoneField(
                  ctrl: _waCtrl,
                  focusNode: _waFocusNode,
                  label: 'WhatsApp Number (Optional)',
                  iso: _waIso,
                  onCountryChanged: (d, iso) => setState(() {
                    _waCode = d;
                    _waIso = iso;
                  }),
                ),
                SizedBox(height: 12.h),
                _selectMaster(
                  'Emirate / State',
                  _states,
                  _selectedState,
                  (v) => setState(() => _selectedState = v),
                ),
                SizedBox(height: 12.h),
                _textField(
                  _cityCtrl,
                  'City',
                  Icons.location_city,
                  focusNode: _cityFocusNode,
                ),
                SizedBox(height: 12.h),
                _textField(
                  _emailCtrl,
                  'Email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocusNode,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _card(
              title: 'Lead Details',
              icon: Icons.assignment_outlined,
              children: [
                _dateTile('Lead Date *', _leadDate, () => _chooseDate(false)),
                _selectMaster(
                  'Staff *',
                  _staffOptions,
                  _selectedStaff,
                  (v) => setState(() => _selectedStaff = v),
                ),
                SizedBox(height: 12.h),
                Autocomplete<String>(
                  optionsBuilder: (value) => _leadModes
                      .where(
                        (m) => m.toString().toLowerCase().contains(
                          value.text.toLowerCase(),
                        ),
                      )
                      .map((m) => m.toString()),
                  onSelected: (v) => _leadModeCtrl.text = v,
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    if (controller.text.isEmpty && _leadModeCtrl.text.isNotEmpty) {
                      controller.text = _leadModeCtrl.text;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (value) => _leadModeCtrl.text = value,
                      decoration: const InputDecoration(
                        labelText: 'Lead Generation Mode *',
                        prefixIcon: Icon(Icons.campaign_outlined),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12.h),
                _selectMaster(
                  'Customer Type *',
                  _customerTypes,
                  _selectedCustomerType,
                  (v) => setState(() => _selectedCustomerType = v),
                ),
                SizedBox(height: 12.h),
                _textField(
                  _referenceCtrl,
                  'Reference (Optional)',
                  Icons.person_search_outlined,
                  focusNode: _referenceFocusNode,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _card(
              title: 'Vehicle Details',
              icon: Icons.directions_car_outlined,
              children: [
                _textField(
                  _vehicleNumberCtrl,
                  'Vehicle Number',
                  Icons.pin,
                  textCapitalization: TextCapitalization.characters,
                  focusNode: _vehicleNumberFocusNode,
                ),
              SizedBox(height: 12.h),
              _selectMaster(
                'Vehicle Type',
                _vehicleTypes,
                _selectedVehicleType,
                (v) => setState(() {
                  _selectedVehicleType = v;
                  _selectedVehicleTypeModel = null;
                }),
              ),
              SizedBox(height: 12.h),
              _searchableField<Map<String, dynamic>>(
                label: 'Make',
                title: 'Make',
                value: _selectedMake,
                items: makes,
                labelOf: (m) => m['name'] ?? '',
                hint: 'Select make',
                onChanged: (v) => setState(() {
                  _selectedMake = v;
                  _selectedBrandModel = null;
                }),
              ),
              SizedBox(height: 12.h),
              _searchableField<Map<String, dynamic>>(
                label: 'Model',
                title: 'Model',
                value: _selectedBrandModel,
                items: models,
                labelOf: (m) => m['name'] ?? '',
                hint: 'Select model',
                onChanged: (v) => setState(() {
                  _selectedBrandModel = v;
                  if (v == null) return;
                  final makeId = v['make_id']?.toString();
                  final make = _makes
                      .cast<Map<String, dynamic>>()
                      .where((m) => m['id']?.toString() == makeId)
                      .cast<Map<String, dynamic>?>()
                      .firstOrNull;
                  if (make != null) _selectedMake = make;
                  final segmentId =
                      v['vehicle_type_model_id']?.toString() ??
                      v['segment_id']?.toString();
                  final segment = _vehicleTypeModels
                      .cast<Map<String, dynamic>>()
                      .where((s) => s['id']?.toString() == segmentId)
                      .cast<Map<String, dynamic>?>()
                      .firstOrNull;
                  if (segment != null) {
                    _selectedVehicleTypeModel = segment;
                    final typeId = segment['vehicle_type_id']?.toString();
                    _selectedVehicleType =
                        _vehicleTypes
                            .cast<Map<String, dynamic>>()
                            .where((type) => type['id']?.toString() == typeId)
                            .cast<Map<String, dynamic>?>()
                            .firstOrNull ??
                        _selectedVehicleType;
                  }
                }),
              ),
              SizedBox(height: 12.h),
              _selectMaster(
                'Segment',
                segments,
                _selectedVehicleTypeModel,
                (v) => setState(() => _selectedVehicleTypeModel = v),
              ),
              Column(
                children: [
                  if (_showMoreVehicle) ...[
                    SizedBox(height: 12.h),
                    _selectMaster(
                      'Color',
                      _colors,
                      _selectedColor,
                      (v) => setState(() => _selectedColor = v),
                    ),
                    SizedBox(height: 12.h),
                    _selectMaster(
                      'Emission Standard',
                      _emissions,
                      _selectedEmission,
                      (v) => setState(() => _selectedEmission = v),
                    ),
                    SizedBox(height: 12.h),
                    _selectMaster(
                      'Fuel Type',
                      _fuelTypes,
                      _selectedFuel,
                      (v) => setState(() => _selectedFuel = v),
                    ),
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      value: _selectedWheelId,
                      decoration: const InputDecoration(
                        labelText: 'Wheel Type',
                      ),
                      items: _wheelTypes
                          .map(
                            (w) => DropdownMenuItem<String>(
                              value: w['id'].toString(),
                              child: Text(w['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _selectedWheelId = v ?? 'normal_wheel',
                      ),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showMoreVehicle = !_showMoreVehicle),
                    icon: Icon(
                      _showMoreVehicle ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(_showMoreVehicle ? 'Less' : 'More'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _card(
            title: 'Service',
            icon: Icons.build_outlined,
            children: [
              ...List.generate(_serviceRows.length, (index) {
                final row = _serviceRows[index];
                final categories = _serviceCategories
                    .cast<Map<String, dynamic>>();
                final filtered = _services
                    .where(
                      (s) =>
                          row['category'] == null ||
                          s['category_id'].toString() ==
                              row['category']['id'].toString(),
                    )
                    .cast<Map<String, dynamic>>()
                    .toList();
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _selectMaster(
                              'Category *',
                              categories,
                              row['category'],
                              (v) => setState(() {
                                row['category'] = v;
                                row['service'] = null;
                              }),
                            ),
                          ),
                          IconButton(
                            onPressed: _serviceRows.length == 1
                                ? null
                                : () => setState(() {
                                    (row['value_controller']
                                            as TextEditingController)
                                        .dispose();
                                    _serviceRows.removeAt(index);
                                  }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _selectMaster(
                        'Service *',
                        filtered,
                        row['service'],
                        (v) => setState(() => row['service'] = v),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: row['value_controller'],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Expected Value',
                          prefixText: '₹ ',
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(_addServiceRow),
                  icon: const Icon(Icons.add),
                  label: const Text('Add service'),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _totalExpectedNotifier,
                builder: (_, total, __) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total expected: ₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _card(
            title: 'Follow-up',
            icon: Icons.event,
            children: [
              _dateTile(
                'Next Follow-up Date *',
                _nextFollowUpDate,
                () => _chooseDate(true),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEditing ? 'Update Lead' : 'Save Lead'),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    ),
  );
}

  // ── Reusable UI helpers ────────────────────────────────────────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: REdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF000080), size: 20.r),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  color: const Color(0xFF000080),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    FocusNode? focusNode,
  }) {
    return Column(
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
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.r, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF000080)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneField({
    required TextEditingController ctrl,
    required String label,
    required String iso,
    required void Function(String dialCode, String iso) onCountryChanged,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return Column(
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
        IntlPhoneField(
          controller: ctrl,
          focusNode: focusNode,
          initialCountryCode: iso,
          onCountryChanged: (country) =>
              onCountryChanged('+${country.dialCode}', country.code),
          onChanged: onChanged == null
              ? null
              : (number) => onChanged(number.number),
          dropdownTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          disableLengthCheck: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF000080)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T?) onChanged,
    String? hint,
  }) {
    T? matched;
    if (value != null) {
      for (final item in items) {
        if (item is Map &&
            value is Map &&
            item['id']?.toString() == (value as Map)['id']?.toString()) {
          matched = item;
          break;
        } else if (item == value) {
          matched = item;
          break;
        }
      }
    }

    return Column(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              menuMaxHeight: 350,
              value: matched,
              hint: Text(
                hint ?? 'Select...',
                style: GoogleFonts.inter(color: Colors.grey.shade500),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(labelOf(item), style: GoogleFonts.inter()),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchableField<T>({
    required String label,
    required String title,
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T?)? onChanged,
    String? hint,
  }) {
    String displayLabel = hint ?? 'Select $title...';
    bool hasValue = false;

    if (value != null && items.isNotEmpty) {
      for (final item in items) {
        bool match =
            (item is Map &&
                value is Map &&
                item['id']?.toString() == (value as Map)['id']?.toString()) ||
            item == value;
        if (match) {
          displayLabel = labelOf(item);
          hasValue = true;
          break;
        }
      }
    } else if (value != null) {
      displayLabel = labelOf(value);
      hasValue = true;
    }

    return Column(
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
        InkWell(
          onTap: (items.isEmpty || onChanged == null)
              ? null
              : () => _showSearchModal<T>(title, items, labelOf, onChanged),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: hasValue ? Colors.black87 : Colors.grey.shade500,
                      fontWeight: hasValue
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search, size: 18.r, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
