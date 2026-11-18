import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'stock_item_form_screen.dart';

class StockItemScreen extends StatelessWidget {
  const StockItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StockItemBodyView(showAppBar: true);
  }
}

class StockItemBodyView extends StatefulWidget {
  final bool showAppBar;
  const StockItemBodyView({super.key, this.showAppBar = false});

  @override
  State<StockItemBodyView> createState() => _StockItemBodyViewState();
}

class _StockItemBodyViewState extends State<StockItemBodyView> {
  final _isLoading = ValueNotifier<bool>(true);
  final _errorMessage = ValueNotifier<String>('');
  final _stocks = ValueNotifier<List<dynamic>>([]);
  final _filteredStocks = ValueNotifier<List<dynamic>>([]);
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStocks();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isLoading.dispose();
    _errorMessage.dispose();
    _stocks.dispose();
    _filteredStocks.dispose();
    super.dispose();
  }

  Future<void> _fetchStocks() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final res = await ApiService.getStockList(token);
      if (res['success'] == true) {
        _stocks.value = res['stocks'] ?? [];
        _filteredStocks.value = List.from(_stocks.value);
        _isLoading.value = false;
      } else {
        _errorMessage.value = res['message'] ?? 'Failed to load stock items';
        _isLoading.value = false;
      }
    } catch (e) {
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredStocks.value = List.from(_stocks.value);
    } else {
      _filteredStocks.value = _stocks.value.where((s) {
        final name = (s['item_name'] ?? '').toString().toLowerCase();
        final code = (s['product_code'] ?? '').toString().toLowerCase();
        final part = (s['part_number'] ?? '').toString().toLowerCase();
        final alt = (s['alternate_part_number'] ?? '').toString().toLowerCase();
        final brand = (s['brand'] ?? '').toString().toLowerCase();
        final group = (s['group_name'] ?? '').toString().toLowerCase();
        final subGroup = (s['sub_group_name'] ?? '').toString().toLowerCase();
        final supplier = (s['supplier_name'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            code.contains(query) ||
            part.contains(query) ||
            alt.contains(query) ||
            brand.contains(query) ||
            group.contains(query) ||
            subGroup.contains(query) ||
            supplier.contains(query);
      }).toList();
    }
  }

  Future<void> _addNewStockItem() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const StockItemFormScreen(),
      ),
    );
    if (result == true) {
      _fetchStocks();
    }
  }

  Future<void> _editStockItem(Map<String, dynamic> item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StockItemFormScreen(item: item),
      ),
    );
    if (result == true) {
      _fetchStocks();
    }
  }

  Future<void> _deleteStockItem(Map<String, dynamic> item) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Delete Stock Item')),
        content: Text('${context.tr('Are you sure you want to delete')} "${item['item_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _isLoading.value = true;
      try {
        final res = await ApiService.deleteStock(token, item['id']);
        if (!mounted) return;
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('Stock item deleted successfully!')), backgroundColor: Colors.green),
          );
          _fetchStocks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? context.tr('Failed to delete stock item')), backgroundColor: Colors.red),
          );
          _isLoading.value = false;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        _isLoading.value = false;
      }
    }
  }

  Future<void> _showStockAdjustModal(Map<String, dynamic> item, {String initialType = 'in'}) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final stockId = item['id']?.toString() ?? '';
    final itemName = item['item_name'] ?? '';
    final currentQty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
    final unit = item['unit_display'] ?? item['unit'] ?? item['base_unit'] ?? 'Pcs';

    String txType = initialType; // 'in' or 'out'
    String selectedReason = txType == 'in' ? 'purchase' : 'internal_use';
    final qtyController = TextEditingController();
    final costController = TextEditingController(text: item['purchase_rate']?.toString() ?? '0');
    final notesController = TextEditingController();
    final refController = TextEditingController();
    bool isSubmitting = false;

    final inReasons = [
      {'key': 'purchase', 'label': context.tr('Direct Purchase')},
      {'key': 'opening_stock', 'label': context.tr('Opening Stock')},
      {'key': 'customer_return', 'label': context.tr('Customer Return')},
      {'key': 'audit_addition', 'label': context.tr('Audit Addition (Physical count)')},
      {'key': 'other', 'label': context.tr('Other')}
    ];

    final outReasons = [
      {'key': 'internal_use', 'label': context.tr('Internal / Workshop Use')},
      {'key': 'damage', 'label': context.tr('Damage / Wastage')},
      {'key': 'expired', 'label': context.tr('Expired')},
      {'key': 'supplier_return', 'label': context.tr('Return to Supplier')},
      {'key': 'audit_reduction', 'label': context.tr('Audit Reduction')},
      {'key': 'loss', 'label': context.tr('Loss / Theft')},
      {'key': 'other', 'label': context.tr('Other')}
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final qtyEntered = double.tryParse(qtyController.text.trim()) ?? 0.0;
            final newQty = txType == 'in'
                ? currentQty + qtyEntered
                : (currentQty - qtyEntered).clamp(0.0, double.infinity);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          txType == 'in' ? Icons.add_circle : Icons.remove_circle,
                          color: txType == 'in' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txType == 'in' ? context.tr('Stock IN') : context.tr('Stock OUT'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                itemName,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.tr('Current'),
                                style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey.shade600),
                              ),
                              Text(
                                '$currentQty $unit',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  txType = 'in';
                                  selectedReason = 'purchase';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: txType == 'in' ? const Color(0xFF16A34A) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+ ${context.tr('Stock IN (Add)')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: txType == 'in' ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  txType = 'out';
                                  selectedReason = 'internal_use';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: txType == 'out' ? const Color(0xFFDC2626) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '- ${context.tr('Stock OUT (Deduct)')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: txType == 'out' ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            autofocus: true,
                            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: '${context.tr('Quantity')} ($unit) *',
                              hintText: '0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: (txType == 'in' ? Colors.green.shade50 : Colors.amber.shade50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: txType == 'in' ? Colors.green.shade200 : Colors.amber.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('New Balance'),
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$newQty $unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: txType == 'in' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: InputDecoration(
                        labelText: context.tr('Reason / Category *'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: (txType == 'in' ? inReasons : outReasons).map((r) {
                        return DropdownMenuItem<String>(
                          value: r['key']!,
                          child: Text(r['label']!, style: GoogleFonts.inter(fontSize: 12.5.sp)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedReason = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refController,
                      style: GoogleFonts.inter(fontSize: 12.5.sp),
                      decoration: InputDecoration(
                        labelText: context.tr('Ref / Bill / Doc No (Optional)'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 12.5.sp),
                      decoration: InputDecoration(
                        labelText: context.tr('Remarks / Notes (Optional)'),
                        hintText: context.tr('Enter remarks here...'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final qty = double.tryParse(qtyController.text.trim()) ?? 0.0;
                              if (qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('Please enter a valid quantity greater than 0')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (txType == 'out' && qty > currentQty) {
                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text(context.tr('Low Stock Warning')),
                                    content: Text(
                                      '${context.tr('Deducting')} $qty $unit ${context.tr('will exceed current stock')} ($currentQty $unit). ${context.tr('Do you want to continue?')}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: Text(context.tr('Cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: Text(context.tr('Continue'), style: const TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (proceed != true) return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final res = await ApiService.adjustStock(
                                  stockId: stockId,
                                  transactionType: txType,
                                  quantity: qty,
                                  reason: selectedReason,
                                  unitCost: double.tryParse(costController.text.trim()) ?? 0.0,
                                  notes: notesController.text.trim(),
                                  referenceNumber: refController.text.trim(),
                                  token: token,
                                );
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                if (!mounted) return;
                                if (res['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? context.tr('Stock updated successfully!')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _fetchStocks();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? context.tr('Failed to update stock')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!ctx.mounted) return;
                                setModalState(() => isSubmitting = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: txType == 'in' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              txType == 'in'
                                  ? context.tr('Confirm Stock IN')
                                  : context.tr('Confirm Stock OUT'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.sp),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showStockHistoryModal(Map<String, dynamic> item) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    final stockId = item['id']?.toString() ?? '';
    final itemName = item['item_name'] ?? '';
    final unit = item['unit_display'] ?? item['unit'] ?? item['base_unit'] ?? 'Pcs';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: ApiService.getStockTransactions(stockId: stockId, token: token),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF000080)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.tr('Movement History')}: $itemName',
                              style: GoogleFonts.inter(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Builder(
                        builder: (ctx) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Expanded(child: Center(child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return Expanded(child: Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red))));
                          }
                          final txs = (snapshot.data?['transactions'] as List<dynamic>? ?? []);
                          if (txs.isEmpty) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  context.tr('No stock movements recorded yet'),
                                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13.sp),
                                ),
                              ),
                            );
                          }
                          return Expanded(
                            child: ListView.separated(
                              controller: scrollController,
                              itemCount: txs.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (c, idx) {
                                final t = txs[idx];
                                final isTxIn = (t['transaction_type'] ?? '') == 'in';
                                final qty = t['quantity'] ?? 0;
                                final reason = t['reason_display'] ?? t['reason'] ?? '';
                                final date = t['date'] ?? '';
                                final by = t['created_by'] ?? '';
                                final notes = (t['notes'] ?? '').toString().trim();
                                final ref = (t['reference_number'] ?? '').toString().trim();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isTxIn ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isTxIn ? Icons.arrow_downward : Icons.arrow_upward,
                                          size: 16,
                                          color: isTxIn ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  reason,
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5.sp),
                                                ),
                                                Text(
                                                  '${isTxIn ? '+' : '-'}$qty $unit',
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.sp,
                                                    color: isTxIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  date,
                                                  style: GoogleFonts.inter(fontSize: 10.5.sp, color: Colors.grey.shade500),
                                                ),
                                                if (by.isNotEmpty)
                                                  Text(
                                                    'By: $by',
                                                    style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600),
                                                  ),
                                              ],
                                            ),
                                            if (ref.isNotEmpty)
                                              Text(
                                                'Ref: $ref',
                                                style: GoogleFonts.inter(fontSize: 10.5.sp, color: Colors.indigo.shade700),
                                              ),
                                            if (notes.isNotEmpty)
                                              Text(
                                                'Note: $notes',
                                                style: GoogleFonts.inter(fontSize: 10.5.sp, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySym = CountryConfig.currencySymbol;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                context.tr('Stock Items'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: _fetchStocks,
                  icon: const Icon(Icons.refresh),
                )
              ],
            )
          : null,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF000080),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('Search code, name, brand, category, supplier...'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, loading, _) => ValueListenableBuilder<String>(
                valueListenable: _errorMessage,
                builder: (context, errMsg, _) => ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _filteredStocks,
                  builder: (context, filtered, _) => loading
                      ? const Center(child: CircularProgressIndicator())
                      : errMsg.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(errMsg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchStocks,
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080), foregroundColor: Colors.white),
                                      child: Text(context.tr('Retry')),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : filtered.isEmpty
                              ? Center(child: Text(context.tr('No stock items found'), style: GoogleFonts.inter(color: Colors.grey, fontSize: 15.sp)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(14),
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, i) {
                                    final item = Map<String, dynamic>.from(filtered[i] as Map);
                                    final name = item['item_name'] ?? '';
                                    final code = item['product_code'] ?? item['part_number'] ?? '';
                                    final brand = item['brand'] ?? '';
                                    final group = item['group_name'] ?? '';
                                    final subGroup = item['sub_group_name'] ?? '';
                                    final unit = item['unit_display'] ?? item['unit'] ?? item['base_unit'] ?? '';
                                    final count = item['quantity'] ?? 0;
                                    final sellingPrice = item['selling_price'] ?? 0.0;
                                    final isTrading = item['is_trading'] == true;
                                    final isOperational = item['is_operational'] == true;

                                    final isIndia = item['is_india'] == true ||
                                        CountryConfig.current.code == CountryCode.india ||
                                        CountryConfig.phoneIsoCode.toUpperCase() == 'IN';

                                    final cgst = double.tryParse(item['cgst_percent']?.toString() ?? '0') ?? 0.0;
                                    final sgst = double.tryParse(item['sgst_percent']?.toString() ?? '0') ?? 0.0;
                                    final taxPercent = double.tryParse(item['tax_percent']?.toString() ?? item['vat_percent']?.toString() ?? '0') ?? 0.0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title & Actions
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.5.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onSelected: (value) {
                                                  if (value == 'adjust_in') {
                                                    _showStockAdjustModal(item, initialType: 'in');
                                                  } else if (value == 'adjust_out') {
                                                    _showStockAdjustModal(item, initialType: 'out');
                                                  } else if (value == 'history') {
                                                    _showStockHistoryModal(item);
                                                  } else if (value == 'edit') {
                                                    _editStockItem(item);
                                                  } else if (value == 'delete') {
                                                    _deleteStockItem(item);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'adjust_in',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF16A34A)),
                                                        const SizedBox(width: 8),
                                                        Text(context.tr('Stock IN'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'adjust_out',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.remove_circle_outline, size: 18, color: Color(0xFFDC2626)),
                                                        const SizedBox(width: 8),
                                                        Text(context.tr('Stock OUT'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'history',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.history, size: 18, color: Color(0xFF0284C7)),
                                                        const SizedBox(width: 8),
                                                        Text(context.tr('Movement History'), style: GoogleFonts.inter()),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuDivider(),
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.edit, size: 18, color: Colors.blue),
                                                        const SizedBox(width: 8),
                                                        Text(context.tr('Edit'), style: GoogleFonts.inter()),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.delete, size: 18, color: Colors.red),
                                                        const SizedBox(width: 8),
                                                        Text(context.tr('Delete'), style: GoogleFonts.inter(color: Colors.red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Badges row: Category, Sub Category, Type
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              if (group.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    group,
                                                    style: GoogleFonts.inter(fontSize: 10.5.sp, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              if (subGroup.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFAF5FF),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    subGroup,
                                                    style: GoogleFonts.inter(fontSize: 10.5.sp, color: const Color(0xFF7E22CE), fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              if (isTrading)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Trading',
                                                    style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF047857), fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              if (isOperational)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFFBEB),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Operational',
                                                    style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFFB45309), fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),

                                          // Details line: Code, Brand, Stock
                                          Row(
                                            children: [
                                              if (code.isNotEmpty) ...[
                                                Text(
                                                  'Code: ',
                                                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: Colors.grey.shade600),
                                                ),
                                                Text(
                                                  code,
                                                  style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                                ),
                                                const SizedBox(width: 14),
                                              ],
                                              if (brand.isNotEmpty) ...[
                                                Text(
                                                  'Brand: ',
                                                  style: GoogleFonts.inter(fontSize: 11.5.sp, color: Colors.grey.shade600),
                                                ),
                                                Text(
                                                  brand,
                                                  style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                                ),
                                                const SizedBox(width: 14),
                                              ],
                                              Text(
                                                'Stock: ',
                                                style: GoogleFonts.inter(fontSize: 11.5.sp, color: Colors.grey.shade600),
                                              ),
                                              Text(
                                                '$count $unit',
                                                style: GoogleFonts.inter(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0284C7)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Bottom line: Price & Tax
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Selling Rate: ',
                                                    style: GoogleFonts.inter(fontSize: 11.5.sp, color: Colors.grey.shade600),
                                                  ),
                                                  Text(
                                                    '$currencySym $sellingPrice',
                                                    style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                                ),
                                                child: Text(
                                                  isIndia && (cgst > 0 || sgst > 0)
                                                      ? 'GST: $taxPercent% ($cgst+$sgst)'
                                                      : 'Tax: $taxPercent%',
                                                  style: GoogleFonts.inter(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                                          const SizedBox(height: 8),

                                          // Quick Stock IN / OUT / History Actions
                                          Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _showStockAdjustModal(item, initialType: 'in'),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.add_circle, size: 15, color: Color(0xFF15803D)),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          context.tr('Stock IN'),
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11.5.sp,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFF15803D),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _showStockAdjustModal(item, initialType: 'out'),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEE2E2),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.remove_circle, size: 15, color: Color(0xFFB91C1C)),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                          context.tr('Stock OUT'),
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11.5.sp,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFFB91C1C),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => _showStockHistoryModal(item),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.history, size: 15, color: Color(0xFF475569)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        context.tr('History'),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11.sp,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF475569),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewStockItem,
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
