import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/job_card_responsive.dart';
import '../widgets/automotive_card.dart';
import 'quotation_search_screen.dart';
import 'quotation_create_screen.dart';
import 'quotation_view_screen.dart';
import 'job_quotation_form_screen.dart';
import 'job_card_create_screen.dart';

class QuotationListScreen extends StatefulWidget {
  final bool jobWorkflow;
  const QuotationListScreen({super.key, this.jobWorkflow = false});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  Future<void> _createQuotation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.jobWorkflow
            ? const JobQuotationFormScreen()
            : const QuotationSearchScreen(),
      ),
    );
    if (result == true || result != null) _loadQuotations();
  }

  String get currencySymbol {
    try {
      return context.read<AuthProvider>().currencySymbol;
    } catch (_) {
      return CountryConfig.currencySymbol;
    }
  }

  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _allQuotations = [];
  List<dynamic> _filteredQuotations = [];
  final TextEditingController _searchController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String _activePreset = 'today';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate = DateTime(now.year, now.month, now.day);
    _activePreset = 'today';
    _searchController.addListener(_onSearchChanged);
    _loadQuotations();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredQuotations = List.from(_allQuotations);
      });
    } else {
      setState(() {
        _filteredQuotations = _allQuotations.where((q) {
          final qNum = (q['quotation_number'] ?? '').toString().toLowerCase();
          final cName = (q['customer_name'] ?? '').toString().toLowerCase();
          final cPhone = (q['customer_phone'] ?? '').toString().toLowerCase();
          final vNum = (q['vehicle_number'] ?? '').toString().toLowerCase();
          return qNum.contains(query) ||
              cName.contains(query) ||
              cPhone.contains(query) ||
              vNum.contains(query);
        }).toList();
      });
    }
  }

  String _formatDateYMD(DateTime dt) {
    return '${dt.year.toString().padLeft(4, "0")}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';
  }

  String _formatDisplayDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _fromDate ?? now,
      end: _toDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF000080),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _activePreset = 'custom';
      });
      _loadQuotations();
    }
  }

  void _selectPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
      if (preset == 'today') {
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = DateTime(now.year, now.month, now.day);
      } else if (preset == 'month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month, now.day);
      } else if (preset == 'last30') {
        _fromDate = now.subtract(const Duration(days: 30));
        _toDate = DateTime(now.year, now.month, now.day);
      } else if (preset == 'all') {
        _fromDate = null;
        _toDate = null;
      }
    });
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final fromStr = _fromDate != null ? _formatDateYMD(_fromDate!) : null;
      final toStr = _toDate != null ? _formatDateYMD(_toDate!) : null;

      final res = widget.jobWorkflow
          ? await ApiService.getJobQuotationList(token)
          : await ApiService.getQuotationList(
              token,
              fromDate: fromStr,
              toDate: toStr,
            );
      if (res['success'] == true) {
        final rawList = res['quotations'] as List<dynamic>? ?? [];
        final list = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _allQuotations = list;
          _isLoading = false;
        });
        _onSearchChanged();
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Failed to load quotations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditQuotation(String quotationId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = widget.jobWorkflow
          ? await ApiService.getJobQuotationDetail(quotationId, token)
          : await ApiService.getQuotationDetail(quotationId, token);
      if (mounted) Navigator.pop(context); // dismiss loader

      if (res['success'] == true && res['quotation'] != null) {
        final qDetail = Map<String, dynamic>.from(res['quotation'] as Map);
        final customer = {
          'id': qDetail['customer_id'],
          'name': qDetail['customer_name'],
          'phone': qDetail['customer_phone'],
          'type': qDetail['customer_type'],
        };
        final vehicle = {
          'id': qDetail['vehicle_id'],
          'no': qDetail['vehicle_number'],
          'type': qDetail['vehicle_type'],
        };

        if (!mounted) return;
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => widget.jobWorkflow
                ? JobQuotationFormScreen(existingQuotation: qDetail)
                : QuotationCreateScreen(
                    customer: customer,
                    vehicle: vehicle,
                    existingQuotation: qDetail,
                    leadId: qDetail['lead_id']?.toString(),
                  ),
          ),
        );
        if (updated == true || updated != null) {
          _loadQuotations();
        }
      } else {
        _snack(
          res['message'] ?? 'Failed to fetch quotation details',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _snack(e.toString(), isError: true);
    }
  }

  Future<void> _deleteJobQuotation(String quotationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete quotation draft?'),
        content: const Text(
          'This will remove the draft from the Job Quotation list. Customer and vehicle records will remain. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final result = await ApiService.deleteJobQuotation(quotationId, token);
      if (!mounted) return;
      if (result['success'] != true) {
        _snack(
          result['message'] ?? 'Unable to delete quotation',
          isError: true,
        );
        return;
      }
      _snack('Job Quotation deleted');
      await _loadQuotations();
    } catch (error) {
      if (mounted) _snack(error.toString(), isError: true);
    }
  }

  Future<void> _acceptQuotation(Map<String, dynamic> quotation) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final id = quotation['id'].toString();
    try {
      final result = widget.jobWorkflow
          ? await ApiService.acceptJobQuotation(id, token)
          : await ApiService.acceptQuotation(id, token);
      if (!mounted) return;
      if (result['success'] == true) {
        _snack(context.tr('Quotation accepted successfully'));
        await _loadQuotations();
      } else {
        _snack(result['message'] ?? 'Could not accept quotation', isError: true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    }
  }

  Future<void> _addJobOrder(Map<String, dynamic> quotation) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final id = quotation['id'].toString();
    try {
      final result = await ApiService.convertJobQuotationToJobCard(id, token);
      if (!mounted) return;
      if (result['success'] == true) {
        final jobId = result['job_card_id']?.toString() ?? '';
        await _loadQuotations();
        if (jobId.isNotEmpty && mounted) {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => JobCardCreateScreen(existingJobCardId: jobId),
            ),
          );
          if (saved == true && mounted) await _loadQuotations();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Could not create job order'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _snack(error.toString(), isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          context.tr('Quotations'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: widget.jobWorkflow ? 'job-quotation-create-fab' : null,
        onPressed: _createQuotation,
        backgroundColor: Color(0xFF000080),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('Create Quotation'),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Header Card
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.tr(
                        'Search by quotation #, customer, vehicle...',
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF000080),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.refresh, color: Color(0xFF000080)),
                  onPressed: _loadQuotations,
                ),
              ],
            ),
          ),

          // Date Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Interactive Date Range Selector Button
                InkWell(
                  onTap: _pickCustomDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _fromDate != null
                            ? const Color(0xFF000080)
                            : Colors.grey.shade300,
                        width: _fromDate != null ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 18,
                          color: _fromDate != null
                              ? const Color(0xFF000080)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fromDate != null && _toDate != null
                                ? (_fromDate == _toDate ||
                                          (_fromDate!.year == _toDate!.year &&
                                              _fromDate!.month ==
                                                  _toDate!.month &&
                                              _fromDate!.day == _toDate!.day)
                                      ? '${context.tr("Date")}: ${_formatDisplayDate(_fromDate!)}'
                                      : '${_formatDisplayDate(_fromDate!)}  —  ${_formatDisplayDate(_toDate!)}')
                                : context.tr('All Dates (Tap to filter)'),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: _fromDate != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _fromDate != null
                                  ? const Color(0xFF000080)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (_fromDate != null)
                          InkWell(
                            onTap: () => _selectPreset('all'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Presets
                _quickPresetRow(),
              ],
            ),
          ),

          // Quotation List Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : _filteredQuotations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.request_quote_outlined,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _fromDate != null
                              ? context.tr(
                                  'No quotations found for selected date range.',
                                )
                              : context.tr('No quotations found'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_fromDate != null) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () => _selectPreset('all'),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(
                              context.tr('Reset Date Filter (Show All)'),
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createQuotation,
                          icon: const Icon(Icons.add),
                          label: Text(context.tr('Create First Quotation')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF000080),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadQuotations,
                    child: widget.jobWorkflow
                        ? JobCardResponsiveList(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredQuotations.length,
                            itemBuilder: (context, index) =>
                                _buildQuotationCard(
                                  Map<String, dynamic>.from(
                                    _filteredQuotations[index] as Map,
                                  ),
                                ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredQuotations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final q = _filteredQuotations[index];
                              return _buildQuotationCard(q);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String _formatDateWithTime(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';
    try {
      final dt = DateTime.parse(str).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d-$m-$y $h:$min';
    } catch (_) {
      return str;
    }
  }

  Widget _buildQuotationCard(Map<String, dynamic> q) {
    final reportedIssues = widget.jobWorkflow
        ? (q['reported_issues'] as List<dynamic>? ?? [])
        : const <dynamic>[];
    final isAccepted = q['is_accepted'] == true;
    final grandTotal = _parseDouble(q['grand_total']);
    final vehicleNo = (q['vehicle_number'] ?? '-').toString();
    final quotationNo = (q['quotation_number'] ?? '').toString();
    final customerName = (q['customer_name'] ?? '').toString();
    final customerPhone = (q['customer_phone'] ?? '').toString();
    final branchName = (q['branch_name'] ?? '').toString();
    final dateStr = _formatDateWithTime(q['created_at'] ?? q['date'] ?? '');
    final jobCardId = (q['job_card_id'] ?? '').toString();

    return AutomotiveCardContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuotationViewScreen(
              quotationId: q['id'],
              jobWorkflow: widget.jobWorkflow,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Quotation No + Date + Status + Delete ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AutomotiveIdBadge(idText: quotationNo),
                      if (dateStr.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      AutomotiveStatusPill(
                        status: isAccepted ? 'Accepted' : 'Draft',
                        label: isAccepted
                            ? context.tr('Accepted')
                            : context.tr('Draft / Sent'),
                      ),
                      if ((q['job_card_number'] ?? '').toString().isNotEmpty)
                        AutomotiveStatusPill(
                          status: 'job_order',
                          label: 'Job: ${q['job_card_number']}',
                          color: const Color(0xFF1D4ED8),
                          backgroundColor: const Color(0xFFEFF6FF),
                        ),
                    ],
                  ),
                ),
                if (widget.jobWorkflow) ...[
                  SizedBox(width: 2.w),
                  PopupMenuButton<String>(
                    tooltip: context.tr('More actions'),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 18.r,
                      color: Colors.grey.shade600,
                    ),
                    onSelected: (action) {
                      if (action == 'accept') {
                        _acceptQuotation(q);
                      }
                      if (action == 'view_job') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobCardCreateScreen(
                              existingJobCardId: q['job_card_id'].toString(),
                            ),
                          ),
                        );
                      }
                      if (action == 'delete') {
                        _deleteJobQuotation(q['id'].toString());
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isAccepted)
                        PopupMenuItem(
                          value: 'accept',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(context.tr('Accept Quotation')),
                            ],
                          ),
                        ),
                      if ((q['job_card_id'] ?? '').toString().isNotEmpty)
                        PopupMenuItem(
                          value: 'view_job',
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_turned_in, size: 18, color: Color(0xFF000080)),
                              const SizedBox(width: 8),
                              Text(context.tr('View Job Order')),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('Delete Quotation')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Body: Plate + Total, Customer & Vehicle, Reported Issues ──
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
                          context.tr('Grand Total'),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$currencySymbol${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Customer info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14.r,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              customerName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (customerPhone.isNotEmpty) ...[
                            SizedBox(width: 6.w),
                            Text(
                              '($customerPhone)',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (branchName.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14.r,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        branchName,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Reported Issues
                if (reportedIssues.isNotEmpty) ...[
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
                              Icons.report_problem_outlined,
                              size: 14.r,
                              color: const Color(0xFFD97706),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${context.tr('Reported Issues')} (${reportedIssues.length})',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        ...reportedIssues.take(2).map((rawIssue) {
                          final issue = Map<String, dynamic>.from(
                            rawIssue as Map,
                          );
                          final service = (issue['service_name'] ?? '')
                              .toString();
                          final name = (issue['issue_text'] ?? '').toString();
                          return Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              service.isEmpty ? '• $name' : '• $service: $name',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF78350F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        if (reportedIssues.length > 2)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              '+${reportedIssues.length - 2} more',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
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

          // ── Actions Footer ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuotationViewScreen(
                          quotationId: q['id'],
                          jobWorkflow: widget.jobWorkflow,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 14.r,
                    color: const Color(0xFF000080),
                  ),
                  label: Text(
                    context.tr('View'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF000080),
                    side: const BorderSide(color: Color(0xFF000080)),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                if (!isAccepted)
                  OutlinedButton.icon(
                    onPressed: () => _openEditQuotation(q['id']),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 14.r,
                      color: const Color(0xFF000080),
                    ),
                    label: Text(
                      context.tr('Edit'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                if (widget.jobWorkflow && jobCardId.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobCardCreateScreen(
                            existingJobCardId: jobCardId,
                          ),
                        ),
                      );
                      if (saved == true && mounted) await _loadQuotations();
                    },
                    icon: Icon(
                      Icons.assignment_outlined,
                      size: 14.r,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.tr('Open Job Card'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  )
                else if (widget.jobWorkflow)
                  ElevatedButton.icon(
                    onPressed: isAccepted ? () => _addJobOrder(q) : null,
                    icon: Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 14.r,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.tr('Convert to Job Order'),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
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
  }

  Widget _quickPresetRow() {
    final chips = [
      _presetChip(
        label: 'Today',
        isSelected: _activePreset == 'today',
        onTap: () => _selectPreset('today'),
      ),
      _presetChip(
        label: 'This Month',
        isSelected: _activePreset == 'month',
        onTap: () => _selectPreset('month'),
      ),
      _presetChip(
        label: 'Last 30 Days',
        isSelected: _activePreset == 'last30',
        onTap: () => _selectPreset('last30'),
      ),
      _presetChip(
        label: 'All Time',
        isSelected: _activePreset == 'all',
        onTap: () => _selectPreset('all'),
      ),
    ];
    final total = Text(
      '${context.tr("Total")}: ${_filteredQuotations.length}',
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
    if (widget.jobWorkflow) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [...chips, total],
      );
    }
    return Row(
      children: [
        chips[0],
        const SizedBox(width: 6),
        chips[1],
        const SizedBox(width: 6),
        chips[2],
        const SizedBox(width: 6),
        chips[3],
        const Spacer(),
        total,
      ],
    );
  }

  Widget _presetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          context.tr(label),
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
