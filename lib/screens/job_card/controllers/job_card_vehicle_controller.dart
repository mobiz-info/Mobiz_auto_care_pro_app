import 'package:flutter/material.dart';
import '../services/job_card_service.dart';

class JobCardVehicleController extends ChangeNotifier {
  List<dynamic> customerVehicles = [];
  Map<String, dynamic>? selectedVehicle;

  // Snapshot / vehicle form fields
  final TextEditingController vehicleNumber = TextEditingController();
  final TextEditingController engineNumberController = TextEditingController();
  final TextEditingController chassisNumberController = TextEditingController();

  String segmentId = '';
  String makeId = '';
  String modelId = '';
  String vehicleTypeId = '';
  String colorId = '';
  String emissionId = '';
  String fuelType = '';
  String wheelType = 'normal_wheel';

  // Metadata dropdown options
  List<dynamic> segments = [];
  List<dynamic> makes = [];
  List<dynamic> models = [];
  List<dynamic> vehicleTypes = [];
  List<dynamic> colors = [];
  List<dynamic> emissions = [];
  List<dynamic> fuelTypes = [];
  List<dynamic> wheelTypes = [];

  VoidCallback? onVehicleChanged;

  void syncVehicleIdentifiers(Map<String, dynamic>? vehicle) {
    engineNumberController.text = (vehicle?['engine_number'] ?? '').toString();
    chassisNumberController.text = (vehicle?['chassis_number'] ?? '').toString();
  }

  void selectVehicle(Map<String, dynamic>? vehicle) {
    selectedVehicle = vehicle;
    syncVehicleIdentifiers(vehicle);
    notifyListeners();
    onVehicleChanged?.call();
  }

  void setCustomerVehicles(List<dynamic> vehicles) {
    customerVehicles = vehicles;
    if (vehicles.isNotEmpty && selectedVehicle == null) {
      selectedVehicle = vehicles.first as Map<String, dynamic>;
      syncVehicleIdentifiers(selectedVehicle);
    }
    notifyListeners();
    onVehicleChanged?.call();
  }

  Future<void> reloadCustomerVehicles(String customerId, String token) async {
    try {
      final res = await JobCardService.getCustomer(customerId, token);
      if (res['success'] == true && res['customer'] != null) {
        final cust = res['customer'] as Map<String, dynamic>;
        final vehs = (cust['vehicles'] as List<dynamic>?) ?? [];
        customerVehicles = vehs;
        if (vehs.isNotEmpty) {
          selectedVehicle = vehs.last as Map<String, dynamic>;
        }
        syncVehicleIdentifiers(selectedVehicle);
        notifyListeners();
        onVehicleChanged?.call();
      }
    } catch (e) {
      debugPrint('Error reloading vehicles: $e');
    }
  }

  void applyLead(Map<String, dynamic> lead) {
    vehicleNumber.text = (lead['vehicle_number'] ?? '').toString();
    engineNumberController.text = (lead['engine_number'] ?? '').toString();
    chassisNumberController.text = (lead['chassis_number'] ?? '').toString();
    vehicleTypeId = (lead['vehicle_type_id'] ?? '').toString();
    segmentId = (lead['vehicle_segment_id'] ?? '').toString();
    makeId = (lead['vehicle_make_id'] ?? '').toString();
    modelId = (lead['vehicle_model_id'] ?? '').toString();
    colorId = (lead['vehicle_color_id'] ?? '').toString();
    emissionId = (lead['vehicle_emission_standard_id'] ?? '').toString();
    fuelType = (lead['vehicle_fuel_type'] ?? '').toString();
    wheelType = (lead['vehicle_wheel_type'] ?? 'normal_wheel').toString();

    selectedVehicle = {
      'id': lead['vehicle_id'] ?? '',
      'vehicle_number': lead['vehicle_number'],
      'engine_number': lead['engine_number'],
      'chassis_number': lead['chassis_number'],
    };
    notifyListeners();
  }

  void loadExistingJobCard(Map<String, dynamic> vehicle) {
    vehicleNumber.text = (vehicle['vehicle_number'] ?? '').toString();
    engineNumberController.text = (vehicle['engine_number'] ?? '').toString();
    chassisNumberController.text = (vehicle['chassis_number'] ?? '').toString();
    segmentId = (vehicle['segment_id'] ?? '').toString();
    makeId = (vehicle['make_id'] ?? '').toString();
    modelId = (vehicle['brand_model_id'] ?? '').toString();
    vehicleTypeId = (vehicle['vehicle_type_id'] ?? '').toString();
    colorId = (vehicle['color_id'] ?? '').toString();
    emissionId = (vehicle['emission_standard_id'] ?? '').toString();
    fuelType = (vehicle['fuel_type'] ?? '').toString();
    wheelType = (vehicle['wheel_type'] ?? 'normal_wheel').toString();

    selectedVehicle = vehicle;
    notifyListeners();
  }

  Map<String, dynamic> getVehicleDetailsPayload() {
    return {
      'vehicle_number': vehicleNumber.text.trim(),
      'vehicle_type_id': vehicleTypeId,
      'segment_id': segmentId,
      'make_id': makeId,
      'brand_model_id': modelId,
      'color_id': colorId,
      'emission_standard_id': emissionId,
      'fuel_type': fuelType,
      'wheel_type': wheelType,
    };
  }

  void onModelSelected(String id) {
    modelId = id;
    final model = models.cast<dynamic>().firstWhere(
      (item) => item['id'].toString() == id,
      orElse: () => null,
    );
    if (model != null) {
      makeId = model['make_id'].toString();
      segmentId = (model['segment_id'] ?? model['vehicle_type_model_id']).toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    vehicleNumber.dispose();
    engineNumberController.dispose();
    chassisNumberController.dispose();
    super.dispose();
  }

  void notify() => notifyListeners();
}
