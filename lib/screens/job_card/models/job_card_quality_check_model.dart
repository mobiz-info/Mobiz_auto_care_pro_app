import 'package:image_picker/image_picker.dart';

class JobCardQualityCheckItem {
  String? id;
  String? serviceId;
  String serviceName;
  String status; // 'satisfied' | 'not_satisfied'
  String remarks;
  List<XFile> newPhotos;
  List<Map<String, dynamic>> existingPhotos;
  List<String> deletedPhotoIds;

  JobCardQualityCheckItem({
    this.id,
    this.serviceId,
    required this.serviceName,
    this.status = 'satisfied',
    this.remarks = '',
    List<XFile>? newPhotos,
    List<Map<String, dynamic>>? existingPhotos,
    List<String>? deletedPhotoIds,
  })  : newPhotos = newPhotos ?? [],
        existingPhotos = existingPhotos ?? [],
        deletedPhotoIds = deletedPhotoIds ?? [];

  bool get isSatisfied => status == 'satisfied';

  Map<String, dynamic> toPayload() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      if (serviceId != null && serviceId!.isNotEmpty) 'service_id': serviceId,
      'service_name': serviceName,
      'status': status,
      'remarks': remarks,
      if (deletedPhotoIds.isNotEmpty) 'delete_photo_ids': deletedPhotoIds,
    };
  }

  factory JobCardQualityCheckItem.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List? ?? [];
    return JobCardQualityCheckItem(
      id: json['id']?.toString(),
      serviceId: json['service_id']?.toString(),
      serviceName: json['service_name']?.toString() ?? '',
      status: json['status']?.toString() == 'not_satisfied'
          ? 'not_satisfied'
          : 'satisfied',
      remarks: json['remarks']?.toString() ?? '',
      existingPhotos: rawPhotos
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

