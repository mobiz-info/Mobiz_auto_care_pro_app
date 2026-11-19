import 'package:flutter/material.dart';
import '../models/job_card_model.dart';
import '../services/job_card_service.dart';

class JobCardBillingController extends ChangeNotifier {
  final TextEditingController billingAmountController = TextEditingController();
  final TextEditingController discountController = TextEditingController(text: '0');
  String discountType = 'amount'; // 'amount' or 'percent'
  String billingSaleType = 'cash';
  String billingPaymentMode = 'cash';
  Map<String, dynamic>? jobCardInvoice;
  bool loadingJobCardInvoice = false;
  bool creatingJobCardInvoice = false;

  double calculateDiscount(double subtotal) {
    final val = JobCardConstants.numberOrZero(discountController.text);
    if (discountType == 'percent') {
      return (subtotal * (val / 100.0));
    }
    return val;
  }

  double calculateEffectiveTotal(double billingTotal) {
    final disc = calculateDiscount(billingTotal);
    return (billingTotal - disc).clamp(0.0, double.infinity);
  }

  void setDiscountType(String type, double billingTotal) {
    discountType = type;
    final finalTotal = calculateEffectiveTotal(billingTotal);
    if (billingSaleType == 'cash') {
      billingAmountController.text = finalTotal.toStringAsFixed(2);
    }
    notifyListeners();
  }

  void updateTotals(double billingTotal) {
    final finalTotal = calculateEffectiveTotal(billingTotal);
    if (billingSaleType == 'cash') {
      billingAmountController.text = finalTotal.toStringAsFixed(2);
    }
    notifyListeners();
  }

  Future<void> loadJobCardInvoice(String? jobCardId, String token) async {
    if (jobCardId == null || loadingJobCardInvoice || jobCardInvoice != null) return;
    loadingJobCardInvoice = true;
    notifyListeners();

    try {
      final result = await JobCardService.getJobCardInvoice(jobCardId, token).timeout(const Duration(seconds: 8));
      jobCardInvoice = result['invoice'] is Map
          ? Map<String, dynamic>.from(result['invoice'])
          : null;
      if (jobCardInvoice != null) {
        billingAmountController.text =
            (jobCardInvoice!['amount_collected'] ?? 0).toString();
      }
    } catch (_) {
    } finally {
      loadingJobCardInvoice = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createJobCardInvoice({
    required String? jobCardId,
    required String token,
    required Future<bool> Function() submitJobCard,
    double billingTotal = 0.0,
  }) async {
    if (jobCardInvoice != null || creatingJobCardInvoice) {
      return {'success': false, 'message': 'Invoice already created or processing'};
    }

    creatingJobCardInvoice = true;
    notifyListeners();

    final saved = await submitJobCard();
    if (!saved || jobCardId == null) {
      creatingJobCardInvoice = false;
      notifyListeners();
      return {'success': false, 'message': 'Failed to save Job Card'};
    }

    try {
      final discountVal = calculateDiscount(billingTotal);
      final discountPct = discountType == 'percent'
          ? JobCardConstants.numberOrZero(discountController.text)
          : 0.0;
      final result = await JobCardService.createJobCardInvoice(
        jobCardId,
        token,
        amountCollected: billingSaleType == 'cash'
            ? JobCardConstants.numberOrZero(billingAmountController.text)
            : 0,
        paymentMode: billingPaymentMode,
        discount: discountVal,
        discountType: discountType,
        discountPercentage: discountPct,
      );

      creatingJobCardInvoice = false;
      if (result['invoice'] is Map) {
        jobCardInvoice = Map<String, dynamic>.from(result['invoice']);
      }
      notifyListeners();
      return result;
    } catch (e) {
      creatingJobCardInvoice = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  void syncBillingTotal(double billingTotal) {
    if (billingAmountController.text.isEmpty) {
      final finalTotal = calculateEffectiveTotal(billingTotal);
      billingAmountController.text = finalTotal.toStringAsFixed(2);
    }
  }

  void setBillingSaleType(String type, double billingTotal) => setSaleType(type, billingTotal);
  void setSaleType(String type, double billingTotal) {
    billingSaleType = type;
    final finalTotal = calculateEffectiveTotal(billingTotal);
    billingAmountController.text = type == 'cash' ? finalTotal.toStringAsFixed(2) : '0';
    notifyListeners();
  }

  void setBillingPaymentMode(String mode) => setPaymentMode(mode);
  void setPaymentMode(String mode) {
    billingPaymentMode = mode;
    notifyListeners();
  }

  @override
  void dispose() {
    billingAmountController.dispose();
    discountController.dispose();
    super.dispose();
  }

  void notify() => notifyListeners();
}
