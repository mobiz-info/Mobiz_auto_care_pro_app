import '../models/job_card_quality_check_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/job_card_model.dart';
import '../services/job_card_service.dart';
import 'job_card_customer_controller.dart';
import 'job_card_vehicle_controller.dart';
import 'job_card_inspection_controller.dart';
import 'job_card_issues_controller.dart';
import 'job_card_pricing_controller.dart';
import 'job_card_billing_controller.dart';

class JobCardController extends ChangeNotifier {
  final Map<String, dynamic>? initialCustomer;
  final Map<String, dynamic>? initialVehicle;
  final Map<String, dynamic>? initialLead;
  final String? existingJobCardId;
  final int initialTabIndex;

  final JobCardCustomerController customerCtrl = JobCardCustomerController();
  final JobCardVehicleController vehicleCtrl = JobCardVehicleController();
  final JobCardInspectionController inspectionCtrl = JobCardInspectionController();
  final JobCardIssuesController issuesCtrl = JobCardIssuesController();
  final JobCardPricingController pricingCtrl = JobCardPricingController();
  final JobCardBillingController billingCtrl = JobCardBillingController();

  String? savedJobCardId;
  final Map<String, dynamic> formData = {};
  String companySealUrl = '';
  List<Map<String, dynamic>> staff = [];
  String? preparedById;
  DateTime? inspectionAt;

  DateTime? expectedDeliveryDate;
  TimeOfDay? expectedDeliveryTime;
  String selectedSection = 'General Inspection';
  String currentService = '';
  List<String> sections = List.from(JobCardConstants.defaultSections);

  final TextEditingController leadTimeController = TextEditingController(text: '2 hours');
  final TextEditingController additionalRemarksController = TextEditingController();
  final TextEditingController appointmentDetailsController = TextEditingController();
  final TextEditingController internalNotesController = TextEditingController();

  List<XFile> beforePhotos = [];
  List<XFile> afterPhotos = [];
  List<Map<String, dynamic>> existingBeforePhotos = [];
  List<Map<String, dynamic>> existingAfterPhotos = [];
  List<String> deletePhotoIds = [];

  final Map<String, JobCardQualityCheckItem> qualityChecks = {};

  List<JobCardQualityCheckItem> get qualityCheckList {
    _syncQualityChecksWithServices();
    return qualityChecks.values.toList();
  }

