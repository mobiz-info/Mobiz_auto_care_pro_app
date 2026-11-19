import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/job_card_service.dart';
import '../models/job_card_model.dart';

class JobCardIssuesController extends ChangeNotifier {
  final List<Map<String, dynamic>> reportedIssues = [];

  List<Map<String, dynamic>> jobIssueCategories = [];
  List<Map<String, dynamic>> jobIssueServices = [];
  List<Map<String, dynamic>> jobIssueChoices = [];
  List<Map<String, dynamic>> jobActivityChoices = [];

  bool isLoadingJobIssueOptions = true;
  String jobIssueOptionsError = '';

  Map<String, dynamic>? jobIssueCategory;
  Map<String, dynamic>? jobIssueService;
  Map<String, dynamic>? jobIssueChoice;

  final TextEditingController reportedIssueTextController = TextEditingController();
  List<XFile> draftIssuePhotos = [];
  List<Map<String, dynamic>> currentExistingIssuePhotos = [];
  int? editingReportedIssueIndex;

  final Map<String, TextEditingController> _activityDraftControllers = {};
  final Map<String, FocusNode> _activityDraftFocusNodes = {};
  final ImagePicker _issueImagePicker = ImagePicker();

  bool isPickingJobMaster = false;
  bool isSubmitting = false;

  List<Map<String, dynamic>> get categoryJobServices => jobIssueServices
      .where(
        (item) =>
            item['category_id']?.toString() ==
            jobIssueCategory?['id']?.toString(),
      )
      .toList();

  List<Map<String, dynamic>> get serviceJobIssues => jobIssueChoices
      .where(
        (item) =>
            item['service_id']?.toString() ==
                jobIssueService?['id']?.toString() &&
            item['category_id']?.toString() ==
                jobIssueCategory?['id']?.toString(),
      )
      .toList();

  int get issuePhotoCount =>
      draftIssuePhotos.length + currentExistingIssuePhotos.length;

  String activityDraftKey(Map<String, dynamic> row, int index) =>
      (row['client_key'] ??
              row['report_id'] ??
              'issue-$index-${row['issue_text']}')
          .toString();

  TextEditingController activityDraftController(Map<String, dynamic> row, int index) {
    final key = activityDraftKey(row, index);
    return _activityDraftControllers.putIfAbsent(key, () {
      final controller = TextEditingController(
        text: row['activity_draft']?.toString() ?? '',
      );
      controller.addListener(() => row['activity_draft'] = controller.text);
      return controller;
    });
  }

  FocusNode activityDraftFocusNode(Map<String, dynamic> row, int index) =>
      _activityDraftFocusNodes.putIfAbsent(
        activityDraftKey(row, index),
        FocusNode.new,
      );

  void setJobIssueCategoryDirectly(Map<String, dynamic> category) {
    jobIssueCategory = category;
    jobIssueService = null;
    jobIssueChoice = null;
    reportedIssueTextController.clear();
    draftIssuePhotos = [];
    currentExistingIssuePhotos = [];
    editingReportedIssueIndex = null;
    notifyListeners();
  }

  void setJobIssueServiceDirectly(Map<String, dynamic> service) {
    jobIssueService = service;
    jobIssueChoice = null;
    reportedIssueTextController.clear();
    draftIssuePhotos = [];
    currentExistingIssuePhotos = [];
    editingReportedIssueIndex = null;
    notifyListeners();
  }

  void setJobIssueChoiceDirectly(Map<String, dynamic>? choice) {
    jobIssueChoice = choice;
    if (choice != null) {
      reportedIssueTextController.text = choice['name'].toString();
    }
    notifyListeners();
  }

