import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/job_card_provider.dart';
import '../services/api_service.dart';
import '../utils/job_card_pdf_helper.dart';
import '../widgets/job_card_responsive.dart';
import 'job_card_create_screen.dart';
import 'job_card/widgets/vehicle/vehicle_before_after_photos_card.dart';

class JobCardDetailScreen extends StatefulWidget {
  final String jobCardId;

  const JobCardDetailScreen({super.key, required this.jobCardId});

  @override
  State<JobCardDetailScreen> createState() => _JobCardDetailScreenState();
}

class _JobCardDetailScreenState extends State<JobCardDetailScreen> {
  Map<String, dynamic>? get _jobCard =>
      context.read<JobCardProvider>().detailFor(widget.jobCardId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDetails();
      }
    });
  }

  Future<void> _fetchDetails() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<JobCardProvider>().fetchJobCardDetail(
      widget.jobCardId,
      token,
    );
  }

  Future<void> _deleteJobCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete Job Card?')),
        content: Text(
          context.tr(
            'This Job Card will be removed. Its lead or quotation can be converted again.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final response = await ApiService.deleteJobCard(widget.jobCardId, token);
      if (!mounted) return;
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Could not delete Job Card'),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'delayed':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFEFF6FF);
      case 'in_progress':
        return const Color(0xFFFEF3C7);
      case 'delayed':
        return const Color(0xFFFEE2E2);
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _sharePdf() async {
    if (_jobCard == null) return;
    try {
      final auth = context.read<AuthProvider>();
      final companyLogo = _jobCard?['company_logo'] ?? auth.companyLogo;
      await JobCardPdfHelper.shareJobCardPdf(
        _jobCard!,
        companyName: auth.companyName,
        branchName: auth.branchName,
        companyLogo: companyLogo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVehicleDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF000080)),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showUpdateStatusSheet() {
    if (_jobCard == null) return;
    final currentStatus = (_jobCard!['status'] ?? 'new').toString();
    final currentSection = (_jobCard!['current_section'] ?? '').toString();
    final currentService = (_jobCard!['current_service'] ?? '').toString();

    final sectionController = TextEditingController(text: currentSection);
    final serviceController = TextEditingController(text: currentService);
    String selectedStatus = currentStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('Update Status & Progress'),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: context.tr('Status'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'new',
                          child: Text(context.tr('New')),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text(context.tr('In Progress')),
                        ),
                        DropdownMenuItem(
                          value: 'delayed',
                          child: Text(context.tr('Delayed')),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text(context.tr('Completed')),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text(context.tr('Cancelled')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setSheetState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: sectionController,
                      decoration: InputDecoration(
                        labelText: context.tr('Current Section'),
                        hintText: 'e.g. Washing, Detailing, Mechanical',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: serviceController,
                      decoration: InputDecoration(
                        labelText: context.tr('Current Service'),
                        hintText: 'e.g. Full Foam Wash, Oil Change',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final token = context.read<AuthProvider>().token;
                        if (token == null) return;

                        final res = await ApiService.updateJobCardStatus(
                          widget.jobCardId,
                          {
                            'status': selectedStatus,
                            'current_section': sectionController.text.trim(),
                            'current_service': serviceController.text.trim(),
                          },
                          token,
                        );

                        if (mounted) {
                          if (res['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('Status updated successfully'),
                                ),
                              ),
                            );
                            _fetchDetails();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message'] ?? 'Failed to update status',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        context.tr('Update Status'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
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
    final jobCardState = context.watch<JobCardProvider>();
    final jobCard = jobCardState.detailFor(widget.jobCardId);
    if (jobCardState.isLoadingDetail(widget.jobCardId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Job Card Details'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (jobCardState.detailError(widget.jobCardId).isNotEmpty ||
        jobCard == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Job Card Details'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(jobCardState.detailError(widget.jobCardId)),
              ElevatedButton(
                onPressed: _fetchDetails,
                child: Text(context.tr('Retry')),
              ),
            ],
          ),
        ),
      );
    }

    final jc = jobCard;
    final customer = jc['customer'] as Map<String, dynamic>? ?? {};
    final vehicle = jc['vehicle'] as Map<String, dynamic>? ?? {};
    final services = (jc['services'] as List<dynamic>?) ?? [];
    final parts = (jc['parts'] as List<dynamic>?) ?? [];
    final labour = (jc['labour'] as List<dynamic>?) ?? [];
    final extras = (jc['extras'] as List<dynamic>?) ?? [];
    final reportedIssues = (jc['reported_issues'] as List<dynamic>?) ?? [];

    final status = (jc['status'] ?? 'new').toString();
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBgColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          jc['job_number'] ?? context.tr('Job Card'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: context.tr('Delete Job Card'),
            onPressed: _deleteJobCard,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: context.tr('Edit Job Card'),
            onPressed: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      JobCardCreateScreen(existingJobCardId: widget.jobCardId),
                ),
              );
              if (changed == true) _fetchDetails();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: context.tr('Share PDF via WhatsApp'),
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note, size: 26),
            tooltip: context.tr('Update Status / Section'),
            onPressed: _showUpdateStatusSheet,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 600 ? 2 : 3;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(customer['phone'] ?? ''),
                      icon: const Icon(
                        Icons.phone,
                        size: 18,
                        color: Color(0xFF000080),
                      ),
                      label: Text(
                        context.tr('Call'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF000080),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF000080)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: OutlinedButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 18,
                        color: Colors.green,
                      ),
                      label: Text(
                        context.tr('Share PDF'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      onPressed: _showUpdateStatusSheet,
                      icon: const Icon(
                        Icons.update,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        context.tr('Status'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: JobCardContent(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Job Card Header Banner ──────────────────────────────────
              Container(
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
                          jc['job_number'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF000080),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            jc['status_display'] ?? status.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (jc['invoice'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${jc['invoice']['invoice_number']}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.sp, color: const Color(0xFF166534)),
                                  ),
                                  Text(
                                    'Total: ₹${jc['invoice']['total']} • Balance: ₹${jc['invoice']['balance']}',
                                    style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final invNo = (jc['invoice']['invoice_number'] ?? '').toString().replaceAll('/', '_');
                                final pdfUrl = "${ApiService.baseUrl.replaceAll('/api', '')}/media/invoices/invoice-$invNo.pdf";
                                launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: Text(context.tr('PDF')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Created: ${jc['job_date']} • Branch: ${jc['branch_name']}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _detailMeta(
                            'Days Needed',
                            (jc['delivery_lead_time'] ?? '').isNotEmpty
                                ? jc['delivery_lead_time']
                                : ((jc['days_needed'] ?? '').isNotEmpty
                                    ? jc['days_needed']
                                    : (jc['expected_delivery_date'] ?? 'Not specified')),
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _detailMeta(
                            'Current Section',
                            jc['current_section'] ?? 'Inspection',
                            Icons.room_service,
                          ),
                        ),
                        Expanded(
                          child: _detailMeta(
                            'Current Service',
                            (jc['current_service'] ?? '').isNotEmpty
                                ? jc['current_service']
                                : '-',
                            Icons.build,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Customer Card ───────────────────────────────────────────────
              _buildSectionContainer(
                title: context.tr('Customer Details'),
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customer['name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer['customer_type'] ?? 'Individual',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _iconText(Icons.phone, customer['phone'] ?? ''),
                    if ((customer['email'] ?? '').isNotEmpty)
                      _iconText(Icons.email_outlined, customer['email']),
                    if ((customer['address'] ?? '').isNotEmpty)
                      _iconText(
                        Icons.location_on_outlined,
                        customer['address'],
                      ),
                    if ((customer['tax_number'] ?? '').isNotEmpty)
                      _iconText(
                        Icons.receipt_outlined,
                        'Tax No: ${customer['tax_number']}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Vehicle Card ────────────────────────────────────────────────
              _buildSectionContainer(
                title: context.tr('Vehicle Details'),
                icon: Icons.directions_car_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle['vehicle_number'] ?? vehicle['no'] ?? '-',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  vehicle['make'],
                                  vehicle['model'],
                                  vehicle['variant_trim'],
                                ].where((s) => (s ?? '').isNotEmpty).join(' '),
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if ((vehicle['model_year'] ?? '').isNotEmpty)
                                Text(
                                  'Year: ${vehicle['model_year']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((vehicle['segment'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.category_outlined,
                            context.tr('Segment'),
                            vehicle['segment'],
                          ),
                        if ((vehicle['vehicle_type'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.directions_car_outlined,
                            context.tr('Type'),
                            vehicle['vehicle_type'],
                          ),
                        if ((vehicle['fuel_type'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.local_gas_station_outlined,
                            context.tr('Fuel'),
                            vehicle['fuel_type'],
                          ),
                        if ((vehicle['transmission_type'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.settings_outlined,
                            context.tr('Transmission'),
                            vehicle['transmission_type'],
                          ),
                        if ((vehicle['color'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.palette_outlined,
                            context.tr('Color'),
                            vehicle['color'],
                          ),
                        if ((vehicle['wheel_type'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.adjust_outlined,
                            context.tr('Wheel'),
                            vehicle['wheel_type']
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                          ),
                        if ((vehicle['current_odometer_km'] ?? '')
                                .toString()
                                .isNotEmpty &&
                            (vehicle['current_odometer_km'] ?? '').toString() !=
                                '0')
                          _buildVehicleDetailChip(
                            Icons.speed_outlined,
                            context.tr('Odometer'),
                            '${vehicle['current_odometer_km']} KM',
                          ),
                        if ((vehicle['chassis_number'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.fingerprint_outlined,
                            context.tr('Chassis No'),
                            vehicle['chassis_number'],
                          ),
                        if ((vehicle['engine_number'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.hardware_outlined,
                            context.tr('Engine No'),
                            vehicle['engine_number'],
                          ),
                        if ((vehicle['emission_standard'] ?? '').isNotEmpty)
                          _buildVehicleDetailChip(
                            Icons.eco_outlined,
                            context.tr('Emission'),
                            vehicle['emission_standard'],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (reportedIssues.isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Reported Issues'),
                  icon: Icons.report_problem_outlined,
                  child: Column(
                    children: reportedIssues.map((raw) {
                      final issue = Map<String, dynamic>.from(raw as Map);
                      final photos = (issue['photos'] as List<dynamic>?) ?? [];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue['service']?['name']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF000080),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              issue['issue_text']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            if (photos.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: photos.map((rawPhoto) {
                                  final photo = Map<String, dynamic>.from(
                                    rawPhoto as Map,
                                  );
                                  final url = photo['url']?.toString() ?? '';
                                  return InkWell(
                                    onTap: () => showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) =>
                                          Dialog.fullscreen(
                                            backgroundColor: Colors.black,
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: InteractiveViewer(
                                                    minScale: .8,
                                                    maxScale: 5,
                                                    child: Center(
                                                      child: Image.network(url),
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top:
                                                      MediaQuery.paddingOf(
                                                        dialogContext,
                                                      ).top +
                                                      8,
                                                  right: 12,
                                                  child: IconButton.filledTonal(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.network(
                                        url,
                                        width: 70.w,
                                        height: 70.h,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (issue != reportedIssues.last)
                              Padding(
                                padding: EdgeInsets.only(top: 10.h),
                                child: const Divider(height: 1),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              _buildInspectionDetailsSection(jc),

              // ── Vehicle Before & After Photos ──────────────────────────────
              VehicleBeforeAfterPhotosCard(
                jobCardId: widget.jobCardId,
                token: context.read<AuthProvider>().token,
                initialBeforePhotos: jc['before_photos'] as List? ?? [],
                initialAfterPhotos: jc['after_photos'] as List? ?? [],
                onPhotosChanged: _fetchDetails,
              ),
              const SizedBox(height: 14),

              // ── Services Table ──────────────────────────────────────────────
              if (services.isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Services'),
                  icon: Icons.cleaning_services_outlined,
                  child: _buildItemsList(
                    services,
                    'service_name',
                    showWarranty: true,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Quality Check Section ─────────────────────────────────────
              _buildQualityCheckSection(jc),

              // ── Accessories & Parts Table ───────────────────────────────────
              if (parts.isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Accessories & Spare Parts'),
                  icon: Icons.settings_outlined,
                  child: _buildItemsList(
                    parts,
                    'product_name',
                    showPartNo: true,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Labour Table ────────────────────────────────────────────────
              if (labour.isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Labour Charges'),
                  icon: Icons.handyman_outlined,
                  child: _buildItemsList(labour, 'labour_particulars'),
                ),
                const SizedBox(height: 14),
              ],

              // ── Extras Table ────────────────────────────────────────────────
              if (extras.isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Extras'),
                  icon: Icons.more_horiz,
                  child: _buildItemsList(extras, 'extra_details'),
                ),
                const SizedBox(height: 14),
              ],

              // ── Remarks & Appointments ──────────────────────────────────────
              if ((jc['additional_remarks'] ?? '').isNotEmpty ||
                  (jc['appointment_details'] ?? '').isNotEmpty) ...[
                _buildSectionContainer(
                  title: context.tr('Remarks & Appointment Details'),
                  icon: Icons.notes_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((jc['additional_remarks'] ?? '').isNotEmpty)
                        Text(
                          jc['additional_remarks'],
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      if ((jc['appointment_details'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Appointment: ${jc['appointment_details']}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Cost Summary ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF000080).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('Total Estimated Cost'),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '₹${((jc['estimated_cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityCheckSection(Map<String, dynamic> jc) {
    final rawQcs = jc['quality_checks'] as List? ?? [];
    if (rawQcs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionContainer(
          title: context.tr('Quality Inspection Check'),
          icon: Icons.verified_outlined,
          child: Column(
            children: rawQcs.map((item) {
              final isSatisfied = item['status'] == 'satisfied';
              final serviceName = item['service_name']?.toString() ?? '';
              final remarks = item['remarks']?.toString() ?? '';
              final photos = (item['photos'] as List? ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSatisfied ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSatisfied ? const Color(0xFFE2E8F0) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            serviceName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSatisfied ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSatisfied ? Icons.check_circle : Icons.cancel,
                                size: 12,
                                color: isSatisfied ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSatisfied ? context.tr('Satisfied') : context.tr('Not Satisfied'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSatisfied ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (remarks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        remarks,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: photos.map((p) {
                          final url = p['url']?.toString() ?? '';
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black87,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: InteractiveViewer(
                                    child: Image.network(url, fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                url,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 55,
                                  height: 55,
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(Icons.broken_image, size: 20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            children: [
              Icon(icon, size: 18, color: const Color(0xFF000080)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildItemsList(
    List<dynamic> items,
    String particularKey, {
    bool showWarranty = false,
    bool showPartNo = false,
  }) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value as Map<String, dynamic>;
        final particular = item[particularKey] ?? '';
        final qty = item['quantity'] ?? 1;
        final rate = item['rate'] ?? 0;
        final total = item['total_amount'] ?? 0;
        final partNo = item['part_number'] ?? '';
        final warranty = item['warranty'] ?? '';
        final remark = item['remarks'] ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${idx + 1}.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      particular,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showPartNo && partNo.isNotEmpty)
                      Text(
                        'Part No: $partNo',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (showWarranty && warranty.isNotEmpty)
                      Text(
                        'Warranty: $warranty',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.green.shade700,
                        ),
                      ),
                    if (remark.toString().isNotEmpty)
                      Text(
                        'Note: $remark',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(total as num).toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$qty x ₹$rate',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _detailMeta(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF000080)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionDetailsSection(Map<String, dynamic> jc) {
    final rawInspection = jc['inspection_details'];
    final inspectionDetails = rawInspection is Map<String, dynamic>
        ? rawInspection
        : (rawInspection is Map
              ? Map<String, dynamic>.from(rawInspection)
              : <String, dynamic>{});
    final inspectionAt = (jc['inspection_at'] ?? '').toString();

    final tyre = inspectionDetails['tyre'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['tyre'] as Map)
        : <String, dynamic>{};
    final wheelAlignment = inspectionDetails['wheel_alignment'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['wheel_alignment'] as Map)
        : <String, dynamic>{};
    final oil = inspectionDetails['oil'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['oil'] as Map)
        : <String, dynamic>{};
    final tyreServices = inspectionDetails['tyre_services'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['tyre_services'] as Map)
        : <String, dynamic>{};
    final oilService = inspectionDetails['oil_service'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['oil_service'] as Map)
        : <String, dynamic>{};
    final brakeService = inspectionDetails['brake_service'] is Map
        ? Map<String, dynamic>.from(inspectionDetails['brake_service'] as Map)
        : <String, dynamic>{};
    final damageMarks = (inspectionDetails['damage_marks'] is List)
        ? List<Map<String, dynamic>>.from(
            (inspectionDetails['damage_marks'] as List).map(
              (m) => Map<String, dynamic>.from(m as Map),
            ),
          )
        : <Map<String, dynamic>>[];

    final hasTyre = tyre.values.any(
      (v) =>
          v != null &&
          v.toString().trim().isNotEmpty &&
          v.toString().trim() != '{}' &&
          v.toString().trim() != '[]',
    );
    final hasAlignment = wheelAlignment.values.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );
    final hasOil = oil.values.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );
    final hasTyreServices = tyreServices.values.any(
      (v) =>
          v != null && v.toString().trim().isNotEmpty && v.toString() != '[]',
    );
    final hasOilService = oilService.values.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );
    final hasBrakeService = brakeService.values.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );

    if (!hasTyre &&
        !hasAlignment &&
        !hasOil &&
        !hasTyreServices &&
        !hasOilService &&
        !hasBrakeService &&
        damageMarks.isEmpty &&
        inspectionAt.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionContainer(
          title: context.tr('Inspection Details'),
          icon: Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inspectionAt.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF000080),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${context.tr('Inspection Date')}: ${JobCardPdfHelper.formatDateTime(inspectionAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000080),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],

              // Vehicle Damage Inspection
              if (damageMarks.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Vehicle Damage Inspection'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${damageMarks.length} ${context.tr("Marked")}',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFFDE68A)),
                      const SizedBox(height: 8),
                      ...damageMarks.map((mark) {
                        final view = (mark['view'] ?? '').toString();
                        final part = (mark['part'] ?? '').toString();
                        final remarks = (mark['remarks'] ?? '').toString().trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  view,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  part,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (remarks.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    remarks,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF991B1B),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Tyre Inspection
              if (hasTyre) ...[
                Text(
                  context.tr('Tyre Inspection'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 8),

                // Wheel assessment
                if (tyre['wheel_assessment'] is Map &&
                    (tyre['wheel_assessment'] as Map).isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: (tyre['wheel_assessment'] as Map).entries.map((
                      e,
                    ) {
                      final wheelKey = e.key.toString();
                      final val = e.value.toString();
                      if (val.trim().isEmpty) return const SizedBox.shrink();
                      Color badgeColor = Colors.green.shade700;
                      Color badgeBg = Colors.green.shade50;
                      final lower = val.toLowerCase();
                      if (lower.contains('replace') ||
                          lower.contains('poor') ||
                          lower.contains('bad') ||
                          lower.contains('critical')) {
                        badgeColor = Colors.red.shade700;
                        badgeBg = Colors.red.shade50;
                      } else if (lower.contains('fair') ||
                          lower.contains('moderate') ||
                          lower.contains('check')) {
                        badgeColor = Colors.amber.shade900;
                        badgeBg = Colors.amber.shade50;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$wheelKey: $val',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Tyre metrics
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if ((tyre['pressure'] ?? '').toString().trim().isNotEmpty)
                      _inspectionMetric(
                        'Pressure',
                        tyre['pressure'].toString(),
                      ),
                    if ((tyre['tread_depth'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _inspectionMetric(
                        'Tread Depth',
                        tyre['tread_depth'].toString(),
                      ),
                    if ((tyre['twi_value'] ?? '').toString().trim().isNotEmpty)
                      _inspectionMetric(
                        'TWI Value',
                        tyre['twi_value'].toString(),
                      ),
                    if ((tyre['wear_indicators'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _inspectionMetric(
                        'Wear Indicator',
                        tyre['wear_indicators'].toString(),
                      ),
                    if ((tyre['dot_year'] ?? '').toString().trim().isNotEmpty)
                      _inspectionMetric(
                        'DOT Year',
                        tyre['dot_year'].toString(),
                      ),
                  ],
                ),

                // Damage / Issues lists
                ...[
                      ('Wear Distribution', tyre['wear_distribution']),
                      ('Surface Damage', tyre['surface_damage']),
                      ('Structural Damage', tyre['structural_damage']),
                      ('Valve Issues', tyre['valve_issues']),
                      ('Rim Issues', tyre['rim_issues']),
                    ]
                    .where(
                      (pair) =>
                          pair.$2 != null &&
                          (pair.$2 is List
                              ? (pair.$2 as List).isNotEmpty
                              : pair.$2.toString().trim().isNotEmpty),
                    )
                    .map((pair) {
                      final listVal = pair.$2 is List
                          ? (pair.$2 as List).join(', ')
                          : pair.$2.toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pair.$1}: ',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                listVal,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                const SizedBox(height: 12),
              ],

              // Wheel Alignment
              if (hasAlignment) ...[
                if (hasTyre) const Divider(height: 1),
                if (hasTyre) const SizedBox(height: 10),
                Text(
                  context.tr('Wheel Alignment & Balancing'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: wheelAlignment.entries
                      .where(
                        (e) =>
                            e.value != null &&
                            e.value.toString().trim().isNotEmpty,
                      )
                      .map((e) => _inspectionMetric(e.key, e.value.toString()))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Oil & Fluid
              if (hasOil) ...[
                if (hasTyre || hasAlignment) const Divider(height: 1),
                if (hasTyre || hasAlignment) const SizedBox(height: 10),
                Text(
                  context.tr('Oil & Fluid Inspection'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: oil.entries
                      .where(
                        (e) =>
                            e.value != null &&
                            e.value.toString().trim().isNotEmpty,
                      )
                      .map((e) => _inspectionMetric(e.key, e.value.toString()))
                      .toList(),
                ),
              ],
              if (hasTyreServices) ...[
                _inspectionKeyValueSection('Tyre Services', tyreServices),
              ],
              if (hasOilService) ...[
                _inspectionKeyValueSection('Oil Service', oilService),
              ],
              if (hasBrakeService) ...[
                _inspectionKeyValueSection('Brake Service', brakeService),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _inspectionMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectionKeyValueSection(String title, Map<String, dynamic> values) {
    final entries = values.entries.where((entry) {
      final value = entry.value;
      if (value == null) return false;
      if (value is List) return value.isNotEmpty;
      if (value is bool) return value;
      return value.toString().trim().isNotEmpty;
    }).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(title),
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: entries.map((entry) {
              final value = entry.value is List
                  ? (entry.value as List).join(', ')
                  : entry.value is bool
                  ? (entry.value as bool ? 'Yes' : 'No')
                  : entry.value.toString();
              return _inspectionMetric(entry.key, value);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
