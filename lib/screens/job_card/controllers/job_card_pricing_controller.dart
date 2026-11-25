import 'package:flutter/material.dart';
import '../models/job_card_model.dart';
import '../services/job_card_service.dart';

class JobCardPricingController extends ChangeNotifier {
  final List<Map<String, dynamic>> addedServices = [];
  final List<Map<String, dynamic>> addedParts = [];
  final List<Map<String, dynamic>> addedLabour = [];
  final List<Map<String, dynamic>> addedExtras = [];
  final List<Map<String, dynamic>> addedLocalPurchases = [];

  List<dynamic> availableServices = [];
  List<Map<String, dynamic>> serviceCategories = [];
  bool isLoadingServices = false;

  String? selectedCategory;
  Map<String, dynamic>? selectedServiceItem;
  final TextEditingController serviceRateController = TextEditingController();
  final TextEditingController serviceQtyController = TextEditingController(text: '1');
  final TextEditingController serviceDiscountController = TextEditingController(text: '0');
  final TextEditingController serviceWarrantyController = TextEditingController();
  final TextEditingController serviceWarrantyPeriodController = TextEditingController();
  final TextEditingController serviceRemarkController = TextEditingController();

  double rowTotal(Map<String, dynamic> row) {
    final rate = double.tryParse((row['rate'] ?? row['rate_with_tax'] ?? '').toString()) ?? 0;
    final quantity = double.tryParse((row['quantity'] ?? '1').toString()) ?? 1;
    final discount = double.tryParse((row['discount'] ?? '').toString()) ?? 0;
    return (rate * quantity - discount).clamp(0, double.infinity).toDouble();
  }

  void recalculateJobItem(Map<String, dynamic> row) {
    row['total_amount'] = rowTotal(row);
    notifyListeners();
  }

  double calculateIssuePricingSubtotal(List<Map<String, dynamic>> reportedIssues) {
    return reportedIssues.fold(0.0, (sum, row) {
      final rate = double.tryParse(row['rate']?.toString() ?? '') ?? 0;
      final qty = double.tryParse(row['quantity']?.toString() ?? '') ?? 1;
      final discount = double.tryParse(row['discount']?.toString() ?? '') ?? 0;
      return sum + (rate * qty - discount).clamp(0, double.infinity).toDouble();
    });
  }

