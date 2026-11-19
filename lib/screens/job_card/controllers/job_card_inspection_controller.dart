import 'package:flutter/material.dart';

class JobCardInspectionController extends ChangeNotifier {
  String selectedInspectionCategory = 'Tyre';
  String selectedDamageView = 'Front';
  String selectedDamagePart = 'Front bumper';
  final TextEditingController damageRemarkController = TextEditingController();

  final List<Map<String, dynamic>> damageMarks = [];
  List<Offset> currentDamageStroke = [];

  // Tyre Inspection
  final Map<String, dynamic> tyreServices = {};
  final Map<String, String> tyreWheelAssessment = {};
  String tyrePressure = '';
  String tyreTreadDepth = '';
  String tyreWearIndicators = '';
  final TextEditingController tyreTwiValueController = TextEditingController();
  final Set<String> tyreWearDistribution = {};
  final Set<String> tyreSurfaceDamage = {};
  final Set<String> tyreStructuralDamage = {};
  final Set<String> tyreValveIssues = {};
  final Set<String> tyreRimIssues = {};
  String tyreDotYear = '';

  // Wheel Alignment
  final Map<String, String> wheelAlignmentValues = {};

  // Oil
  final Map<String, String> oilInspectionValues = {};
  final Map<String, String> legacyOilInspectionValues = {};

  // Brake
  final Map<String, String> brakeInspectionValues = {};

  // Dynamic Checklist (Superadmin Master)
  List<Map<String, dynamic>> checklistCategories = [];
  final Map<String, Map<String, dynamic>> checklistValues = {};

