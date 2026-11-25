import 'package:flutter/material.dart';

class ServiceReminderItem {
  final String? serviceId;
  final String serviceName;
  final String? categoryName;
  bool isEnabled;
  final List<TextEditingController> daysControllers;

  ServiceReminderItem({
    this.serviceId,
    required this.serviceName,
    this.categoryName,
    this.isEnabled = false,
    List<TextEditingController>? daysControllers,
  }) : daysControllers = daysControllers ?? [];

  void addDays([String days = '120']) {
    daysControllers.add(TextEditingController(text: days));
  }

  void removeDays(int index) {
    if (index >= 0 && index < daysControllers.length) {
      final ctrl = daysControllers.removeAt(index);
      ctrl.dispose();
    }
  }

  void dispose() {
    for (final c in daysControllers) {
      c.dispose();
    }
    daysControllers.clear();
  }
}

class JobCardRemindersController extends ChangeNotifier {
  final Map<String, ServiceReminderItem> serviceReminders = {};
  final List<ServiceReminderItem> customReminders = [];

  List<ServiceReminderItem> get allServiceList => serviceReminders.values.toList();

  String _inferTemplate(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('oil')) return 'oilreminder';
    if (lower.contains('wheel') || lower.contains('alignment') || lower.contains('balance')) {
      return 'wheelalignment';
    }
    if (lower.contains('smoke') || lower.contains('pollution')) return 'smoketest';
    if (lower.contains('battery')) return 'batteryservice';
    if (lower.contains('insurance')) return 'insurancereminder';
    return 'servicesreminder';
  }

  String _defaultDaysFor(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('oil')) return '90';
    if (lower.contains('wheel') || lower.contains('alignment')) return '90';
    if (lower.contains('battery')) return '180';
    return '120';
  }

  void syncWithServices(
    List<Map<String, dynamic>> addedServices,
    List<Map<String, dynamic>> reportedIssues,
  ) {
    bool changed = false;

    for (final s in addedServices) {
      final name = (s['name'] ?? s['service_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final id = (s['id'] ?? s['service_id'])?.toString();
      final cat = (s['category_name'] ?? s['category']?['name'])?.toString();

      if (!serviceReminders.containsKey(key)) {
        serviceReminders[key] = ServiceReminderItem(
          serviceId: id,
          serviceName: name,
          categoryName: cat,
          isEnabled: false,
        );
        changed = true;
      }
    }

    for (final issue in reportedIssues) {
      final name = (issue['service']?['name'] ??
              issue['service_name'] ??
              issue['issue_text'] ??
              issue['issue']?['name'] ??
              '')
          .toString()
          .trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final id = issue['service']?['id']?.toString();
      final cat = issue['category']?['name']?.toString();

      if (!serviceReminders.containsKey(key)) {
        serviceReminders[key] = ServiceReminderItem(
          serviceId: id,
          serviceName: name,
          categoryName: cat,
          isEnabled: false,
        );
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void toggleServiceReminder(String key, bool? enabled) {
    final item = serviceReminders[key];
    if (item == null) return;
    item.isEnabled = enabled ?? false;
    if (item.isEnabled && item.daysControllers.isEmpty) {
      item.addDays(_defaultDaysFor(item.serviceName));
    }
    notifyListeners();
  }

  void addDaysToService(String key, [String? days]) {
    final item = serviceReminders[key];
    if (item == null) return;
    item.addDays(days ?? _defaultDaysFor(item.serviceName));
    notifyListeners();
  }

  void removeDaysFromService(String key, int index) {
    final item = serviceReminders[key];
    if (item == null) return;
    item.removeDays(index);
    notifyListeners();
  }

  void addCustomReminder() {
    final item = ServiceReminderItem(
      serviceName: 'Custom Service',
      isEnabled: true,
    );
    item.addDays('120');
    customReminders.add(item);
    notifyListeners();
  }

  void removeCustomReminder(int index) {
    if (index >= 0 && index < customReminders.length) {
      final item = customReminders.removeAt(index);
      item.dispose();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getPayload() {
    final List<Map<String, dynamic>> payload = [];

    for (final item in serviceReminders.values) {
      if (!item.isEnabled) continue;
      for (final ctrl in item.daysControllers) {
        final days = int.tryParse(ctrl.text.trim()) ?? 0;
        if (days > 0) {
          payload.add({
            'service_id': item.serviceId,
            'service_name': item.serviceName,
            'days_after': days,
            'template_name': _inferTemplate(item.serviceName),
          });
        }
      }
    }

    for (final item in customReminders) {
      if (!item.isEnabled) continue;
      for (final ctrl in item.daysControllers) {
        final days = int.tryParse(ctrl.text.trim()) ?? 0;
        if (days > 0) {
          payload.add({
            'service_id': item.serviceId,
            'service_name': item.serviceName,
            'days_after': days,
            'template_name': _inferTemplate(item.serviceName),
          });
        }
      }
    }

    return payload;
  }

  void loadFromData(dynamic rawReminders) {
    for (final item in serviceReminders.values) {
      item.dispose();
    }
    serviceReminders.clear();
    for (final item in customReminders) {
      item.dispose();
    }
    customReminders.clear();

    if (rawReminders is! List || rawReminders.isEmpty) {
      notifyListeners();
      return;
    }

    for (final r in rawReminders) {
      if (r is! Map) continue;
      final svcName = (r['service_name'] ?? r['service']?['name'] ?? '').toString().trim();
      final svcId = (r['service_id'] ?? r['service']?['id'])?.toString();
      final daysVal = int.tryParse((r['days_after'] ?? r['days'] ?? '').toString()) ?? 0;
      if (daysVal <= 0) continue;

      final key = svcName.isNotEmpty ? svcName.toLowerCase() : 'custom_${customReminders.length}';
      if (svcName.isNotEmpty) {
        if (!serviceReminders.containsKey(key)) {
          serviceReminders[key] = ServiceReminderItem(
            serviceId: svcId,
            serviceName: svcName,
            isEnabled: true,
          );
        }
        final item = serviceReminders[key]!;
        item.isEnabled = true;
        item.addDays(daysVal.toString());
      } else {
        final item = ServiceReminderItem(
          serviceName: 'General Reminder',
          isEnabled: true,
        );
        item.addDays(daysVal.toString());
        customReminders.add(item);
      }
    }
    notifyListeners();
  }

  void notify() => notifyListeners();

  @override
  void dispose() {
    for (final item in serviceReminders.values) {
      item.dispose();
    }
    serviceReminders.clear();
    for (final item in customReminders) {
      item.dispose();
    }
    customReminders.clear();
    super.dispose();
  }
}