  double calculateServicesSubtotal(List<Map<String, dynamic>> reportedIssues) {
    final issueSub = calculateIssuePricingSubtotal(reportedIssues);
    return addedServices.fold(
      issueSub,
      (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
    );
  }

  double get partsSubtotal => addedParts.fold(
        0.0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

  static double activityLabourNet(Map<dynamic, dynamic> activity) {
    final staffLabour = activity['staff_labour'] as List?;
    if (staffLabour != null && staffLabour.isNotEmpty) {
      return staffLabour.fold<double>(0, (sSum, sRaw) {
        final s = sRaw as Map;
        final cost = JobCardConstants.numberOrZero(s['cost']);
        final discount = JobCardConstants.numberOrZero(s['discount']);
        return sSum + (cost - discount).clamp(0, double.infinity);
      });
    }
    return (JobCardConstants.numberOrZero(activity['cost']) -
            JobCardConstants.numberOrZero(activity['discount']))
        .clamp(0, double.infinity);
  }

  double calculateLabourSubtotal(List<Map<String, dynamic>> reportedIssues) {
    return addedLabour.fold(
      reportedIssues.fold<double>(0, (sum, report) {
        final activities = report['activities'] as List? ?? [];
        return sum +
            activities.fold<double>(0, (activitySum, raw) {
              return activitySum + activityLabourNet(raw as Map);
            });
      }),
      (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
    );
  }

  double get extrasSubtotal => addedExtras.fold(
        0.0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

  double get localPurchasesSubtotal => addedLocalPurchases.fold(
        0.0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      );

  double calculateGrandEstimatedTotal(List<Map<String, dynamic>> reportedIssues) {
    return calculateServicesSubtotal(reportedIssues) +
        partsSubtotal +
        calculateLabourSubtotal(reportedIssues) +
        extrasSubtotal +
        localPurchasesSubtotal;
  }

  double calculateBillingTotal(List<Map<String, dynamic>> reportedIssues) {
    double total = 0;
    for (final rows in [
      addedServices,
      addedParts,
      addedLabour,
      addedExtras,
      addedLocalPurchases,
    ]) {
      for (final row in rows) {
        final net = JobCardConstants.numberOrZero(row['total_amount']);
        total += net + net * JobCardConstants.numberOrZero(row['vat_percentage']) / 100;
      }
    }
    total += reportedIssues.fold<double>(0, (sum, row) {
      final amount = JobCardConstants.numberOrZero(row['rate']) *
              JobCardConstants.numberOrZero(row['quantity'], fallback: 1) -
          JobCardConstants.numberOrZero(row['discount']);
      return sum + amount.clamp(0, double.infinity);
    });
    total += reportedIssues.fold<double>(0, (sum, report) {
      return sum +
          (report['activities'] as List? ?? []).fold<double>(0, (activitySum, raw) {
            return activitySum + activityLabourNet(raw as Map);
          });
    });
    return total;
  }

  void addServiceToTable({void Function(String message)? onMessage}) {
    if (selectedCategory == null || selectedServiceItem == null) {
      onMessage?.call('Select a service category and service');
      return;
    }

    final rate = double.tryParse(serviceRateController.text) ?? 0.0;
    final qty = double.tryParse(serviceQtyController.text) ?? 1.0;
    final discount = double.tryParse(serviceDiscountController.text) ?? 0.0;
    final name = selectedServiceItem!['name'];
    final svcId = selectedServiceItem!['id'];

    final base = (rate * qty) - discount;
    final total = base > 0 ? base : 0.0;

    addedServices.add({
      'service_id': svcId,
      'service_name': name,
      'quantity': qty,
      'unit': 'Unit',
      'rate': rate,
      'discount': discount,
      'vat_percentage': 0.0,
      'total_amount': total,
      'warranty': serviceWarrantyController.text.trim(),
      'warranty_period': serviceWarrantyPeriodController.text.trim(),
      'remarks': serviceRemarkController.text.trim(),
    });

    serviceRateController.clear();
    serviceQtyController.text = '1';
    serviceDiscountController.text = '0';
    serviceWarrantyController.clear();
    serviceRemarkController.clear();
    selectedServiceItem = null;
    notifyListeners();
  }

  void addLabourToTable() {
    addedLabour.add({
      'labour_particulars': '',
      'quantity': '1',
      'rate': '',
      'discount': '',
      'vat_percentage': 0.0,
      'total_amount': 0.0,
      'remarks': '',
    });
    notifyListeners();
  }

  void addExtraToTable() {
    addedExtras.add({
      'extra_details': '',
      'quantity': '1',
      'rate': '',
      'discount': '',
      'vat_percentage': 0.0,
      'total_amount': 0.0,
      'remarks': '',
    });
    notifyListeners();
  }

  void addPart(
    Map<String, dynamic> selected, {
    String? rate,
    String? quantity,
    String? discount,
    String? remarks,
  }) {
    final tax = (selected['tax_percent'] as num?)?.toDouble() ?? 0;
    final r = rate ??
        (selected['rate'] ??
                selected['sales_rate'] ??
                selected['price'] ??
                '')
            .toString();
    final q = quantity ?? '1';
    final d = discount ?? '';
    final row = {
      'stock_item_id': selected['id'],
      'part_number': selected['part_number'] ?? '',
      'alternate_part_number': selected['alternate_part_number'] ?? '',
      'product_code': selected['product_code'] ?? '',
      'product_name': selected['product_name'] ?? 'Accessory',
      'current_stock': selected['current_stock'] ?? selected['stock'] ?? 0,
      'unit': selected['unit'] ?? selected['unit_name'] ?? 'Pcs',
      'rate': r,
      'rate_with_tax': r,
      'quantity': q,
      'discount': d,
      'warranty_years': '0',
      'vat_percentage': tax,
      'total_amount': 0.0,
      'remarks': remarks ?? '',
    };
    row['total_amount'] = rowTotal(row);
    addedParts.add(row);
    notifyListeners();
  }

  Future<void> loadVehicleServices(String customerId, String vehicleId, String token) async {
    isLoadingServices = true;
    notifyListeners();
    try {
      final res = await JobCardService.getInvoiceServices(customerId, vehicleId, token);
      if (res['success'] == true) {
        final prices = <String, Map<String, dynamic>>{};
        for (final raw in (res['services'] as List? ?? [])) {
          final service = Map<String, dynamic>.from(raw as Map);
          prices[service['id'].toString()] = service;
        }
        availableServices = availableServices.map((raw) {
          final service = Map<String, dynamic>.from(raw as Map);
          final price = prices[service['id'].toString()];
          if (price != null) {
            service['rate'] = price['rate'] ?? service['rate'] ?? 0;
            service['service_type'] ??= price['service_type'];
          }
          return service;
        }).toList();
      }
    } catch (_) {
    } finally {
      isLoadingServices = false;
      notifyListeners();
    }
  }

  void loadExistingJobCard(Map<String, dynamic> data) {
    _replaceRows(addedServices, data['services']);
    _replaceRows(addedParts, data['parts']);
    _replaceRows(addedLabour, data['labour']);
    _replaceRows(addedExtras, data['extras']);
    _replaceRows(addedLocalPurchases, data['local_purchases']);
    notifyListeners();
  }

  void _replaceRows(List<Map<String, dynamic>> target, dynamic values) {
    if (values is List) {
      target.clear();
      target.addAll(values.map((e) => Map<String, dynamic>.from(e as Map)));
    }
  }

  List<Map<String, dynamic>> getPartsPayload() {
    return addedParts.map((row) {
      final rate = JobCardConstants.numberOrZero(row['rate']);
      final quantity = JobCardConstants.numberOrZero(row['quantity'], fallback: 1);
      final discount = JobCardConstants.numberOrZero(row['discount']);
      final tax = JobCardConstants.numberOrZero(row['vat_percentage']);
      return {
        ...row,
        'rate': rate,
        'rate_with_tax': rate * (1 + tax / 100),
        'quantity': quantity,
        'discount': discount,
        'warranty_years': JobCardConstants.numberOrZero(row['warranty_years']),
        'total_amount': (rate * quantity - discount).clamp(0, double.infinity).toDouble(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> getLabourPayload() {
    return addedLabour
        .where(
          (row) => (row['labour_particulars'] ?? '').toString().trim().isNotEmpty,
        )
        .map((row) {
      final rate = JobCardConstants.numberOrZero(row['rate']);
      final quantity = JobCardConstants.numberOrZero(row['quantity'], fallback: 1);
      final discount = JobCardConstants.numberOrZero(row['discount']);
      return {
        ...row,
        'quantity': quantity,
        'rate': rate,
        'discount': discount,
        'total_amount': (rate * quantity - discount).clamp(0, double.infinity).toDouble(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> getExtrasPayload() {
    return addedExtras
        .where(
          (row) => (row['extra_details'] ?? '').toString().trim().isNotEmpty,
        )
        .map((row) {
      final rate = JobCardConstants.numberOrZero(row['rate']);
      final quantity = JobCardConstants.numberOrZero(row['quantity'], fallback: 1);
      final discount = JobCardConstants.numberOrZero(row['discount']);
      return {
        ...row,
        'quantity': quantity,
        'rate': rate,
        'discount': discount,
        'total_amount': (rate * quantity - discount).clamp(0, double.infinity).toDouble(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> getLocalPurchasesPayload() {
    return addedLocalPurchases
        .where(
          (row) => (row['item_name'] ?? '').toString().trim().isNotEmpty,
        )
        .map((row) {
      final rate = JobCardConstants.numberOrZero(row['rate']);
      final quantity = JobCardConstants.numberOrZero(row['quantity'], fallback: 1);
      final discount = JobCardConstants.numberOrZero(row['discount']);
      final costPrice = JobCardConstants.numberOrZero(row['cost_price']);
      return {
        ...row,
        'cost_price': costPrice,
        'quantity': quantity,
        'rate': rate,
        'discount': discount,
        'total_amount': (rate * quantity - discount).clamp(0, double.infinity).toDouble(),
      };
    }).toList();
  }

  void addLocalPurchase({
    required String itemName,
    String? supplierName,
    String? billNumber,
    double costPrice = 0.0,
    double rate = 0.0,
    double quantity = 1.0,
    double discount = 0.0,
    String unit = 'Pcs',
    String? remarks,
  }) {
    final net = ((rate * quantity) - discount).clamp(0.0, double.infinity);
    addedLocalPurchases.add({
      'item_name': itemName,
      'supplier_name': supplierName ?? '',
      'bill_number': billNumber ?? '',
      'cost_price': costPrice,
      'rate': rate,
      'quantity': quantity,
      'discount': discount,
      'unit': unit,
      'vat_percentage': 0.0,
      'total_amount': net,
      'remarks': remarks ?? '',
    });
    notifyListeners();
  }

  void updateLocalPurchase(int index, Map<String, dynamic> updated) {
    if (index >= 0 && index < addedLocalPurchases.length) {
      final rate = JobCardConstants.numberOrZero(updated['rate']);
      final quantity = JobCardConstants.numberOrZero(updated['quantity'], fallback: 1);
      final discount = JobCardConstants.numberOrZero(updated['discount']);
      final net = ((rate * quantity) - discount).clamp(0.0, double.infinity);
      addedLocalPurchases[index] = {
        ...updated,
        'rate': rate,
        'quantity': quantity,
        'discount': discount,
        'total_amount': net,
      };
      notifyListeners();
    }
  }

  void removeLocalPurchase(int index) {
    if (index >= 0 && index < addedLocalPurchases.length) {
      addedLocalPurchases.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    serviceRateController.dispose();
    serviceQtyController.dispose();
    serviceDiscountController.dispose();
    serviceWarrantyController.dispose();
    serviceWarrantyPeriodController.dispose();
    serviceRemarkController.dispose();
    super.dispose();
  }

  void notify() => notifyListeners();
}
