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

class VehicleMakeScreen extends StatefulWidget {
  const VehicleMakeScreen({super.key});

  @override
  State<VehicleMakeScreen> createState() => _VehicleMakeScreenState();
}

class _VehicleMakeScreenState extends State<VehicleMakeScreen> {
  static const _navy = Color(0xFF000080);
  static const _bg   = Color(0xFFF1F5F9);

  final _isLoading   = ValueNotifier<bool>(true);
  final _items       = ValueNotifier<List<dynamic>>([]);
  final _filtered    = ValueNotifier<List<dynamic>>([]);
  final _searchCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _isLoading.dispose();
    _items.dispose();
    _filtered.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  String get _apiBaseUrl {
    final base = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/api';
  }

  Future<void> _fetch() async {
    _isLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('$_apiBaseUrl/master/vehicle-makes/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      final data = json.decode(res.body);
      if (data['success'] == true) {
        final list = List<dynamic>.from(data['vehicle_makes'] ?? []);
        _items.value   = list;
        _filtered.value = List.from(list);
      }
    } catch (_) {}
    _isLoading.value = false;
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    _filtered.value = q.isEmpty
        ? List.from(_items.value)
        : _items.value
            .where((m) => m['name'].toString().toLowerCase().contains(q))
            .toList();
  }

  Future<void> _addNew() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleMakeCreateScreen()),
    );
    if (result != null) {
      _fetch();
    }
  }
  Future<void> _delete(Map<String, dynamic> item) async {
    if (item['is_superadmin'] == true || item['can_delete'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('Superadmin items cannot be deleted')),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: REdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: REdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.red.shade500, size: 28.r),
              ),
              SizedBox(height: 16.h),
              Text(
                context.tr('Delete Make?'),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 17.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                '"${item['name']}"',
                style: GoogleFonts.inter(
                    color: Colors.grey.shade600, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: REdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(context.tr('Cancel'),
                          style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: REdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(context.tr('Delete'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse('$_apiBaseUrl/master/vehicle-makes/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': item['id']}),
      );
      final data = json.decode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _items.value =
            _items.value.where((m) => m['id'] != item['id']).toList();
        _filter();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('Deleted successfully')),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          context.tr('Vehicle Make'),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetch,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNew,
        backgroundColor: _navy,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('Add Make'),
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Header info bar
          Container(
            color: _navy,
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              padding: REdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.inter(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: context.tr('Search vehicle makes...'),
                  hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade400, fontSize: 14.sp),
                  prefixIcon: Icon(Icons.search,
                      color: _navy.withOpacity(0.6), size: 22.r),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (_, v, __) => v.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey.shade400, size: 20.r),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      REdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, loading, __) {
                if (loading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: _navy),
                        SizedBox(height: 16.h),
                        Text(context.tr('Loading...'),
                            style: GoogleFonts.inter(
                                color: Colors.grey.shade400, fontSize: 14.sp)),
                      ],
                    ),
                  );
                }
                return ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _filtered,
                  builder: (_, list, __) {
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: REdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _navy.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.directions_car_outlined,
                                  size: 48.r,
                                  color: _navy.withOpacity(0.35)),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              context.tr('No vehicle makes found'),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              context.tr('Tap + button to add a new make'),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 13.sp),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: REdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final item = list[i] as Map<String, dynamic>;
                        return Container(
                          margin: REdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.06),
                                blurRadius: 8.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: REdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 44.r,
                              height: 44.r,
                              decoration: BoxDecoration(
                                color: _navy.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(Icons.directions_car,
                                  color: _navy, size: 22.r),
                            ),
                            title: Text(
                              item['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                                color: const Color(0xFF1e293b),
                              ),
                            ),
                            subtitle: Text(
                              context.tr('Vehicle Manufacturer'),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 12.sp),
                            ),
                            trailing: (item['is_superadmin'] == true || item['can_delete'] == false)
                                ? null
                                : IconButton(
                                    icon: Container(
                                      padding: REdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(Icons.delete_outline,
                                          color: Colors.red.shade400, size: 20.r),
                                    ),
                                    onPressed: () => _delete(item),
                                  ),
                          ),
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
    );
  }
}
