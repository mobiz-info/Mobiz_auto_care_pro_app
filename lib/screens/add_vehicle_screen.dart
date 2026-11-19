import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'vehicle_make_create_screen.dart';
import 'vehicle_brand_create_screen.dart';

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic> customerData;
  final String token;

  const AddVehicleScreen({
    super.key,
    required this.customerData,
    required this.token,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  Map<String, dynamic>? _fullCustomerData;

  List<dynamic> _vehicleTypes = [];
  List<dynamic> _vehicleTypeModels = [];
  List<dynamic> _makes = [];
  List<dynamic> _brandModels = [];
  List<dynamic> _colors = [];
  List<dynamic> _emissionStandards = [];

  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedSegment;
  Map<String, dynamic>? _selectedMake;
  Map<String, dynamic>? _selectedBrand;
  Map<String, dynamic>? _selectedColor;
  Map<String, dynamic>? _selectedEmission;
  String _selectedWheelType = 'normal_wheel';

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  final TextEditingController _engineController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _trimController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  String? _selectedTransmission;
  String? _selectedFuel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _chassisController.dispose();
    _engineController.dispose();
    _yearController.dispose();
    _trimController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        ApiService.getCustomer(widget.customerData['id'], widget.token),
        ApiService.getFormData(widget.token),
      ]);

      final customerRes = results[0];
      final formDataRes = results[1];

      if (customerRes['success'] == true && formDataRes['success'] == true) {
        final vehicleTypes = formDataRes['vehicle_types'] as List<dynamic>? ?? [];
        _vehicleTypes = vehicleTypes;
        _vehicleTypeModels = formDataRes['vehicle_type_models'] as List<dynamic>? ??
            formDataRes['vehicle_models'] as List<dynamic>? ??
            [];
        _makes = formDataRes['makes'] as List<dynamic>? ?? [];
        _brandModels = formDataRes['brand_models'] as List<dynamic>? ?? [];
        _colors = formDataRes['colors'] as List<dynamic>? ?? [];
        _emissionStandards = formDataRes['emission_standards'] as List<dynamic>? ?? [];

        _fullCustomerData = customerRes['customer'];
        if (vehicleTypes.isNotEmpty) {
          _selectedType = vehicleTypes.first;
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load details or options';
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

  List<dynamic> _segmentsForType(String? vehicleTypeId) {
    if (vehicleTypeId == null) return [];
    return _vehicleTypeModels.where((m) => m['vehicle_type_id'] == vehicleTypeId).toList();
  }

  List<dynamic> _makesForTypeAndSegment(String? vehicleTypeId, String? segmentId) {
    Iterable<dynamic> list = _brandModels;
    if (segmentId != null && segmentId.isNotEmpty) {
      list = list.where((b) => b['vehicle_type_model_id']?.toString() == segmentId.toString());
    } else if (vehicleTypeId != null && vehicleTypeId.isNotEmpty) {
      final validSegmentIds = _vehicleTypeModels
          .where((s) => s['vehicle_type_id']?.toString() == vehicleTypeId.toString())
          .map((s) => s['id']?.toString())
          .toSet();
      list = list.where((b) => validSegmentIds.contains(b['vehicle_type_model_id']?.toString()));
    } else {
      return _makes;
    }
    final makeIds = list
        .map((b) => b['make_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();
    return _makes.where((m) => makeIds.contains(m['id']?.toString())).toList();
  }

  List<dynamic> _brandModelsForSegmentAndMake(String? segmentId, String? makeId) {
    Iterable<dynamic> list = _brandModels;
    if (segmentId != null && segmentId.isNotEmpty) {
      list = list.where((b) => b['vehicle_type_model_id']?.toString() == segmentId);
    }
    if (makeId != null && makeId.isNotEmpty) {
      list = list.where((b) => b['make_id']?.toString() == makeId);
    }
    return list.toList();
  }

  void _onBrandModelSelected(dynamic val) {
    _selectedBrand = val;
    if (val != null) {
      final makeId = val['make_id']?.toString();
      if (makeId != null && makeId.isNotEmpty) {
        final matchedMake = _makes.firstWhere(
          (mk) => mk['id']?.toString() == makeId,
          orElse: () => null,
        );
        if (matchedMake != null) _selectedMake = matchedMake;
      }

      final vtmId = val['vehicle_type_model_id']?.toString();
      if (vtmId != null && vtmId.isNotEmpty) {
        final matchedSegment = _vehicleTypeModels.firstWhere(
          (vm) => vm['id']?.toString() == vtmId,
          orElse: () => null,
        );
        if (matchedSegment != null) {
          _selectedSegment = matchedSegment;
          final vtId = matchedSegment['vehicle_type_id']?.toString();
          if (vtId != null && vtId.isNotEmpty) {
            final matchedVt = _vehicleTypes.firstWhere(
              (vt) => vt['id']?.toString() == vtId,
              orElse: () => null,
            );
            if (matchedVt != null) _selectedType = matchedVt;
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    final number = _numberController.text.trim().toUpperCase();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please enter vehicle number')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_selectedSegment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select a vehicle type and segment')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      final vehicleData = <String, dynamic>{
        'vehicle_number': number,
        'vehicle_model_id': _selectedSegment!['id'],
        'wheel_type': _selectedWheelType,
      };
      if (_selectedMake != null) vehicleData['make_id'] = _selectedMake!['id'];
      if (_selectedBrand != null) vehicleData['brand_model_id'] = _selectedBrand!['id'];
      if (_selectedColor != null) vehicleData['color_id'] = _selectedColor!['id'];
      if (_selectedEmission != null) vehicleData['emission_standard_id'] = _selectedEmission!['id'];
      if (_selectedSegment != null) vehicleData['segment'] = _selectedSegment!['name'] ?? '';
      if (_chassisController.text.trim().isNotEmpty) vehicleData['chassis_number'] = _chassisController.text.trim().toUpperCase();
      if (_engineController.text.trim().isNotEmpty) vehicleData['engine_number'] = _engineController.text.trim().toUpperCase();
      if (_yearController.text.trim().isNotEmpty) vehicleData['model_year'] = _yearController.text.trim();
      if (_trimController.text.trim().isNotEmpty) vehicleData['variant_trim'] = _trimController.text.trim();
      if (_selectedTransmission != null) vehicleData['transmission_type'] = _selectedTransmission;
      if (_selectedFuel != null) vehicleData['fuel_type'] = _selectedFuel;
      if (_odometerController.text.trim().isNotEmpty) {
        vehicleData['current_odometer_km'] = int.tryParse(_odometerController.text.trim()) ?? 0;
      }

      final customerId = _fullCustomerData?['id'] ?? widget.customerData['id'];
      final name = _fullCustomerData?['name'] ?? widget.customerData['name'];
      final phone = _fullCustomerData?['phone'] ?? widget.customerData['phone'];

      final response = await ApiService.editCustomer({
        'customer_id': customerId,
        'name': name,
        'phone': phone,
        'whatsapp_number': _fullCustomerData?['whatsapp_number'] ?? widget.customerData['whatsapp_number'] ?? '',
        'email': _fullCustomerData?['email'] ?? widget.customerData['email'] ?? '',
        'address': _fullCustomerData?['address'] ?? widget.customerData['address'] ?? '',
        'customer_type_id': _fullCustomerData?['customer_type_id'] ?? widget.customerData['customer_type_id'],
        'new_vehicles': [vehicleData],
      }, widget.token);

      if (response['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to add vehicle';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }


  Future<void> _createNewMake() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const VehicleMakeCreateScreen()),
    );
    if (result != null && mounted) {
      final newId = result['id']?.toString();
      final newName = result['name']?.toString() ?? '';

      await _loadData();

      Map<String, dynamic>? newMake;
      for (final m in _makes) {
        if (m['id']?.toString() == newId) {
          newMake = m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m);
          break;
        }
      }
      newMake ??= {'id': newId, 'name': newName};

      if (!_makes.any((m) => m['id']?.toString() == newId)) {
        _makes.add(newMake);
      }

      setState(() {
        _selectedMake = newMake;
        _selectedBrand = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Selected Make: $newName'),
        backgroundColor: const Color(0xFF000080),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _createNewBrandModel() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleBrandCreateScreen(
          initialMakeId: _selectedMake?['id']?.toString(),
          initialMakeName: _selectedMake?['name']?.toString(),
          initialSegmentId: _selectedSegment?['id']?.toString(),
          initialSegmentName: _selectedSegment?['name']?.toString(),
        ),
      ),
    );
    if (result != null && mounted) {
      final newId = result['id']?.toString();
      final newName = result['name']?.toString() ?? '';
      final makeId = result['make_id']?.toString() ?? _selectedMake?['id']?.toString();
      final segmentId = result['vehicle_type_model_id']?.toString() ?? _selectedSegment?['id']?.toString();

      await _loadData();

      Map<String, dynamic>? newBrand;
      for (final b in _brandModels) {
        if (b['id']?.toString() == newId) {
          newBrand = b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b);
          break;
        }
      }
      newBrand ??= {
        'id': newId,
        'name': newName,
        'make_id': makeId,
        'vehicle_type_model_id': segmentId,
      };

      if (!_brandModels.any((b) => b['id']?.toString() == newId)) {
        _brandModels.add(newBrand);
      }

      setState(() {
        _selectedBrand = newBrand;

        if (makeId != null && makeId.isNotEmpty) {
          for (final mk in _makes) {
            if (mk['id']?.toString() == makeId) {
              _selectedMake = mk;
              break;
            }
          }
        }

        if (segmentId != null && segmentId.isNotEmpty) {
          for (final seg in _vehicleTypeModels) {
            if (seg['id']?.toString() == segmentId) {
              _selectedSegment = seg;
              final vtId = seg['vehicle_type_id']?.toString();
              if (vtId != null && vtId.isNotEmpty) {
                for (final vt in _vehicleTypes) {
                  if (vt['id']?.toString() == vtId) {
                    _selectedType = vt;
                    break;
                  }
                }
              }
              break;
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Selected Model: $newName'),
        backgroundColor: const Color(0xFF000080),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: const Color(0xFF000080), size: 20.r),
              ),
              SizedBox(width: 10.w),
              Text(
                context.tr(title),
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000080),
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown<T>(
    BuildContext context, {
    required String label,
    required String title,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?)? onChanged,
    String? hint,
    VoidCallback? onAddNew,
    String? addNewText,
  }) {
    String displayLabel = hint ?? context.tr('Select ...');
    bool hasValue = false;
    if (value != null && items.isNotEmpty) {
      if (value is Map && value.containsKey('id')) {
        final valId = value['id']?.toString();
        for (final item in items) {
          if (item is Map && item['id']?.toString() == valId) {
            displayLabel = labelBuilder(item);
            hasValue = true;
            break;
          }
        }
      } else {
        displayLabel = labelBuilder(value);
        hasValue = true;
      }
    } else if (value != null) {
      displayLabel = labelBuilder(value);
      hasValue = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (onAddNew != null)
              GestureDetector(
                onTap: onAddNew,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle, size: 14.sp, color: const Color(0xFF000080)),
                      const SizedBox(width: 4),
                      Text(
                        addNewText ?? '+ Add',
                        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: const Color(0xFF000080)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: (onChanged == null)
              ? null
              : () => _showSearchableModal<T>(context, title, items, labelBuilder, onChanged, onAddNew: onAddNew, addNewText: addNewText),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: hasValue ? Colors.black87 : Colors.grey.shade500,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search, size: 18.r, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableModal<T>(
    BuildContext context,
    String title,
    List<T> items,
    String Function(T) labelBuilder,
    void Function(T?) onChanged, {
    VoidCallback? onAddNew,
    String? addNewText,
  }) {
    final searchNotifier = ValueNotifier<String>('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: EdgeInsets.only(
          top: 20.h,
          left: 20.w,
          right: 20.w,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.tr('Select')} $title',
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000080),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAddNew != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onAddNew();
                        },
                        icon: const Icon(Icons.add_circle, size: 16, color: Color(0xFF000080)),
                        label: Text(addNewText ?? 'Add New', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF000080), fontSize: 13.sp)),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.h),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: context.tr('Search ...'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: (v) => searchNotifier.value = v.toLowerCase().trim(),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: searchNotifier,
                builder: (_, query, __) {
                  final filtered = items
                      .where((item) => labelBuilder(item).toLowerCase().contains(query))
                      .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('No results found'),
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            if (onAddNew != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onAddNew();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  query.isNotEmpty ? 'Create "$query"' : (addNewText ?? 'Create New $title'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        title: Text(
                          labelBuilder(item),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14.sp),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14.r, color: Colors.grey.shade400),
                        onTap: () {
                          onChanged(item);
                          Navigator.pop(ctx);
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

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    void Function(T?)? onChanged,
    String? hint,
  }) {
    T? matchedValue;
    if (value != null && items.isNotEmpty) {
      if (value is Map && value.containsKey('id')) {
        final valId = value['id']?.toString();
        for (final item in items) {
          if (item is Map && item['id']?.toString() == valId) {
            matchedValue = item;
            break;
          }
        }
      } else {
        for (final item in items) {
          if (item == value) {
            matchedValue = item;
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              menuMaxHeight: 300,
              value: matchedValue,
              hint: Text(
                hint ?? context.tr('Select...'),
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: GoogleFonts.inter(fontSize: 14.sp),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customerData['name']?.toString() ?? 'Customer';
    final customerPhone = widget.customerData['phone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          context.tr('Add Vehicle'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13.sp),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Customer Summary Card
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000080).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFF000080).withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF000080),
                          radius: 20.r,
                          child: const Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.sp,
                                  color: const Color(0xFF000080),
                                ),
                              ),
                              if (customerPhone.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  customerPhone,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vehicle Details Form Card
                  _buildCard(
                    title: 'Vehicle Details',
                    icon: Icons.directions_car_filled_outlined,
                    children: [
                      // Vehicle Number
                      Text(
                        context.tr('Vehicle Number *'),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _numberController,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: context.tr('e.g. KL09AA1111'),
                          prefixIcon: const Icon(Icons.tag, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: Color(0xFF000080), width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // 1. Vehicle Type
                      _buildDropdown<dynamic>(
                        label: context.tr('Vehicle Type *'),
                        value: _selectedType,
                        items: _vehicleTypes,
                        labelBuilder: (item) => context.tr(item['name'] ?? ''),
                        onChanged: (val) {
                          setState(() {
                            _selectedType = val;
                            final validMakes = _makesForTypeAndSegment(
                              val?['id']?.toString(),
                              _selectedSegment?['id']?.toString(),
                            );
                            if (_selectedMake != null &&
                                !validMakes.any((m) => m['id']?.toString() == _selectedMake?['id']?.toString())) {
                              _selectedMake = null;
                              _selectedBrand = null;
                            }
                          });
                        },
                      ),
                      SizedBox(height: 16.h),

                      // 2. Make (Searchable Dropdown)
                      Builder(builder: (context) {
                        final rawMakes = _makesForTypeAndSegment(
                          _selectedType?['id']?.toString(),
                          _selectedSegment?['id']?.toString(),
                        );
                        final makes = List<dynamic>.from(rawMakes);
                        if (_selectedMake != null && !makes.any((m) => m['id']?.toString() == _selectedMake?['id']?.toString())) {
                          makes.insert(0, _selectedMake);
                        }
                        return _buildSearchableDropdown<dynamic>(
                          context,
                          label: context.tr('Vehicle Make'),
                          title: context.tr('Make'),
                          value: _selectedMake,
                          items: makes,
                          labelBuilder: (item) => item['name'] ?? '',
                          hint: context.tr('Select Make (e.g. Maruti, Hyundai)...'),
                          onAddNew: _createNewMake,
                          addNewText: '+ Add Make',
                          onChanged: (val) {
                            setState(() {
                              _selectedMake = val;
                              _selectedBrand = null;
                            });
                          },
                        );
                      }),
                      SizedBox(height: 16.h),

                      // 3. Brand / Model (Searchable Dropdown)
                      Builder(builder: (context) {
                        final rawBrands = _brandModelsForSegmentAndMake(
                          _selectedSegment?['id']?.toString(),
                          _selectedMake?['id']?.toString(),
                        );
                        final brands = List<dynamic>.from(rawBrands);
                        if (_selectedBrand != null && !brands.any((b) => b['id']?.toString() == _selectedBrand?['id']?.toString())) {
                          brands.insert(0, _selectedBrand);
                        }
                        return _buildSearchableDropdown<dynamic>(
                          context,
                          label: context.tr('Brand / Model'),
                          title: context.tr('Brand Model'),
                          value: _selectedBrand,
                          items: brands,
                          labelBuilder: (item) => item['name'] ?? '',
                          hint: context.tr('Select Model (e.g. Swift, Creta)...'),
                          onAddNew: _createNewBrandModel,
                          addNewText: '+ Add Model',
                          onChanged: _onBrandModelSelected,
                        );
                      }),
                      SizedBox(height: 16.h),

                      // 4. Segment
                      Builder(builder: (context) {
                        final segments = _segmentsForType(_selectedType?['id']?.toString());
                        if (segments.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _buildDropdown<dynamic>(
                              label: context.tr('Vehicle Model (Segment) *'),
                              value: _selectedSegment,
                              items: segments,
                              labelBuilder: (item) => item['name'] ?? '',
                              onChanged: (val) {
                                setState(() {
                                  _selectedSegment = val;
                                });
                              },
                            ),
                            SizedBox(height: 16.h),
                          ],
                        );
                      }),

                      // 5. Color selection
                      _buildDropdown<dynamic>(
                        label: context.tr('Color'),
                        value: _selectedColor,
                        items: _colors,
                        labelBuilder: (item) => context.tr(item['name'] ?? ''),
                        hint: context.tr('Select Color...'),
                        onChanged: (val) {
                          setState(() {
                            _selectedColor = val;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),

                      // 6. Emission Standard selection
                      if (_emissionStandards.isNotEmpty) ...[
                        _buildDropdown<dynamic>(
                          label: context.tr('Emission Standard'),
                          value: _selectedEmission,
                          items: _emissionStandards,
                          labelBuilder: (item) => item['name'] ?? '',
                          hint: context.tr('Select Emission...'),
                          onChanged: (val) {
                            setState(() {
                              _selectedEmission = val;
                            });
                          },
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // 7. Wheel Type selection
                      Text(
                        context.tr('Wheel Type *'),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                context.tr('Alloy Wheel'),
                                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                              value: 'alloy_wheel',
                              groupValue: _selectedWheelType,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: const Color(0xFF000080),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedWheelType = val;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                context.tr('Normal Wheel'),
                                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                              value: 'normal_wheel',
                              groupValue: _selectedWheelType,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: const Color(0xFF000080),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedWheelType = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Technical & Registration Specs Card (Chassis, Engine, Year, Gear)
                  _buildCard(
                    title: 'Chassis, Engine & Technical Specs',
                    icon: Icons.precision_manufacturing_outlined,
                    children: [
                      // Chassis & Engine Number
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Chassis Number (VIN)'),
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: _chassisController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: context.tr('e.g. MA3E...'),
                                    filled: true,
                                    fillColor: const Color(0xFFFAFAFA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Engine Number'),
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: _engineController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: context.tr('e.g. K12M...'),
                                    filled: true,
                                    fillColor: const Color(0xFFFAFAFA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Model Year & Variant / Trim
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Model Year'),
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: _yearController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: context.tr('e.g. 2023'),
                                    filled: true,
                                    fillColor: const Color(0xFFFAFAFA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Variant / Trim'),
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                ),
                                SizedBox(height: 6.h),
                                TextField(
                                  controller: _trimController,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: context.tr('e.g. VXi / ZXi / Sport'),
                                    filled: true,
                                    fillColor: const Color(0xFFFAFAFA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Transmission & Fuel Type
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<String>(
                              label: context.tr('Transmission'),
                              value: _selectedTransmission,
                              items: ['Automatic', 'Manual', 'CVT', 'DCT', 'AMT'],
                              labelBuilder: (item) => context.tr(item),
                              hint: context.tr('Select Gear...'),
                              onChanged: (val) => setState(() => _selectedTransmission = val),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildDropdown<String>(
                              label: context.tr('Fuel Type'),
                              value: _selectedFuel,
                              items: ['Petrol', 'Diesel', 'CNG', 'LPG', 'Electric', 'Hybrid'],
                              labelBuilder: (item) => context.tr(item),
                              hint: context.tr('Select Fuel...'),
                              onChanged: (val) => setState(() => _selectedFuel = val),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Current Odometer
                      Text(
                        context.tr('Current Odometer (KM)'),
                        style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _odometerController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13.sp),
                        decoration: InputDecoration(
                          hintText: context.tr('e.g. 45000'),
                          prefixIcon: const Icon(Icons.speed, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 80.h),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: (_isLoading || _isSaving) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8.w),
                        Text(
                          context.tr('Add Vehicle'),
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
