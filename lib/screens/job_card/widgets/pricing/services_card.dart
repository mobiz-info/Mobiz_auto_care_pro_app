import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_issues_controller.dart';
import '../../controllers/job_card_pricing_controller.dart';
import '../common/job_item_widgets.dart';

class ServicesCard extends StatelessWidget {
  final JobCardPricingController pricingCtrl;
  final JobCardIssuesController issuesCtrl;

  const ServicesCard({
    super.key,
    required this.pricingCtrl,
    required this.issuesCtrl,
  });

  Future<Map<String, dynamic>?> _pickJobMaster(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> options,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, refresh) {
            final filtered = options
                .where(
                  (item) => item['name'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  16.h,
                  16.w,
                  MediaQuery.viewInsetsOf(ctx).bottom + 16.h,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * .65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ctx.tr(title),
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        autofocus: true,
                        onChanged: (value) =>
                            refresh(() => query = value.trim()),
                        decoration: InputDecoration(
                          hintText: ctx.tr('Search'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, index) => ListTile(
                            key: ValueKey(
                              '${title}_${filtered[index]['id']}',
                            ),
                            title: Text(filtered[index]['name'].toString()),
                            onTap: () => Navigator.of(sheetContext).pop(filtered[index]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<AuthProvider>().currencySymbol.trim();
    return AnimatedBuilder(
      animation: Listenable.merge([pricingCtrl, issuesCtrl]),
      builder: (context, _) {
        final filteredServices = pricingCtrl.availableServices
            .where((s) => s['category_id']?.toString() == pricingCtrl.selectedCategory)
            .map((service) => Map<String, dynamic>.from(service as Map))
            .toList();

        final servicesTotal =
            pricingCtrl.calculateServicesSubtotal(issuesCtrl.reportedIssues);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('Service Details'),
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (pricingCtrl.isLoadingServices)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: pricingCtrl.selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('Service Category *'),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: pricingCtrl.serviceCategories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category['id'].toString(),
                        child: Text(
                          category['name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  pricingCtrl.selectedCategory = category;
                  pricingCtrl.selectedServiceItem = null;
                  pricingCtrl.serviceRateController.clear();
                  pricingCtrl.notify();
                },
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: () async {
                  final service = await _pickJobMaster(
                    context,
                    'Select Service',
                    filteredServices,
                  );
                  if (service == null) return;
                  pricingCtrl.selectedServiceItem = service;
                  pricingCtrl.serviceRateController.text =
                      (service['rate'] ?? 0).toString();
                  pricingCtrl.notify();
                },
                borderRadius: BorderRadius.circular(10.r),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('Service *'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    pricingCtrl.selectedServiceItem?['name']?.toString() ??
                        context.tr('Select an option'),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: pricingCtrl.selectedServiceItem == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pricingCtrl.serviceRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.tr('Rate'),
                        labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pricingCtrl.serviceQtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr('Qty'),
                        labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pricingCtrl.serviceDiscountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.tr('Discount'),
                        labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pricingCtrl.serviceWarrantyController,
                      decoration: InputDecoration(
                        labelText: context.tr('Warranty (e.g. 6 Months)'),
                        labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pricingCtrl.serviceRemarkController,
                      decoration: InputDecoration(
                        labelText: context.tr('Remark / Note'),
                        labelStyle: GoogleFonts.inter(fontSize: 11.sp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => pricingCtrl.addServiceToTable(
                      onMessage: (msg) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(context.tr(msg)))),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      context.tr('+ Add'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pricingCtrl.addedServices.isNotEmpty) ...[
                ItemsTableWidget(
                  items: pricingCtrl.addedServices,
                  onDelete: (idx) {
                    pricingCtrl.addedServices.removeAt(idx);
                    pricingCtrl.notify();
                  },
                  particularKey: 'service_name',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Text(
                      '${context.tr('Service Total')}: $currencySymbol ${servicesTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
