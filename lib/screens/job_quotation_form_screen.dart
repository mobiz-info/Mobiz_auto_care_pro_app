import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/job_card_responsive.dart';
import 'quotation_view_screen.dart';
import 'job_card/controllers/job_card_inspection_controller.dart';
import 'job_card/widgets/inspection/inspection_tab_view.dart';
import 'job_card/widgets/inspection/inspection_summary_tab_view.dart';
import 'job_card/widgets/common/job_item_widgets.dart';
import 'job_card/widgets/pricing/accessory_picker_dialog.dart';

class JobQuotationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? lead;
  final Map<String, dynamic>? existingQuotation;

  const JobQuotationFormScreen({super.key, this.lead, this.existingQuotation});

  @override
  State<JobQuotationFormScreen> createState() => _JobQuotationFormScreenState();
}

class _JobQuotationFormScreenState extends State<JobQuotationFormScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _tax = TextEditingController();
  final _tin = TextEditingController();
  final _pan = TextEditingController();
  final _comments = TextEditingController();
  final _plate = TextEditingController();
  final _engineNumber = TextEditingController();
  final _chassisNumber = TextEditingController();
  final _damageInspectionCtrl = JobCardInspectionController();
  final _issueText = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _customerTypes = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  List<Map<String, dynamic>> _segments = [];
  List<Map<String, dynamic>> _makes = [];
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _emissions = [];
  List<Map<String, dynamic>> _fuelTypes = [];
  List<Map<String, dynamic>> _jobCardCategories = [];
  List<Map<String, dynamic>> _jobCardServices = [];
  List<Map<String, dynamic>> _jobCardIssues = [];
  List<Map<String, dynamic>> _oilBrands = [];
  List<Map<String, dynamic>> _oilGrades = [];
  List<Map<String, dynamic>> _activityChoices = [];
  List<Map<String, dynamic>> _staff = [];
  final List<Map<String, dynamic>> _reportedIssues = [];
  final Map<String, dynamic> _inspectionDetails = {};
  final List<Map<String, dynamic>> _accessories = [];
  final List<Map<String, dynamic>> _extras = [];
  final List<Map<String, dynamic>> _labourCharges = [];
  final List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _availableTaxes = [];
  List<Map<String, dynamic>> _pricingServiceCategories = [];
  List<Map<String, dynamic>> _pricingAvailableServices = [];
  String? _selectedPricingCategory;
  Map<String, dynamic>? _selectedPricingService;
  final _serviceRateCtrl = TextEditingController();
  final _serviceQtyCtrl = TextEditingController(text: '1');
  final _serviceDiscountCtrl = TextEditingController(text: '0');
  final _serviceWarrantyCtrl = TextEditingController();
  final _serviceRemarkCtrl = TextEditingController();
  List<Map<String, dynamic>> _leadServices = [];
  final _labourNameCtrl = TextEditingController(text: 'Labour Charge');
  final _labourRateCtrl = TextEditingController();
  final _labourQtyCtrl = TextEditingController(text: '1');
  final _labourDiscountCtrl = TextEditingController(text: '0');
  final _labourRemarksCtrl = TextEditingController();

  final _extraNameCtrl = TextEditingController();
  final _extraRateCtrl = TextEditingController();
  final _extraQtyCtrl = TextEditingController(text: '1');
  final _extraDiscountCtrl = TextEditingController(text: '0');
  final _extraRemarksCtrl = TextEditingController();
  Map<String, dynamic>? _entryAccessoryItem;
  final _accessoryRateCtrl = TextEditingController(text: '0.00');
  final _accessoryQtyCtrl = TextEditingController(text: '1');
  final _accessoryDiscountCtrl = TextEditingController(text: '0.00');
  int? _editingAccessoryIndex;
  List<XFile> _issuePhotos = [];
  List<Map<String, dynamic>> _existingIssuePhotos = [];

  Map<String, dynamic>? _customerType;
  Map<String, dynamic>? _state;
  Map<String, dynamic>? _vehicleType;
  Map<String, dynamic>? _segment;
  Map<String, dynamic>? _make;
  Map<String, dynamic>? _model;
  Map<String, dynamic>? _color;
  Map<String, dynamic>? _emission;
  Map<String, dynamic>? _jobCardCategory;
  Map<String, dynamic>? _jobCardService;
  Map<String, dynamic>? _jobCardIssue;
  int? _editingIssueIndex;
  String _fuel = '';
  String _wheel = 'normal_wheel';
  String _companySealUrl = '';
  Map<String, dynamic>? _preparedBy;
  DateTime? _inspectionAt;
  DateTime? _tentativeDeliveryAt;
  final _internalNotes = TextEditingController();
  final _daysNeededCtrl = TextEditingController();

  bool get _isCorporate => (_customerType?['name'] ?? '')
      .toString()
      .toLowerCase()
      .contains('corporate');

  String _numberText(dynamic value) {
    final text = (value ?? '').toString().trim();
    final parsed = double.tryParse(text);
    return parsed == null || parsed == 0 ? '' : text;
  }

  double _numberValue(dynamic value) =>
      double.tryParse((value ?? '').toString().trim()) ?? 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(_handleTabChange);
    _prefillLead();
    _loadFormData();
  }

  void _prefillLead() {
    final quotation = widget.existingQuotation;
    if (quotation != null) {
      _name.text = (quotation['customer_name'] ?? '').toString();
      _phone.text = (quotation['customer_phone'] ?? '').toString();
      _whatsapp.text = (quotation['whatsapp_number'] ?? '').toString();
      _email.text = (quotation['email'] ?? '').toString();
      _city.text = (quotation['city'] ?? '').toString();
      _tax.text = (quotation['tax_number'] ?? '').toString();
      _tin.text = (quotation['tin_number'] ?? '').toString();
      _pan.text = (quotation['pan_number'] ?? '').toString();
      _comments.text = (quotation['customer_comments'] ?? '').toString();
      _plate.text = (quotation['vehicle_number'] ?? '').toString();
      _engineNumber.text =
          (quotation['engine_number'] ??
                  quotation['vehicle']?['engine_number'] ??
                  '')
              .toString();
      _chassisNumber.text =
          (quotation['chassis_number'] ??
                  quotation['vehicle']?['chassis_number'] ??
                  '')
              .toString();
      return;
    }
    final lead = widget.lead;
    if (lead == null) return;
    _name.text = (lead['customer_name'] ?? '').toString();
    _phone.text = (lead['phone_number'] ?? '').toString();
    _whatsapp.text = (lead['whatsapp_number'] ?? '').toString();
    _email.text = (lead['email'] ?? '').toString();
    _city.text = (lead['city'] ?? '').toString();
    _plate.text = (lead['vehicle_number'] ?? '').toString();
    _engineNumber.text = (lead['engine_number'] ?? '').toString();
    _chassisNumber.text = (lead['chassis_number'] ?? '').toString();

    final interests = List<dynamic>.from(lead['service_interests'] ?? []);
    final List<Map<String, dynamic>> servicesToImport = [];
    if (interests.isNotEmpty) {
      for (final raw in interests) {
        if (raw is Map) {
          servicesToImport.add(Map<String, dynamic>.from(raw));
        }
      }
    } else if ((lead['service_name'] ?? '').toString().trim().isNotEmpty) {
      for (final name in (lead['service_name'] as String).split(',')) {
        final trimmed = name.trim();
        if (trimmed.isNotEmpty) {
          servicesToImport.add({
            'service_name': trimmed,
            'category_name': 'General Service',
            'service_id': '',
            'expected_value': lead['expected_value'] ?? 0,
          });
        }
      }
    }

    _reportedIssues.clear();
    for (final interest in servicesToImport) {
      final sName = (interest['service_name'] ?? '').toString().trim();
      final cName = (interest['category_name'] ?? '').toString().trim();
      final sId = (interest['service_id'] ?? '').toString().trim();
      final expectedVal = interest['expected_value'];
      final rateVal = (expectedVal is num)
          ? (expectedVal > 0 ? expectedVal.toString() : '')
          : (double.tryParse((expectedVal ?? '').toString()) != null &&
                    double.parse(expectedVal.toString()) > 0
                ? expectedVal.toString()
                : '');

      _reportedIssues.add({
        'report_id': null,
        '_pricingKey': Object(),
        '_activityKey': Object(),
        'category': {'id': '', 'name': cName.isNotEmpty ? cName : 'Service'},
        'service': {
          'id': sId,
          'name': sName.isNotEmpty ? sName : 'General Service',
        },
        'issue': {
          'id': '',
          'name': sName.isNotEmpty ? sName : 'General Service',
        },
        'issue_text': sName.isNotEmpty ? sName : 'General Service',
        'rate': rateVal,
        'quantity': '1',
        'discount': '',
        'activities': <Map<String, dynamic>>[],
        'photos': <XFile>[],
        'existing_photos': <Map<String, dynamic>>[],
      });
    }
  }

  void _handleTabChange() {
    if (mounted && !_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChange);
    _tabs.dispose();
    for (final controller in [
      _name,
      _phone,
      _whatsapp,
      _email,
      _city,
      _tax,
      _tin,
      _pan,
      _comments,
      _plate,
      _engineNumber,
      _chassisNumber,
      _issueText,
      _internalNotes,
    ]) {
      controller.dispose();
    }
    for (final row in _reportedIssues) {
      (row['_activityController'] as TextEditingController?)?.dispose();
      (row['_activityFocusNode'] as FocusNode?)?.dispose();
    }
    _serviceRateCtrl.dispose();
    _serviceQtyCtrl.dispose();
    _serviceDiscountCtrl.dispose();
    _serviceWarrantyCtrl.dispose();
    _serviceRemarkCtrl.dispose();
    _damageInspectionCtrl.dispose();
    _labourNameCtrl.dispose();
    _labourRateCtrl.dispose();
    _labourQtyCtrl.dispose();
    _labourDiscountCtrl.dispose();
    _labourRemarksCtrl.dispose();
    _extraNameCtrl.dispose();
    _extraRateCtrl.dispose();
    _extraQtyCtrl.dispose();
    _extraDiscountCtrl.dispose();
    _extraRemarksCtrl.dispose();
    _accessoryRateCtrl.dispose();
    _accessoryQtyCtrl.dispose();
    _accessoryDiscountCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<void> _loadFormData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final result = await ApiService.getFormData(token);
      if (!mounted) return;
      if (result['success'] != true)
        throw Exception(result['message'] ?? 'Unable to load form options');
      final issueOptions = await ApiService.getJobCardIssueOptions(token);
      if (!mounted) return;
      if (issueOptions['success'] != true) {
        throw Exception(
          issueOptions['message'] ?? 'Unable to load Job Card issues',
        );
      }
      final leadFormData = await ApiService.getJobLeadFormData(token);
      if (!mounted) return;
      Map<String, dynamic> checklistRes = {};
      try {
        checklistRes = await ApiService.getInspectionChecklist(token);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        if (checklistRes['success'] == true && checklistRes['categories'] is List) {
          _damageInspectionCtrl.checklistCategories = List<Map<String, dynamic>>.from(
            (checklistRes['categories'] as List).map((c) => Map<String, dynamic>.from(c as Map)),
          );
          if (_damageInspectionCtrl.checklistCategories.isNotEmpty) {
            _damageInspectionCtrl.selectedInspectionCategory =
                _damageInspectionCtrl.checklistCategories.first['name'].toString();
          }
        }
        _customerTypes = _maps(result['customer_types']);
        _states = _maps(result['states']);
        _vehicleTypes = _maps(result['vehicle_types']);
        _segments = _maps(result['vehicle_type_models']);
        _makes = _maps(result['makes']);
        _models = _maps(result['brand_models']);
        _colors = _maps(result['colors']);
        _emissions = _maps(result['emission_standards']);
        _fuelTypes = _maps(result['fuel_types']);
        _jobCardCategories = _maps(issueOptions['categories']);
        _jobCardServices = _maps(issueOptions['services']);
        _jobCardIssues = _maps(issueOptions['issues']);
        _activityChoices = _maps(issueOptions['activities']);
        _oilBrands = _maps(result['oil_brands']);
        _oilGrades = _maps(result['oil_grades']);
        _staff = _maps(leadFormData['staff']);
        _companySealUrl = (leadFormData['company_seal_url'] ?? '').toString();
        _availableTaxes = _maps(leadFormData['taxes']);
        _pricingServiceCategories =
            (leadFormData['service_categories'] as List? ?? [])
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
        if (_pricingServiceCategories.isEmpty) {
          _pricingServiceCategories = _jobCardCategories;
        }
        _pricingAvailableServices = (leadFormData['services'] as List? ?? [])
            .map((item) {
              final s = Map<String, dynamic>.from(item as Map);
              return <String, dynamic>{
                ...s,
                'category_id':
                    s['category_id']?.toString() ??
                    s['service_type_id']?.toString(),
                'category_name': s['category_name'] ?? s['service_type'] ?? '',
                'rate': s['rate'] ?? 0,
              };
            })
            .toList();
        if (_pricingAvailableServices.isEmpty) {
          _pricingAvailableServices = _jobCardServices
              .map(
                (s) => <String, dynamic>{
                  ...s,
                  'category_id': s['category_id']?.toString(),
                  'rate': 0,
                },
              )
              .toList();
        }
        _selectedPricingCategory = _pricingServiceCategories.firstOrNull?['id']
            ?.toString();
        _jobCardCategory = _jobCardCategories.firstOrNull;
        if (widget.existingQuotation != null) {
          _reportedIssues.clear();
        }
        _services.clear();
        _inspectionDetails
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(
              leadFormData['inspection_details'] as Map? ?? {},
            ),
          );
        if (widget.existingQuotation?['inspection_details'] is Map) {
          _inspectionDetails
            ..clear()
            ..addAll(
              Map<String, dynamic>.from(
                widget.existingQuotation!['inspection_details'] as Map,
              ),
            );
        }
        _damageInspectionCtrl.loadExistingInspection(_inspectionDetails);
        if (_engineNumber.text.isEmpty) {
          _engineNumber.text =
              (widget.existingQuotation?['engine_number'] ??
                      widget.existingQuotation?['vehicle']?['engine_number'] ??
                      leadFormData['vehicle']?['engine_number'] ??
                      '')
                  .toString();
        }
        if (_chassisNumber.text.isEmpty) {
          _chassisNumber.text =
              (widget.existingQuotation?['chassis_number'] ??
                      widget.existingQuotation?['vehicle']?['chassis_number'] ??
                      leadFormData['vehicle']?['chassis_number'] ??
                      '')
                  .toString();
        }
        _accessories.clear();
        _extras.clear();
        _labourCharges.clear();
        for (final rawIssue
            in widget.existingQuotation?['reported_issues'] as List<dynamic>? ??
                []) {
          final saved = Map<String, dynamic>.from(rawIssue as Map);
          final category = _find(_jobCardCategories, saved['category_id']);
          final service = _find(_jobCardServices, saved['service_id']);
          if (category == null || service == null) continue;
          final issue =
              _find(_jobCardIssues, saved['issue_id']) ??
              {
                'id': saved['issue_id'] ?? '',
                'name': saved['issue_text'] ?? '',
              };
          _reportedIssues.add({
            'report_id': saved['id'],
            '_pricingKey': Object(),
            '_activityKey': Object(),
            'category': category,
            'service': service,
            'issue': issue,
            'issue_text': saved['issue_text'] ?? '',
            'rate': _numberText(saved['pricing']?['rate']),
            'quantity': (saved['pricing']?['quantity'] ?? 1).toString(),
            'discount': _numberText(saved['pricing']?['discount']),
            'activities': List<Map<String, dynamic>>.from(
              (saved['activities'] as List? ?? []).map(
                (value) => Map<String, dynamic>.from(value as Map),
              ),
            ),
            'photos': <XFile>[],
            'existing_photos': List<Map<String, dynamic>>.from(
              (saved['photo_records'] as List<dynamic>? ?? []).map(
                (photo) => Map<String, dynamic>.from(photo as Map),
              ),
            ),
          });
        }
        final lead = widget.existingQuotation ?? widget.lead ?? {};
        _internalNotes.text = (lead['internal_notes'] ?? '').toString();
        _inspectionAt = DateTime.tryParse(
          (lead['inspection_at'] ?? '').toString(),
        )?.toLocal();
        _tentativeDeliveryAt = DateTime.tryParse(
          (lead['tentative_delivery_at'] ?? '').toString(),
        )?.toLocal();
        _daysNeededCtrl.text =
            (lead['days_needed'] ??
                    ((lead['additional_days_needed'] != null &&
                            lead['additional_days_needed'] != 0)
                        ? '${lead['additional_days_needed']} Days'
                        : (lead['delivery_lead_time'] ?? '')))
                .toString();
        _preparedBy = _find(_staff, lead['prepared_by_id']);
        if (lead['company_seal_url'] != null)
          _companySealUrl = lead['company_seal_url'].toString();
        for (final raw in lead['items'] as List<dynamic>? ?? []) {
          final item = Map<String, dynamic>.from(raw as Map);
          if (item['line_type'] == 'service') {
            item['rate'] = _numberText(item['rate']);
            item['discount'] = _numberText(item['discount']);
            final r = double.tryParse((item['rate'] ?? '0').toString()) ?? 0;
            final q =
                double.tryParse((item['quantity'] ?? '1').toString()) ?? 1;
            final d =
                double.tryParse((item['discount'] ?? '0').toString()) ?? 0;
            final tot = item['total'] != null
                ? (double.tryParse(item['total'].toString()) ?? 0)
                : ((r * q) - d).clamp(0, double.infinity);
            item['total_amount'] = tot;
            item['total'] = tot;
            _services.add(item);
          } else if (item['line_type'] == 'accessory') {
            item['rate'] = _numberText(item['rate']);
            item['discount'] = _numberText(item['discount']);
            _accessories.add(item);
          }
        }
        for (final raw in lead['extras'] as List<dynamic>? ?? []) {
          final extra = Map<String, dynamic>.from(raw as Map);
          if (extra['line_type'] == 'quote_form') {
            extra['price'] = _numberText(extra['price']);
            extra['rate'] = extra['price'];
            extra['quantity'] = _numberText(extra['quantity'] ?? 1);
            extra['discount'] = _numberText(extra['discount']);
            extra['total_amount'] = _pricedRowTotal(extra, extra: true);
            _extras.add(extra);
          }
          if (extra['line_type'] == 'labour') {
            final eName = (extra['name'] ?? '').toString().trim();
            final isActivityLabour = _reportedIssues.any((r) {
              final sName = (r['service']?['name'] ?? r['issue_text'] ?? '').toString().trim();
              return (r['activities'] as List? ?? []).any((a) {
                final aName = (a['name'] ?? '').toString().trim();
                return eName == aName || eName == '$sName · $aName';
              });
            });
            if (isActivityLabour) {
              for (final r in _reportedIssues) {
                final sName = (r['service']?['name'] ?? r['issue_text'] ?? '').toString().trim();
                for (final a in (r['activities'] as List? ?? [])) {
                  final aName = (a['name'] ?? '').toString().trim();
                  if (eName == aName || eName == '$sName · $aName') {
                    if ((a['cost'] == null || a['cost'].toString().isEmpty || a['cost'] == '0') && extra['price'] != null) {
                      a['cost'] = _numberText(extra['price']);
                    }
                    if ((a['discount'] == null || a['discount'].toString().isEmpty || a['discount'] == '0') && extra['discount'] != null) {
                      a['discount'] = _numberText(extra['discount']);
                    }
                  }
                }
              }
            } else {
              extra['price'] = _numberText(extra['price']);
              extra['rate'] = extra['price'];
              extra['quantity'] = _numberText(extra['quantity'] ?? 1);
              extra['discount'] = _numberText(extra['discount']);
              extra['total_amount'] = _pricedRowTotal(extra, extra: true);
              _labourCharges.add(extra);
            }
          }
        }
        // Capture lead services for display in Reported Issues and prefill in Pricing tab
        if (widget.existingQuotation == null && widget.lead != null) {
          final leadMap = widget.lead!;
          final interests = List<dynamic>.from(
            leadMap['service_interests'] ?? [],
          );
          final List<Map<String, dynamic>> servicesToImport = [];
          if (interests.isNotEmpty) {
            for (final raw in interests) {
              if (raw is Map) {
                servicesToImport.add(Map<String, dynamic>.from(raw));
              }
            }
          } else if ((leadMap['service_name'] ?? '')
              .toString()
              .trim()
              .isNotEmpty) {
            for (final name in (leadMap['service_name'] as String).split(',')) {
              final trimmed = name.trim();
              if (trimmed.isNotEmpty) {
                servicesToImport.add({
                  'service_name': trimmed,
                  'category_name': '',
                  'service_id': '',
                  'expected_value': leadMap['expected_value'] ?? 0,
                });
              }
            }
          }
          _leadServices = servicesToImport;
          if (_reportedIssues.isEmpty && widget.existingQuotation == null) {
            for (int i = 0; i < servicesToImport.length; i++) {
              final item = servicesToImport[i];
              final amount =
                  (item['expected_value'] as num?)?.toDouble() ?? 0.0;
              final categoryId = (item['category_id'] ?? '').toString();
              final categoryName = (item['category_name'] ?? '').toString();
              final serviceId = (item['service_id'] ?? '').toString();
              final serviceName = (item['service_name'] ?? '').toString();
              if (serviceName.isNotEmpty) {
                _reportedIssues.add({
                  '_pricingKey': Object(),
                  '_activityKey': Object(),
                  'client_key':
                      'lead-$serviceId-${DateTime.now().microsecondsSinceEpoch}-$i',
                  'category': {
                    'id': categoryId,
                    'name': categoryName.isNotEmpty ? categoryName : 'General',
                  },
                  'service': {
                    'id': serviceId,
                    'name': serviceName,
                    'category_id': categoryId,
                  },
                  'issue': {
                    'id': '',
                    'name': serviceName,
                    'category_id': categoryId,
                    'service_id': serviceId,
                  },
                  'issue_text': serviceName,
                  'rate': amount > 0 ? amount.toStringAsFixed(2) : '',
                  'quantity': '1',
                  'discount': '',
                  'warranty': '',
                  'remarks': '',
                  'activities': <Map<String, dynamic>>[],
                  'photos': <XFile>[],
                  'existing_photos': <Map<String, dynamic>>[],
                });
              }
            }
          }
          if (_leadServices.isNotEmpty) {
            _prefillPricingServiceFromLead(_leadServices.first);
          }
        }

        _customerType = _find(_customerTypes, lead['customer_type_id']);
        _state =
            _find(_states, lead['state_id']) ??
            _states
                .where(
                  (item) =>
                      item['name']?.toString().toLowerCase() ==
                      (lead['state'] ?? '').toString().toLowerCase(),
                )
                .firstOrNull;
        _vehicleType = _find(_vehicleTypes, lead['vehicle_type_id']);
        _segment = _find(
          _segments,
          lead['segment_id'] ?? lead['vehicle_segment_id'],
        );
        _make = _find(_makes, lead['make_id'] ?? lead['vehicle_make_id']);
        _model = _find(
          _models,
          lead['brand_model_id'] ?? lead['vehicle_model_id'],
        );
        _color = _find(_colors, lead['color_id'] ?? lead['vehicle_color_id']);
        _emission = _find(
          _emissions,
          lead['emission_standard_id'] ?? lead['vehicle_emission_standard_id'],
        );
        _fuel = (lead['fuel_type'] ?? lead['vehicle_fuel_type'] ?? '')
            .toString();
        _wheel =
            (lead['wheel_type'] ?? lead['vehicle_wheel_type'] ?? 'normal_wheel')
                .toString();
        _loading = false;
      });
      _autoFillVehicleFromModel(_model);
      await _prefillFromMatchingCustomer(token);
      if (_oilBrands.isEmpty) {
        try {
          final bRes = await ApiService.getOilBrands(token);
          if (bRes['success'] == true && mounted) {
            setState(() {
              _oilBrands = _maps(
                bRes['oil_brands'] ?? bRes['brands'] ?? bRes['data'],
              );
            });
          }
        } catch (_) {}
      }
      if (_oilGrades.isEmpty) {
        try {
          final gRes = await ApiService.getOilGrades(token);
          if (gRes['success'] == true && mounted) {
            setState(() {
              _oilGrades = _maps(
                gRes['oil_grades'] ?? gRes['grades'] ?? gRes['data'],
              );
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _prefillFromMatchingCustomer(String token) async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) return;
    final result = await ApiService.searchCustomer(
      phone,
      token,
      branchId: widget.lead?['branch_id']?.toString(),
    );
    final customer = result['customer'];
    if (result['success'] != true || customer is! Map || !mounted) return;
    final profile = Map<String, dynamic>.from(customer);
    final leadBranchId = widget.lead?['branch_id']?.toString() ?? '';
    if (leadBranchId.isNotEmpty &&
        profile['branch_id']?.toString() != leadBranchId)
      return;
    final typeName = (profile['type'] ?? '').toString().toLowerCase();
    final matchedState = _states
        .where(
          (item) =>
              item['name'].toString().toLowerCase() ==
              (profile['state'] ?? '').toString().toLowerCase(),
        )
        .firstOrNull;
    final vehicleRows = List<dynamic>.from(profile['vehicles'] ?? []);
    final normalizedPlate = _plate.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final matchingVehicle = vehicleRows
        .where(
          (item) =>
              (item['no'] ?? '').toString().toUpperCase().replaceAll(
                    RegExp(r'[^A-Z0-9]'),
                    '',
                  ) ==
                  normalizedPlate &&
              normalizedPlate.isNotEmpty,
        )
        .firstOrNull;
    setState(() {
      if (_name.text.trim().isEmpty)
        _name.text = (profile['name'] ?? '').toString();
      if (_whatsapp.text.trim().isEmpty)
        _whatsapp.text = (profile['whatsapp'] ?? '').toString();
      if (_email.text.trim().isEmpty)
        _email.text = (profile['email'] ?? '').toString();
      if (_city.text.trim().isEmpty)
        _city.text = (profile['city'] ?? '').toString();
      if (_tax.text.trim().isEmpty)
        _tax.text = (profile['tax_number'] ?? '').toString();
      if (_tin.text.trim().isEmpty)
        _tin.text = (profile['tin_number'] ?? '').toString();
      if (_pan.text.trim().isEmpty)
        _pan.text = (profile['pan_number'] ?? '').toString();
      _customerType ??= _customerTypes
          .where((item) => item['name'].toString().toLowerCase() == typeName)
          .firstOrNull;
      if (_state == null && (profile['state'] ?? '').toString().isNotEmpty) {
        _state =
            matchedState ??
            {'id': 'saved-state', 'name': profile['state'].toString()};
        if (!_states.any((item) => item['name'] == _state!['name']))
          _states = [..._states, _state!];
      }
      if (matchingVehicle is Map) {
        final existing = Map<String, dynamic>.from(matchingVehicle);
        _vehicleType ??= _find(_vehicleTypes, existing['vehicle_type_id']);
        _segment ??= _find(_segments, existing['vehicle_type_model_id']);
        _make ??= _find(_makes, existing['make_id']);
        _model ??= _find(_models, existing['brand_model_id']);
        _color ??= _find(_colors, existing['color_id']);
        _emission ??= _find(_emissions, existing['emission_standard_id']);
        if (_fuel.isEmpty) _fuel = (existing['fuel_type'] ?? '').toString();
        _wheel = (existing['wheel_type'] ?? _wheel).toString();
      }
    });
    _autoFillVehicleFromModel(_model);
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, dynamic id) {
    if (id == null || id.toString().isEmpty) return null;
    for (final item in list) {
      if (item['id']?.toString() == id.toString()) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> get _visibleSegments => _segments
      .where(
        (item) =>
            _vehicleType == null ||
            item['vehicle_type_id']?.toString() ==
                _vehicleType!['id']?.toString(),
      )
      .toList();
  List<Map<String, dynamic>> get _visibleMakes => _makes
      .where(
        (item) =>
            _model == null ||
            item['id']?.toString() == _model!['make_id']?.toString(),
      )
      .toList();
  List<Map<String, dynamic>> get _visibleModels => _models.where((item) {
    final matchesMake =
        _make == null ||
        item['make_id']?.toString() == _make!['id']?.toString();
    final matchesSegment =
        _segment == null ||
        item['vehicle_type_model_id']?.toString() ==
            _segment!['id']?.toString();
    return matchesMake && matchesSegment;
  }).toList();

  void _autoFillVehicleFromModel(Map<String, dynamic>? model) {
    if (model == null) return;
    final make = _find(_makes, model['make_id']);
    final segment = _find(_segments, model['vehicle_type_model_id']);
    setState(() {
      _make = make ?? _make;
      _segment = segment ?? _segment;
      _vehicleType =
          _find(_vehicleTypes, segment?['vehicle_type_id']) ?? _vehicleType;
    });
  }

  String? _required(String? value, String field) =>
      value == null || value.trim().isEmpty ? '$field is required' : null;

  Future<void> _continue() async {
    if (_tabs.index == 0) {
      if (!_validateProfile()) return;
      _tabs.animateTo(1);
      return;
    }
    if (_tabs.index == 1) {
      if (!_validateVehicle()) return;
      _tabs.animateTo(2);
      return;
    }
    if (_tabs.index == 2) {
      _tabs.animateTo(3);
      return;
    }
    if (_tabs.index == 3) {
      _tabs.animateTo(4);
      return;
    }
    if (_tabs.index == 4) {
      if (_selectedPricingService == null && _leadServices.isNotEmpty) {
        _prefillPricingServiceFromLead(_leadServices.first);
      }
      _tabs.animateTo(5);
      return;
    }
    if (_tabs.index == 5) {
      _tabs.animateTo(6);
      return;
    }
    if (_tabs.index == 6) {
      await _save();
      return;
    }
  }

  bool _validateVehicle() {
    if (_plate.text.trim().isEmpty ||
        _make == null ||
        _model == null ||
        _segment == null) {
      _snack(
        'Vehicle number, make, model and segment are required',
        error: true,
      );
      return false;
    }
    return true;
  }

  bool _validateProfile() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final corporateValid =
        !_isCorporate ||
        (_tax.text.trim().isNotEmpty &&
            _tin.text.trim().isNotEmpty &&
            _pan.text.trim().isNotEmpty);
    final requiredValid =
        _name.text.trim().isNotEmpty &&
        _phone.text.trim().isNotEmpty &&
        _customerType != null &&
        _state != null &&
        _city.text.trim().isNotEmpty;
    if (!requiredValid || !corporateValid || !formValid) {
      _snack(
        _isCorporate && !corporateValid
            ? 'Tax Registration No, TIN and PAN are required for corporate customers'
            : 'Complete the required customer profile fields',
        error: true,
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validateProfile()) {
      _tabs.animateTo(0);
      return;
    }
    if (!_validateVehicle()) {
      _tabs.animateTo(1);
      return;
    }
    final hasActivities = _reportedIssues.any(
      (row) => (row['activities'] as List? ?? []).isNotEmpty,
    );
    if (_reportedIssues.isEmpty &&
        _services.isEmpty &&
        _accessories.isEmpty &&
        _extras.isEmpty &&
        _labourCharges.isEmpty &&
        !hasActivities) {
      _tabs.animateTo(6);
      _snack(
        'Add at least one service, extra, or issue before saving',
        error: true,
      );
      return;
    }
    for (var i = 0; i < _reportedIssues.length; i++) {
      final row = _reportedIssues[i];
      final rate = _numberValue(row['rate']);
      final quantity = double.tryParse((row['quantity'] ?? '').toString());
      final discount = _numberValue(row['discount']);
      if (rate < 0 || quantity == null || quantity <= 0 || discount < 0) {
        _tabs.animateTo(6);
        _snack(
          'Check rate, quantity, and discount for service ${i + 1}',
          error: true,
        );
        return;
      }
    }
    for (final row in _services) {
      final rate = _numberValue(row['rate']);
      final quantity = double.tryParse((row['quantity'] ?? '').toString());
      final discount = _numberValue(row['discount']);
      if (rate < 0 || quantity == null || quantity <= 0 || discount < 0) {
        _tabs.animateTo(6);
        _snack(
          'Check rate, quantity, and discount in requested services',
          error: true,
        );
        return;
      }
    }
    for (final row in _accessories) {
      final rate = _numberValue(row['rate'] ?? row['price']);
      final quantity = double.tryParse((row['quantity'] ?? '').toString());
      final discount = _numberValue(row['discount']);
      if (rate < 0 || quantity == null || quantity <= 0 || discount < 0) {
        _tabs.animateTo(5);
        _snack(
          'Check rate, quantity, and discount in accessories',
          error: true,
        );
        return;
      }
    }
    for (final row in [..._extras, ..._labourCharges]) {
      final rate = _numberValue(row['rate'] ?? row['price']);
      final quantity = double.tryParse((row['quantity'] ?? '').toString());
      final discount = _numberValue(row['discount']);
      if (rate < 0 || quantity == null || quantity <= 0 || discount < 0) {
        _tabs.animateTo(6);
        _snack(
          'Check rate, quantity, and discount in extras and labour',
          error: true,
        );
        return;
      }
      if ((row['line_type'] == 'quote_form' || row['line_type'] == 'labour') &&
          (row['name'] ?? '').toString().trim().isEmpty) {
        _tabs.animateTo(6);
        _snack('Enter a name for each extra and labour charge', error: true);
        return;
      }
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final finalInspection = Map<String, dynamic>.from(_inspectionDetails);
      final damagePayload = _damageInspectionCtrl.getInspectionPayload();
      finalInspection.addAll(damagePayload);

      final payload = <String, dynamic>{
        if (widget.lead?['id'] != null && widget.lead!['id'].toString().isNotEmpty)
          'lead_id': widget.lead!['id'],
        if (widget.lead?['branch_id'] != null && widget.lead!['branch_id'].toString().isNotEmpty)
          'branch_id': widget.lead!['branch_id'],
        'customer_profile': {
          'name': _name.text.trim(),
          'customer_type_id': (_customerType?['id'] ?? '').toString().isNotEmpty ? _customerType!['id'] : null,
          'phone': _phone.text.trim(),
          'whatsapp': _whatsapp.text.trim(),
          'email': _email.text.trim(),
          'state': _state?['name'] ?? '',
          'city': _city.text.trim(),
          'tax_number': _tax.text.trim(),
          'tin_number': _tin.text.trim(),
          'pan_number': _pan.text.trim(),
        },
        'customer_comments': _comments.text.trim(),
        'engine_number': _engineNumber.text.trim(),
        'chassis_number': _chassisNumber.text.trim(),
        'vehicle_details': {
          'vehicle_number': _plate.text.trim(),
          'engine_number': _engineNumber.text.trim(),
          'chassis_number': _chassisNumber.text.trim(),
          'vehicle_type_id': (_vehicleType?['id'] ?? '').toString().isNotEmpty ? _vehicleType!['id'] : null,
          'segment_id': (_segment?['id'] ?? '').toString().isNotEmpty ? _segment!['id'] : null,
          'make_id': (_make?['id'] ?? '').toString().isNotEmpty ? _make!['id'] : null,
          'brand_model_id': (_model?['id'] ?? '').toString().isNotEmpty ? _model!['id'] : null,
          'color_id': (_color?['id'] ?? '').toString().isNotEmpty ? _color!['id'] : null,
          'emission_standard_id': (_emission?['id'] ?? '').toString().isNotEmpty ? _emission!['id'] : null,
          'fuel_type': _fuel,
          'wheel_type': _wheel,
        },
        'items': [
          ..._accessories.map(
            (row) => {
              if (row['id'] != null && row['id'].toString().isNotEmpty) 'id': row['id'],
              'line_type': 'accessory',
              if ((row['stock_item_id'] ?? '').toString().isNotEmpty)
                'stock_item_id': row['stock_item_id'],
              'stock_item_name': row['stock_item_name'],
              'rate': _numberValue(row['rate']),
              'quantity': double.parse((row['quantity'] ?? '1').toString()),
              'discount': _numberValue(row['discount']),
              'warranty_years': double.parse(
                (row['warranty_years'] ?? '0').toString(),
              ),
              'remarks': row['remarks'] ?? '',
            },
          ),
          ..._services.map(
            (row) => {
              if (row['id'] != null && row['id'].toString().isNotEmpty) 'id': row['id'],
              'line_type': 'service',
              if ((row['service_id'] ?? '').toString().isNotEmpty)
                'service_id': row['service_id'],
              'service_name': row['service_name'],
              'rate': _numberValue(row['rate']),
              'quantity': double.parse((row['quantity'] ?? '1').toString()),
              'discount': _numberValue(row['discount']),
              'warranty_years':
                  double.tryParse(
                    (row['warranty'] ?? row['warranty_years'] ?? '0')
                        .toString(),
                  ) ??
                  0.0,
              'remarks': row['remarks'] ?? '',
            },
          ),
        ],
        'extras': _extras
            .map(
              (row) => {
                if (row['id'] != null && row['id'].toString().isNotEmpty) 'id': row['id'],
                'line_type': 'quote_form',
                'name': row['name'] ?? '',
                'price': _numberValue(row['price']),
                'quantity': double.parse((row['quantity'] ?? '1').toString()),
                'discount': _numberValue(row['discount']),
                'remarks': row['remarks'] ?? '',
              },
            )
            .toList(),
        'labour_charges': [
          ..._reportedIssues.expand((report) {
            final activities = report['activities'] as List? ?? [];
            final serviceName = report['service']?['name'] ?? report['issue_text'] ?? 'Service';
            return activities.map((raw) {
              final act = raw as Map;
              final cost = double.tryParse((act['cost'] ?? '').toString()) ?? 0.0;
              final discount = double.tryParse((act['discount'] ?? '').toString()) ?? 0.0;
              return {
                'name': '$serviceName · ${act['name']}',
                'price': cost,
                'discount': discount,
                'remarks': (act['remarks'] ?? '').toString(),
              };
            });
          }),
          ..._labourCharges.map(
            (row) => {
              if (row['id'] != null && row['id'].toString().isNotEmpty) 'id': row['id'],
              'name': row['name'] ?? '',
              'price': _numberValue(row['price'] ?? row['cost']),
              'discount': _numberValue(row['discount']),
              'remarks': row['remarks'] ?? '',
            },
          ),
        ],
        'reported_issues': _reportedIssues
            .map(
              (row) => {
                if (row['report_id'] != null && row['report_id'].toString().isNotEmpty)
                  'report_id': row['report_id'],
                if ((row['category']?['id'] ?? '').toString().isNotEmpty)
                  'category_id': row['category']['id'],
                'category_name': row['category']?['name'] ?? '',
                if ((row['service']?['id'] ?? '').toString().isNotEmpty)
                  'service_id': row['service']['id'],
                'service_name': row['service']?['name'] ?? '',
                if ((row['issue']?['id'] ?? '').toString().isNotEmpty)
                  'issue_id': row['issue']['id'],
                'issue_text': row['issue_text'] ?? row['service']?['name'] ?? '',
                'rate': _numberValue(row['rate']),
                'quantity': double.parse((row['quantity'] ?? '1').toString()),
                'discount': _numberValue(row['discount']),
                'activities': (row['activities'] as List? ?? []).map((raw) {
                  final act = raw as Map;
                  return {
                    'name': act['name'] ?? '',
                    'cost': double.tryParse((act['cost'] ?? '').toString()) ?? 0.0,
                    'discount': double.tryParse((act['discount'] ?? '').toString()) ?? 0.0,
                    if (act['remarks'] != null) 'remarks': act['remarks'],
                  };
                }).toList(),
                'keep_photo_ids': (row['existing_photos'] as List? ?? [])
                    .map((photo) => (photo as Map)['id'].toString())
                    .where((id) => id.isNotEmpty)
                    .toList(),
              },
            )
            .toList(),
        'internal_notes': _internalNotes.text.trim(),
        'inspection_details': finalInspection,
        'inspection_at': _inspectionAt?.toUtc().toIso8601String(),
        'days_needed': _daysNeededCtrl.text.trim(),
        'additional_days_needed':
            int.tryParse(
              _daysNeededCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'tentative_delivery_at': _tentativeDeliveryAt
            ?.toUtc()
            .toIso8601String(),
        'prepared_by_id': (_preparedBy?['id'] ?? '').toString().isNotEmpty ? _preparedBy!['id'] : null,
        'subtotal': _calculateSubtotal(),
        'tax_percentage': _calculateTaxPercent(),
        'tax_amount': _calculateSubtotal() * (_calculateTaxPercent() / 100.0),
        'discount': 0,
        'grand_total': _calculateSubtotal() + (_calculateSubtotal() * (_calculateTaxPercent() / 100.0)),
        'is_grand_total': true,
      };
      final result = widget.existingQuotation != null
          ? await ApiService.updateJobQuotation(
              widget.existingQuotation!['id'].toString(),
              {
                'customer_profile': payload['customer_profile'],
                'vehicle_details': payload['vehicle_details'],
                'engine_number': payload['engine_number'],
                'chassis_number': payload['chassis_number'],
                'customer_comments': payload['customer_comments'],
                'reported_issues': payload['reported_issues'],
                'items': payload['items'],
                'extras': payload['extras'],
                'labour_charges': payload['labour_charges'],
                'internal_notes': payload['internal_notes'],
                'inspection_details': payload['inspection_details'],
                'inspection_at': payload['inspection_at'],
                'tentative_delivery_at': payload['tentative_delivery_at'],
                'days_needed': payload['days_needed'],
                'additional_days_needed': payload['additional_days_needed'],
                'prepared_by_id': payload['prepared_by_id'],
              },
              token,
              issuePhotos: _reportedIssues
                  .map((row) => List<XFile>.from(row['photos'] as List))
                  .toList(),
            )
          : await ApiService.createJobQuotation(
              {...payload, 'skip_whatsapp': true},
              token,
              issuePhotos: _reportedIssues
                  .map((row) => List<XFile>.from(row['photos'] as List))
                  .toList(),
            );
      if (!mounted) return;
      if (result['success'] != true)
        throw Exception(result['message'] ?? 'Unable to save quotation');
      if (widget.existingQuotation != null) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuotationViewScreen(
              quotationId: result['quotation_id'].toString(),
              jobWorkflow: true,
              autoSendWhatsapp: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.existingQuotation == null
              ? 'Create Job Quotation'
              : 'Edit Job Quotation',
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.white24,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          labelPadding: EdgeInsets.symmetric(horizontal: 18.w),
          tabs: const [
            Tab(text: 'Customer Profile'),
            Tab(text: 'Vehicle Details'),
            Tab(text: 'Inspection'),
            Tab(text: 'Inspection Summary'),
            Tab(text: 'Services & Complaints'),
            Tab(text: 'Accessories'),
            Tab(text: 'Pricing'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          : JobCardContent(
              padding: EdgeInsets.zero,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _customerTab(),
                          _vehicleTab(),
                          _inspectionTab(),
                          _inspectionSummaryTab(),
                          _issuesTab(),
                          _accessoriesTab(),
                          _serviceDetailsTab(),
                        ],
                      ),
                    ),
                    _footer(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _customerTab() => ListView(
    padding: REdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      _section('Customer Profile', Icons.person_outline, [
        JobCardResponsiveFields(
          children: [
            _input(
              _name,
              'Customer Name / Business *',
              validator: (v) => _required(v, 'Customer name'),
            ),
            _dropdown(
              _customerTypes,
              _customerType,
              'Customer Type *',
              (v) => setState(() => _customerType = v),
              validator: (v) => v == null ? 'Customer type is required' : null,
            ),
            _input(
              _phone,
              'Mobile No *',
              keyboard: TextInputType.phone,
              validator: (v) => _required(v, 'Mobile number'),
            ),
            _input(_whatsapp, 'WhatsApp No', keyboard: TextInputType.phone),
            _input(_email, 'Email Id', keyboard: TextInputType.emailAddress),
            _dropdown(
              _states,
              _state,
              'Emirate / State *',
              (v) => setState(() => _state = v),
              validator: (v) =>
                  v == null ? 'Emirate / State is required' : null,
            ),
            _input(_city, 'City *', validator: (v) => _required(v, 'City')),
            if (_isCorporate) ...[
              _input(
                _tax,
                'Tax Registration No *',
                validator: (v) => _required(v, 'Tax Registration No'),
              ),
              _input(
                _tin,
                'TIN No *',
                validator: (v) => _required(v, 'TIN No'),
              ),
              _input(
                _pan,
                'PAN No *',
                validator: (v) => _required(v, 'PAN No'),
              ),
            ],
          ],
        ),
      ]),
    ],
  );

  Widget _vehicleTab() => ListView(
    padding: REdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      _section('Vehicle Details', Icons.directions_car_outlined, [
        JobCardResponsiveFields(
          children: [
            _input(
              _plate,
              'Vehicle Number *',
              validator: (v) => _required(v, 'Vehicle number'),
            ),
            _input(_engineNumber, 'Engine Number'),
            _input(_chassisNumber, 'Chassis Number'),
            _dropdown(
              _vehicleTypes,
              _vehicleType,
              'Vehicle Type',
              (v) => setState(() {
                _vehicleType = v;
                _segment = null;
                _model = null;
              }),
            ),
            _dropdown(
              _visibleMakes,
              _make,
              'Make *',
              (v) => setState(() {
                _make = v;
                _model = null;
              }),
            ),
            _dropdown(_visibleModels, _model, 'Model *', (v) {
              setState(() => _model = v);
              _autoFillVehicleFromModel(v);
            }),
            _dropdown(
              _visibleSegments,
              _segment,
              'Segment *',
              (v) => setState(() {
                _segment = v;
                _model = null;
              }),
            ),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(top: 10.h),
          title: Text(
            'More vehicle details',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
          leading: const Icon(Icons.tune, color: Color(0xFF000080)),
          children: [
            JobCardResponsiveFields(
              children: [
                _dropdown(
                  _colors,
                  _color,
                  'Color',
                  (v) => setState(() => _color = v),
                ),
                _dropdown(
                  _emissions,
                  _emission,
                  'Emission Standard',
                  (v) => setState(() => _emission = v),
                ),
                _dropdown(
                  _fuelTypes,
                  _find(_fuelTypes, _fuel),
                  'Fuel Type',
                  (v) => setState(() => _fuel = v?['id']?.toString() ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: _wheel,
                  decoration: const InputDecoration(labelText: 'Wheel Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'normal_wheel',
                      child: Text('Normal Wheel'),
                    ),
                    DropdownMenuItem(
                      value: 'alloy_wheel',
                      child: Text('Alloy Wheel'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _wheel = v ?? 'normal_wheel'),
                ),
              ],
            ),
          ],
        ),
      ]),
    ],
  );

  List<Map<String, dynamic>> get _categoryServices => _jobCardServices
      .where(
        (item) =>
            item['category_id']?.toString() ==
            _jobCardCategory?['id']?.toString(),
      )
      .toList();

  List<Map<String, dynamic>> get _serviceIssues => _jobCardIssues
      .where(
        (item) =>
            item['service_id']?.toString() ==
            _jobCardService?['id']?.toString(),
      )
      .toList();

  Widget _issueSuggestions() {
    if (_jobCardService == null || _jobCardIssue != null) {
      return const SizedBox.shrink();
    }
    final query = _issueText.text.trim().toLowerCase();
    final matches = _serviceIssues
        .where(
          (item) =>
              (item['name'] ?? '').toString().toLowerCase().contains(query),
        )
        .take(6)
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: matches
            .map(
              (issue) => ListTile(
                dense: true,
                title: Text(issue['name']?.toString() ?? ''),
                onTap: () => setState(() {
                  _jobCardIssue = issue;
                  _issueText.text = issue['name'].toString();
                }),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _selectJobCategory(Map<String, dynamic> category) async {
    final hasDraft =
        _jobCardService != null ||
        _issueText.text.trim().isNotEmpty ||
        _issuePhotos.isNotEmpty;
    if (hasDraft) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change category?'),
          content: const Text(
            'The current issue entry has not been added yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard entry'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() {
      _jobCardCategory = category;
      _jobCardService = null;
      _jobCardIssue = null;
      _issueText.clear();
      _issuePhotos = [];
      _editingIssueIndex = null;
    });
  }

  TextEditingController _activityController(Map<String, dynamic> row) =>
      row.putIfAbsent('_activityController', TextEditingController.new)
          as TextEditingController;

  FocusNode _activityFocusNode(Map<String, dynamic> row) =>
      row.putIfAbsent('_activityFocusNode', FocusNode.new) as FocusNode;

  List<Widget> _reportedActivitySuggestions(Map<String, dynamic> row) {
    final query = _activityController(row).text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final serviceId = row['service']?['id']?.toString();
    final allMatching = _activityChoices
        .where(
          (item) =>
              (item['name'] ?? '').toString().toLowerCase().contains(query),
        )
        .toList();

    allMatching.sort((a, b) {
      final aSameService = a['service_id']?.toString() == serviceId;
      final bSameService = b['service_id']?.toString() == serviceId;
      if (aSameService && !bSameService) return -1;
      if (!aSameService && bSameService) return 1;
      return (a['name'] ?? '').toString().compareTo(
        (b['name'] ?? '').toString(),
      );
    });

    final seen = <String>{};
    final matches = <Map<String, dynamic>>[];
    for (final item in allMatching) {
      final nameLower = (item['name'] ?? '').toString().toLowerCase();
      if (!seen.contains(nameLower)) {
        seen.add(nameLower);
        matches.add(item);
        if (matches.length >= 8) break;
      }
    }
    if (matches.isEmpty) return const [];
    return [
      Container(
        constraints: BoxConstraints(maxHeight: 180.h),
        margin: EdgeInsets.only(top: 4.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final option = matches[index];
            return ListTile(
              dense: true,
              title: Text(option['name'].toString()),
              onTap: () {
                _activityController(row).text = option['name'].toString();
                setState(() {});
                _activityFocusNode(row).requestFocus();
              },
            );
          },
        ),
      ),
    ];
  }

  Future<void> _appendReportedActivity(Map<String, dynamic> row) async {
    final controller = _activityController(row);
    final name = controller.text.trim();
    final service = row['service'] as Map?;
    final token = context.read<AuthProvider>().token;
    if (name.isEmpty || service == null || token == null) return;
    try {
      final response = await ApiService.createJobCardActivityOption({
        'service_id': service['id'],
        'name': name,
      }, token);
      if (response['success'] != true) {
        _snack(
          response['message']?.toString() ?? 'Unable to save activity',
          error: true,
        );
        return;
      }
      final option = Map<String, dynamic>.from(response['activity'] as Map);
      if (!_activityChoices.any(
        (item) => item['id']?.toString() == option['id']?.toString(),
      )) {
        _activityChoices = [..._activityChoices, option];
      }
      setState(() {
        final activities = List<Map<String, dynamic>>.from(
          row['activities'] as List? ?? [],
        );
        activities.add({'name': option['name']});
        row['activities'] = activities;
        controller.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activityFocusNode(row).requestFocus();
      });
    } catch (error) {
      _snack('Unable to save activity: $error', error: true);
    }
  }

  Future<Map<String, dynamic>?> _searchJobMaster(
    String title,
    List<Map<String, dynamic>> options,
    Map<String, dynamic>? selected, {
    Future<Map<String, dynamic>?> Function(String query)? onAddNew,
  }) async {
    var queryText = '';
    var isAdding = false;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) {
          final query = queryText.trim().toLowerCase();
          final filtered = options
              .where(
                (item) => (item['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query),
              )
              .toList();
          final hasExact = options.any(
            (item) =>
                (item['name'] ?? '').toString().trim().toLowerCase() == query,
          );
          final showAddButton =
              onAddNew != null && query.isNotEmpty && !hasExact;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.62,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => refresh(() => queryText = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search $title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    if (showAddButton) ...[
                      SizedBox(height: 8.h),
                      ListTile(
                        leading: isAdding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.add_circle,
                                color: Color(0xFF000080),
                              ),
                        title: Text(
                          'Add "${queryText.trim()}"',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF000080),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text('Save new $title to database'),
                        onTap: isAdding
                            ? null
                            : () async {
                                refresh(() => isAdding = true);
                                final created = await onAddNew(
                                  queryText.trim(),
                                );
                                if (created != null && sheetContext.mounted) {
                                  Navigator.pop(sheetContext, created);
                                } else {
                                  refresh(() => isAdding = false);
                                }
                              },
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Expanded(
                      child: filtered.isEmpty && !showAddButton
                          ? Center(
                              child: Text(
                                'No matching $title found',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final option = filtered[index];
                                final isSelected =
                                    option['id']?.toString() ==
                                    selected?['id']?.toString();
                                return ListTile(
                                  title: Text(option['name']?.toString() ?? ''),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Color(0xFF000080),
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(sheetContext, option),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (!mounted) return null;
    return result;
  }

  Future<void> _pickIssuePhotos({required bool camera}) async {
    final remaining = 3 - _issuePhotos.length - _existingIssuePhotos.length;
    if (remaining <= 0) {
      _snack('Each reported issue can have up to 3 photos', error: true);
      return;
    }
    try {
      if (camera) {
        final photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 82,
          maxWidth: 1800,
        );
        if (photo != null && mounted)
          setState(() => _issuePhotos = [..._issuePhotos, photo]);
      } else {
        final photos = await _imagePicker.pickMultiImage(
          imageQuality: 82,
          maxWidth: 1800,
        );
        if (!mounted || photos.isEmpty) return;
        final selected = photos.take(remaining).toList();
        setState(() => _issuePhotos = [..._issuePhotos, ...selected]);
        if (photos.length > remaining)
          _snack('Only 3 photos are allowed per issue');
      }
    } catch (e) {
      if (mounted) _snack('Unable to select photo: $e', error: true);
    }
  }

  Widget _inspectionTab() => InspectionTabView(
    controller: _damageInspectionCtrl,
    onAddService: (serviceData) {
      final serviceName = serviceData['name']?.toString() ?? 'Service';
      setState(() {
        _reportedIssues.add({
          'client_key': 'inspect-${DateTime.now().microsecondsSinceEpoch}',
          '_pricingKey': Object(),
          '_activityKey': Object(),
          'category': serviceData['category'],
          'service': serviceData['service'],
          'issue': {
            'id': '',
            'name': serviceName,
          },
          'issue_text': serviceName,
          'rate': (serviceData['rate'] ?? '').toString(),
          'quantity': '1',
          'discount': '',
          'warranty': '',
          'remarks': '',
          'activities': <Map<String, dynamic>>[],
          'photos': <XFile>[],
          'existing_photos': <Map<String, dynamic>>[],
        });
      });
      _snack("Added '$serviceName' to Services & Complaints");
    },
  );

  Widget _inspectionSummaryTab() => InspectionSummaryTabView(
    controller: _damageInspectionCtrl,
  );

  Future<void> _addReportedIssue() async {
    final category = _jobCardCategory;
    final service = _jobCardService;
    if (category == null || service == null) {
      _snack('Select a category and service', error: true);
      return;
    }
    final name = _issueText.text.trim().isEmpty
        ? (service['name']?.toString() ?? 'Service')
        : _issueText.text.trim();
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      var issue = _jobCardIssue;
      if (issue == null ||
          issue['name'].toString().toLowerCase() != name.toLowerCase()) {
        final response = await ApiService.createJobCardIssue({
          'category_id': category['id'],
          'service_id': service['id'],
          'name': name,
        }, token);
        if (response['success'] != true)
          throw Exception(response['message'] ?? 'Unable to save issue');
        issue = Map<String, dynamic>.from(response['issue'] as Map);
        if (!_jobCardIssues.any(
          (item) => item['id']?.toString() == issue!['id']?.toString(),
        )) {
          _jobCardIssues = [..._jobCardIssues, issue];
        }
      }
      final previousRow = _editingIssueIndex == null
          ? <String, dynamic>{}
          : _reportedIssues[_editingIssueIndex!];
      final defaultRate =
          (service['rate'] ??
                  service['price'] ??
                  service['standard_rate'] ??
                  '')
              .toString();
      final rateValue =
          (previousRow['rate'] != null &&
              previousRow['rate'].toString().isNotEmpty)
          ? previousRow['rate'].toString()
          : defaultRate;
      final row = <String, dynamic>{
        ...previousRow,
        '_pricingKey': previousRow['_pricingKey'] ?? Object(),
        '_activityKey': previousRow['_activityKey'] ?? Object(),
        'rate': rateValue,
        'quantity': (previousRow['quantity'] ?? '1').toString(),
        'discount': (previousRow['discount'] ?? '').toString(),
        if (_editingIssueIndex != null &&
            _reportedIssues[_editingIssueIndex!]['report_id'] != null)
          'report_id': _reportedIssues[_editingIssueIndex!]['report_id'],
        'category': category,
        'service': service,
        'issue': issue,
        'issue_text': name,
        'activities': List<Map<String, dynamic>>.from(
          previousRow['activities'] as List? ?? [],
        ),
        'photos': List<XFile>.from(_issuePhotos),
        'existing_photos': List<Map<String, dynamic>>.from(
          _existingIssuePhotos,
        ),
      };
      setState(() {
        if (_editingIssueIndex == null) {
          _reportedIssues.add(row);
        } else {
          _reportedIssues[_editingIssueIndex!] = row;
        }
        _issueText.clear();
        _issuePhotos = [];
        _existingIssuePhotos = [];
        _jobCardService = null;
        _jobCardIssue = null;
        _editingIssueIndex = null;
      });
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editReportedIssue(int index) {
    final row = _reportedIssues[index];
    setState(() {
      _editingIssueIndex = index;
      _jobCardCategory = Map<String, dynamic>.from(row['category'] as Map);
      _jobCardService = Map<String, dynamic>.from(row['service'] as Map);
      _jobCardIssue = Map<String, dynamic>.from(row['issue'] as Map);
      _issueText.text = row['issue_text'].toString();
      _issuePhotos = List<XFile>.from(row['photos'] as List);
      _existingIssuePhotos = List<Map<String, dynamic>>.from(
        row['existing_photos'] as List? ?? [],
      );
    });
  }

  void _deleteReportedIssue(int index) {
    setState(() {
      final removed = _reportedIssues.removeAt(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        (removed['_activityController'] as TextEditingController?)?.dispose();
        (removed['_activityFocusNode'] as FocusNode?)?.dispose();
      });
      if (_editingIssueIndex == index) {
        _editingIssueIndex = null;
        _jobCardService = null;
        _jobCardIssue = null;
        _issueText.clear();
        _issuePhotos = [];
        _existingIssuePhotos = [];
      } else if (_editingIssueIndex != null && _editingIssueIndex! > index) {
        _editingIssueIndex = _editingIssueIndex! - 1;
      }
    });
  }

  double _serviceLineTotal(Map<String, dynamic> row) {
    final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0;
    final quantity = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1;
    final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0;
    return (rate * quantity - discount).clamp(0, double.infinity).toDouble();
  }

  void _prefillPricingServiceFromLead(Map<String, dynamic> interest) {
    final sName = (interest['service_name'] ?? '').toString().trim();
    final cName = (interest['category_name'] ?? '').toString().trim();
    final sId = (interest['service_id'] ?? '').toString().trim();
    final expectedVal = interest['expected_value'];

    Map<String, dynamic>? matchedService;
    if (sId.isNotEmpty) {
      matchedService = _pricingAvailableServices
          .where((s) => s['id']?.toString() == sId)
          .firstOrNull;
    }
    if (matchedService == null && sName.isNotEmpty) {
      matchedService = _pricingAvailableServices
          .where(
            (s) =>
                (s['name'] ?? '').toString().trim().toLowerCase() ==
                sName.toLowerCase(),
          )
          .firstOrNull;
    }
    if (matchedService == null && sName.isNotEmpty) {
      matchedService = _pricingAvailableServices
          .where(
            (s) =>
                (s['name'] ?? '').toString().toLowerCase().contains(
                  sName.toLowerCase(),
                ) ||
                sName.toLowerCase().contains(
                  (s['name'] ?? '').toString().toLowerCase(),
                ),
          )
          .firstOrNull;
    }

    Map<String, dynamic>? matchedCategory;
    if (matchedService != null && matchedService['category_id'] != null) {
      matchedCategory = _pricingServiceCategories
          .where(
            (c) =>
                c['id']?.toString() ==
                matchedService!['category_id']?.toString(),
          )
          .firstOrNull;
    }
    if (matchedCategory == null && cName.isNotEmpty) {
      matchedCategory = _pricingServiceCategories
          .where(
            (c) =>
                (c['name'] ?? '').toString().trim().toLowerCase() ==
                cName.toLowerCase(),
          )
          .firstOrNull;
    }
    if (matchedCategory == null && cName.isNotEmpty) {
      matchedCategory = _pricingServiceCategories
          .where(
            (c) =>
                (c['name'] ?? '').toString().toLowerCase().contains(
                  cName.toLowerCase(),
                ) ||
                cName.toLowerCase().contains(
                  (c['name'] ?? '').toString().toLowerCase(),
                ),
          )
          .firstOrNull;
    }

    matchedCategory ??= _pricingServiceCategories.firstOrNull;
    if (matchedCategory != null) {
      _selectedPricingCategory = matchedCategory['id']?.toString();
    }

    if (matchedService != null) {
      _selectedPricingService = matchedService;
      final svcRate = matchedService['rate'];
      if (expectedVal != null &&
          (double.tryParse(expectedVal.toString()) ?? 0) > 0) {
        _serviceRateCtrl.text = expectedVal.toString();
      } else if (svcRate != null &&
          (double.tryParse(svcRate.toString()) ?? 0) > 0) {
        _serviceRateCtrl.text = svcRate.toString();
      }
    } else if (sName.isNotEmpty) {
      _selectedPricingService = {
        'id': sId,
        'name': sName,
        'category_id': _selectedPricingCategory,
        'rate': expectedVal ?? 0,
      };
      if (expectedVal != null &&
          (double.tryParse(expectedVal.toString()) ?? 0) > 0) {
        _serviceRateCtrl.text = expectedVal.toString();
      }
    }
  }

  void _addLabourCharge() {
    final name = _labourNameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter labour description', error: true);
      return;
    }
    final rate = double.tryParse(_labourRateCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_labourQtyCtrl.text.trim()) ?? 1.0;
    final disc = double.tryParse(_labourDiscountCtrl.text.trim()) ?? 0.0;
    final base = (rate * qty) - disc;
    final total = base > 0 ? base : 0.0;

    setState(() {
      _labourCharges.add({
        'line_type': 'labour',
        'name': name,
        'rate': rate.toString(),
        'price': rate.toString(),
        'quantity': qty.toString(),
        'discount': disc.toString(),
        'total_amount': total,
        'total': total,
        'remarks': _labourRemarksCtrl.text.trim(),
      });
      _labourNameCtrl.text = 'Labour Charge';
      _labourRateCtrl.clear();
      _labourQtyCtrl.text = '1';
      _labourDiscountCtrl.text = '0';
      _labourRemarksCtrl.clear();
    });
  }

  void _addExtra() {
    final name = _extraNameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Enter extra description', error: true);
      return;
    }
    final rate = double.tryParse(_extraRateCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_extraQtyCtrl.text.trim()) ?? 1.0;
    final disc = double.tryParse(_extraDiscountCtrl.text.trim()) ?? 0.0;
    final base = (rate * qty) - disc;
    final total = base > 0 ? base : 0.0;

    setState(() {
      _extras.add({
        'line_type': 'quote_form',
        'name': name,
        'rate': rate.toString(),
        'price': rate.toString(),
        'quantity': qty.toString(),
        'discount': disc.toString(),
        'total_amount': total,
        'total': total,
        'remarks': _extraRemarksCtrl.text.trim(),
      });
      _extraNameCtrl.clear();
      _extraRateCtrl.clear();
      _extraQtyCtrl.text = '1';
      _extraDiscountCtrl.text = '0';
      _extraRemarksCtrl.clear();
    });
  }

  double _issueLineTotal(Map<String, dynamic> row) {
    final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0;
    final quantity = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1;
    final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0;
    return (rate * quantity - discount).clamp(0, double.infinity).toDouble();
  }

  double _pricedRowTotal(Map<String, dynamic> row, {required bool extra}) {
    final rate =
        double.tryParse(
          (extra ? row['price'] : row['rate'] ?? '0').toString(),
        ) ??
        0;
    final quantity = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1;
    final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0;
    return (rate * quantity - discount).clamp(0, double.infinity).toDouble();
  }

  double get _entryAccessoryTotal {
    final rate = double.tryParse(_accessoryRateCtrl.text.trim()) ?? 0.0;
    final qty = double.tryParse(_accessoryQtyCtrl.text.trim()) ?? 1.0;
    final discount = double.tryParse(_accessoryDiscountCtrl.text.trim()) ?? 0.0;
    return ((rate * qty) - discount).clamp(0.0, double.infinity);
  }

  void _clearAccessoryEntryBar() {
    setState(() {
      _entryAccessoryItem = null;
      _accessoryRateCtrl.text = '0.00';
      _accessoryQtyCtrl.text = '1';
      _accessoryDiscountCtrl.text = '0.00';
      _editingAccessoryIndex = null;
    });
  }

  void _onAddOrUpdateAccessory() {
    if (_entryAccessoryItem == null) {
      _snack(context.tr('Please select a stock item first'), error: true);
      return;
    }

    final qty = double.tryParse(_accessoryQtyCtrl.text.trim()) ?? 0.0;
    if (qty <= 0) {
      _snack(context.tr('Quantity must be greater than 0'), error: true);
      return;
    }

    final rate = _accessoryRateCtrl.text.trim();
    final disc = _accessoryDiscountCtrl.text.trim();

    setState(() {
      if (_editingAccessoryIndex != null && _editingAccessoryIndex! < _accessories.length) {
        final row = _accessories[_editingAccessoryIndex!];
        row['rate'] = rate;
        row['quantity'] = qty.toString();
        row['discount'] = disc;
        if (_entryAccessoryItem != null) {
          row['stock_item_id'] = _entryAccessoryItem!['id'] ?? row['stock_item_id'];
          row['stock_item_name'] = _entryAccessoryItem!['product_name'] ?? _entryAccessoryItem!['name'] ?? row['stock_item_name'];
          row['product_code'] = _entryAccessoryItem!['product_code'] ?? _entryAccessoryItem!['part_number'] ?? row['product_code'];
          row['part_number'] = _entryAccessoryItem!['part_number'] ?? _entryAccessoryItem!['product_code'] ?? row['part_number'];
        }
      } else {
        _accessories.add({
          'line_type': 'accessory',
          'stock_item_id': _entryAccessoryItem!['id'],
          'stock_item_name': _entryAccessoryItem!['product_name'] ?? _entryAccessoryItem!['name'] ?? 'Accessory',
          'product_code': _entryAccessoryItem!['product_code'] ?? _entryAccessoryItem!['part_number'] ?? '',
          'part_number': _entryAccessoryItem!['part_number'] ?? _entryAccessoryItem!['product_code'] ?? '',
          'rate': rate,
          'quantity': qty.toString(),
          'discount': disc,
          'warranty_years': '0',
          'remarks': '',
        });
      }
      _clearAccessoryEntryBar();
    });
  }

  void _onEditAccessoryRow(int index) {
    if (index >= _accessories.length) return;
    final row = _accessories[index];
    setState(() {
      _editingAccessoryIndex = index;
      _entryAccessoryItem = {
        'id': row['stock_item_id'],
        'product_name': row['stock_item_name'] ?? row['product_name'],
        'product_code': row['product_code'] ?? row['part_number'],
        'part_number': row['part_number'],
        'current_stock': row['current_stock'] ?? 0,
        'unit': row['unit'] ?? 'Pcs',
      };
      _accessoryRateCtrl.text = (row['rate'] ?? '0.00').toString();
      _accessoryQtyCtrl.text = (row['quantity'] ?? '1').toString();
      _accessoryDiscountCtrl.text = (row['discount'] ?? '0.00').toString();
    });
  }

  Widget _buildAccessoryQuickAddEntryBar() {
    final token = context.read<AuthProvider>().token ?? '';
    final hasItem = _entryAccessoryItem != null;
    final itemCode = (_entryAccessoryItem?['product_code'] ?? _entryAccessoryItem?['part_number'] ?? '').toString();
    final itemName = (_entryAccessoryItem?['product_name'] ?? _entryAccessoryItem?['name'] ?? '').toString();
    final brand = (_entryAccessoryItem?['brand_name'] ?? _entryAccessoryItem?['brand'] ?? '').toString();
    final stockVal = _entryAccessoryItem?['current_stock'] ?? _entryAccessoryItem?['stock'] ?? 0;
    final stockQty = (stockVal is num) ? stockVal.toDouble() : (double.tryParse(stockVal.toString()) ?? 0.0);
    final unit = (_entryAccessoryItem?['unit'] ?? _entryAccessoryItem?['unit_name'] ?? 'Pcs').toString();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Selector Header Bar
          InkWell(
            onTap: _saving ? null : () async {
              final selected = await showAccessoryPickerDialog(
                context: context,
                token: token,
              );
              if (selected != null) {
                setState(() {
                  _entryAccessoryItem = selected;
                  final defaultRate = selected['rate'] ?? selected['sales_rate'] ?? selected['price'] ?? 0.0;
                  final rateNum = (defaultRate is num) ? defaultRate.toDouble() : (double.tryParse(defaultRate.toString()) ?? 0.0);
                  if (rateNum > 0) {
                    _accessoryRateCtrl.text = rateNum.toStringAsFixed(2);
                  }
                  if (_accessoryQtyCtrl.text.isEmpty || _accessoryQtyCtrl.text == '0') {
                    _accessoryQtyCtrl.text = '1';
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: hasItem ? Colors.white : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: hasItem ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: const Color(0xFFD97706),
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: hasItem
                        ? Row(
                            children: [
                              if (itemCode.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    itemCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                              Expanded(
                                child: Text(
                                  brand.isNotEmpty ? '$itemName ($brand)' : itemName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  '${context.tr('Stock')}: ${stockQty.toStringAsFixed(1)} $unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            context.tr('product code/ part no/alternate no/product name'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  SizedBox(width: 4.w),
                  if (hasItem)
                    InkWell(
                      onTap: _clearAccessoryEntryBar,
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    )
                  else
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFD97706)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ── Row with Rate | Qty | Discount | Total | [Add/Update] Button ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rate
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Rate'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _accessoryRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Qty
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Qty'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _accessoryQtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Discount
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Discount'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextField(
                      controller: _accessoryDiscountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),

              // Total preview
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Total'),
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 38.h,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _entryAccessoryTotal.toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF000080),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // [ Add / Update ] Button
              ElevatedButton(
                onPressed: _onAddOrUpdateAccessory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editingAccessoryIndex != null ? Colors.green.shade800 : const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  elevation: 1,
                ),
                child: Text(
                  _editingAccessoryIndex != null ? context.tr('Update') : context.tr('Add'),
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPlanDate(bool inspection) async {
    final initial =
        (inspection ? _inspectionAt : _tentativeDeliveryAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      final selected = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (inspection) {
        _inspectionAt = selected;
      } else {
        _tentativeDeliveryAt = selected;
      }
    });
  }

  String _formatPlanDate(DateTime? value) => value == null
      ? 'Select date and time'
      : '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year} ${TimeOfDay.fromDateTime(value).format(context)}';



  Future<void> _showEditAccessoryDialog(Map<String, dynamic> row, int index) async {
    final rateCtrl = TextEditingController(text: (row['rate'] ?? '').toString());
    final qtyCtrl = TextEditingController(text: (row['quantity'] ?? '1').toString());
    final discCtrl = TextEditingController(text: (row['discount'] ?? '0').toString());
    final warCtrl = TextEditingController(text: (row['warranty_years'] ?? '0').toString());
    final remCtrl = TextEditingController(text: (row['remarks'] ?? '').toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF000080)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                (row['stock_item_name'] ?? row['product_name'] ?? 'Edit Item').toString(),
                style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rate', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: discCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Discount', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: warCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Warranty (years)', border: OutlineInputBorder()),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: remCtrl,
                decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () {
              setState(() {
                row['rate'] = rateCtrl.text.trim();
                row['quantity'] = qtyCtrl.text.trim();
                row['discount'] = discCtrl.text.trim();
                row['warranty_years'] = warCtrl.text.trim();
                row['remarks'] = remCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 12.5.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fontSize ?? 12.5.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? const Color(0xFF000080) : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  Widget _accessoriesScrollableTable(String currencySymbol, double accessoriesSubtotal) {
    if (_accessories.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36.sp, color: Colors.grey.shade400),
            SizedBox(height: 8.h),
            Text(
              'No accessories added yet',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select accessory above to add parts to this quotation.',
              style: GoogleFonts.inter(
                fontSize: 11.5.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final subtotal = _accessories.fold<double>(
      0.0,
      (sum, row) {
        final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0.0;
        final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
        return sum + (rate * qty);
      },
    );
    final totalDiscount = _accessories.fold<double>(
      0.0,
      (sum, row) => sum + (double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0),
    );
    final grandTotal = (subtotal - totalDiscount).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Container(
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      _tableHeaderCell('#', 36.w, textAlign: TextAlign.center),
                      _tableDivider(),
                      _tableHeaderCell(context.tr('Part Number'), 100.w),
                      _tableDivider(),
                      _tableHeaderCell('Item', 145.w),
                      _tableDivider(),
                      _tableHeaderCell('Rate', 75.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell('Qty', 55.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell('Discount', 70.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell('Total', 85.w, textAlign: TextAlign.right),
                      _tableDivider(),
                      _tableHeaderCell('', 65.w, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // Data Rows
                for (int i = 0; i < _accessories.length; i++) ...[
                  _tableDataRow(_accessories[i], i),
                  if (i < _accessories.length - 1)
                    Container(height: 1, color: Colors.grey.shade200),
                ],
                // Footer Total Row
                Container(
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      _tableCell('', 36.w),
                      _tableDivider(),
                      _tableCell('', 100.w),
                      _tableDivider(),
                      _tableCell('', 145.w),
                      _tableDivider(),
                      _tableCell('', 75.w),
                      _tableDivider(),
                      _tableCell('', 55.w),
                      _tableDivider(),
                      _tableCell('Total:', 70.w, textAlign: TextAlign.right, isBold: true),
                      _tableDivider(),
                      _tableCell(
                        grandTotal.toStringAsFixed(2),
                        85.w,
                        textAlign: TextAlign.right,
                        isBold: true,
                        textColor: const Color(0xFF000080),
                      ),
                      _tableDivider(),
                      _tableCell('', 65.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Subtotal, Discount, Grand Total Summary Card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildSummaryLine(
                context.tr('Subtotal'),
                '$currencySymbol ${subtotal.toStringAsFixed(2)}',
              ),
              if (totalDiscount > 0) ...[
                SizedBox(height: 6.h),
                _buildSummaryLine(
                  context.tr('Discount'),
                  '- $currencySymbol ${totalDiscount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFFDC2626),
                ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const Divider(height: 1, thickness: 1, color: Color(0xFFCBD5E1)),
              ),
              _buildSummaryLine(
                context.tr('Grand Total'),
                '$currencySymbol ${grandTotal.toStringAsFixed(2)}',
                isBold: true,
                valueColor: const Color(0xFF000080),
                fontSize: 14.sp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.grey.shade300,
    );
  }

  Widget _tableHeaderCell(
    String text,
    double width, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : (textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E293B),
        ),
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(
    String text,
    double width, {
    TextAlign textAlign = TextAlign.left,
    bool isBold = false,
    Color? textColor,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : (textAlign == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11.5.sp,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableDataRow(Map<String, dynamic> row, int index) {
    final isEven = index % 2 == 0;
    final isEditing = _editingAccessoryIndex == index;
    final partNumber = (row['part_number'] ?? row['product_code'] ?? '-').toString();
    final name = (row['stock_item_name'] ?? row['product_name'] ?? 'Accessory').toString();
    final rate = double.tryParse((row['rate'] ?? '0').toString()) ?? 0.0;
    final qty = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1.0;
    final discount = double.tryParse((row['discount'] ?? '0').toString()) ?? 0.0;
    final total = _pricedRowTotal(row, extra: false);

    return InkWell(
      onTap: () => _onEditAccessoryRow(index),
      onLongPress: () => _showEditAccessoryDialog(row, index),
      child: Container(
        height: 40.h,
        color: isEditing
            ? const Color(0xFFFEF3C7)
            : (isEven ? Colors.white : const Color(0xFFF8FAFC)),
        child: Row(
          children: [
            _tableCell('${index + 1}', 36.w, textAlign: TextAlign.center, textColor: Colors.grey.shade600),
            _tableDivider(),
            _tableCell(partNumber.isNotEmpty ? partNumber : '-', 100.w, isBold: true, textColor: const Color(0xFF000080)),
            _tableDivider(),
            _tableCell(name, 145.w),
            _tableDivider(),
            _tableCell(rate.toStringAsFixed(2), 75.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2), 55.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(discount.toStringAsFixed(2), 70.w, textAlign: TextAlign.right),
            _tableDivider(),
            _tableCell(total.toStringAsFixed(2), 85.w, textAlign: TextAlign.right, isBold: true, textColor: const Color(0xFF000080)),
            _tableDivider(),
            Container(
              width: 65.w,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _onEditAccessoryRow(index),
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(Icons.edit_outlined, size: 16.sp, color: const Color(0xFF000080)),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  InkWell(
                    onTap: () {
                      if (_editingAccessoryIndex == index) {
                        _clearAccessoryEntryBar();
                      } else if (_editingAccessoryIndex != null && _editingAccessoryIndex! > index) {
                        _editingAccessoryIndex = _editingAccessoryIndex! - 1;
                      }
                      setState(() => _accessories.removeAt(index));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(Icons.delete_outline, size: 16.sp, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _issuePriceInput(
    int index,
    String key,
    String label, {
    bool decimal = false,
    int maxLines = 1,
  }) {
    final row = _reportedIssues[index];
    final reportKey = row['report_id'] ?? row['issue_text'] ?? index;
    return TextFormField(
      key: ValueKey('quote-issue-field-$index-$key-$reportKey'),
      initialValue: (row[key] ?? (key == 'quantity' ? '1' : '')).toString(),
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          color: Colors.grey.shade700,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      onChanged: (value) {
        setState(() {
          row[key] = value;
        });
      },
    );
  }

  Widget _finalQuotationDetails() => _section(
    'Schedule & Sign-off',
    Icons.fact_check_outlined,
    [
      InkWell(
        onTap: () => _pickPlanDate(true),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Inspection Date & Time',
            prefixIcon: const Icon(Icons.fact_check_outlined, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          child: Text(
            _inspectionAt == null
                ? 'Select date and time'
                : _formatPlanDate(_inspectionAt),
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
        ),
      ),
      SizedBox(height: 12.h),
      TextField(
        controller: _daysNeededCtrl,
        decoration: InputDecoration(
          labelText: 'Days Needed',
          hintText: 'e.g. 2 Days, 3 Days',
          prefixIcon: const Icon(Icons.schedule, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
      SizedBox(height: 12.h),
      _input(_comments, 'Comment to client', maxLines: 3),
      SizedBox(height: 12.h),
      _input(_internalNotes, 'Internal notes', maxLines: 3),
      SizedBox(height: 12.h),
      _dropdown(
        _staff,
        _preparedBy,
        'Prepared by',
        (value) => setState(() => _preparedBy = value),
      ),
      if (_companySealUrl.isNotEmpty) ...[
        SizedBox(height: 12.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company seal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Image.network(_companySealUrl, height: 80.h, fit: BoxFit.contain),
          ],
        ),
      ],
      SizedBox(height: 12.h),
      Container(
        height: 90.h,
        alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade500)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Text(
            'Signature',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
        ),
      ),
    ],
  );

  Widget _accessoriesTab() {
    final currencySymbol =
        context.watch<AuthProvider>().currencySymbol.trim().isNotEmpty
        ? context.watch<AuthProvider>().currencySymbol.trim()
        : '₹';
    final accessoriesSubtotal = _accessories.fold<double>(
      0,
      (sum, row) => sum + _pricedRowTotal(row, extra: false),
    );

    return ListView(
      key: const ValueKey('quotation_accessories_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: REdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _section('Accessories & Parts', Icons.inventory_2_outlined, [
          _buildAccessoryQuickAddEntryBar(),
          SizedBox(height: 14.h),
          _accessoriesScrollableTable(currencySymbol, accessoriesSubtotal),
        ]),
      ],
    );
  }

  double _calculateSubtotal() {
    final serviceTotal = _reportedIssues.fold<double>(
      0,
      (sum, row) => sum + _issueLineTotal(row),
    );
    final servicesTotal = _services.fold<double>(
      0,
      (sum, row) => sum + _serviceLineTotal(row),
    );
    final accessoriesTotal = _accessories.fold<double>(
      0,
      (sum, row) => sum + _pricedRowTotal(row, extra: false),
    );
    final extrasTotal = _extras.fold<double>(
      0,
      (sum, row) => sum + _pricedRowTotal(row, extra: true),
    );
    final activityLabourTotal = _reportedIssues.fold<double>(0, (sum, report) {
      final activities = report['activities'] as List? ?? [];
      return sum +
          activities.fold<double>(0, (actSum, raw) {
            final act = raw as Map;
            final cost = double.tryParse((act['cost'] ?? '').toString()) ?? 0.0;
            final disc = double.tryParse((act['discount'] ?? '').toString()) ?? 0.0;
            return actSum + (cost - disc).clamp(0.0, double.infinity);
          });
    });
    final manualLabourTotal = _labourCharges.fold<double>(
      0,
      (sum, row) => sum + _pricedRowTotal(row, extra: true),
    );
    return serviceTotal + servicesTotal + accessoriesTotal + extrasTotal + activityLabourTotal + manualLabourTotal;
  }

  double _calculateTaxPercent() {
    return _availableTaxes.fold<double>(
      0.0,
      (sum, t) => sum + ((t['percent'] as num?)?.toDouble() ?? 0.0),
    );
  }

  Widget _serviceDetailsTab() {
    final currencySymbol =
        context.watch<AuthProvider>().currencySymbol.trim().isNotEmpty
        ? context.watch<AuthProvider>().currencySymbol.trim()
        : '₹';
    final serviceTotal = _reportedIssues.fold<double>(
      0,
      (sum, row) => sum + _issueLineTotal(row),
    );
    final servicesTotal = _services.fold<double>(
      0,
      (sum, row) => sum + _serviceLineTotal(row),
    );
    final activityLabourTotal = _reportedIssues.fold<double>(0, (sum, report) {
      final activities = report['activities'] as List? ?? [];
      return sum +
          activities.fold<double>(0, (actSum, raw) {
            final act = raw as Map;
            final cost = double.tryParse((act['cost'] ?? '').toString()) ?? 0.0;
            final disc = double.tryParse((act['discount'] ?? '').toString()) ?? 0.0;
            return actSum + (cost - disc).clamp(0.0, double.infinity);
          });
    });
    final manualLabourTotal = _labourCharges.fold<double>(
      0,
      (sum, row) => sum + _pricedRowTotal(row, extra: true),
    );
    final labourTotal = activityLabourTotal + manualLabourTotal;
    final subtotal = _calculateSubtotal();
    final taxPercent = _calculateTaxPercent();
    final taxAmount = subtotal * (taxPercent / 100.0);
    final grandTotal = subtotal + taxAmount;

    return ListView(
      key: const ValueKey('quotation_pricing_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: REdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _section('Services & Repairs Pricing', Icons.build_circle_outlined, [
          if (_reportedIssues.isEmpty && _services.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20.sp,
                    color: const Color(0xFF000080),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'No services added yet. Add services in Tab 4 (Services & Issues) to set pricing.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...List.generate(_reportedIssues.length, (index) {
              final row = _reportedIssues[index];
              final serviceName =
                  (row['service'] as Map?)?['name']?.toString() ?? 'Service';
              final categoryName =
                  (row['category'] as Map?)?['name']?.toString() ?? '';
              final issueText = (row['issue_text'] ?? '').toString();
              final hasSpecificComplaint =
                  issueText.isNotEmpty &&
                  issueText.toLowerCase() != serviceName.toLowerCase();
              final lineTotal = _issueLineTotal(row);

              return Container(
                key: ValueKey(
                  'quote-issue-pricing-$index-${row['report_id'] ?? row['issue_text']}',
                ),
                margin: EdgeInsets.only(bottom: 10.h),
                padding: REdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categoryName.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  margin: EdgeInsets.only(bottom: 3.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3730A3),
                                    ),
                                  ),
                                ),
                              Text(
                                '${index + 1}. $serviceName',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                              if (hasSpecificComplaint)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    'Complaint: $issueText',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      color: const Color(0xFFD97706),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '$currencySymbol ${lineTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 520;
                        final fields = [
                          _issuePriceInput(
                            index,
                            'rate',
                            'Rate',
                            decimal: true,
                          ),
                          _issuePriceInput(
                            index,
                            'quantity',
                            'Qty',
                            decimal: true,
                          ),
                          _issuePriceInput(
                            index,
                            'discount',
                            'Discount',
                            decimal: true,
                          ),
                        ];
                        if (!compact) {
                          return Row(
                            children: fields
                                .map(
                                  (field) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: field,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }
                        return Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: fields
                              .map(
                                (field) => SizedBox(
                                  width: (constraints.maxWidth - 8.w) / 2,
                                  child: field,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),
                    _issuePriceInput(
                      index,
                      'warranty',
                      'Warranty (e.g. 6 Months)',
                    ),
                    SizedBox(height: 8.h),
                    _issuePriceInput(
                      index,
                      'remarks',
                      'Remarks / Note',
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }),
            if (_services.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'Legacy Services',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ItemsTableWidget(
                items: _services,
                onDelete: (idx) => setState(() => _services.removeAt(idx)),
                particularKey: 'service_name',
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Services Subtotal: $currencySymbol ${(serviceTotal + servicesTotal).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000080),
                  ),
                ),
              ),
            ),
          ],
        ]),
        SizedBox(height: 14.h),
        Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20.sp,
                  color: const Color(0xFF000080),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accessories & Parts (${_accessories.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _accessories.isEmpty
                          ? 'No accessories added'
                          : 'Subtotal: $currencySymbol ${_accessories.fold<double>(0, (s, r) => s + _pricedRowTotal(r, extra: false)).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _tabs.animateTo(5),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF000080),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _section('Labour Charge', Icons.handyman_outlined, [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              'Additional Labour',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _labourNameCtrl,
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Labour Description *',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _labourRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Cost',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _labourDiscountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Discount',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              ElevatedButton(
                onPressed: _addLabourCharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                ),
                child: Text(
                  '+ Add',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          if (_labourCharges.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ItemsTableWidget(
              items: _labourCharges,
              onDelete: (idx) => setState(() => _labourCharges.removeAt(idx)),
              particularKey: 'name',
            ),
          ],
          if (_reportedIssues.every((r) => (r['activities'] as List? ?? []).isEmpty) &&
              _labourCharges.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No activity or labour charges added.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                'Labour Total: $currencySymbol ${labourTotal.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF000080),
                ),
              ),
            ),
          ),
        ]),
        SizedBox(height: 14.h),
        _section('Extras', Icons.add_circle_outline, [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _extraNameCtrl,
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Extra Description *',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _extraRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _extraQtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _extraDiscountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    labelText: 'Discount',
                    labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              ElevatedButton(
                onPressed: _addExtra,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                ),
                child: Text(
                  '+ Add',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          if (_extras.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No extras added.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12.sp,
                ),
              ),
            )
          else ...[
            SizedBox(height: 10.h),
            ItemsTableWidget(
              items: _extras,
              onDelete: (idx) => setState(() => _extras.removeAt(idx)),
              particularKey: 'name',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  'Extras Total: $currencySymbol ${_extras.fold<double>(0, (s, r) => s + _pricedRowTotal(r, extra: true)).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF000080),
                  ),
                ),
              ),
            ),
          ],
        ]),
        SizedBox(height: 14.h),
        _finalQuotationDetails(),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: const Color(0xFF000080).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('Subtotal'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${subtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (taxPercent > 0) ...[
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.tr("Tax")} (${taxPercent.toStringAsFixed(taxPercent % 1 == 0 ? 0 : 1)}%)',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$currencySymbol ${taxAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('Grand Total'),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF000080),
                    ),
                  ),
                  Text(
                    '$currencySymbol ${grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _issuesTab() => ListView(
    padding: REdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      _section('Services & Issues', Icons.build_circle_outlined, [
        if (_leadServices.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 16.sp,
                      color: const Color(0xFF1D4ED8),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Requested Services',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ...List.generate(_leadServices.length, (idx) {
                  final s = _leadServices[idx];
                  final cat = (s['category_name'] ?? '').toString().trim();
                  final name = (s['service_name'] ?? '').toString().trim();
                  return Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      '${idx + 1}. ${cat.isNotEmpty ? '$cat · ' : ''}$name',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (_reportedIssues.isNotEmpty)
          ...List.generate(_reportedIssues.length, (index) {
            final report = _reportedIssues[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      '${report['category']['name']} · ${report['service']['name']}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        if (_jobCardCategories.isEmpty)
          const Text('No Job Card categories are available.')
        else
          SizedBox(
            height: 42.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _jobCardCategories.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final category = _jobCardCategories[index];
                final selected =
                    category['id']?.toString() ==
                    _jobCardCategory?['id']?.toString();
                return ChoiceChip(
                  label: Text(category['name']?.toString() ?? ''),
                  selected: selected,
                  onSelected: (_) => _selectJobCategory(category),
                  selectedColor: const Color(0xFF000080),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF334155),
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF000080)
                        : Colors.grey.shade300,
                  ),
                );
              },
            ),
          ),
        _searchableMasterField(
          'Service name *',
          _jobCardService,
          _categoryServices,
          () async {
            final chosen = await _searchJobMaster(
              'Service',
              _categoryServices,
              _jobCardService,
            );
            if (chosen != null && mounted)
              setState(() {
                _jobCardService = chosen;
                _jobCardIssue = null;
                _issueText.clear();
              });
          },
        ),
        TextField(
          controller: _issueText,
          onChanged: (value) {
            final matchingIssue = _serviceIssues
                .where(
                  (item) =>
                      item['name'].toString().toLowerCase() ==
                      value.trim().toLowerCase(),
                )
                .firstOrNull;
            setState(() => _jobCardIssue = matchingIssue);
          },
          decoration: InputDecoration(
            labelText: 'Complaint / Issue (Optional)',
            hintText: _jobCardService == null
                ? 'Select a service first'
                : 'Specific complaint (defaults to service name)',
            prefixIcon: const Icon(Icons.report_problem_outlined),
            suffixIcon: IconButton(
              tooltip: 'Search issues',
              onPressed: _jobCardService == null
                  ? null
                  : () async {
                      final chosen = await _searchJobMaster(
                        'Issue',
                        _serviceIssues,
                        _jobCardIssue,
                      );
                      if (chosen != null && mounted) {
                        setState(() {
                          _jobCardIssue = chosen;
                          _issueText.text = chosen['name'].toString();
                        });
                      }
                    },
              icon: const Icon(Icons.arrow_drop_down),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
        _issueSuggestions(),
        Row(
          children: [
            Text(
              'Photos ${_issuePhotos.length + _existingIssuePhotos.length}/3',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Take photo',
              onPressed: _issuePhotos.length + _existingIssuePhotos.length < 3
                  ? () => _pickIssuePhotos(camera: true)
                  : null,
              icon: const Icon(Icons.photo_camera_outlined),
            ),
            IconButton(
              tooltip: 'Choose from gallery',
              onPressed: _issuePhotos.length + _existingIssuePhotos.length < 3
                  ? () => _pickIssuePhotos(camera: false)
                  : null,
              icon: const Icon(Icons.photo_library_outlined),
            ),
          ],
        ),
        if (_issuePhotos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _issuePhotos.length,
              (index) => _localPhotoPreview(
                _issuePhotos[index],
                () => setState(() => _issuePhotos.removeAt(index)),
              ),
            ),
          ),
        if (_existingIssuePhotos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _existingIssuePhotos.length,
              (index) => _remotePhotoPreview(
                _existingIssuePhotos[index]['url']?.toString() ?? '',
                () => setState(() => _existingIssuePhotos.removeAt(index)),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _addReportedIssue,
            icon: Icon(_editingIssueIndex == null ? Icons.add : Icons.check),
            label: Text(
              _editingIssueIndex == null ? 'Add Service' : 'Update Service',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ]),
      if (_reportedIssues.isNotEmpty) ...[
        SizedBox(height: 14.h),
        _section(
          'Added Services & Issues (${_reportedIssues.length})',
          Icons.list_alt,
          [
            ...List.generate(
              _reportedIssues.length,
              (index) => _reportedIssueTile(index),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _searchableMasterField(
    String label,
    Map<String, dynamic>? value,
    List<Map<String, dynamic>> options,
    VoidCallback onTap,
  ) => InkWell(
    onTap: options.isEmpty ? null : onTap,
    borderRadius: BorderRadius.circular(10.r),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      child: Text(
        value?['name']?.toString() ?? 'Select service',
        style: TextStyle(
          color: value == null ? Colors.grey.shade600 : Colors.black87,
        ),
      ),
    ),
  );

  Widget _localPhotoPreview(XFile photo, VoidCallback onRemove) => Stack(
    children: [
      FutureBuilder(
        future: photo.readAsBytes(),
        builder: (context, snapshot) => InkWell(
          onTap: snapshot.hasData
              ? () => _showPhotoViewer(Image.memory(snapshot.data!))
              : null,
          child: Container(
            width: 78.w,
            height: 78.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: snapshot.hasData
                ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.cancel, color: Colors.red),
          visualDensity: VisualDensity.compact,
          tooltip: 'Remove photo',
        ),
      ),
    ],
  );

  Widget _remotePhotoPreview(String url, VoidCallback onRemove) => Stack(
    children: [
      Container(
        width: 78.w,
        height: 78.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.grey.shade100,
        ),
        child: InkWell(
          onTap: () =>
              _showPhotoViewer(Image.network(url, fit: BoxFit.contain)),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.cancel, color: Colors.red),
          visualDensity: VisualDensity.compact,
          tooltip: 'Remove photo',
        ),
      ),
    ],
  );

  Future<void> _showPhotoViewer(Widget image) => showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(child: image),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(dialogContext).top + 8,
            right: 12,
            child: IconButton.filledTonal(
              tooltip: 'Close image',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reportedIssueTile(int index) {
    final row = _reportedIssues[index];
    final photos = List<XFile>.from(row['photos'] as List);
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: REdgeInsets.all(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['category']['name'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      row['service']['name'].toString(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    if (row['issue_text'] != null &&
                        row['issue_text'].toString().trim().isNotEmpty &&
                        row['issue_text'].toString().trim().toLowerCase() !=
                            row['service']['name']
                                .toString()
                                .trim()
                                .toLowerCase())
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          'Complaint: ${row['issue_text']}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            color: const Color(0xFFD97706),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit service',
                onPressed: () => _editReportedIssue(index),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF000080)),
              ),
              IconButton(
                tooltip: 'Delete service',
                onPressed: () => _deleteReportedIssue(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey(row['_activityKey']),
                  controller: _activityController(row),
                  focusNode: _activityFocusNode(row),
                  decoration: InputDecoration(
                    labelText: 'Activity',
                    hintText: 'Search or enter activity',
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton.filled(
                tooltip: 'Add activity',
                onPressed: _saving ? null : () => _appendReportedActivity(row),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          ..._reportedActivitySuggestions(row),
          if ((row['activities'] as List? ?? []).isNotEmpty)
            ...List.generate((row['activities'] as List).length, (
              displayIndex,
            ) {
              final activities = row['activities'] as List;
              final activityIndex = activities.length - 1 - displayIndex;
              final activity = activities[activityIndex] as Map;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 11.r,
                  backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
                  child: Text(
                    '${displayIndex + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                title: Text(activity['name'].toString()),
                trailing: IconButton(
                  tooltip: 'Remove activity',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      setState(() => activities.removeAt(activityIndex)),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              );
            }),
          if (photos.isNotEmpty ||
              (row['existing_photos'] as List? ?? []).isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...(row['existing_photos'] as List? ?? []).map((rawPhoto) {
                  final photo = Map<String, dynamic>.from(rawPhoto as Map);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: InkWell(
                      onTap: () => _showPhotoViewer(
                        Image.network(
                          photo['url']?.toString() ?? '',
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: Image.network(
                        photo['url']?.toString() ?? '',
                        width: 56.w,
                        height: 56.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
                ...photos.map(
                  (photo) => FutureBuilder(
                    future: photo.readAsBytes(),
                    builder: (context, snapshot) => InkWell(
                      onTap: snapshot.hasData
                          ? () => _showPhotoViewer(
                              Image.memory(snapshot.data!, fit: BoxFit.contain),
                            )
                          : null,
                      child: Container(
                        width: 56.w,
                        height: 56.h,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.r),
                          color: Colors.grey.shade100,
                        ),
                        child: snapshot.hasData
                            ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                            : const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
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
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            ...children.map(
              (w) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: w,
              ),
            ),
          ],
        ),
      );

  Widget _input(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => Column(
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
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 14.sp),
        decoration: InputDecoration(
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 14.h,
          ),
        ),
      ),
    ],
  );

  Widget _dropdown(
    List<Map<String, dynamic>> options,
    Map<String, dynamic>? value,
    String label,
    ValueChanged<Map<String, dynamic>?> onChanged, {
    String? Function(Map<String, dynamic>?)? validator,
  }) => DropdownButtonFormField<Map<String, dynamic>>(
    key: ValueKey('${label}_${value?['id'] ?? 'none'}'),
    value:
        value != null &&
            options.any(
              (item) => item['id']?.toString() == value['id']?.toString(),
            )
        ? options.firstWhere(
            (item) => item['id']?.toString() == value['id']?.toString(),
          )
        : null,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    ),
    items: options
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(
              (item['name'] ?? '').toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );

  Widget _footer() => SafeArea(
    child: Container(
      color: Colors.white,
      padding: REdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          if (_tabs.index > 0)
            OutlinedButton(
              onPressed: () => _tabs.animateTo(_tabs.index - 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF000080),
                side: const BorderSide(color: Color(0xFF000080)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
              ),
              child: const Text('Back'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saving ? null : _continue,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _tabs.index == 6
                        ? Icons.save_outlined
                        : Icons.arrow_forward,
                  ),
            label: Text(
              _saving
                  ? 'Saving'
                  : _tabs.index == 6
                  ? widget.existingQuotation == null
                        ? 'Save Draft'
                        : 'Save Changes'
                  : 'Continue',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
            ),
          ),
        ],
      ),
    ),
  );
}
