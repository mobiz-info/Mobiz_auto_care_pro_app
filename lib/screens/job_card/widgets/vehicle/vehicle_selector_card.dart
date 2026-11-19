import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../controllers/job_card_customer_controller.dart';
import '../../controllers/job_card_vehicle_controller.dart';
import '../../../add_vehicle_screen.dart';
import 'selected_vehicle_details_card.dart';

class VehicleSelectorCard extends StatelessWidget {
  final JobCardVehicleController vehicleCtrl;
  final JobCardCustomerController customerCtrl;

  const VehicleSelectorCard({
    super.key,
    required this.vehicleCtrl,
    required this.customerCtrl,
  });

  void _openAddVehiclePage(BuildContext context) async {
    if (customerCtrl.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select a customer first'))),
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final customerData = Map<String, dynamic>.from(customerCtrl.selectedCustomer!);
    customerData['id'] = customerData['id'].toString();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(
          customerData: customerData,
          token: token,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Vehicle added successfully!')),
          backgroundColor: Colors.green,
        ),
      );
      await vehicleCtrl.reloadCustomerVehicles(
        customerData['id'].toString(),
        token,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vehicleCtrl,
      builder: (context, _) {
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
                    context.tr('2. Vehicle Information'),
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAddVehiclePage(context),
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF000080)),
                    label: Text(
                      context.tr('+ Add Vehicle'),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (vehicleCtrl.customerVehicles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr(
                            'No vehicles registered for this customer. Please add one.',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: vehicleCtrl.customerVehicles.map((v) {
                    final isSelected = vehicleCtrl.selectedVehicle?['id'] == v['id'];
                    final plate = (v['no'] ?? v['vehicle_number'] ?? '-').toString();
                    final make = (v['make'] ?? '').toString();
                    final model = (v['model'] ?? v['type'] ?? '').toString();
                    final desc = [make, model].where((s) => s.isNotEmpty).join(' ');

                    return InkWell(
                      onTap: () => vehicleCtrl.selectVehicle(v as Map<String, dynamic>),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF000080)
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? const Color(0xFF000080)
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                plate,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc.isNotEmpty ? desc : 'Vehicle',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  if ((v['segment'] ?? '').toString().isNotEmpty ||
                                      (v['fuel_type'] ?? '').toString().isNotEmpty)
                                    Text(
                                      '${v['segment'] ?? ''} ${(v['segment'] != null && v['fuel_type'] != null) ? '•' : ''} ${v['fuel_type'] ?? ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (vehicleCtrl.selectedVehicle != null)
                SelectedVehicleDetailsCard(controller: vehicleCtrl),
            ],
          ),
        );
      },
    );
  }
}
