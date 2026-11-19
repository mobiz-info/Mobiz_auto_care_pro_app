import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'vehicle_make_create_screen.dart';

class VehicleBrandCreateScreen extends StatefulWidget {
  final String? initialMakeId;
  final String? initialMakeName;
  final String? initialSegmentId;
  final String? initialSegmentName;

  const VehicleBrandCreateScreen({
    super.key,
    this.initialMakeId,
    this.initialMakeName,
    this.initialSegmentId,
    this.initialSegmentName,
  });

  @override
  State<VehicleBrandCreateScreen> createState() =>
      _VehicleBrandCreateScreenState();
}

class _VehicleBrandCreateScreenState extends State<VehicleBrandCreateScreen> {
  static const _navy = Color(0xFF000080);
  static const _bg   = Color(0xFFF1F5F9);

  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // Dropdown data
  List<Map<String, String>> _segments = [];
  List<Map<String, String>> _makes    = [];
  List<Map<String, String>> _allMakes = [];
  bool _showAllMakes = false;

  String? _selectedSegmentId;
  String? _selectedSegmentName;

  String? _selectedMakeId;
  String? _selectedMakeName;

  // Loading states
  bool _loadingSegments = true;
  bool _loadingMakes    = false;
  bool _saving          = false;

  @override
  void initState() {
    super.initState();
    _selectedMakeId = widget.initialMakeId;
    _selectedMakeName = widget.initialMakeName;
    _selectedSegmentId = widget.initialSegmentId;
    _selectedSegmentName = widget.initialSegmentName;
    _loadSegments();
    if (_selectedSegmentId != null) {
      _loadMakesForSegment(_selectedSegmentId!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  String get _apiBaseUrl {
    final base = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/api';
  }

  // ── Load segments (all active vehicle segments for company) ───────────────
  Future<void> _loadSegments() async {
    setState(() => _loadingSegments = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBaseUrl/master/vehicle-types/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = json.decode(res.body);
      if (data['success'] == true) {
        final list = (data['vehicle_types'] as List<dynamic>? ?? [])
            .map<Map<String, String>>((t) => {
                  'id': t['id'].toString(),
                  'name': (t['full_name'] ?? t['name'] ?? '').toString(),
                  'type_name': (t['type_name'] ?? '').toString(),
                })
            .toList();
        setState(() {
          _segments = list;
          // Pre-select or sync name if id exists
          if (_selectedSegmentId != null) {
            final found = _segments.where((s) => s['id'] == _selectedSegmentId).toList();
            if (found.isNotEmpty) {
              _selectedSegmentName = found.first['name'];
            } else {
              _selectedSegmentId = null;
              _selectedSegmentName = null;
            }
          }
        });
      }
    } catch (_) {}
    setState(() => _loadingSegments = false);
  }

  // ── Load makes for selected segment (cascade) ─────────────────────────────
  Future<void> _loadMakesForSegment(String segmentId) async {
    final String? preserveMakeId = _selectedMakeId ?? widget.initialMakeId;
    final String? preserveMakeName = _selectedMakeName ?? widget.initialMakeName;
    setState(() {
      _loadingMakes   = true;
      _makes          = [];
      _allMakes       = [];
      _selectedMakeId = preserveMakeId;
      _selectedMakeName = preserveMakeName;
    });
    try {
      final res = await http.get(
        Uri.parse('$_apiBaseUrl/master/vehicle-makes-by-type/?vehicle_type_id=$segmentId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = json.decode(res.body);
      if (data['success'] == true) {
        final returnedMakes = (data['vehicle_makes'] as List<dynamic>? ?? [])
            .map<Map<String, String>>((m) =>
                {'id': m['id'].toString(), 'name': m['name'].toString()})
            .toList();
        final allReturned = (data['all_makes'] as List<dynamic>? ?? [])
            .map<Map<String, String>>((m) =>
                {'id': m['id'].toString(), 'name': m['name'].toString()})
            .toList();

        setState(() {
          _makes = returnedMakes;
          _allMakes = allReturned.isNotEmpty ? allReturned : returnedMakes;
          if (_selectedMakeId != null) {
            final foundMake = _allMakes.where((m) => m['id'] == _selectedMakeId).toList();
            if (foundMake.isNotEmpty) {
              _selectedMakeName = foundMake.first['name'];
            }
          }
        });
      }
    } catch (_) {}
    setState(() => _loadingMakes = false);
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_selectedSegmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('Please select a vehicle segment')),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'vehicle_type_id': _selectedSegmentId,
      };
      if (_selectedMakeId != null && _selectedMakeId!.isNotEmpty) {
        payload['make_id'] = _selectedMakeId;
      }

      final res = await http.post(
        Uri.parse('$_apiBaseUrl/master/vehicle-brand-models/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );
      final data = json.decode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('Vehicle brand added successfully')),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ));
        Navigator.pop(context, {
          'id': data['id'],
          'name': data['name'],
          'make_id': _selectedMakeId,
          'make_name': data['make_name'] ?? _selectedMakeName ?? '',
          'vehicle_type_model_id': _selectedSegmentId,
          'vehicle_type_name': data['vehicle_type_name'] ?? _selectedSegmentName ?? '',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? context.tr('Failed to save')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _saving = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      setState(() => _saving = false);
    }
  }

  // ── Searchable Modal Sheet ───────────────────────────────────────────────
  void _openSearchableModal<T>({
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T) labelBuilder,
    String Function(T)? subtitleBuilder,
    required void Function(T) onSelected,
    Widget? trailingAction,
    bool showNoneOption = false,
    VoidCallback? onNoneSelected,
  }) {
    final searchNotifier = ValueNotifier<String>('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          top: 16.h,
          left: 20.w,
          right: 20.w,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (trailingAction != null) trailingAction,
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                  splashRadius: 20.r,
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Search Bar
            TextField(
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search, color: _navy),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              onChanged: (v) => searchNotifier.value = v.toLowerCase().trim(),
            ),
            SizedBox(height: 12.h),

            // Optional None button
            if (showNoneOption)
              InkWell(
                onTap: () {
                  if (onNoneSelected != null) onNoneSelected();
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.clear, size: 18.r, color: Colors.grey.shade500),
                      SizedBox(width: 10.w),
                      Text(
                        '-- ${context.tr('None')} --',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Item count indicator
            Text(
              '${items.length} ${context.tr('options available')}',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
            ),
            SizedBox(height: 8.h),

            // List
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: searchNotifier,
                builder: (_, query, __) {
                  final filtered = items.where((item) {
                    final label = labelBuilder(item).toLowerCase();
                    final sub = subtitleBuilder != null
                        ? subtitleBuilder(item).toLowerCase()
                        : '';
                    return label.contains(query) || sub.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40.r, color: Colors.grey.shade300),
                          SizedBox(height: 10.h),
                          Text(
                            context.tr('No results found'),
                            style: GoogleFonts.inter(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final label = labelBuilder(item);
                      final subtitle = subtitleBuilder != null
                          ? subtitleBuilder(item)
                          : null;

                      return ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        title: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: subtitle != null && subtitle.isNotEmpty
                            ? Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp, color: Colors.grey.shade500),
                              )
                            : null,
                        trailing: Icon(Icons.arrow_forward_ios,
                            size: 13.r, color: Colors.grey.shade400),
                        onTap: () {
                          onSelected(item);
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

  // ── Searchable Selector Field Widget ─────────────────────────────────────
  Widget _buildSearchableField({
    required String label,
    required String? valueText,
    required String hintText,
    required VoidCallback? onTap,
    bool required = false,
    bool isLoading = false,
    Widget? rightAction,
  }) {
    final hasVal = valueText != null && valueText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(label, required: required),
            if (rightAction != null) rightAction,
          ],
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasVal ? _navy.withValues(alpha: 0.5) : Colors.grey.shade200,
                width: hasVal ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isLoading
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: _navy),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              context.tr('Loading...'),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade400, fontSize: 14.sp),
                            ),
                          ],
                        )
                      : Text(
                          hasVal ? valueText : hintText,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: hasVal ? const Color(0xFF1E293B) : Colors.grey.shade400,
                            fontWeight: hasVal ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 22.r, color: hasVal ? _navy : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14.sp),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: _navy, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: REdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: REdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569)),
          children: required
              ? [
                  TextSpan(
                    text: '  *',
                    style: GoogleFonts.inter(
                        color: Colors.red, fontWeight: FontWeight.w700),
                  )
                ]
              : [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMakesList = _showAllMakes ? _allMakes : _makes;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Add Vehicle Brand'),
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18.sp),
        ),
      ),
      body: _loadingSegments
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: _navy),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('Loading segments...'),
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade500, fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: REdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card ──────────────────────────────────────────────
                    Container(
                      padding: REdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withValues(alpha: 0.07),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: REdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _navy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.car_repair,
                                    color: _navy, size: 26.r),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('Vehicle Brand / Model'),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17.sp,
                                          color: const Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      context.tr('e.g. City, Corolla, Nexon'),
                                      style: GoogleFonts.inter(
                                          color: Colors.grey.shade500,
                                          fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // ── 1. Searchable Vehicle Segment ────────────────
                          _buildSearchableField(
                            label: context.tr('Vehicle Segment'),
                            required: true,
                            valueText: _selectedSegmentName,
                            hintText: context.tr('Select vehicle segment (Searchable)...'),
                            onTap: () {
                              _openSearchableModal<Map<String, String>>(
                                title: context.tr('Select Vehicle Segment'),
                                searchHint: context.tr('Search segment (e.g. Car, 100 CC, BS-6)...'),
                                items: _segments,
                                labelBuilder: (s) => s['name'] ?? '',
                                onSelected: (s) {
                                  setState(() {
                                    _selectedSegmentId   = s['id'];
                                    _selectedSegmentName = s['name'];
                                    _showAllMakes        = false;
                                  });
                                  if (s['id'] != null) {
                                    _loadMakesForSegment(s['id']!);
                                  }
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20.h),

                          // ── 2. Searchable Make Dropdown (cascade) ────────
                          _buildSearchableField(
                            label: context.tr('Vehicle Make (optional)'),
                            isLoading: _loadingMakes,
                            valueText: _selectedMakeName,
                            hintText: _selectedSegmentId == null
                                ? context.tr('Select a segment first')
                                : activeMakesList.isEmpty
                                    ? context.tr('No makes found — tap to add or browse all')
                                    : context.tr('Select make (e.g. Honda, Toyota)...'),
                            rightAction: Row(
                              children: [
                                if (_allMakes.isNotEmpty && _makes.isNotEmpty && _allMakes.length > _makes.length)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _showAllMakes = !_showAllMakes);
                                    },
                                    child: Padding(
                                      padding: REdgeInsets.only(right: 12),
                                      child: Text(
                                        _showAllMakes
                                            ? context.tr('Segment Makes')
                                            : context.tr('All Makes'),
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF2563EB),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () async {
                                    final newMake = await Navigator.push<Map<String, dynamic>>(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const VehicleMakeCreateScreen()),
                                    );
                                    if (newMake != null && mounted) {
                                      if (_selectedSegmentId != null) {
                                        await _loadMakesForSegment(_selectedSegmentId!);
                                      }
                                      setState(() {
                                        _selectedMakeId   = newMake['id']?.toString();
                                        _selectedMakeName = newMake['name']?.toString();
                                      });
                                    }
                                  },
                                  child: Text(
                                    '+ ${context.tr('Add Make')}',
                                    style: GoogleFonts.inter(
                                      color: _navy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: _selectedSegmentId == null
                                ? null
                                : () {
                                    final listToSearch = activeMakesList.isNotEmpty
                                        ? activeMakesList
                                        : _allMakes;
                                    _openSearchableModal<Map<String, String>>(
                                      title: context.tr('Select Vehicle Make'),
                                      searchHint: context.tr('Search make (e.g. Honda, Toyota)...'),
                                      items: listToSearch,
                                      showNoneOption: true,
                                      onNoneSelected: () {
                                        setState(() {
                                          _selectedMakeId   = null;
                                          _selectedMakeName = null;
                                        });
                                      },
                                      labelBuilder: (m) => m['name'] ?? '',
                                      onSelected: (m) {
                                        setState(() {
                                          _selectedMakeId   = m['id'];
                                          _selectedMakeName = m['name'];
                                        });
                                      },
                                      trailingAction: TextButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final newMake = await Navigator.push<Map<String, dynamic>>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => const VehicleMakeCreateScreen()),
                                          );
                                          if (newMake != null && mounted) {
                                            if (_selectedSegmentId != null) {
                                              await _loadMakesForSegment(_selectedSegmentId!);
                                            }
                                            setState(() {
                                              _selectedMakeId   = newMake['id']?.toString();
                                              _selectedMakeName = newMake['name']?.toString();
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 16, color: _navy),
                                        label: Text(
                                          context.tr('New Make'),
                                          style: GoogleFonts.inter(
                                            color: _navy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          SizedBox(height: 20.h),

                          // ── 3. Brand / Model Name ─────────────────────────
                          _label(context.tr('Model / Brand Name'), required: true),
                          SizedBox(height: 6.h),
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.inter(fontSize: 15.sp),
                            decoration: _inputDeco(
                                context.tr('e.g. City, Corolla, Nexon, Creta')),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? context.tr('Model name is required')
                                    : null,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            context.tr(
                                'The model name is linked to the selected segment and make.'),
                            style: GoogleFonts.inter(
                                color: Colors.grey.shade400, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // ── Save Button ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: _saving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(context.tr('Saving...'),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp)),
                                ],
                              )
                            : Text(
                                context.tr('Save Vehicle Brand'),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
