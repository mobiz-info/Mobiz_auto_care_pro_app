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
import '../widgets/automotive_card.dart';
import 'job_card_create_screen.dart';
import 'job_card_detail_screen.dart';

class JobCardDashboardScreen extends StatefulWidget {
  const JobCardDashboardScreen({super.key});

  @override
  State<JobCardDashboardScreen> createState() => _JobCardDashboardScreenState();
}

class _JobCardDashboardScreenState extends State<JobCardDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['All', 'New', 'Delayed', 'History', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchJobCards();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobCards();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _currentTabKey {
    switch (_tabController.index) {
      case 1:
        return 'new';
      case 2:
        return 'delayed';
      case 3:
        return 'history';
      case 4:
        return 'completed';
      default:
        return 'all';
    }
  }

  Future<void> _fetchJobCards() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    await context.read<JobCardProvider>().fetchJobCards(
      token,
      tab: _currentTabKey,
      search: _searchController.text.trim(),
    );
    if (!mounted) return;
    if (_tabController.index == 0 || _tabController.index == 1) {
      await context.read<JobCardProvider>().fetchSuccessfulLeads(
        token,
        search: _searchController.text.trim(),
      );
    }
  }

  Future<void> _deleteJobCard(Map<String, dynamic> jobCard) async {
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
      final response = await ApiService.deleteJobCard(
        jobCard['id'].toString(),
        token,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('Job Card deleted'))));
        await _fetchJobCards();
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
        return const Color(0xFF2563EB); // Vibrant Blue
      case 'in_progress':
        return const Color(0xFFD97706); // Amber
      case 'delayed':
        return const Color(0xFFDC2626); // Red
      case 'completed':
        return const Color(0xFF16A34A); // Green
      case 'success':
        return const Color(0xFF15803D);
      case 'cancelled':
        return const Color(0xFF6B7280); // Gray
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
      case 'success':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Cannot launch phone dialer'))),
        );
      }
    }
  }

  Future<void> _openWhatsApp(
    String phone,
    String customerName,
    String jobNumber,
  ) async {
    var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    }
    final text = Uri.encodeComponent(
      'Hello $customerName, regarding your Job Card #$jobNumber at Mobiz Auto Care Pro: ',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Could not open WhatsApp'))),
        );
      }
    }
  }

  Future<void> _shareJobCardPdf(Map<String, dynamic> jc) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.5),
                SizedBox(width: 16),
                Text('Generating PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await ApiService.getJobCardDetail(jc['id'], token);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Dismiss loading
      }

      if (res['success'] == true && res['job_card'] != null) {
        final fullJc = res['job_card'] as Map<String, dynamic>;
        final auth = context.read<AuthProvider>();
        final companyLogo = fullJc['company_logo'] ?? auth.companyLogo;
        await JobCardPdfHelper.shareJobCardPdf(
          fullJc,
          companyName: auth.companyName,
          branchName: auth.branchName,
          companyLogo: companyLogo,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message'] ?? 'Failed to load Job Card details',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showContactOptions(Map<String, dynamic> jc) {
    final name = jc['customer_name'] ?? 'Customer';
    final phone = jc['customer_phone'] ?? '';
    final whatsapp = jc['customer_whatsapp'] ?? phone;
    final jobNo = jc['job_number'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF000080).withOpacity(0.1),
                      child: const Icon(Icons.person, color: Color(0xFF000080)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  title: Text(
                    context.tr('Call Customer'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(phone),
                  onTap: () {
                    Navigator.pop(ctx);
                    _makePhoneCall(phone);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat, color: Colors.green),
                  ),
                  title: Text(
                    context.tr('Chat on WhatsApp'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(whatsapp),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openWhatsApp(whatsapp, name, jobNo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _quickUpdateStatus(Map<String, dynamic> jc) {
    final jcId = jc['id'];
    final currentStatus = (jc['status'] ?? 'new').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final statuses = [
          {'key': 'new', 'label': 'New', 'color': Colors.blue},
          {
            'key': 'in_progress',
            'label': 'In Progress',
            'color': Colors.amber.shade800,
          },
          {'key': 'delayed', 'label': 'Delayed', 'color': Colors.red},
          {'key': 'completed', 'label': 'Completed', 'color': Colors.green},
          {'key': 'cancelled', 'label': 'Cancelled', 'color': Colors.grey},
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Update Status'),
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...statuses.map((st) {
                  final isSelected = st['key'] == currentStatus;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: st['color'] as Color,
                    ),
                    title: Text(
                      context.tr(st['label'] as String),
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF000080)
                            : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF000080))
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final token = context.read<AuthProvider>().token;
                      if (token == null) return;
                      final res = await ApiService.updateJobCardStatus(jcId, {
                        'status': st['key'],
                      }, token);
                      if (mounted) {
                        if (res['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('Status updated successfully'),
                              ),
                            ),
                          );
                          _fetchJobCards();
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
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobCardState = context.watch<JobCardProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.tr('Job Orders'),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('Refresh'),
            onPressed: _fetchJobCards,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF000080),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF000080),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs.map((t) => Tab(text: context.tr(t))).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'job-card-create-fab',
        backgroundColor: const Color(0xFF000080),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('New Job Card'),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JobCardCreateScreen()),
          );
          if (res == true) {
            _fetchJobCards();
          }
        },
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchJobCards(),
              decoration: InputDecoration(
                hintText: context.tr('Search Job No, Vehicle No, Customer...'),
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF000080)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchJobCards();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF000080),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Job Cards List ──────────────────────────────────────────
          Expanded(
            child:
                (jobCardState.isLoadingJobCards ||
                    (_tabController.index == 0 &&
                        jobCardState.isLoadingSuccessfulLeads))
                ? const Center(child: CircularProgressIndicator())
                : jobCardState.jobCardsError.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            jobCardState.jobCardsError,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchJobCards,
                            child: Text(context.tr('Retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : jobCardState.jobCards.isEmpty &&
                      (!(_tabController.index == 0 ||
                              _tabController.index == 1) ||
                          jobCardState.successfulLeads.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('No job cards found'),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchJobCards,
                    child: JobCardResponsiveList(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount:
                          jobCardState.jobCards.length +
                          ((_tabController.index == 0 ||
                                  _tabController.index == 1)
                              ? jobCardState.successfulLeads.length
                              : 0),
                      itemBuilder: (context, index) {
                        final showLeads =
                            _tabController.index == 0 ||
                            _tabController.index == 1;
                        if (showLeads &&
                            index < jobCardState.successfulLeads.length) {
                          final lead = Map<String, dynamic>.from(
                            jobCardState.successfulLeads[index] as Map,
                          );
                          return _buildJobCardItem(
                            _successfulLeadCardData(lead),
                          );
                        }
                        final cardIndex =
                            index -
                            (showLeads
                                ? jobCardState.successfulLeads.length
                                : 0);
                        final item = jobCardState.jobCards[cardIndex];
                        return _buildJobCardItem(
                          Map<String, dynamic>.from(item as Map),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _successfulLeadCardData(Map<String, dynamic> lead) {
    final services = (lead['service_interests'] as List? ?? [])
        .map((item) => (item as Map)['service_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
    return {
      'id': lead['id'],
      'source_lead': lead,
      'is_successful_lead': true,
      'job_number': lead['lead_number'] ?? 'Lead',
      'job_date': lead['lead_date'] ?? '',
      'vehicle_number': lead['vehicle_number'] ?? '-',
      'vehicle_make': lead['vehicle_make'] ?? '',
      'vehicle_model': lead['vehicle_model'] ?? '',
      'vehicle_type': lead['vehicle_type'] ?? '',
      'customer_name': lead['customer_name'] ?? '-',
      'customer_phone': lead['phone_number'] ?? '',
      'customer_whatsapp':
          lead['whatsapp_number'] ?? lead['phone_number'] ?? '',
      'estimated_cost': lead['expected_value'] ?? 0,
      'current_section': context.tr('Successful Lead'),
      'current_service': services,
      'delivery_date': lead['next_follow_up_date'] ?? '',
      'status': 'success',
      'status_display': context.tr('Successful Lead'),
    };
  }

  Widget _buildJobCardItem(Map<String, dynamic> jc) {
    final isSuccessfulLead = jc['is_successful_lead'] == true;
    final hasInvoice = jc['invoice'] != null;
    final status = (jc['status'] ?? 'new').toString();
    final workflowStatus = (jc['workflow_status'] ?? status).toString();
    final canContinue =
        !isSuccessfulLead && status != 'completed' && status != 'cancelled' && !hasInvoice;
    final resumeTab = workflowStatus == 'in_progress' ? 6 : 5;
    final statusDisplay = (jc['status_display'] ?? status).toString();
    final statusColor = _getStatusColor(status);
    final statusBg = _getStatusBgColor(status);

    final jobNo = jc['job_number'] ?? 'JC-000';
    final vehicleNo = jc['vehicle_number'] ?? '-';
    final customerName = jc['customer_name'] ?? '-';
    final vehicleType = jc['vehicle_type'] ?? '';
    final vehicleMake = jc['vehicle_make'] ?? '';
    final vehicleModel = jc['vehicle_model'] ?? '';
    final deliveryDate = jc['delivery_date'] ?? '';
    final leadTime = jc['delivery_lead_time'] ?? '';
    // final currentSection = jc['current_section'] ?? 'Inspection';
    final currentService = jc['current_service'] ?? '';
    final estCost = (jc['estimated_cost'] as num?)?.toDouble() ?? 0.0;

    String vehicleDesc = [
      vehicleMake,
      vehicleModel,
    ].where((s) => s.isNotEmpty).join(' ');
    if (vehicleDesc.isEmpty && vehicleType.isNotEmpty) {
      vehicleDesc = vehicleType;
    }

    return AutomotiveCardContainer(
      onTap: () async {
        if (isSuccessfulLead) {
          final sourceLead = Map<String, dynamic>.from(
            jc['source_lead'] as Map,
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobCardCreateScreen(
                initialLead: sourceLead,
              ),
            ),
          );
          if (result == true) _fetchJobCards();
        } else {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  JobCardDetailScreen(jobCardId: jc['id']),
            ),
          );
          if (updated == true) _fetchJobCards();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Job Number + Date + Status + Menu ─────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                AutomotiveIdBadge(idText: jobNo),
                SizedBox(width: 8.w),
                if ((jc['job_date'] ?? '').toString().isNotEmpty)
                  Text(
                    jc['job_date'] ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                AutomotiveStatusPill(
                  status: statusDisplay,
                  color: statusColor,
                  backgroundColor: statusBg,
                  onTap: isSuccessfulLead ? null : () => _quickUpdateStatus(jc),
                  showDropdownArrow: !isSuccessfulLead,
                ),
                if (!isSuccessfulLead) ...[
                  SizedBox(width: 4.w),
                  PopupMenuButton<String>(
                    tooltip: context.tr('More actions'),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 18.r,
                      color: Colors.grey.shade600,
                    ),
                    onSelected: (action) {
                      if (action == 'delete') _deleteJobCard(jc);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('Delete')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Vehicle & Customer Info ──────────────────────────────────
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    VehiclePlateBadge(plateNumber: vehicleNo),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('Estimated Cost'),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${estCost.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                if (vehicleDesc.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 14.r,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          vehicleDesc,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                ],

                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14.r,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        customerName,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Operational Info (Service & Days Needed) ─────
                if (currentService.isNotEmpty || leadTime.isNotEmpty || (deliveryDate.isNotEmpty && !hasInvoice)) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        if (currentService.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Current Service'),
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  currentService,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (leadTime.isNotEmpty || (deliveryDate.isNotEmpty && !hasInvoice))
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  leadTime.isNotEmpty
                                      ? context.tr('Days Needed')
                                      : (isSuccessfulLead ? context.tr('Follow-up') : context.tr('Delivery')),
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 11.r,
                                      color: Colors.orange.shade800,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      leadTime.isNotEmpty ? leadTime : deliveryDate,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Actions Footer ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 600 || isSuccessfulLead
                    ? 2
                    : canContinue
                    ? 4
                    : 3;
                final itemWidth =
                    (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: OutlinedButton.icon(
                        onPressed: () => _showContactOptions(jc),
                        icon: Icon(
                          Icons.call,
                          size: 15.r,
                          color: const Color(0xFF000080),
                        ),
                        label: Text(
                          context.tr('Contact'),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF000080)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                        ),
                      ),
                    ),
                    if (!isSuccessfulLead)
                      SizedBox(
                        width: itemWidth,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareJobCardPdf(jc),
                          icon: Icon(
                            Icons.picture_as_pdf,
                            size: 15.r,
                            color: Colors.green.shade700,
                          ),
                          label: Text(
                            context.tr('Share PDF'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.green.shade600),
                            foregroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                    if (hasInvoice)
                      SizedBox(
                        width: itemWidth,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final inv = jc['invoice'] as Map<String, dynamic>;
                            final invNo = (inv['invoice_number'] ?? '').toString().replaceAll('/', '_');
                            final pdfUrl = "${ApiService.baseUrl.replaceAll('/api', '')}/media/invoices/invoice-$invNo.pdf";
                            launchUrl(Uri.parse(pdfUrl), mode: LaunchMode.externalApplication);
                          },
                          icon: Icon(
                            Icons.receipt_long,
                            size: 15.r,
                            color: Colors.white,
                          ),
                          label: Text(
                            context.tr('View Invoice'),
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                    if (canContinue)
                      SizedBox(
                        width: itemWidth,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobCardCreateScreen(
                                  existingJobCardId: jc['id'].toString(),
                                  initialTabIndex: resumeTab,
                                ),
                              ),
                            );
                            if (updated == true) _fetchJobCards();
                          },
                          icon: Icon(
                            Icons.play_arrow_rounded,
                            size: 17.r,
                            color: const Color(0xFF000080),
                          ),
                          label: Text(
                            context.tr(
                              resumeTab == 6
                                  ? 'Continue Pricing'
                                  : 'Continue Progress',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF000080)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 8.h,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: itemWidth,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isSuccessfulLead) {
                            final sourceLead = Map<String, dynamic>.from(
                              jc['source_lead'] as Map,
                            );
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobCardCreateScreen(
                                  initialLead: sourceLead,
                                ),
                              ),
                            );
                            if (result == true) _fetchJobCards();
                          } else {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobCardDetailScreen(jobCardId: jc['id']),
                              ),
                            );
                            if (updated == true) _fetchJobCards();
                          }
                        },
                        icon: Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 15.r,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.tr(
                            isSuccessfulLead
                                ? 'Create Job Card'
                                : 'View Details',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
