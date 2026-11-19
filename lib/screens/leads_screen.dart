import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'lead_form_screen.dart';
import 'job_quotation_form_screen.dart';
import 'job_lead_update_screen.dart';
import '../widgets/job_card_responsive.dart';
import 'job_card_create_screen.dart';
import '../widgets/automotive_card.dart';
import 'quotation_search_screen.dart';
import '../utils/job_lead_pdf_helper.dart';

class LeadsScreen extends StatefulWidget {
  final bool jobWorkflow;
  const LeadsScreen({super.key, this.jobWorkflow = false});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          context.tr('Leads'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        bottom: widget.jobWorkflow
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.list_alt, size: 20),
                    text: context.tr('List'),
                  ),
                  Tab(
                    icon: const Icon(Icons.notifications_active, size: 20),
                    text: context.tr('Reminders'),
                  ),
                ],
              ),
      ),
      body: widget.jobWorkflow
          ? _LeadsListTab(jobWorkflow: true)
          : TabBarView(
              controller: _tabController,
              children: [const _LeadsListTab(), _LeadsRemindersTab()],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Leads List
// ─────────────────────────────────────────────────────────────────────────────

class _LeadsListTab extends StatefulWidget {
  final bool jobWorkflow;
  const _LeadsListTab({this.jobWorkflow = false});

  @override
  State<_LeadsListTab> createState() => _LeadsListTabState();
}

class _LeadsListTabState extends State<_LeadsListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<dynamic>> _leadsNotifier = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> _filteredLeadsNotifier = ValueNotifier([]);
  final TextEditingController _searchController = TextEditingController();
  String _pipelineFilter = 'all';
  DateTime _fromDate = DateUtils.dateOnly(DateTime.now());
  DateTime _toDate = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.jobWorkflow) _pipelineFilter = 'follow_up';
    _searchController.addListener(_filterLeads);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLeads());
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLeads);
    _searchController.dispose();
    _isLoadingNotifier.dispose();
    _leadsNotifier.dispose();
    _filteredLeadsNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    _isLoadingNotifier.value = true;
    try {
      final res = widget.jobWorkflow
          ? await ApiService.listJobLeads(token)
          : await ApiService.listLeads(token);
      if (res['status'] == 'success') {
        _leadsNotifier.value = List<dynamic>.from(res['leads'] ?? []);
        _filterLeads();
      }
    } catch (e) {
      _showSnack('Failed to load leads: $e', Colors.red);
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _filterLeads() {
    final q = _searchController.text.toLowerCase();
    _filteredLeadsNotifier.value = _leadsNotifier.value.where((l) {
      final statusMatches =
          _pipelineFilter == 'all' ||
          (l['status'] ?? 'follow_up') == _pipelineFilter;
      if (!statusMatches) return false;
      if (widget.jobWorkflow &&
          const {'follow_up', 'success', 'lost'}.contains(_pipelineFilter)) {
        final eventDate = _jobLeadDateForSelectedStatus(
          Map<String, dynamic>.from(l as Map),
        );
        if (eventDate == null) return false;
        final date = DateUtils.dateOnly(eventDate);
        if (date.isBefore(_fromDate) || date.isAfter(_toDate)) return false;
      }
      if (q.isEmpty) return true;
      final name = (l['customer_name'] ?? '').toString().toLowerCase();
      final phone = (l['phone_number'] ?? '').toString().toLowerCase();
      final vehicle = (l['vehicle_details'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || vehicle.contains(q);
    }).toList();
  }

  DateTime? _jobLeadDateForSelectedStatus(Map<String, dynamic> lead) {
    if (_pipelineFilter == 'follow_up') {
      return DateTime.tryParse((lead['next_follow_up_date'] ?? '').toString());
    }
    final followUps =
        List<Map<String, dynamic>>.from(
          (lead['follow_ups'] ?? const []).whereType<Map>().map(
            (event) => Map<String, dynamic>.from(event),
          ),
        )..sort((a, b) {
          final left = DateTime.tryParse((a['date_added'] ?? '').toString());
          final right = DateTime.tryParse((b['date_added'] ?? '').toString());
          return (right ?? DateTime(1970)).compareTo(left ?? DateTime(1970));
        });
    for (final event in followUps) {
      if (event['status']?.toString() == _pipelineFilter) {
        return DateTime.tryParse((event['date_added'] ?? '').toString());
      }
    }
    return DateTime.tryParse(
      (lead['date_updated'] ?? lead['lead_date'] ?? '').toString(),
    );
  }

  Future<void> _pickLeadDate({required bool from}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: from ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (from) {
        _fromDate = DateUtils.dateOnly(selected);
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = DateUtils.dateOnly(selected);
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      }
    });
    _filterLeads();
  }

  Widget _leadDateButton(String label, DateTime date, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined, size: 17),
      label: Text('$label  ${_formatDate(date.toIso8601String())}'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF000080),
        alignment: Alignment.centerLeft,
        padding: REdgeInsets.symmetric(horizontal: 10, vertical: 11),
      ),
    );
  }

  Future<void> _exportJobLeadPdf(
    Map<String, dynamic> lead, {
    required bool download,
  }) async {
    try {
      if (download) {
        await JobLeadPdfHelper.downloadLeadPdf(
          lead,
          companyName: context.read<AuthProvider>().companyName,
          companyLogo: context.read<AuthProvider>().companyLogo,
        );
      } else {
        await JobLeadPdfHelper.shareLeadPdf(
          lead,
          companyName: context.read<AuthProvider>().companyName,
          companyLogo: context.read<AuthProvider>().companyLogo,
        );
      }
    } catch (error) {
      if (mounted) {
        _showSnack('Unable to create lead PDF: $error', Colors.red);
      }
    }
  }

  Future<void> _openQuotationForLead(Map<String, dynamic> lead) async {
    if (widget.jobWorkflow) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobQuotationFormScreen(lead: lead)),
      );
      await _fetchLeads();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationSearchScreen(
          leadId: lead['id']?.toString(),
          jobWorkflow: widget.jobWorkflow,
        ),
      ),
    );
    await _fetchLeads();
  }

  Future<void> _recordFollowUp(Map<String, dynamic> lead) async {
    if (widget.jobWorkflow) {
      await _updateJobLead(lead);
      return;
    }
    final remarks = TextEditingController();
    final nextDate = TextEditingController();
    final chance = TextEditingController(
      text: (lead['success_chance'] ?? '').toString(),
    );
    final lostReason = TextEditingController(
      text: (lead['lost_reason'] ?? '').toString(),
    );
    var status = (lead['status'] ?? 'follow_up').toString();
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('Record Follow-up')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: remarks,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr('Remarks *'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nextDate,
                  decoration: InputDecoration(
                    labelText: context.tr('Next follow-up date (YYYY-MM-DD)'),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(labelText: context.tr('Status')),
                  items: const [
                    DropdownMenuItem(
                      value: 'follow_up',
                      child: Text('Follow-up'),
                    ),
                    DropdownMenuItem(value: 'quoted', child: Text('Quoted')),
                    DropdownMenuItem(value: 'success', child: Text('Success')),
                    DropdownMenuItem(value: 'lost', child: Text('Lost')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
                if (status != 'lost' && status != 'success') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: chance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('Success chance %'),
                    ),
                  ),
                ],
                if (status == 'lost') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: lostReason,
                    decoration: InputDecoration(
                      labelText: context.tr('Lost reason *'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (remarks.text.trim().isEmpty ||
                    (status == 'lost' && lostReason.text.trim().isEmpty)) {
                  _showSnack(
                    context.tr(
                      'Enter remarks and a lost reason when applicable.',
                    ),
                    Colors.red,
                  );
                  return;
                }
                try {
                  final followupData = {
                    'remarks': remarks.text.trim(),
                    'next_follow_up_date': nextDate.text.trim(),
                    'status': status,
                    'success_chance': status == 'success'
                        ? 100
                        : double.tryParse(chance.text.trim()),
                    'lost_reason': lostReason.text.trim(),
                  };
                  final response = widget.jobWorkflow
                      ? await ApiService.createJobLeadFollowUp(
                          token,
                          lead['id'].toString(),
                          followupData,
                        )
                      : await ApiService.createLeadFollowUp(
                          token,
                          lead['id'].toString(),
                          followupData,
                        );
                  if (response['status'] == 'success' ||
                      response['success'] == true) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await _fetchLeads();
                  } else {
                    _showSnack(
                      response['message'] ?? 'Failed to save follow-up',
                      Colors.red,
                    );
                  }
                } catch (e) {
                  _showSnack('Error: $e', Colors.red);
                }
              },
              child: Text(context.tr('Save')),
            ),
          ],
        ),
      ),
    );
    remarks.dispose();
    nextDate.dispose();
    chance.dispose();
    lostReason.dispose();
  }

  Future<void> _updateJobLead(Map<String, dynamic> lead) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => JobLeadUpdateScreen(lead: lead)),
    );
    if (updated == true && mounted) await _fetchLeads();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _openCreateOrEditSheet({Map<String, dynamic>? lead}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LeadFormScreen(lead: lead, jobWorkflow: widget.jobWorkflow),
      ),
    );
    if (result == true) {
      await _fetchLeads();
    }
  }

  Future<void> _deleteLead(String leadId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          context.tr('Delete Lead'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${context.tr('Delete lead for')} $name?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              context.tr('Delete'),
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = widget.jobWorkflow
          ? await ApiService.deleteJobLead(token, leadId)
          : await ApiService.deleteLead(token, leadId);
      if (res['status'] == 'success' || res['success'] == true) {
        _showSnack(context.tr('Lead deleted.'), Colors.green);
        await _fetchLeads();
      } else {
        _showSnack(res['message'] ?? 'Failed', Colors.red);
      }
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: REdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: context.tr('Search name, phone, vehicle...'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              ElevatedButton.icon(
                onPressed: () => _openCreateOrEditSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: REdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  context.tr('Create'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: REdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children:
                [
                      ('all', 'All'),
                      ('follow_up', 'Follow-ups'),
                      ('quoted', 'Quoted'),
                      ('success', 'Success'),
                      ('lost', 'Lost'),
                    ]
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(context.tr(entry.$2)),
                          selected: _pipelineFilter == entry.$1,
                          onSelected: (_) {
                            setState(() => _pipelineFilter = entry.$1);
                            _filterLeads();
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),

        if (widget.jobWorkflow &&
            const {'follow_up', 'success', 'lost'}.contains(_pipelineFilter))
          Container(
            color: Colors.white,
            padding: REdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _leadDateButton(
                    'From',
                    _fromDate,
                    () => _pickLeadDate(from: true),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _leadDateButton(
                    'To',
                    _toDate,
                    () => _pickLeadDate(from: false),
                  ),
                ),
              ],
            ),
          ),

        // List
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ValueListenableBuilder<List<dynamic>>(
                valueListenable: _filteredLeadsNotifier,
                builder: (context, leads, _) {
                  if (leads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 60.r,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            context.tr('No leads found.'),
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            context.tr('Tap Create to add your first lead.'),
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade400,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _fetchLeads,
                    child: widget.jobWorkflow
                        ? JobCardResponsiveList(
                            padding: REdgeInsets.all(16),
                            itemCount: leads.length,
                            itemBuilder: (_, i) => _buildLeadCard(
                              Map<String, dynamic>.from(leads[i] as Map),
                            ),
                          )
                        : ListView.separated(
                            padding: REdgeInsets.all(16),
                            itemCount: leads.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10.h),
                            itemBuilder: (_, i) => _buildLeadCard(leads[i]),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCard(Map<String, dynamic> lead) {
    if (widget.jobWorkflow) return _buildJobLeadCard(lead);
    final renewalDate = widget.jobWorkflow
        ? lead['next_follow_up_date']
        : lead['renewal_date'];
    final renewalDisplay = renewalDate != null
        ? _formatDate(renewalDate.toString())
        : context.tr('No date set');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: REdgeInsets.fromLTRB(16, 10, 12, 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF000080).withOpacity(0.1),
          radius: 22.r,
          child: Text(
            (lead['customer_name'] ?? '?').toString().isNotEmpty
                ? lead['customer_name'].toString()[0].toUpperCase()
                : '?',
            style: GoogleFonts.inter(
              color: const Color(0xFF000080),
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          lead['customer_name'] ?? '',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
            color: const Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.phone, size: 13.r, color: Colors.grey.shade500),
                SizedBox(width: 4.w),
                Text(
                  lead['phone_number'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if ((lead['vehicle_details'] ?? '').toString().isNotEmpty) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 13.r,
                    color: Colors.grey.shade500,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      lead['vehicle_details'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 4.h),
            Container(
              padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: renewalDate != null
                    ? const Color(0xFF000080).withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 11.r,
                    color: renewalDate != null
                        ? const Color(0xFF000080)
                        : Colors.grey.shade400,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    widget.jobWorkflow
                        ? '${context.tr('Next follow-up')}: $renewalDisplay'
                        : renewalDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: renewalDate != null
                          ? const Color(0xFF000080)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'quote') {
              _openQuotationForLead(Map<String, dynamic>.from(lead));
            }
            if (action == 'share_pdf') {
              _exportJobLeadPdf(Map<String, dynamic>.from(lead), download: false);
            }
            if (action == 'download_pdf') {
              _exportJobLeadPdf(Map<String, dynamic>.from(lead), download: true);
            }
            if (action == 'follow_up') {
              _recordFollowUp(Map<String, dynamic>.from(lead));
            }
            if (action == 'edit') {
              _openCreateOrEditSheet(lead: Map<String, dynamic>.from(lead));
            }
            if (action == 'delete') {
              _deleteLead(lead['id'].toString(), lead['customer_name'] ?? '');
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'quote',
              child: Text(context.tr('Create quotation')),
            ),
            PopupMenuItem(
              value: 'share_pdf',
              child: Text(context.tr('Share lead PDF')),
            ),
            PopupMenuItem(
              value: 'download_pdf',
              child: Text(context.tr('Download lead PDF')),
            ),
            PopupMenuItem(
              value: 'follow_up',
              child: Text(context.tr('Record follow-up')),
            ),
            PopupMenuItem(value: 'edit', child: Text(context.tr('Edit lead'))),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.tr('Delete lead')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobLeadCard(Map<String, dynamic> lead) {
    final makeModel = [
      lead['vehicle_make'],
      lead['vehicle_model'],
    ].where((v) => v != null && v.toString().trim().isNotEmpty).join(' · ');
    final vehicleDetails = (lead['vehicle_details'] ?? '').toString().trim();
    final vehicleDesc = makeModel.isNotEmpty
        ? makeModel
        : (vehicleDetails.isNotEmpty ? vehicleDetails : '');
    final plateNumber = (lead['vehicle_number'] ?? (vehicleDesc.isNotEmpty ? vehicleDesc : '-')).toString();

    final followUps = List<dynamic>.from(lead['follow_ups'] ?? []);
    final isCorporate = (lead['customer_type_name'] ?? '')
        .toString()
        .toLowerCase()
        .contains('corporate');
    final leadNumber = (lead['lead_number'] ?? '').toString();
    final leadDate = _formatDate((lead['lead_date'] ?? '').toString());
    final nextFollowUp = (lead['next_follow_up_date'] ?? '').toString();
    final customerName = (lead['customer_name'] ?? '-').toString();
    final phoneNumber = (lead['phone_number'] ?? '').toString();

    final interests = List<dynamic>.from(lead['service_interests'] ?? []);
    final serviceNames = interests
        .map((item) => (item['service_name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
    if (serviceNames.isEmpty &&
        (lead['service_name'] ?? '').toString().trim().isNotEmpty) {
      serviceNames.addAll(
        (lead['service_name'] as String)
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty),
      );
    }

    final mode = (lead['lead_generation_mode'] ?? '').toString();
    final reference = (lead['reference'] ?? '').toString();
    final city = (lead['city'] ?? '').toString();
    final staff = (lead['staff_name'] ?? '').toString();

    var showAllServices = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return AutomotiveCardContainer(
          onTap: () => _updateJobLead(Map<String, dynamic>.from(lead)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Lead ID + Date + Status + Popup Menu ──
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    AutomotiveIdBadge(
                      idText: leadNumber.isNotEmpty ? 'LEAD-$leadNumber' : 'LEAD',
                    ),
                    SizedBox(width: 8.w),
                    if (leadDate.isNotEmpty)
                      Text(
                        leadDate,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Spacer(),
                    if ((lead['job_card_number'] ?? '').toString().isNotEmpty)
                      AutomotiveStatusPill(
                        status: 'job_order',
                        label: 'Job: ${lead['job_card_number']}',
                        color: const Color(0xFF1D4ED8),
                        backgroundColor: const Color(0xFFEFF6FF),
                      )
                    else if (followUps.isNotEmpty)
                      AutomotiveStatusPill(
                        status: 'follow_up',
                        label: '${followUps.length} ${context.tr('Follow-up(s)')}',
                      )
                    else if (isCorporate)
                      AutomotiveStatusPill(
                        status: 'corporate',
                        label: context.tr('Corporate'),
                        color: const Color(0xFFB45309),
                        backgroundColor: const Color(0xFFFEF3C7),
                      )
                    else
                      AutomotiveStatusPill(
                        status: 'new',
                        label: context.tr('New Lead'),
                      ),
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
                        if (action == 'view_job_order') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCardCreateScreen(
                                existingJobCardId: lead['job_card_id'].toString(),
                              ),
                            ),
                          );
                        }
                        if (action == 'create_job_order') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCardCreateScreen(
                                initialLead: Map<String, dynamic>.from(lead),
                              ),
                            ),
                          ).then((val) {
                            if (val == true) _fetchLeads();
                          });
                        }
                        if (action == 'edit') {
                          _openCreateOrEditSheet(
                            lead: Map<String, dynamic>.from(lead),
                          );
                        }
                        if (action == 'delete') {
                          _deleteLead(
                            lead['id'].toString(),
                            customerName,
                          );
                        }
                        if (action == 'share_pdf') {
                          _exportJobLeadPdf(lead, download: false);
                        }
                        if (action == 'download_pdf') {
                          _exportJobLeadPdf(lead, download: true);
                        }
                      },
                      itemBuilder: (_) => [
                        if ((lead['job_card_id'] ?? '').toString().isNotEmpty)
                          PopupMenuItem(
                            value: 'view_job_order',
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_turned_in, size: 16, color: Color(0xFF000080)),
                                const SizedBox(width: 8),
                                Text(context.tr('View Job Order')),
                              ],
                            ),
                          )
                        else if (lead['status'] == 'success')
                          PopupMenuItem(
                            value: 'create_job_order',
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Text(context.tr('Create Job Order')),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.tr('Edit lead')),
                        ),
                        PopupMenuItem(
                          value: 'share_pdf',
                          child: Text(context.tr('Share lead PDF')),
                        ),
                        PopupMenuItem(
                          value: 'download_pdf',
                          child: Text(context.tr('Download lead PDF')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.tr('Delete lead')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body: Plate + Next Follow-up, Customer & Details ──
              Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        VehiclePlateBadge(plateNumber: plateNumber),
                        const Spacer(),
                        if (nextFollowUp.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 12.r,
                                  color: const Color(0xFF1D4ED8),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatDate(nextFollowUp),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Customer info + Quick Call & WhatsApp
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
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (phoneNumber.isNotEmpty) ...[
                          InkWell(
                            onTap: () async {
                              final numOnly = phoneNumber.replaceAll(' ', '');
                              final uri = Uri(scheme: 'tel', path: numOnly);
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.all(4.r),
                              child: Icon(
                                Icons.call,
                                size: 18.r,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          InkWell(
                            onTap: () => _launchWhatsApp(lead),
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.all(4.r),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 18.r,
                                color: const Color(0xFF25D366),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (vehicleDesc.isNotEmpty && vehicleDesc != plateNumber) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 14.r,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            vehicleDesc,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Metadata details row (Mode, Reference, Staff, City)
                    if (mode.isNotEmpty ||
                        reference.isNotEmpty ||
                        staff.isNotEmpty ||
                        city.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          if (mode.isNotEmpty)
                            _buildLeadMetaTag('Mode', mode),
                          if (reference.isNotEmpty)
                            _buildLeadMetaTag('Ref', reference),
                          if (staff.isNotEmpty)
                            _buildLeadMetaTag('Staff', staff),
                          if (city.isNotEmpty)
                            _buildLeadMetaTag('City', city),
                        ],
                      ),
                    ],

                    // Interested Services (styled like quotation reported issues)
                    if (serviceNames.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.build_circle_outlined,
                                  size: 14.r,
                                  color: const Color(0xFFD97706),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  '${context.tr('Interested Services')} (${serviceNames.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            ...(showAllServices
                                    ? serviceNames
                                    : serviceNames.take(2))
                                .map(
                              (name) => Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  '• $name',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF78350F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (serviceNames.length > 2)
                              Padding(
                                padding: EdgeInsets.only(top: 3.h),
                                child: InkWell(
                                  onTap: () => setCardState(
                                    () => showAllServices = !showAllServices,
                                  ),
                                  child: Text(
                                    showAllServices
                                        ? context.tr('Show less')
                                        : '+${serviceNames.length - 2} ${context.tr('more')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Actions Footer ──────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showJobLeadHistory(lead),
                      icon: Icon(
                        Icons.history,
                        size: 14.r,
                        color: const Color(0xFF000080),
                      ),
                      label: Text(
                        context.tr('History'),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF000080),
                        side: const BorderSide(color: Color(0xFF000080)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    PopupMenuButton<String>(
                      tooltip: context.tr('Lead PDF'),
                      onSelected: (action) {
                        if (action == 'share_pdf') {
                          _exportJobLeadPdf(lead, download: false);
                        }
                        if (action == 'download_pdf') {
                          _exportJobLeadPdf(lead, download: true);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'share_pdf',
                          child: Row(
                            children: [
                              Icon(
                                Icons.share,
                                size: 16.r,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Text(context.tr('Share lead PDF')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'download_pdf',
                          child: Row(
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                size: 16.r,
                                color: const Color(0xFF000080),
                              ),
                              SizedBox(width: 8.w),
                              Text(context.tr('Download lead PDF')),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.green.shade600),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 14.r,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              context.tr('PDF'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 16.r,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (lead['status'] == 'success' &&
                        (lead['job_card_id'] ?? '').toString().isEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCardCreateScreen(
                                initialLead: Map<String, dynamic>.from(lead),
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchLeads();
                          }
                        },
                        icon: Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 14.r,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.tr('Create Job Order'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      )
                    else if ((lead['job_card_id'] ?? '')
                        .toString()
                        .isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCardCreateScreen(
                                existingJobCardId:
                                    lead['job_card_id'].toString(),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.assignment_turned_in,
                          size: 14.r,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.tr('View Job Order'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _openQuotationForLead(
                          Map<String, dynamic>.from(lead),
                        ),
                        icon: Icon(
                          Icons.request_quote_outlined,
                          size: 14.r,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.tr('Quote Now'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadMetaTag(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          color: Colors.blueGrey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(dynamic lead) async {
    final phone = (lead['whatsapp_number'] ?? lead['phone_number'] ?? '').toString();
    final name = (lead['customer_name'] ?? 'Customer').toString();
    final cleanedPhone = CountryConfig.formatPhoneForWhatsapp(phone);
    if (cleanedPhone.isEmpty) {
      _showSnack(context.tr('Invalid phone number.'), Colors.red);
      return;
    }
    final msg = 'Hello $name, thank you for contacting us.';
    final url = Uri.parse(
      'https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(msg)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnack('${context.tr('Could not launch WhatsApp:')} $e', Colors.red);
    }
  }

  Future<void> _showJobLeadHistory(Map<String, dynamic> lead) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = await ApiService.getJobLeadHistory(
        token,
        lead['id'].toString(),
      );
      if (!mounted) return;
      if (res['success'] != true) {
        _showSnack(
          res['message'] ?? context.tr('Unable to load lead history.'),
          Colors.red,
        );
        return;
      }
      final events = List<dynamic>.from(res['events'] ?? []);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.history, color: const Color(0xFF000080), size: 20.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${context.tr('Lead History')} · ${lead['lead_number'] ?? ''}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 400.h),
              child: events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          context.tr('No history yet.'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: events.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 12.h, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final event = events[i] as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 4.h),
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF000080),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if ((event['description'] ?? '').toString().isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        event['description'].toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    if ((event['next_follow_up_date'] ?? '').toString().isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${context.tr('Next follow-up')}: ${_formatDate(event['next_follow_up_date'].toString())}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                    if ((event['incharge_staff_name'] ?? '').toString().isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${context.tr('Staff')}: ${event['incharge_staff_name']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatDate(event['date']?.toString() ?? ''),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Close')),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Unable to load lead history: $e', Colors.red);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.tryParse(isoDate);
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().padLeft(4, '0')}';
      }
      final parts = isoDate.split('-');
      if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (_) {}
    return isoDate;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Leads Reminders
// ─────────────────────────────────────────────────────────────────────────────

class _LeadsRemindersTab extends StatefulWidget {
  @override
  State<_LeadsRemindersTab> createState() => _LeadsRemindersTabState();
}

class _LeadsRemindersTabState extends State<_LeadsRemindersTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<dynamic>> _leadsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _showAllNotifier = ValueNotifier(false);
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<Set<String>> _sendingIdsNotifier = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchReminders());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isLoadingNotifier.dispose();
    _leadsNotifier.dispose();
    _showAllNotifier.dispose();
    _sendingIdsNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchReminders() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    _isLoadingNotifier.value = true;
    try {
      final res = await ApiService.getLeadsReminders(
        token,
        showAll: _showAllNotifier.value,
        daysAhead: 30,
      );
      if (res['status'] == 'success') {
        _leadsNotifier.value = List<dynamic>.from(res['leads'] ?? []);
      }
    } catch (e) {
      _showSnack('Failed to load reminders: $e', Colors.red);
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  List<dynamic> get _filteredLeads {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _leadsNotifier.value;
    return _leadsNotifier.value.where((l) {
      final name = (l['customer_name'] ?? '').toString().toLowerCase();
      final phone = (l['phone_number'] ?? '').toString().toLowerCase();
      final vehicle = (l['vehicle_details'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || vehicle.contains(q);
    }).toList();
  }

  Future<void> _launchWhatsApp(dynamic lead) async {
    final leadId = (lead['id'] ?? '').toString();
    final phone = (lead['whatsapp_number'] ?? lead['phone_number'] ?? '')
        .toString();
    final name = (lead['customer_name'] ?? 'Customer').toString();

    final rawVehicle =
        lead['vehicle_details'] ??
        lead['vehicle_display'] ??
        lead['vehicle_number'] ??
        '';
    final vehicle = rawVehicle.toString().trim();
    final renewalDisplay = (lead['renewal_date_display'] ?? '')
        .toString()
        .trim();

    final authProvider = context.read<AuthProvider>();
    final String bName = (authProvider.branchName ?? '').trim();
    final String cName = (authProvider.companyName ?? '').trim();
    final String dName = (authProvider.displayName ?? '').trim();
    final String branchName = bName.isNotEmpty
        ? bName
        : cName.isNotEmpty
        ? cName
        : dName.isNotEmpty
        ? dName
        : 'Mobiz Auto Care Pro';

    final vehicleInfo = vehicle.isNotEmpty ? ' vehicle ($vehicle)' : ' vehicle';
    final dateInfo = renewalDisplay.isNotEmpty ? ' on $renewalDisplay' : '';
    final msg =
        'Dear $name, your$vehicleInfo insurance renewal is due$dateInfo. Thank you, $branchName.';

    final cleanedPhone = CountryConfig.formatPhoneForWhatsapp(phone);
    if (cleanedPhone.isEmpty) {
      _showSnack(context.tr('Invalid phone number.'), Colors.red);
      return;
    }

    final sendingSet = Set<String>.from(_sendingIdsNotifier.value);
    sendingSet.add(leadId);
    _sendingIdsNotifier.value = sendingSet;

    final url = Uri.parse(
      'https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(msg)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      _showSnack(
        '${context.tr('Opened WhatsApp chat for')} $name',
        Colors.green,
      );
    } catch (e) {
      _showSnack('${context.tr('Could not launch WhatsApp:')} $e', Colors.red);
    } finally {
      final finalSet = Set<String>.from(_sendingIdsNotifier.value);
      finalSet.remove(leadId);
      _sendingIdsNotifier.value = finalSet;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Controls bar
        Container(
          color: Colors.white,
          padding: REdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16.r,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 6.w),
                  ValueListenableBuilder<bool>(
                    valueListenable: _showAllNotifier,
                    builder: (context, showAll, _) => Row(
                      children: [
                        _filterChip(context, false, showAll),
                        SizedBox(width: 8.w),
                        _filterChip(context, true, showAll),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: 20.r,
                      color: const Color(0xFF000080),
                    ),
                    onPressed: _fetchReminders,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: context.tr('Search name, phone, vehicle...'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reminders list
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final leads = _filteredLeads;
              if (leads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 60.r,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        context.tr('No upcoming renewals.'),
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _fetchReminders,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: _sendingIdsNotifier,
                  builder: (context, sendingIds, _) {
                    return ListView.separated(
                      padding: REdgeInsets.all(16),
                      itemCount: leads.length,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (_, i) =>
                          _buildReminderCard(leads[i], sendingIds),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context, bool isAll, bool currentShowAll) {
    final isSelected = isAll == currentShowAll;
    return GestureDetector(
      onTap: () {
        _showAllNotifier.value = isAll;
        _fetchReminders();
      },
      child: Container(
        padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF000080) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          isAll ? context.tr('All') : context.tr('Next 30 Days'),
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> lead, Set<String> sendingIds) {
    final leadId = (lead['id'] ?? '').toString();
    final daysUntil = lead['days_until_renewal'] as int?;
    final isOverdue = lead['is_overdue'] == true;
    final isToday = lead['is_today'] == true;
    final isSending = sendingIds.contains(leadId);

    Color statusColor;
    String statusLabel;
    if (isOverdue) {
      statusColor = Colors.red;
      statusLabel = context.tr('Overdue');
    } else if (isToday) {
      statusColor = Colors.orange;
      statusLabel = context.tr('Today');
    } else if (daysUntil != null && daysUntil <= 7) {
      statusColor = Colors.orange.shade700;
      statusLabel = '${daysUntil}d';
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = daysUntil != null ? '${daysUntil}d' : '';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withOpacity(0.3)
              : isToday
              ? Colors.orange.withOpacity(0.3)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Padding(
        padding: REdgeInsets.all(14),
        child: Row(
          children: [
            // Status badge
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : isToday
                        ? Icons.today
                        : Icons.schedule,
                    color: statusColor,
                    size: 18.r,
                  ),
                  if (statusLabel.isNotEmpty)
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead['customer_name'] ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 12.r,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        lead['phone_number'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if ((lead['vehicle_details'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 12.r,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            lead['vehicle_details'].toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12.r,
                        color: statusColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        lead['renewal_date_display'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // WhatsApp button
            GestureDetector(
              onTap: isSending ? null : () => _launchWhatsApp(lead),
              child: Container(
                padding: REdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSending
                      ? Colors.grey.shade100
                      : const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSending
                        ? Colors.grey.shade300
                        : const Color(0xFF25D366).withOpacity(0.4),
                  ),
                ),
                child: isSending
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chat,
                        color: const Color(0xFF25D366),
                        size: 22.r,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