  void _syncQualityChecksWithServices() {
    final services = pricingCtrl.addedServices;
    for (final s in services) {
      final name = (s['name'] ?? s['service_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      if (!qualityChecks.containsKey(name)) {
        qualityChecks[name] = JobCardQualityCheckItem(
          serviceName: name,
          serviceId: (s['id'] ?? s['service_id'])?.toString(),
          status: 'satisfied',
          remarks: '',
        );
      } else {
        final existing = qualityChecks[name]!;
        if (existing.serviceId == null || existing.serviceId!.isEmpty) {
          existing.serviceId = (s['id'] ?? s['service_id'])?.toString();
        }
      }
    }
    for (final issue in issuesCtrl.reportedIssues) {
      final issueName = (issue['issue_text'] ?? issue['issue']?['name'] ?? '').toString().trim();
      if (issueName.isEmpty) continue;
      if (!qualityChecks.containsKey(issueName)) {
        qualityChecks[issueName] = JobCardQualityCheckItem(
          serviceName: issueName,
          status: 'satisfied',
          remarks: '',
        );
      }
    }
  }

  void setQualityCheckStatus(String serviceName, String status) {
    _syncQualityChecksWithServices();
    if (qualityChecks.containsKey(serviceName)) {
      qualityChecks[serviceName]!.status = status;
      notifyListeners();
    }
  }

  void setQualityCheckRemarks(String serviceName, String remarks) {
    _syncQualityChecksWithServices();
    if (qualityChecks.containsKey(serviceName)) {
      qualityChecks[serviceName]!.remarks = remarks;
      notifyListeners();
    }
  }

  void addQualityCheckPhoto(String serviceName, XFile photo) {
    _syncQualityChecksWithServices();
    if (qualityChecks.containsKey(serviceName)) {
      qualityChecks[serviceName]!.newPhotos.add(photo);
      notifyListeners();
    }
  }

  void removeQualityCheckNewPhoto(String serviceName, int index) {
    if (qualityChecks.containsKey(serviceName)) {
      final item = qualityChecks[serviceName]!;
      if (index >= 0 && index < item.newPhotos.length) {
        item.newPhotos.removeAt(index);
        notifyListeners();
      }
    }
  }

  void removeQualityCheckExistingPhoto(String serviceName, String photoId) {
    if (qualityChecks.containsKey(serviceName)) {
      final item = qualityChecks[serviceName]!;
      item.existingPhotos.removeWhere((p) => p['id']?.toString() == photoId);
      item.deletedPhotoIds.add(photoId);
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getQualityChecksPayload() {
    _syncQualityChecksWithServices();
    return qualityChecks.values.map((item) => item.toPayload()).toList();
  }

  Map<int, List<XFile>> getQualityCheckPhotoUploads() {
    _syncQualityChecksWithServices();
    final uploads = <int, List<XFile>>{};
    var idx = 0;
    for (final item in qualityChecks.values) {
      if (item.newPhotos.isNotEmpty) {
        uploads[idx] = List.from(item.newPhotos);
      }
      idx++;
    }
    return uploads;
  }


  void addBeforePhotos(List<XFile> photos) {
    beforePhotos.addAll(photos);
    notifyListeners();
  }

  void removeBeforePhoto(int index) {
    beforePhotos.removeAt(index);
    notifyListeners();
  }

  void removeExistingBeforePhoto(int index) {
    final photo = existingBeforePhotos.removeAt(index);
    if (photo['id'] != null) {
      deletePhotoIds.add(photo['id'].toString());
    }
    notifyListeners();
  }

  void addAfterPhotos(List<XFile> photos) {
    afterPhotos.addAll(photos);
    notifyListeners();
  }

  void removeAfterPhoto(int index) {
    afterPhotos.removeAt(index);
    notifyListeners();
  }

  void removeExistingAfterPhoto(int index) {
    final photo = existingAfterPhotos.removeAt(index);
    if (photo['id'] != null) {
      deletePhotoIds.add(photo['id'].toString());
    }
    notifyListeners();
  }

  bool isSubmitting = false;

  bool get snapshotMode => initialLead != null || existingJobCardId != null;
  bool get hasSavedJobCard => (savedJobCardId ?? existingJobCardId) != null;

  String? get jobNumber {
    final jn = formData['job_number']?.toString();
    if (jn != null && jn.isNotEmpty) return jn;
    if (initialLead != null && initialLead!['job_number'] != null) {
      return initialLead!['job_number'].toString();
    }
    return null;
  }

  JobCardController({
    this.initialCustomer,
    this.initialVehicle,
    this.initialLead,
    this.existingJobCardId,
    this.initialTabIndex = 0,
  });

  void initialize(String? token) {
    savedJobCardId = existingJobCardId;
    if (initialLead != null && initialLead!['job_number'] != null) {
      formData['job_number'] = initialLead!['job_number'];
    }
    customerCtrl.init();

    // Hook vehicle changes to trigger vehicle service price loading
    vehicleCtrl.onVehicleChanged = () {
      if (token != null &&
          customerCtrl.selectedCustomer != null &&
          vehicleCtrl.selectedVehicle != null) {
        final custId = customerCtrl.selectedCustomer!['id'].toString();
        final vehId = vehicleCtrl.selectedVehicle!['id'].toString();
        pricingCtrl.loadVehicleServices(custId, vehId, token);
      }
    };

    customerCtrl.onCustomerChanged = () {
      if (customerCtrl.selectedCustomer != null) {
        final vehs = customerCtrl.selectedCustomer!['vehicles'] ?? [];
        vehicleCtrl.setCustomerVehicles(vehs is List ? vehs : []);
      }
    };

    expectedDeliveryDate = DateTime.now().add(const Duration(hours: 4));
    expectedDeliveryTime = TimeOfDay.fromDateTime(expectedDeliveryDate!);

    if (initialLead != null) {
      applyLead(initialLead!);
    }

    if (initialCustomer != null) {
      customerCtrl.selectedCustomer = initialCustomer;
      final vehs = (initialCustomer?['vehicles'] as List?) ?? [];
      vehicleCtrl.customerVehicles = vehs;
      if (initialVehicle != null) {
        vehicleCtrl.selectedVehicle = initialVehicle;
      } else if (vehs.isNotEmpty) {
        vehicleCtrl.selectedVehicle = vehs.first as Map<String, dynamic>;
      }
      vehicleCtrl.syncVehicleIdentifiers(vehicleCtrl.selectedVehicle);
    }

    if (token != null) {
      loadMetadata(token);
      if (existingJobCardId != null) {
        loadExistingJobCard(token);
      }
      if (customerCtrl.selectedCustomer != null && vehicleCtrl.selectedVehicle != null) {
        final custId = customerCtrl.selectedCustomer!['id'].toString();
        final vehId = vehicleCtrl.selectedVehicle!['id'].toString();
        pricingCtrl.loadVehicleServices(custId, vehId, token);
      }
    }
  }

  void applyLead(Map<String, dynamic> lead) {
    formData['lead_id'] = lead['id'];
    formData['vehicle_make_name'] = (lead['vehicle_make'] ?? '').toString();
    formData['vehicle_model_name'] = (lead['vehicle_model'] ?? '').toString();

    customerCtrl.applyLead(lead);
    vehicleCtrl.applyLead(lead);

    final interests = lead['service_interests'] as List? ?? [];
    issuesCtrl.reportedIssues.clear();
    for (int i = 0; i < interests.length; i++) {
      final raw = interests[i];
      final item = Map<String, dynamic>.from(raw as Map);
      final amount = (item['expected_value'] as num?)?.toDouble() ?? 0;
      final categoryId = (item['category_id'] ?? '').toString();
      final categoryName = (item['category_name'] ?? '').toString();
      final serviceId = (item['service_id'] ?? '').toString();
      final serviceName = (item['service_name'] ?? '').toString();

      issuesCtrl.reportedIssues.add({
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
        'activity_draft': '',
        'activity_draft_revision': 0,
        'photos': <XFile>[],
        'existing_photos': <Map<String, dynamic>>[],
      });
    }
    notifyListeners();
  }

  Future<void> loadMetadata(String token) async {
    Map<String, dynamic> res = {};
    Map<String, dynamic> leadRes = {};
    Map<String, dynamic> issueRes = {};
    String issueOptionsError = '';

    try {
      res = await JobCardService.getJobCardMetadata(token);
    } catch (_) {}
    try {
      leadRes = await JobCardService.getJobLeadFormData(
        token,
        branchId: initialLead?['branch_id']?.toString(),
      );
    } catch (_) {}
    try {
      issueRes = await JobCardService.getJobCardIssueOptions(token);
      if (issueRes['success'] != true) {
        issueOptionsError =
            (issueRes['message'] ?? 'Unable to load issue options').toString();
      }
    } catch (error) {
      issueOptionsError = error.toString();
    }

    if (res['success'] == true) {
      customerCtrl.customerTypes = res['customer_types'] ?? [];
      if (res['sections'] != null) {
        sections = List<String>.from(res['sections']);
      }
    }

    if (leadRes['success'] == true) {
      companySealUrl = (leadRes['company_seal_url'] ?? '').toString();
      staff = (leadRes['staff'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      customerCtrl.customerTypes = leadRes['customer_types'] ?? customerCtrl.customerTypes;
      vehicleCtrl.segments = leadRes['vehicle_segments'] ?? [];
      vehicleCtrl.makes = leadRes['makes'] ?? [];
      vehicleCtrl.models = leadRes['vehicle_models'] ?? [];
      vehicleCtrl.vehicleTypes = leadRes['vehicle_types'] ?? [];
      vehicleCtrl.colors = leadRes['colors'] ?? [];
      vehicleCtrl.emissions = leadRes['emission_standards'] ?? [];
      vehicleCtrl.fuelTypes = leadRes['fuel_types'] ?? [];
      vehicleCtrl.wheelTypes = leadRes['wheel_types'] ?? [];
      pricingCtrl.serviceCategories = (leadRes['service_categories'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      pricingCtrl.availableServices = (leadRes['services'] as List? ?? []).map((item) {
        final service = Map<String, dynamic>.from(item as Map);
        return <String, dynamic>{
          ...service,
          'service_type': service['category_name'] ?? '',
          'service_type_id': service['category_id']?.toString(),
          'rate': service['rate'] ?? 0,
        };
      }).toList();
    }

    if (issueRes['success'] == true) {
      issuesCtrl.jobIssueCategories = (issueRes['categories'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      issuesCtrl.jobIssueServices = (issueRes['services'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      issuesCtrl.jobIssueChoices = (issueRes['issues'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      issuesCtrl.jobActivityChoices = (issueRes['activities'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      for (final row in issuesCtrl.reportedIssues) {
        final sId = row['service']?['id']?.toString();
        if ((row['category']?['name'] == null ||
                row['category']?['name'] == '' ||
                row['category']?['name'] == 'General') &&
            sId != null &&
            sId.isNotEmpty) {
          final matchedService = issuesCtrl.jobIssueServices.firstWhere(
            (s) => s['id']?.toString() == sId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedService.isNotEmpty) {
            final catId = matchedService['category_id']?.toString();
            final matchedCat = issuesCtrl.jobIssueCategories.firstWhere(
              (c) => c['id']?.toString() == catId,
              orElse: () => <String, dynamic>{},
            );
            if (matchedCat.isNotEmpty) {
              row['category'] = matchedCat;
            }
          }
        }
        if ((row['issue']?['id'] == null ||
                row['issue']?['id'] == '') &&
            sId != null &&
            sId.isNotEmpty) {
          final matchedIssue = issuesCtrl.jobIssueChoices.firstWhere(
            (iss) => iss['service_id']?.toString() == sId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedIssue.isNotEmpty) {
            row['issue'] = matchedIssue;
          }
        }
      }
      if (!issuesCtrl.jobIssueCategories.any(
        (item) => item['id']?.toString() == issuesCtrl.jobIssueCategory?['id']?.toString(),
      )) {
        issuesCtrl.jobIssueCategory = issuesCtrl.jobIssueCategories.firstOrNull;
      }
      issuesCtrl.jobIssueOptionsError = '';
    } else {
      issuesCtrl.jobIssueOptionsError = issueOptionsError.isEmpty
          ? 'Unable to load issue options'
          : issueOptionsError;
    }
    issuesCtrl.isLoadingJobIssueOptions = false;

    try {
      final checklistRes = await JobCardService.getInspectionChecklist(token);
      if (checklistRes['success'] == true && checklistRes['categories'] is List) {
        inspectionCtrl.checklistCategories = List<Map<String, dynamic>>.from(
          (checklistRes['categories'] as List).map((c) => Map<String, dynamic>.from(c as Map)),
        );
        if (inspectionCtrl.checklistCategories.isNotEmpty) {
          inspectionCtrl.selectedInspectionCategory =
              inspectionCtrl.checklistCategories.first['name'].toString();
        }
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> loadExistingJobCard(String token) async {
    if (existingJobCardId == null) return;
    final response = await JobCardService.getJobCardDetail(existingJobCardId!, token);
    final card = response['job_card'];
    if (response['success'] != true || card is! Map) return;

    final data = Map<String, dynamic>.from(card);
    formData['job_number'] = data['job_number'];
    final customer = Map<String, dynamic>.from(data['customer'] ?? {});
    final vehicle = Map<String, dynamic>.from(data['vehicle'] ?? {});

    formData['vehicle_make_name'] = (vehicle['make'] ?? '').toString();
    formData['vehicle_model_name'] = (vehicle['model'] ?? '').toString();

    customerCtrl.loadExistingJobCard(customer);
    vehicleCtrl.loadExistingJobCard(vehicle);
    issuesCtrl.loadExistingJobCard(data['reported_issues'] as List? ?? []);

    leadTimeController.text = (data['delivery_lead_time'] ?? '').toString();
    final deliveryText = (data['expected_delivery_date'] ?? '').toString();
    if (deliveryText.isNotEmpty) {
      try {
        final parsed = DateFormat('dd-MM-yyyy hh:mm a').parseLoose(deliveryText);
        expectedDeliveryDate = parsed;
        expectedDeliveryTime = TimeOfDay.fromDateTime(parsed);
      } catch (_) {}
    }

    additionalRemarksController.text = (data['additional_remarks'] ?? '').toString();
    appointmentDetailsController.text = (data['appointment_details'] ?? '').toString();
    internalNotesController.text = (data['internal_notes'] ?? '').toString();
    preparedById = (data['prepared_by_id'] ?? '').toString().isEmpty
        ? null
        : data['prepared_by_id'].toString();
    inspectionAt = DateTime.tryParse((data['inspection_at'] ?? '').toString())?.toLocal();

    final inspectionDetails = data['inspection_details'];
    if (inspectionDetails is Map) {
      inspectionCtrl.loadExistingInspection(Map<String, dynamic>.from(inspectionDetails));
    }

    currentService = (data['current_service'] ?? '').toString();
    selectedSection = (data['current_section'] ?? sections.first).toString();

    existingBeforePhotos = (data['before_photos'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    existingAfterPhotos = (data['after_photos'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final rawQcs = data['quality_checks'] as List? ?? [];
    for (final q in rawQcs) {
      if (q is Map) {
        final qcItem = JobCardQualityCheckItem.fromJson(Map<String, dynamic>.from(q));
        if (qcItem.serviceName.isNotEmpty) {
          qualityChecks[qcItem.serviceName] = qcItem;
        }
      }
    }
    _syncQualityChecksWithServices();
    pricingCtrl.loadExistingJobCard(data);
    notifyListeners();
  }

  bool validateStageDraft(int tabIndex, {void Function(String message)? onMessage}) {
    if ((tabIndex == 3 || tabIndex == 4) &&
        (issuesCtrl.editingReportedIssueIndex != null ||
            issuesCtrl.jobIssueService != null ||
            issuesCtrl.reportedIssueTextController.text.trim().isNotEmpty ||
            issuesCtrl.draftIssuePhotos.isNotEmpty ||
            issuesCtrl.currentExistingIssuePhotos.isNotEmpty)) {
      onMessage?.call('Add or finish the current issue first');
      return false;
    }
    if ((tabIndex >= 4 && tabIndex <= 6) &&
        issuesCtrl.reportedIssues.any(
          (row) => (row['activity_draft'] ?? '').toString().trim().isNotEmpty,
        )) {
      onMessage?.call('Add the entered activity before saving');
      return false;
    }
    return true;
  }

  Future<Map<String, dynamic>> submitJobCard({
    required String token,
    bool keepOpen = false,
    String? statusOverride,
    void Function(String message)? onMessage,
  }) async {
    if (!snapshotMode && customerCtrl.selectedCustomer == null) {
      onMessage?.call('Please select a customer');
      return {'success': false, 'message': 'Please select a customer'};
    }
    if (!snapshotMode && vehicleCtrl.selectedVehicle == null) {
      onMessage?.call('Please select a vehicle');
      return {'success': false, 'message': 'Please select a vehicle'};
    }
    if (snapshotMode) {
      final selectedType = customerCtrl.customerTypes
          .cast<dynamic>()
          .where((item) => item['id'].toString() == customerCtrl.customerTypeId)
          .toList();
      final isCorporate = selectedType.isNotEmpty &&
          selectedType.first['name'].toString().toLowerCase().contains('corporate');

      if (customerCtrl.profileName.text.trim().isEmpty ||
          customerCtrl.profilePhone.text.trim().isEmpty ||
          customerCtrl.customerTypeId.isEmpty ||
          customerCtrl.profileState.text.trim().isEmpty ||
          customerCtrl.profileCity.text.trim().isEmpty ||
          vehicleCtrl.vehicleNumber.text.trim().isEmpty ||
          vehicleCtrl.segmentId.isEmpty) {
        onMessage?.call('Complete required customer and vehicle details');
        return {'success': false, 'message': 'Complete required customer and vehicle details'};
      }

      if (isCorporate &&
          [
            customerCtrl.profileTax,
            customerCtrl.profileTin,
            customerCtrl.profilePan,
          ].any((controller) => controller.text.trim().isEmpty)) {
        onMessage?.call('Tax registration number, TIN, and PAN are required for corporate customers');
        return {'success': false, 'message': 'Tax registration number, TIN, and PAN are required'};
      }
    }

    isSubmitting = true;
    notifyListeners();

    String? deliveryDateStr;
    if (expectedDeliveryDate != null) {
      final dt = DateTime(
        expectedDeliveryDate!.year,
        expectedDeliveryDate!.month,
        expectedDeliveryDate!.day,
        expectedDeliveryTime?.hour ?? 12,
        expectedDeliveryTime?.minute ?? 0,
      );
      deliveryDateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    }

    final payload = <String, dynamic>{
      'expected_delivery_date': deliveryDateStr,
      'delivery_lead_time': leadTimeController.text.trim(),
      'current_section': selectedSection,
      'current_service': currentService,
      'additional_remarks': additionalRemarksController.text.trim(),
      'appointment_details': appointmentDetailsController.text.trim(),
      'inspection_at': inspectionAt?.toUtc().toIso8601String() ?? '',
      'engine_number': vehicleCtrl.engineNumberController.text.trim(),
      'chassis_number': vehicleCtrl.chassisNumberController.text.trim(),
      'inspection_details': inspectionCtrl.getInspectionPayload(),
      'internal_notes': internalNotesController.text.trim(),
      'prepared_by_id': preparedById ?? '',
      'services': pricingCtrl.addedServices,
      'parts': pricingCtrl.getPartsPayload(),
      'labour': pricingCtrl.getLabourPayload(),
      'extras': pricingCtrl.getExtrasPayload(),
      'local_purchases': pricingCtrl.getLocalPurchasesPayload(),
      'reported_issues': issuesCtrl.getReportedIssuesPayload(),
      'quality_checks': getQualityChecksPayload(),
    };
    final qcPhotoUploads = getQualityCheckPhotoUploads();
    if (statusOverride != null) payload['status'] = statusOverride;
    final issuePhotoUploads = issuesCtrl.getIssuePhotoUploads();

    if (snapshotMode) {
      payload['customer_profile'] = customerCtrl.getCustomerProfilePayload();
      payload['vehicle_details'] = vehicleCtrl.getVehicleDetailsPayload();
      if (initialLead != null) {
        payload['lead_id'] = initialLead!['id'];
      }
    } else {
      payload['customer_id'] = customerCtrl.selectedCustomer!['id'];
      payload['vehicle_id'] = vehicleCtrl.selectedVehicle!['id'];
    }

    if (deletePhotoIds.isNotEmpty) {
      payload['delete_photo_ids'] = deletePhotoIds;
    }

    try {
      final jobCardId = savedJobCardId ?? existingJobCardId;
      final res = jobCardId != null
          ? await JobCardService.updateJobCard(
              jobCardId,
              payload,
              token,
              issuePhotos: issuePhotoUploads,
              beforePhotos: beforePhotos,
              afterPhotos: afterPhotos,
              qualityCheckPhotos: qcPhotoUploads,
            )
          : await JobCardService.createJobCard(
              payload,
              token,
              issuePhotos: issuePhotoUploads,
              beforePhotos: beforePhotos,
              afterPhotos: afterPhotos,
              qualityCheckPhotos: qcPhotoUploads,
            );

      isSubmitting = false;
      if (res['success'] == true) {
        savedJobCardId = (res['job_card_id'] ?? jobCardId)?.toString();
        if (res['job_number'] != null && res['job_number'].toString().isNotEmpty) {
          formData['job_number'] = res['job_number'].toString();
        }
        notifyListeners();
        return res;
      } else {
        notifyListeners();
        onMessage?.call(res['message'] ?? 'Failed to save job card');
        return res;
      }
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      onMessage?.call('Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  void dispose() {
    leadTimeController.dispose();
    additionalRemarksController.dispose();
    appointmentDetailsController.dispose();
    internalNotesController.dispose();

    customerCtrl.dispose();
    vehicleCtrl.dispose();
    inspectionCtrl.dispose();
    issuesCtrl.dispose();
    pricingCtrl.dispose();
    billingCtrl.dispose();

    super.dispose();
  }

  void notify() => notifyListeners();
}
