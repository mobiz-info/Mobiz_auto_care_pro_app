import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<String> _errorNotifier = ValueNotifier('');
  final ValueNotifier<List<dynamic>> _payslipsNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, dynamic>> _summaryNotifier = ValueNotifier({});
  final ValueNotifier<String> _currencySymbolNotifier = ValueNotifier('₹');

  final ValueNotifier<List<dynamic>> _branchesNotifier = ValueNotifier([]);
  final ValueNotifier<String?> _selectedBranchIdNotifier = ValueNotifier(null);

  final ValueNotifier<int> _selectedYearNotifier = ValueNotifier(DateTime.now().year);
  final ValueNotifier<int> _selectedMonthNotifier = ValueNotifier(DateTime.now().month);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranches();
      _fetchPayslips();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    _payslipsNotifier.dispose();
    _summaryNotifier.dispose();
    _currencySymbolNotifier.dispose();
    _branchesNotifier.dispose();
    _selectedBranchIdNotifier.dispose();
    _selectedYearNotifier.dispose();
    _selectedMonthNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _fetchPayslips();
  }

  Future<void> _loadBranches() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isCompanyAdmin) return;
    try {
      final res = await ApiService.getCompanyBranches(auth.token!);
      if (res['success'] == true && res['branches'] != null) {
        _branchesNotifier.value = List.from(res['branches']);
      }
    } catch (_) {}
  }

  Future<void> _fetchPayslips() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _isLoadingNotifier.value = true;
    _errorNotifier.value = '';

    try {
      final res = await ApiService.getStaffPayslips(
        token,
        year: _selectedYearNotifier.value,
        month: _selectedMonthNotifier.value,
        branchId: _selectedBranchIdNotifier.value,
        search: _searchController.text.trim(),
      );

      if (res['success'] == true) {
        _payslipsNotifier.value = List.from(res['payslips'] ?? []);
        _summaryNotifier.value = Map<String, dynamic>.from(res['summary'] ?? {});
        if (res['currency_symbol'] != null) {
          _currencySymbolNotifier.value = res['currency_symbol'].toString();
        }
      } else {
        _errorNotifier.value = res['message'] ?? 'Failed to load payslips.';
      }
    } catch (e) {
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _previousMonth() {
    int y = _selectedYearNotifier.value;
    int m = _selectedMonthNotifier.value - 1;
    if (m < 1) {
      m = 12;
      y--;
    }
    _selectedYearNotifier.value = y;
    _selectedMonthNotifier.value = m;
    _fetchPayslips();
  }

  void _nextMonth() {
    int y = _selectedYearNotifier.value;
    int m = _selectedMonthNotifier.value + 1;
    if (m > 12) {
      m = 1;
      y++;
    }
    _selectedYearNotifier.value = y;
    _selectedMonthNotifier.value = m;
    _fetchPayslips();
  }

  Future<void> _pickMonth(BuildContext context) async {
    int y = _selectedYearNotifier.value;
    int m = _selectedMonthNotifier.value;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthNames = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('Select Payslip Month'),
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000080),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setModalState(() {
                                y--;
                              });
                            },
                          ),
                          Text(
                            '$y',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setModalState(() {
                                y++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(12, (index) {
                      final monthNum = index + 1;
                      final isSel = m == monthNum;
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - 70) / 3,
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              monthNames[index],
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF000080),
                          onSelected: (_) {
                            _selectedYearNotifier.value = y;
                            _selectedMonthNotifier.value = monthNum;
                            Navigator.pop(ctx);
                            _fetchPayslips();
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _viewPayslipPdf(Map<String, dynamic> staff) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final staffId = staff['staff_id']?.toString() ?? '';
    final staffName = staff['name'] ?? 'Staff';
    final y = _selectedYearNotifier.value;
    final m = _selectedMonthNotifier.value;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${context.tr("Generating payslip for")} $staffName...',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      final pdfBytes = await ApiService.downloadPayslipPdf(token, staffId, y, m);
      final filename = "Payslip_${staffName.replaceAll(' ', '_')}_${y}_${m.toString().padLeft(2, '0')}.pdf";
      await Printing.layoutPdf(
        name: filename,
        onLayout: (format) async => Uint8List.fromList(pdfBytes),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr("Failed to load PDF")}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecordPaymentModal(Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RecordPaymentModal(
          staff: staff,
          year: _selectedYearNotifier.value,
          month: _selectedMonthNotifier.value,
          currencySymbol: _currencySymbolNotifier.value,
          onSuccess: () {
            _fetchPayslips();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          context.tr('Staff Payslips'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF000080),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: context.tr('Refresh'),
            onPressed: _fetchPayslips,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPayslips,
        color: const Color(0xFF000080),
        child: Column(
          children: [
            // Top Date Header & Controls
            _buildTopHeader(auth),

            // Content Area
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF000080)),
                    );
                  }

                  return ValueListenableBuilder<String>(
                    valueListenable: _errorNotifier,
                    builder: (context, errorMsg, child) {
                      if (errorMsg.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  errorMsg,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 14.sp),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchPayslips,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(context.tr('Retry')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF000080),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ValueListenableBuilder<List<dynamic>>(
                        valueListenable: _payslipsNotifier,
                        builder: (context, payslips, child) {
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Summary KPI Section
                              _buildSummaryCards(),

                              const SizedBox(height: 16),

                              // Payslip Cards
                              if (payslips.isEmpty)
                                _buildEmptyState()
                              else
                                ...payslips.map((p) {
                                  final staff = Map<String, dynamic>.from(p as Map);
                                  return _buildStaffPayslipCard(staff);
                                }),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(AuthProvider auth) {
    return Container(
      color: const Color(0xFF000080),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _previousMonth,
              ),
              InkWell(
                onTap: () => _pickMonth(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedYearNotifier,
                    builder: (context, y, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: _selectedMonthNotifier,
                        builder: (context, m, _) {
                          final date = DateTime(y, m, 1);
                          return Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMMM yyyy').format(date),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar & Optional Branch Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr('Search staff name or ID...'),
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13.sp),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF000080), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              if (auth.isCompanyAdmin) ...[
                const SizedBox(width: 10),
                ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _branchesNotifier,
                  builder: (context, branches, child) {
                    if (branches.isEmpty) return const SizedBox.shrink();
                    return ValueListenableBuilder<String?>(
                      valueListenable: _selectedBranchIdNotifier,
                      builder: (context, selectedBranchId, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBranchId,
                              hint: Text(
                                context.tr('All Branches'),
                                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    context.tr('All Branches'),
                                    style: GoogleFonts.inter(fontSize: 13.sp),
                                  ),
                                ),
                                ...branches.map((b) {
                                  return DropdownMenuItem<String>(
                                    value: b['id']?.toString(),
                                    child: Text(
                                      b['name'] ?? '',
                                      style: GoogleFonts.inter(fontSize: 13.sp),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                _selectedBranchIdNotifier.value = val;
                                _fetchPayslips();
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _summaryNotifier,
      builder: (context, summary, _) {
        final symbol = _currencySymbolNotifier.value;
        final gross = (summary['total_gross'] ?? 0.0).toDouble();
        final advance = (summary['total_advance'] ?? 0.0).toDouble();
        final net = (summary['total_net'] ?? 0.0).toDouble();
        final paid = (summary['total_paid'] ?? 0.0).toDouble();
        final balance = (summary['total_balance'] ?? 0.0).toDouble();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: context.tr('Gross Payroll'),
                    value: '$symbol${gross.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: context.tr('Advances Deducted'),
                    value: '$symbol${advance.toStringAsFixed(2)}',
                    icon: Icons.history_edu_outlined,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: context.tr('Net Payable'),
                    value: '$symbol${net.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF0F766E),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: context.tr('Total Paid'),
                    value: '$symbol${paid.toStringAsFixed(2)}',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: context.tr('Balance Due'),
                    value: '$symbol${balance.toStringAsFixed(2)}',
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            context.tr('No staff payslips found'),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Try selecting another month or branch, or check staff management.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPayslipCard(Map<String, dynamic> staff) {
    final symbol = _currencySymbolNotifier.value;
    final name = (staff['name'] ?? 'Staff').toString();
    final empId = (staff['employee_id'] ?? '').toString();
    final branchName = (staff['branch_name'] ?? '').toString();
    final salaryMode = (staff['salary_mode_display'] ?? staff['salary_mode'] ?? 'Monthly').toString();
    final status = (staff['payment_status'] ?? 'UNPAID').toString().toUpperCase();

    final gross = (staff['gross_salary'] ?? 0.0).toDouble();
    final advance = (staff['advance_deduction'] ?? 0.0).toDouble();
    final net = (staff['net_salary'] ?? 0.0).toDouble();
    final paid = (staff['paid_amount'] ?? 0.0).toDouble();
    final balance = (staff['balance_amount'] ?? 0.0).toDouble();

    Color statusColor;
    Color statusBgColor;
    if (status == 'PAID') {
      statusColor = const Color(0xFF16A34A);
      statusBgColor = const Color(0xFFDCFCE7);
    } else if (status == 'PARTIAL') {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEE2E2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (empId.isNotEmpty)
                            _buildPill(empId, Colors.grey.shade700, Colors.grey.shade100),
                          if (branchName.isNotEmpty)
                            _buildPill(branchName, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
                          _buildPill(salaryMode, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Numbers Breakdown Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRowItem(context.tr('Gross Salary'), '$symbol${gross.toStringAsFixed(2)}'),
                    _buildRowItem(
                      context.tr('Advance Deductions'),
                      advance > 0 ? '-$symbol${advance.toStringAsFixed(2)}' : '$symbol 0.00',
                      textColor: advance > 0 ? const Color(0xFFD97706) : Colors.black87,
                    ),
                    _buildRowItem(
                      context.tr('Net Salary'),
                      '$symbol${net.toStringAsFixed(2)}',
                      textColor: const Color(0xFF000080),
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRowItem(
                      context.tr('Paid Amount'),
                      '$symbol${paid.toStringAsFixed(2)}',
                      textColor: const Color(0xFF16A34A),
                    ),
                    _buildRowItem(
                      context.tr('Balance Remaining'),
                      '$symbol${balance.toStringAsFixed(2)}',
                      textColor: balance > 0 ? const Color(0xFFDC2626) : Colors.black87,
                      isBold: balance > 0,
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions Row (View PDF & Pay Salary / Advance)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewPayslipPdf(staff),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(context.tr('Payslip PDF')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecordPaymentModal(staff),
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text(context.tr('Pay / Advance')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildRowItem(String label, String value, {Color? textColor, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontSize: 13.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}


class _RecordPaymentModal extends StatefulWidget {
  final Map<String, dynamic> staff;
  final int year;
  final int month;
  final String currencySymbol;
  final VoidCallback onSuccess;

  const _RecordPaymentModal({
    required this.staff,
    required this.year,
    required this.month,
    required this.currencySymbol,
    required this.onSuccess,
  });

  @override
  State<_RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<_RecordPaymentModal> {
  String _payType = 'SALARY'; // 'SALARY' or 'ADVANCE'
  String _paymentMode = 'CASH'; // 'CASH' or 'BANK'
  String? _selectedBankAccountId;
  List<dynamic> _bankAccounts = [];
  bool _isLoadingBanks = false;
  bool _isSubmitting = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final balance = (widget.staff['balance_amount'] ?? 0.0).toDouble();
    if (balance > 0) {
      _amountController.text = balance.toStringAsFixed(2);
    }
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoadingBanks = true);
    try {
      final res = await ApiService.getBankAccounts(token);
      if (res['success'] == true && res['bank_accounts'] != null) {
        setState(() {
          _bankAccounts = List.from(res['bank_accounts']);
          if (_bankAccounts.isNotEmpty) {
            _selectedBankAccountId = _bankAccounts.first['id']?.toString();
          }
        });
      }
    } catch (_) {}
    setState(() => _isLoadingBanks = false);
  }

  Future<void> _submit() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a valid amount'))),
      );
      return;
    }

    if (_paymentMode == 'BANK' && (_selectedBankAccountId == null || _selectedBankAccountId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select a bank account'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final staffId = widget.staff['staff_id']?.toString();
      final payload = {
        'staff_id': staffId,
        'pay_type': _payType,
        'amount': amount,
        'payment_mode': _paymentMode,
        'bank_account_id': _paymentMode == 'BANK' ? _selectedBankAccountId : null,
        'year': widget.year,
        'month': widget.month,
        'remarks': _remarksController.text.trim(),
      };

      final res = await ApiService.recordPayslipPayment(token, payload);
      if (res['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? context.tr('Payment recorded successfully!')),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSuccess();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? context.tr('Failed to record payment')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffName = widget.staff['name'] ?? 'Staff';
    final balance = (widget.staff['balance_amount'] ?? 0.0).toDouble();
    final symbol = widget.currencySymbol;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Record Staff Payment'),
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$staffName • ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month, 1))}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Type Selector (Salary vs Advance)
            Text(
              context.tr('Payment Type *'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: context.tr('Salary Payment'),
                    isSelected: _payType == 'SALARY',
                    icon: Icons.payments_outlined,
                    onSelected: () {
                      setState(() {
                        _payType = 'SALARY';
                        if (balance > 0) {
                          _amountController.text = balance.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceChip(
                    label: context.tr('Salary Advance'),
                    isSelected: _payType == 'ADVANCE',
                    icon: Icons.history_edu_outlined,
                    onSelected: () {
                      setState(() {
                        _payType = 'ADVANCE';
                        _amountController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount Field
            Text(
              context.tr('Amount *'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    symbol,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000080),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            if (_payType == 'SALARY' && balance > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${context.tr("Current Balance Due")}: $symbol${balance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFDC2626)),
              ),
            ],

            const SizedBox(height: 16),

            // Payment Mode (Cash vs Bank)
            Text(
              context.tr('Payment Mode *'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceChip(
                    label: context.tr('Cash'),
                    isSelected: _paymentMode == 'CASH',
                    icon: Icons.money,
                    onSelected: () {
                      setState(() => _paymentMode = 'CASH');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceChip(
                    label: context.tr('Bank'),
                    isSelected: _paymentMode == 'BANK',
                    icon: Icons.account_balance,
                    onSelected: () {
                      setState(() => _paymentMode = 'BANK');
                    },
                  ),
                ),
              ],
            ),

            if (_paymentMode == 'BANK') ...[
              const SizedBox(height: 14),
              Text(
                context.tr('Select Bank Account *'),
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              if (_isLoadingBanks)
                const LinearProgressIndicator(color: Color(0xFF000080))
              else
                DropdownButtonFormField<String>(
                  value: _selectedBankAccountId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _bankAccounts.map((b) {
                    final bName = b['name'] ?? '';
                    final bAcc = b['account_number'] ?? '';
                    final bBal = b['current_balance'] != null ? ' ($symbol${b['current_balance']})' : '';
                    return DropdownMenuItem<String>(
                      value: b['id']?.toString(),
                      child: Text(
                        '$bName - $bAcc$bBal',
                        style: GoogleFonts.inter(fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedBankAccountId = val);
                  },
                ),
            ],

            const SizedBox(height: 16),

            // Remarks Field
            Text(
              context.tr('Remarks (Optional)'),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                hintText: context.tr('Enter remarks or transaction note...'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      context.tr('Confirm Payment'),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF000080) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

