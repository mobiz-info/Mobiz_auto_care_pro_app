import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';

class JobCardService {
  static Future<Map<String, dynamic>> searchVehicleList(String query, String token) {
    return ApiService.searchVehicleList(query, token);
  }

  static Future<Map<String, dynamic>> searchCustomerList(String query, String token) {
    return ApiService.searchCustomerList(query, token);
  }

  static Future<Map<String, dynamic>> searchCustomer(
    String query,
    String token, {
    bool isVehicle = false,
  }) {
    return ApiService.searchCustomer(query, token, isVehicle: isVehicle);
  }

  static Future<Map<String, dynamic>> getCustomer(String customerId, String token) {
    return ApiService.getCustomer(customerId, token);
  }

  static Future<Map<String, dynamic>> addCustomer(Map<String, dynamic> payload, String token) {
    return ApiService.addCustomer(payload, token);
  }

  static Future<Map<String, dynamic>> getJobCardMetadata(String token) {
    return ApiService.getJobCardMetadata(token);
  }

  static Future<Map<String, dynamic>> getInspectionChecklist(String token) {
    return ApiService.getInspectionChecklist(token);
  }

  static Future<Map<String, dynamic>> getJobLeadFormData(String token, {String? branchId}) {
    return ApiService.getJobLeadFormData(token, branchId: branchId);
  }

  static Future<Map<String, dynamic>> getJobCardIssueOptions(String token) {
    return ApiService.getJobCardIssueOptions(token);
  }

  static Future<Map<String, dynamic>> getInvoiceServices(
    String customerId,
    String vehicleId,
    String token,
  ) {
    return ApiService.getInvoiceServices(customerId, vehicleId, token);
  }

  static Future<Map<String, dynamic>> getJobCardDetail(String jobCardId, String token) {
    return ApiService.getJobCardDetail(jobCardId, token);
  }

  static Future<Map<String, dynamic>> createJobCard(
    Map<String, dynamic> payload,
    String token, {
    List<List<XFile>>? issuePhotos,
    List<XFile>? beforePhotos,
    List<XFile>? afterPhotos,
    Map<int, List<XFile>>? qualityCheckPhotos,
  }) {
    return ApiService.createJobCard(
      payload,
      token,
      issuePhotos: issuePhotos ?? const [],
      beforePhotos: beforePhotos ?? const [],
      afterPhotos: afterPhotos ?? const [],
      qualityCheckPhotos: qualityCheckPhotos ?? const {},
    );
  }

  static Future<Map<String, dynamic>> updateJobCard(
    String jobCardId,
    Map<String, dynamic> payload,
    String token, {
    List<List<XFile>>? issuePhotos,
    List<XFile>? beforePhotos,
    List<XFile>? afterPhotos,
    Map<int, List<XFile>>? qualityCheckPhotos,
  }) {
    return ApiService.updateJobCard(
      jobCardId,
      payload,
      token,
      issuePhotos: issuePhotos ?? const [],
      beforePhotos: beforePhotos ?? const [],
      afterPhotos: afterPhotos ?? const [],
      qualityCheckPhotos: qualityCheckPhotos ?? const {},
    );
  }

  static Future<Map<String, dynamic>> uploadJobCardQualityCheckPhoto({
    required String jobCardId,
    required XFile photo,
    required String serviceName,
    required String token,
    String? status,
    String? remarks,
  }) {
    return ApiService.uploadJobCardQualityCheckPhoto(
      jobCardId: jobCardId,
      photo: photo,
      serviceName: serviceName,
      token: token,
      status: status,
      remarks: remarks,
    );
  }

  static Future<Map<String, dynamic>> deleteJobCardQualityCheckPhoto({
    required String jobCardId,
    required String photoId,
    required String token,
  }) {
    return ApiService.deleteJobCardQualityCheckPhoto(
      jobCardId: jobCardId,
      photoId: photoId,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> uploadJobCardVehiclePhoto({
    required String jobCardId,
    required XFile photo,
    required String photoType,
    required String token,
    String? caption,
  }) {
    return ApiService.uploadJobCardVehiclePhoto(
      jobCardId: jobCardId,
      photo: photo,
      photoType: photoType,
      token: token,
      caption: caption,
    );
  }

  static Future<Map<String, dynamic>> deleteJobCardVehiclePhoto({
    required String jobCardId,
    required String photoId,
    required String token,
  }) {
    return ApiService.deleteJobCardVehiclePhoto(
      jobCardId: jobCardId,
      photoId: photoId,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> createJobCardIssue(Map<String, dynamic> payload, String token) {
    return ApiService.createJobCardIssue(payload, token);
  }

  static Future<Map<String, dynamic>> createJobCardActivityOption(Map<String, dynamic> payload, String token) {
    return ApiService.createJobCardActivityOption(payload, token);
  }

  static Future<Map<String, dynamic>> searchJobCardAccessories(String query, String token) {
    return ApiService.searchJobCardAccessories(query, token);
  }

  static Future<Map<String, dynamic>> getJobCardInvoice(String jobCardId, String token) {
    return ApiService.getJobCardInvoice(jobCardId, token);
  }

  static Future<Map<String, dynamic>> createJobCardInvoice(
    String jobCardId,
    String token, {
    double? amountCollected,
    String? paymentMode,
    double discount = 0.0,
    String discountType = 'amount',
    double discountPercentage = 0.0,
  }) {
    return ApiService.createJobCardInvoice(
      jobCardId,
      token,
      amountCollected: amountCollected ?? 0.0,
      paymentMode: paymentMode ?? 'cash',
      discount: discount,
      discountType: discountType,
      discountPercentage: discountPercentage,
    );
  }
}