  void setChecklistStatus(String itemId, String status, {String? name, String? category}) {
    checklistValues[itemId] = {
      ...checklistValues[itemId] ?? {},
      'status': status,
      if (name != null && name.isNotEmpty) 'name': name,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    notifyListeners();
  }

  void setChecklistValue(String itemId, String value, {String? name, String? category}) {
    checklistValues[itemId] = {
      ...checklistValues[itemId] ?? {},
      'value': value,
      if (name != null && name.isNotEmpty) 'name': name,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    notifyListeners();
  }

  void setChecklistRemarks(String itemId, String remarks, {String? name, String? category}) {
    checklistValues[itemId] = {
      ...checklistValues[itemId] ?? {},
      'remarks': remarks,
      if (name != null && name.isNotEmpty) 'name': name,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    notifyListeners();
  }

  String getChecklistStatus(String itemId) =>
      (checklistValues[itemId]?['status'] ?? '').toString();

  String getChecklistValue(String itemId) =>
      (checklistValues[itemId]?['value'] ?? '').toString();

  String getChecklistRemarks(String itemId) =>
      (checklistValues[itemId]?['remarks'] ?? '').toString();

  void selectInspectionCategory(String category) {
    selectedInspectionCategory = category;
    notifyListeners();
  }

  void selectDamageView(String view) {
    selectedDamageView = view;
    currentDamageStroke = [];
    notifyListeners();
  }

  void setCurrentDamageStroke(List<Offset> stroke) {
    currentDamageStroke = stroke;
    notifyListeners();
  }

  void addPointToCurrentStroke(Offset point) {
    currentDamageStroke.add(point);
    notifyListeners();
  }

  void clearDamageStroke() {
    currentDamageStroke = [];
    notifyListeners();
  }

  void addDamageMark({
    required String view,
    required String part,
    required String remarks,
    required List<Offset> points,
    String damageType = 'Scratch',
    String severity = 'Minor',
    dynamic photo,
    String? photoPath,
    String? photoUrl,
    String? id,
  }) {
    selectedDamagePart = part;
    damageMarks.add({
      'id': id ?? 'damage-${DateTime.now().microsecondsSinceEpoch}',
      'view': view,
      'part': part,
      'damage_type': damageType,
      'severity': severity,
      'remarks': remarks,
      if (photo != null) 'photo': photo,
      if (photoPath != null && photoPath.isNotEmpty) 'photo_path': photoPath,
      'photo_url': photoUrl ?? '',
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    });
    currentDamageStroke = [];
    notifyListeners();
  }

  void updateDamageMark(
    int index, {
    String? part,
    String? damageType,
    String? severity,
    String? remarks,
    dynamic photo,
    String? photoPath,
    String? photoUrl,
  }) {
    if (index >= 0 && index < damageMarks.length) {
      final mark = damageMarks[index];
      if (part != null) mark['part'] = part;
      if (damageType != null) mark['damage_type'] = damageType;
      if (severity != null) mark['severity'] = severity;
      if (remarks != null) mark['remarks'] = remarks;
      if (photo != null) mark['photo'] = photo;
      if (photoPath != null) mark['photo_path'] = photoPath;
      if (photoUrl != null) mark['photo_url'] = photoUrl;
      notifyListeners();
    }
  }

  void undoDamageMark({String? view}) {
    if (currentDamageStroke.isNotEmpty) {
      currentDamageStroke = [];
      notifyListeners();
      return;
    }
    if (damageMarks.isEmpty) return;

    if (view != null) {
      final idx = damageMarks.lastIndexWhere((m) => m['view'] == view);
      if (idx != -1) {
        damageMarks.removeAt(idx);
        notifyListeners();
        return;
      }
    }
    damageMarks.removeLast();
    notifyListeners();
  }

  void clearDamageMarksForView(String view) {
    damageMarks.removeWhere((m) => m['view'] == view);
    if (selectedDamageView == view) {
      currentDamageStroke = [];
    }
    notifyListeners();
  }

  void clearAllDamageMarks() {
    damageMarks.clear();
    currentDamageStroke = [];
    notifyListeners();
  }

  void removeDamageMark(int index) {
    damageMarks.removeAt(index);
    notifyListeners();
  }

  void loadExistingInspection(Map<String, dynamic> inspectionDetails) {
    if (inspectionDetails['tyre'] is Map) {
      final tyre = Map<String, dynamic>.from(inspectionDetails['tyre'] as Map);
      tyreWheelAssessment
        ..clear()
        ..addAll(
          Map<String, dynamic>.from(tyre['wheel_assessment'] as Map? ?? {})
              .map((key, value) => MapEntry(key, value.toString())),
        );
      tyrePressure = (tyre['pressure'] ?? '').toString();
      tyreTreadDepth = (tyre['tread_depth'] ?? '').toString();
      tyreTwiValueController.text = (tyre['twi_value'] ?? '').toString();
      tyreWearIndicators = (tyre['wear_indicators'] ?? '').toString();
      tyreWearDistribution
        ..clear()
        ..addAll(List<String>.from(tyre['wear_distribution'] ?? const []));
      tyreSurfaceDamage
        ..clear()
        ..addAll(List<String>.from(tyre['surface_damage'] ?? const []));
      tyreStructuralDamage
        ..clear()
        ..addAll(List<String>.from(tyre['structural_damage'] ?? const []));
      tyreDotYear = (tyre['dot_year'] ?? '').toString();
      tyreValveIssues
        ..clear()
        ..addAll(List<String>.from(tyre['valve_issues'] ?? const []));
      tyreRimIssues
        ..clear()
        ..addAll(List<String>.from(tyre['rim_issues'] ?? const []));
    }

    final marks = inspectionDetails['damage_marks'];
    if (marks is List) {
      damageMarks
        ..clear()
        ..addAll(
          marks.whereType<Map>().map((row) {
            final m = Map<String, dynamic>.from(row);
            return {
              'id': m['id'] ?? 'damage-${DateTime.now().microsecondsSinceEpoch}',
              'view': m['view'] ?? 'Front',
              'part': m['part'] ?? 'Other',
              'damage_type': m['damage_type'] ?? 'Scratch',
              'severity': m['severity'] ?? 'Minor',
              'remarks': m['remarks'] ?? '',
              'photo_url': m['photo_url'] ?? '',
              'photo_path': m['photo_path'],
              'points': m['points'] ?? [],
            };
          }),
        );
    }

    final tServices = inspectionDetails['tyre_services'];
    if (tServices is Map) {
      tyreServices
        ..clear()
        ..addAll(Map<String, dynamic>.from(tServices));
    }

    final brakeService = inspectionDetails['brake_service'];
    if (brakeService is Map) {
      brakeInspectionValues
        ..clear()
        ..addAll(
          Map<String, dynamic>.from(brakeService)
              .map((key, value) => MapEntry(key, value.toString())),
        );
    }

    final oilService = inspectionDetails['oil_service'];
    if (oilService is Map) {
      oilInspectionValues
        ..clear()
        ..addAll(
          Map<String, dynamic>.from(oilService)
              .map((key, value) => MapEntry(key, value.toString())),
        );
    }

    if (inspectionDetails['wheel_alignment'] is Map) {
      wheelAlignmentValues
        ..clear()
        ..addAll(
          Map<String, dynamic>.from(inspectionDetails['wheel_alignment'] as Map)
              .map((key, value) => MapEntry(key, value.toString())),
        );
    }

    if (inspectionDetails['oil'] is Map) {
      legacyOilInspectionValues
        ..clear()
        ..addAll(
          Map<String, dynamic>.from(inspectionDetails['oil'] as Map)
              .map((key, value) => MapEntry(key, value.toString())),
        );
    }

    if (inspectionDetails['checklist'] is Map) {
      checklistValues.clear();
      (inspectionDetails['checklist'] as Map).forEach((k, v) {
        if (v is Map) {
          checklistValues[k.toString()] = Map<String, dynamic>.from(v);
        }
      });
    }

    notifyListeners();
  }

  Map<String, dynamic> getInspectionPayload() {
    return {
      'damage_marks': damageMarks
          .map(
            (mark) => {
              'id': mark['id'] ?? '',
              'view': mark['view'] ?? '',
              'part': mark['part'] ?? '',
              'damage_type': mark['damage_type'] ?? 'Scratch',
              'severity': mark['severity'] ?? 'Minor',
              'remarks': mark['remarks'] ?? '',
              'photo_url': mark['photo_url'] ?? '',
              if (mark['photo_path'] != null) 'photo_path': mark['photo_path'],
              'points': mark['points'] ?? [],
            },
          )
          .toList(),
      'checklist': checklistValues,
      'tyre_services': tyreServices,
      'oil_service': oilInspectionValues,
      'brake_service': brakeInspectionValues,
      'tyre': {
        'wheel_assessment': tyreWheelAssessment,
        'pressure': tyrePressure,
        'tread_depth': tyreTreadDepth,
        'twi_value': tyreTwiValueController.text.trim(),
        'wear_indicators': tyreWearIndicators,
        'wear_distribution': tyreWearDistribution.toList(),
        'surface_damage': tyreSurfaceDamage.toList(),
        'structural_damage': tyreStructuralDamage.toList(),
        'dot_year': tyreDotYear,
        'valve_issues': tyreValveIssues.toList(),
        'rim_issues': tyreRimIssues.toList(),
      },
      'wheel_alignment': wheelAlignmentValues,
      'oil': legacyOilInspectionValues,
    };
  }

  @override
  void dispose() {
    damageRemarkController.dispose();
    tyreTwiValueController.dispose();
    super.dispose();
  }

  void notify() => notifyListeners();
}