  Future<void> pickJobIssuePhotos(ImageSource source, {void Function(String message)? onMessage}) async {
    final remaining = 3 - issuePhotoCount;
    if (remaining <= 0) return;
    try {
      if (source == ImageSource.camera) {
        final photo = await _issueImagePicker.pickImage(
          source: source,
          imageQuality: 45,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (photo != null) {
          draftIssuePhotos.add(photo);
          notifyListeners();
        }
      } else {
        final photos = await _issueImagePicker.pickMultiImage(
          imageQuality: 45,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (photos.isEmpty) return;
        draftIssuePhotos.addAll(photos.take(remaining));
        notifyListeners();
        if (photos.length > remaining) {
          onMessage?.call('Only 3 photos are allowed per issue');
        }
      }
    } catch (error) {
      onMessage?.call('Unable to select photo: $error');
    }
  }

  void removeDraftPhoto(int index) {
    draftIssuePhotos.removeAt(index);
    notifyListeners();
  }

  void removeExistingPhoto(int index) {
    currentExistingIssuePhotos.removeAt(index);
    notifyListeners();
  }

  Future<bool> addReportedIssue(String token, {void Function(String message)? onMessage}) async {
    final category = jobIssueCategory;
    final service = jobIssueService;
    var name = reportedIssueTextController.text.trim();
    if (category == null || service == null) {
      onMessage?.call('Select a service category and service');
      return false;
    }
    if (name.isEmpty) {
      name = service['name']?.toString() ?? 'Service';
    }

    isSubmitting = true;
    notifyListeners();

    try {
      var issue = jobIssueChoice;
      if (issue == null ||
          issue['name'].toString().toLowerCase() != name.toLowerCase()) {
        final existingMatch = jobIssueChoices.firstWhere(
          (item) =>
              item['service_id']?.toString() == service['id']?.toString() &&
              item['name'].toString().toLowerCase() == name.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        if (existingMatch.isNotEmpty) {
          issue = existingMatch;
        } else {
          try {
            final response = await JobCardService.createJobCardIssue({
              'category_id': category['id'],
              'service_id': service['id'],
              'name': name,
            }, token);
            if (response['success'] == true && response['issue'] != null) {
              issue = Map<String, dynamic>.from(response['issue'] as Map);
              if (!jobIssueChoices.any(
                (item) => item['id'].toString() == issue!['id'].toString(),
              )) {
                jobIssueChoices = [...jobIssueChoices, issue];
              }
            }
          } catch (_) {}
        }
      }
      issue ??= {
        'id': '',
        'name': name,
        'category_id': category['id'],
        'service_id': service['id'],
      };

      final previous = editingReportedIssueIndex == null
          ? <String, dynamic>{}
          : reportedIssues[editingReportedIssueIndex!];
      final defaultRate =
          (service['rate'] ?? service['expected_value'] ?? '').toString();
      final hasRate = previous['rate'] != null &&
          previous['rate'].toString().trim().isNotEmpty;
      final resolvedRate = hasRate
          ? previous['rate'].toString()
          : (defaultRate != '0' &&
                  defaultRate != '0.0' &&
                  defaultRate != '0.00'
              ? defaultRate
              : '');

      final row = <String, dynamic>{
        ...previous,
        'client_key':
            previous['client_key'] ??
            'draft-${DateTime.now().microsecondsSinceEpoch}',
        'category': category,
        'service': service,
        'issue': issue,
        'issue_text': name,
        'rate': resolvedRate,
        'quantity': previous['quantity'] ?? '1',
        'discount': previous['discount'] ?? '',
        'warranty': previous['warranty'] ?? '',
        'remarks': previous['remarks'] ?? '',
        'activities': List<Map<String, dynamic>>.from(
          previous['activities'] as List? ?? [],
        ),
        'activity_draft': previous['activity_draft'] ?? '',
        'activity_draft_revision': previous['activity_draft_revision'] ?? 0,
        'photos': List<XFile>.from(draftIssuePhotos),
        'existing_photos': List<Map<String, dynamic>>.from(
          currentExistingIssuePhotos,
        ),
      };

      if (editingReportedIssueIndex == null) {
        reportedIssues.add(row);
      } else {
        reportedIssues[editingReportedIssueIndex!] = row;
      }

      editingReportedIssueIndex = null;
      jobIssueService = null;
      jobIssueChoice = null;
      reportedIssueTextController.clear();
      draftIssuePhotos = [];
      currentExistingIssuePhotos = [];
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (error) {
      isSubmitting = false;
      notifyListeners();
      onMessage?.call(error.toString());
      return false;
    }
  }

  void editReportedIssue(int index) {
    final row = reportedIssues[index];
    editingReportedIssueIndex = index;
    jobIssueCategory = Map<String, dynamic>.from(row['category'] as Map);
    jobIssueService = Map<String, dynamic>.from(row['service'] as Map);
    jobIssueChoice = Map<String, dynamic>.from(row['issue'] as Map);
    reportedIssueTextController.text = row['issue_text'].toString();
    draftIssuePhotos = List<XFile>.from(row['photos'] as List? ?? []);
    currentExistingIssuePhotos = List<Map<String, dynamic>>.from(
      row['existing_photos'] as List? ?? [],
    );
    notifyListeners();
  }

  void deleteReportedIssue(int index) {
    final row = reportedIssues[index];
    final activityKey = activityDraftKey(row, index);
    _activityDraftControllers.remove(activityKey)?.dispose();
    _activityDraftFocusNodes.remove(activityKey)?.dispose();

    reportedIssues.removeAt(index);
    if (editingReportedIssueIndex == index) {
      editingReportedIssueIndex = null;
      jobIssueService = null;
      jobIssueChoice = null;
      reportedIssueTextController.clear();
      draftIssuePhotos = [];
      currentExistingIssuePhotos = [];
    } else if (editingReportedIssueIndex != null &&
        editingReportedIssueIndex! > index) {
      editingReportedIssueIndex = editingReportedIssueIndex! - 1;
    }
    notifyListeners();
  }

  Future<void> appendJobActivity(
    int reportIndex,
    String token, {
    void Function(String message)? onMessage,
    VoidCallback? onActivityAdded,
  }) async {
    final row = reportedIssues[reportIndex];
    final controller = activityDraftController(row, reportIndex);
    final name = controller.text.trim();
    if (name.isEmpty) return;

    try {
      final response = await JobCardService.createJobCardActivityOption({
        'service_id': row['service']['id'],
        'name': name,
      }, token);
      if (response['success'] != true) {
        onMessage?.call(
          response['message']?.toString() ?? 'Unable to save activity',
        );
        return;
      }
      final option = Map<String, dynamic>.from(response['activity'] as Map);
      if (!jobActivityChoices.any(
        (item) => item['id'].toString() == option['id'].toString(),
      )) {
        jobActivityChoices = [...jobActivityChoices, option];
      }

      final activities = List<Map<String, dynamic>>.from(
        row['activities'] as List? ?? [],
      );
      activities.add({
        'name': option['name'],
        'status': 'pending',
        'staff_id': '',
        'cost': '',
        'discount': '',
      });
      row['activities'] = activities;
      row['activity_draft'] = '';
      controller.clear();
      notifyListeners();
      onActivityAdded?.call();
    } catch (error) {
      onMessage?.call('Unable to save activity: $error');
    }
  }

  void loadExistingJobCard(List<dynamic> rawIssues) {
    reportedIssues.clear();
    for (final raw in rawIssues) {
      final report = Map<String, dynamic>.from(raw as Map);
      reportedIssues.add({
        ...report,
        'category': Map<String, dynamic>.from(report['category'] as Map),
        'service': Map<String, dynamic>.from(report['service'] as Map),
        'issue': Map<String, dynamic>.from(report['issue'] as Map),
        'client_key':
            report['report_id']?.toString() ??
            'saved-${reportedIssues.length}',
        'rate': (report['pricing']?['rate'] ?? 0).toString(),
        'quantity': (report['pricing']?['quantity'] ?? 1).toString(),
        'discount': (report['pricing']?['discount'] ?? 0).toString(),
        'warranty': (report['pricing']?['warranty'] ?? '').toString(),
        'remarks': (report['pricing']?['remarks'] ?? '').toString(),
        'activities': (report['activities'] as List? ?? [])
            .map(
              (activity) => Map<String, dynamic>.from(activity as Map)
                ..['cost'] = (activity['cost'] ?? 0).toString()
                ..['discount'] = (activity['discount'] ?? '').toString(),
            )
            .toList(),
        'activity_draft': '',
        'activity_draft_revision': 0,
        'photos': <XFile>[],
        'existing_photos': (report['photos'] as List? ?? [])
            .map((photo) => Map<String, dynamic>.from(photo as Map))
            .toList(),
      });
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getReportedIssuesPayload() {
    return reportedIssues
        .map(
          (row) => {
            'report_id': row['report_id'],
            'category_id': row['category']?['id'],
            'service_id': row['service']?['id'],
            'issue_id': row['issue']?['id'],
            'issue_text': row['issue_text'],
            'rate': row['rate'] ?? 0,
            'quantity': row['quantity'] ?? 1,
            'discount': row['discount'] ?? 0,
            'warranty': row['warranty'] ?? '',
            'remarks': row['remarks'] ?? '',
            'status': row['status'] ?? 'pending',
            'bay': row['bay'],
            'started_at': row['started_at'] ?? '',
            'completed_at': row['completed_at'] ?? '',
            'parked_at': row['parked_at'] ?? '',
            'parked_remark': row['parked_remark'] ?? '',
            'staff_id': row['staff_id'] ?? '',
            'assigned_staff_ids': List<String>.from(row['assigned_staff_ids'] ?? []),
            'sort_order': row['sort_order'],
            'existing_photo_ids': (row['existing_photos'] as List? ?? [])
                .map((photo) => photo['id'].toString())
                .toList(),
            'activities': (row['activities'] as List? ?? []).map((raw) {
              final activity = raw as Map<String, dynamic>;
              return {
                'id': activity['id'],
                'name': activity['name'],
                'status': activity['status'] ?? 'pending',
                'staff_id': activity['staff_id'] ?? '',
                'assigned_staff_ids': List<String>.from(activity['assigned_staff_ids'] ?? []),
                'bay': activity['bay'],
                'started_at': activity['started_at'] ?? '',
                'completed_at': activity['completed_at'] ?? '',
                'parked_at': activity['parked_at'] ?? '',
                'parked_remark': activity['parked_remark'] ?? '',
                'sort_order': activity['sort_order'],
                'cost': JobCardConstants.numberOrZero(activity['cost']),
                'discount': JobCardConstants.numberOrZero(activity['discount']),
                'staff_labour': activity['staff_labour'] ?? [],
              };
            }).toList(),
          },
        )
        .toList();
  }

  List<List<XFile>> getIssuePhotoUploads() {
    return reportedIssues
        .map((row) => List<XFile>.from(row['photos'] as List? ?? []))
        .toList();
  }

  @override
  void dispose() {
    reportedIssueTextController.dispose();
    for (final c in _activityDraftControllers.values) {
      c.dispose();
    }
    for (final n in _activityDraftFocusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void notify() => notifyListeners();
}
