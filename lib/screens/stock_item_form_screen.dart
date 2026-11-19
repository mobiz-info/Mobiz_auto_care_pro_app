import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/country_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class StockItemFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;

  const StockItemFormScreen({super.key, this.item});

  @override
  State<StockItemFormScreen> createState() => _StockItemFormScreenState();
}

class _StockItemFormScreenState extends State<StockItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingDropdowns = true;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _productCodeController;
  late TextEditingController _partNumberController;
  late TextEditingController _alternatePartNumberController;
  late TextEditingController _brandController;
  late TextEditingController _countryOfOriginController;
  late TextEditingController _supplierNameController;
  late TextEditingController _quantityController;
  late TextEditingController _purchaseRateController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _taxPercentController;
  late TextEditingController _cgstController;
  late TextEditingController _sgstController;
  late TextEditingController _igstController;

  // Preserved background fields
  String? _hsnCode;
  String? _barcode;
  String? _criticalLevel;
  String? _profitMargin;
  String? _selectedExpenseHeadId;

  String? _selectedUnit;
  String? _selectedGroupId;
  String? _selectedSubGroupId;
  String? _selectedSupplierId;
  bool _isTrading = true;
  bool _isOperational = false;

  List<dynamic> _stockGroups = [];
  List<dynamic> _currentSubGroups = [];
  List<dynamic> _suppliers = [];

  final List<Map<String, String>> _unitChoices = [
    {'value': 'Litre', 'display': 'Litre (Ltr)'},
    {'value': 'Millilitre', 'display': 'Millilitre (ml)'},
    {'value': 'Kilogram', 'display': 'Kilogram (Kg)'},
    {'value': 'Gram', 'display': 'Gram (g)'},
    {'value': 'Piece', 'display': 'Piece (Pcs)'},
    {'value': 'Box', 'display': 'Box'},
    {'value': 'Packet', 'display': 'Packet'},
    {'value': 'Bottle', 'display': 'Bottle'},
    {'value': 'Can', 'display': 'Can'},
    {'value': 'Roll', 'display': 'Roll'},
  ];

  bool get isEdit => widget.item != null;

  bool get isIndia {
    if (widget.item != null && widget.item!['is_india'] != null) {
      return widget.item!['is_india'] == true;
    }
    return CountryConfig.current.code == CountryCode.india ||
        CountryConfig.phoneIsoCode.toUpperCase() == 'IN' ||
        CountryConfig.displayName.toLowerCase().contains('india');
  }

  Map<String, dynamic>? get _selectedGroupObj {
    if (_selectedGroupId == null) return null;
    final found = _stockGroups.firstWhere(
      (g) => g['id']?.toString() == _selectedGroupId,
      orElse: () => null,
    );
    return found != null ? Map<String, dynamic>.from(found) : null;
  }

  Map<String, dynamic>? get _selectedSubGroupObj {
    if (_selectedSubGroupId == null) return null;
    final found = _currentSubGroups.firstWhere(
      (sg) => sg['id']?.toString() == _selectedSubGroupId,
      orElse: () => null,
    );
    return found != null ? Map<String, dynamic>.from(found) : null;
  }

  Map<String, dynamic>? get _selectedSupplierObj {
    if (_selectedSupplierId == null) return null;
    final found = _suppliers.firstWhere(
      (s) => s['id']?.toString() == _selectedSupplierId,
      orElse: () => null,
    );
    return found != null ? Map<String, dynamic>.from(found) : null;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameController = TextEditingController(text: item?['item_name'] ?? '');
    _productCodeController = TextEditingController(text: item?['product_code'] ?? item?['part_number'] ?? '');
    _partNumberController = TextEditingController(text: item?['part_number'] ?? item?['product_code'] ?? '');
    _alternatePartNumberController = TextEditingController(text: item?['alternate_part_number'] ?? '');
    _brandController = TextEditingController(text: item?['brand'] ?? '');
    _countryOfOriginController = TextEditingController(text: item?['country_of_origin'] ?? '');
    _supplierNameController = TextEditingController(text: item?['supplier_name'] ?? '');
    _quantityController = TextEditingController(
      text: item?['quantity'] != null ? item!['quantity'].toString() : '0',
    );
    _purchaseRateController = TextEditingController(
      text: item?['purchase_rate'] != null ? item!['purchase_rate'].toString() : '0.00',
    );
    _sellingPriceController = TextEditingController(
      text: item?['selling_price'] != null ? item!['selling_price'].toString() : '0.00',
    );

    _hsnCode = item?['hsn_code'] ?? '';
    _barcode = item?['barcode'] ?? '';
    _criticalLevel = item?['critical_level']?.toString() ?? '0.0';
    _profitMargin = item?['profit_margin_percent']?.toString() ?? '0.0';
    _selectedExpenseHeadId = item?['expense_head_id']?.toString();

    // Initial Tax Setup based on Country
    if (isIndia) {
      double cgst = 0.0;
      double sgst = 0.0;
      double igst = 0.0;
      if (item != null) {
        cgst = double.tryParse(item['cgst_percent']?.toString() ?? '0') ?? 0.0;
        sgst = double.tryParse(item['sgst_percent']?.toString() ?? '0') ?? 0.0;
        igst = double.tryParse(item['igst_percent']?.toString() ?? '0') ?? 0.0;
        final taxP = double.tryParse(item['tax_percent']?.toString() ?? '0') ?? 0.0;
        if (igst == 0 && cgst == 0 && sgst == 0 && taxP > 0) {
          igst = taxP;
          cgst = taxP / 2.0;
          sgst = taxP / 2.0;
        } else if (igst > 0 && cgst == 0 && sgst == 0) {
          cgst = igst / 2.0;
          sgst = igst / 2.0;
        } else if (igst == 0 && (cgst > 0 || sgst > 0)) {
          igst = cgst + sgst;
        }
      } else {
        cgst = 9.0;
        sgst = 9.0;
        igst = 18.0;
      }
      _cgstController = TextEditingController(text: _formatNum(cgst));
      _sgstController = TextEditingController(text: _formatNum(sgst));
      _igstController = TextEditingController(text: _formatNum(igst));
      _taxPercentController = TextEditingController(text: _formatNum(igst));
    } else {
      double taxRate = 5.0;
      if (item != null) {
        taxRate = double.tryParse(item['tax_percent']?.toString() ?? item['vat_percent']?.toString() ?? '0') ?? 0.0;
      }
      _taxPercentController = TextEditingController(text: _formatNum(taxRate));
      _cgstController = TextEditingController(text: '0.0');
      _sgstController = TextEditingController(text: '0.0');
      _igstController = TextEditingController(text: _formatNum(taxRate));
    }

    _selectedUnit = item?['unit'] ?? item?['base_unit'];
    _selectedGroupId = item?['group_id']?.toString() ?? item?['group']?['id']?.toString();
    _selectedSubGroupId = item?['sub_group_id']?.toString() ?? item?['sub_group']?['id']?.toString();
    _selectedSupplierId = item?['supplier_id']?.toString() ?? item?['supplier']?['id']?.toString();
    _isTrading = item?['is_trading'] ?? true;
    _isOperational = item?['is_operational'] ?? false;

    _fetchDropdownData();
  }

  String _formatNum(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  void _onCgstChanged(String val) {
    final cVal = double.tryParse(val.trim());
    if (cVal != null) {
      _sgstController.text = _formatNum(cVal);
      final igst = cVal * 2.0;
      _igstController.text = _formatNum(igst);
      _taxPercentController.text = _formatNum(igst);
    }
  }

  void _onSgstChanged(String val) {
    final sVal = double.tryParse(val.trim());
    final cVal = double.tryParse(_cgstController.text.trim()) ?? 0.0;
    if (sVal != null) {
      final igst = cVal + sVal;
      _igstController.text = _formatNum(igst);
      _taxPercentController.text = _formatNum(igst);
    }
  }

  void _onIgstChanged(String val) {
    final iVal = double.tryParse(val.trim());
    if (iVal != null) {
      final half = iVal / 2.0;
      _cgstController.text = _formatNum(half);
      _sgstController.text = _formatNum(half);
      _taxPercentController.text = _formatNum(iVal);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productCodeController.dispose();
    _partNumberController.dispose();
    _alternatePartNumberController.dispose();
    _brandController.dispose();
    _countryOfOriginController.dispose();
    _supplierNameController.dispose();
    _quantityController.dispose();
    _purchaseRateController.dispose();
    _sellingPriceController.dispose();
    _taxPercentController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _isLoadingDropdowns = false);
      return;
    }

    try {
      final results = await Future.wait([
        ApiService.getStockGroups(token).catchError((_) => <String, dynamic>{}),
        ApiService.getSuppliersList(token).catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] == true) {
            _stockGroups = results[0]['groups'] ?? results[0]['stock_groups'] ?? [];
            _updateSubGroups();
          }
          if (results[1]['success'] == true) {
            _suppliers = results[1]['suppliers'] ?? [];
          }
          _isLoadingDropdowns = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  void _updateSubGroups() {
    if (_selectedGroupId == null) {
      _currentSubGroups = [];
      _selectedSubGroupId = null;
      return;
    }

    final group = _stockGroups.firstWhere(
      (g) => g['id']?.toString() == _selectedGroupId?.toString(),
      orElse: () => null,
    );

    if (group != null && group['sub_groups'] != null) {
      _currentSubGroups = List<dynamic>.from(group['sub_groups']);
      if (!_currentSubGroups.any((sg) => sg['id']?.toString() == _selectedSubGroupId?.toString())) {
        _selectedSubGroupId = null;
      }
    } else {
      _currentSubGroups = [];
      _selectedSubGroupId = null;
    }
  }

  void _showStockGroupSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final filtered = _stockGroups.where((g) {
              final name = (g['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('Select Category'),
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: context.tr('Search categories...'),
                      hintStyle: GoogleFonts.inter(fontSize: 12.5.sp, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (val) {
                      setInnerState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(
                            context.tr('None / ---------'),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          trailing: _selectedGroupId == null
                              ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedGroupId = null;
                              _updateSubGroups();
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const Divider(height: 1),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                context.tr('No categories found'),
                                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...filtered.map((g) {
                            final idStr = g['id']?.toString();
                            final isSelected = idStr == _selectedGroupId;
                            return ListTile(
                              dense: true,
                              title: Text(
                                g['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedGroupId = idStr;
                                  _updateSubGroups();
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubGroupSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final filtered = _currentSubGroups.where((sg) {
              final name = (sg['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('Select Sub Category'),
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: context.tr('Search sub categories...'),
                      hintStyle: GoogleFonts.inter(fontSize: 12.5.sp, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (val) {
                      setInnerState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(
                            context.tr('None / ---------'),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          trailing: _selectedSubGroupId == null
                              ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                              : null,
                          onTap: () {
                            setState(() => _selectedSubGroupId = null);
                            Navigator.pop(ctx);
                          },
                        ),
                        const Divider(height: 1),
                        if (_selectedGroupId == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                context.tr('Please select a Category first'),
                                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.amber.shade800),
                              ),
                            ),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                context.tr('No sub categories found for this category'),
                                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...filtered.map((sg) {
                            final idStr = sg['id']?.toString();
                            final isSelected = idStr == _selectedSubGroupId;
                            return ListTile(
                              dense: true,
                              title: Text(
                                sg['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                                  : null,
                              onTap: () {
                                setState(() => _selectedSubGroupId = idStr);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSupplierSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setInnerState) {
            final filtered = _suppliers.where((s) {
              final name = (s['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('Select Supplier'),
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: context.tr('Search suppliers...'),
                      hintStyle: GoogleFonts.inter(fontSize: 12.5.sp, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (val) {
                      setInnerState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(
                            context.tr('None / Custom Supplier'),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          trailing: _selectedSupplierId == null
                              ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedSupplierId = null;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        const Divider(height: 1),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                context.tr('No suppliers found'),
                                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          ...filtered.map((s) {
                            final idStr = s['id']?.toString();
                            final isSelected = idStr == _selectedSupplierId;
                            return ListTile(
                              dense: true,
                              title: Text(
                                s['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Color(0xFF2563EB), size: 18)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedSupplierId = idStr;
                                  _supplierNameController.text = s['name'] ?? '';
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveStockItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select a Unit')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'item_name': _nameController.text.trim(),
      'product_code': _productCodeController.text.trim(),
      'part_number': _partNumberController.text.trim(),
      'alternate_part_number': _alternatePartNumberController.text.trim(),
      'brand': _brandController.text.trim(),
      'country_of_origin': _countryOfOriginController.text.trim(),
      'supplier_id': _selectedSupplierId,
      'supplier_name': _supplierNameController.text.trim(),
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0.0,
      'unit': _selectedUnit,
      'base_unit': _selectedUnit,
      'purchase_rate': double.tryParse(_purchaseRateController.text.trim()) ?? 0.0,
      'selling_price': double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
      'group_id': _selectedGroupId,
      'sub_group_id': _selectedSubGroupId,
      'expense_head_id': _selectedExpenseHeadId,
      'hsn_code': _hsnCode ?? '',
      'barcode': _barcode ?? '',
      'is_trading': _isTrading,
      'is_operational': _isOperational,
      'critical_level': double.tryParse(_criticalLevel ?? '0') ?? 0.0,
      'profit_margin_percent': double.tryParse(_profitMargin ?? '0') ?? 0.0,
    };

    if (isIndia) {
      final cgst = double.tryParse(_cgstController.text.trim()) ?? 0.0;
      final sgst = double.tryParse(_sgstController.text.trim()) ?? 0.0;
      final igst = double.tryParse(_igstController.text.trim()) ?? (cgst + sgst);
      payload['cgst_percent'] = cgst;
      payload['sgst_percent'] = sgst;
      payload['igst_percent'] = igst;
      payload['tax_percent'] = igst > 0 ? igst : (cgst + sgst);
      payload['vat_percent'] = 0.0;
    } else {
      final tax = double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
      payload['cgst_percent'] = 0.0;
      payload['sgst_percent'] = 0.0;
      payload['igst_percent'] = tax;
      payload['vat_percent'] = tax;
      payload['tax_percent'] = tax;
    }

    try {
      final res = isEdit
          ? await ApiService.editStock(token, widget.item!['id'], payload)
          : await ApiService.createStock(token, payload);

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? context.tr('Stock item updated successfully!')
                  : context.tr('Stock item created successfully!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? context.tr('Failed to save stock item')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText != null ? context.tr(hintText) : null,
      hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false, String? optionalNote}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF1E293B), fontWeight: FontWeight.w600),
          children: [
            TextSpan(text: context.tr(label)),
            if (isRequired)
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (optionalNote != null)
              TextSpan(
                text: ' (${context.tr(optionalNote)})',
                style: GoogleFonts.inter(fontSize: 10.5.sp, color: const Color(0xFF94A3B8), fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySym = CountryConfig.currencySymbol;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEdit ? context.tr('Edit Stock Item') : context.tr('Create Stock Item'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Country & Tax Info Badge (matching Web badge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Text(CountryConfig.flag, style: TextStyle(fontSize: 16.sp)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${CountryConfig.displayName} (${isIndia ? "GST" : "VAT"})',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Row 0: Category & Sub Category (Same as Web Row 0)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Category'),
                                InkWell(
                                  onTap: _showStockGroupSelector,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedGroupObj != null ? _selectedGroupObj!['name'] : context.tr('Select Category'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5.sp,
                                              color: _selectedGroupObj != null ? const Color(0xFF1E293B) : Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Sub Category'),
                                InkWell(
                                  onTap: _showSubGroupSelector,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedSubGroupObj != null ? _selectedSubGroupObj!['name'] : context.tr('Select Sub Category'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5.sp,
                                              color: _selectedSubGroupObj != null ? const Color(0xFF1E293B) : Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 1: Product Code & Brand (Same as Web Row 1)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Product Code'),
                                TextFormField(
                                  controller: _productCodeController,
                                  decoration: _inputDecoration(hintText: 'Enter Product Code'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Brand'),
                                TextFormField(
                                  controller: _brandController,
                                  decoration: _inputDecoration(hintText: 'Enter Brand'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 1.5: Spare Part No & Alternate No (Same as Web Row 1.5)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Spare Part No'),
                                TextFormField(
                                  controller: _partNumberController,
                                  decoration: _inputDecoration(hintText: 'Enter Spare Part No'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Alternate No'),
                                TextFormField(
                                  controller: _alternatePartNumberController,
                                  decoration: _inputDecoration(hintText: 'Enter Alternate No'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Product Name * & Country of Origin (Same as Web Row 2)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Product Name', isRequired: true),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _inputDecoration(hintText: 'Enter Product Name'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return context.tr('Product Name is required');
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Country of Origin'),
                                TextFormField(
                                  controller: _countryOfOriginController,
                                  decoration: _inputDecoration(hintText: 'Enter Country of Origin'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 3: Supplier (Registered) & Supplier Name (or Custom) (Same as Web Row 3)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Supplier (Registered)'),
                                InkWell(
                                  onTap: _showSupplierSelector,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedSupplierObj != null ? _selectedSupplierObj!['name'] : context.tr('Select Supplier'),
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5.sp,
                                              color: _selectedSupplierObj != null ? const Color(0xFF1E293B) : Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Supplier Name (or Custom)'),
                                TextFormField(
                                  controller: _supplierNameController,
                                  decoration: _inputDecoration(hintText: 'Enter Supplier Name'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 4: Stock Count & Unit * (Same as Web Row 4)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Stock Count'),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(hintText: 'Enter Stock Count'),
                                  style: GoogleFonts.inter(fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Unit', isRequired: true),
                                DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  isExpanded: true,
                                  decoration: _inputDecoration(hintText: 'Select Unit'),
                                  style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF1E293B)),
                                  items: _unitChoices.map((u) {
                                    return DropdownMenuItem<String>(
                                      value: u['value'],
                                      child: Text(u['display'] ?? '', style: TextStyle(fontSize: 12.5.sp)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedUnit = val);
                                  },
                                  validator: (val) => val == null || val.isEmpty ? context.tr('Unit is required') : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 5: Purchase Rate & Selling Rate * (Same as Web Row 5)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Purchase Rate ($currencySym)'),
                                TextFormField(
                                  controller: _purchaseRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(hintText: 'Enter Purchase Rate'),
                                  style: GoogleFonts.inter(fontSize: 13.sp),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Selling Rate ($currencySym)', isRequired: true),
                                TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(hintText: 'Enter Selling Rate'),
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return context.tr('Selling Rate is required');
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 6: Tax Section (Country-Specific) (Same as Web Row 6)
                      if (isIndia)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.percent, color: Color(0xFF2563EB), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('GST Details (India)'),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'CGST + SGST or IGST',
                                    style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('CGST (%)'),
                                        TextFormField(
                                          controller: _cgstController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: _inputDecoration(hintText: '9.0'),
                                          style: GoogleFonts.inter(fontSize: 12.5.sp),
                                          onChanged: _onCgstChanged,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('SGST (%)'),
                                        TextFormField(
                                          controller: _sgstController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: _inputDecoration(hintText: '9.0'),
                                          style: GoogleFonts.inter(fontSize: 12.5.sp),
                                          onChanged: _onSgstChanged,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('IGST (%)'),
                                        TextFormField(
                                          controller: _igstController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: _inputDecoration(hintText: '18.0'),
                                          style: GoogleFonts.inter(fontSize: 12.5.sp),
                                          onChanged: _onIgstChanged,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.percent, color: Color(0xFF2563EB), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('Tax (%)'),
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _taxPercentController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration(hintText: '5.0'),
                                style: GoogleFonts.inter(fontSize: 13.sp),
                              ),
                             
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Row 7: Trading & Operational Item Toggles (Same as Web Row 7)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                context.tr('Trading Item (Yes / No)'),
                                style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                             
                              value: _isTrading,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) => setState(() => _isTrading = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                context.tr('Operational Item (Yes / No)'),
                                style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                              
                              value: _isOperational,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (val) => setState(() => _isOperational = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bottom Action Buttons (Same as Web)
                      SizedBox(
                        width: double.infinity,
                        height: 44.h,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveStockItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            isEdit ? context.tr('Save Changes') : context.tr('Save Stock Item'),
                            style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40.h,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            context.tr('Cancel'),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
