import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class VehicleMakeCreateScreen extends StatefulWidget {
  const VehicleMakeCreateScreen({super.key});

  @override
  State<VehicleMakeCreateScreen> createState() => _VehicleMakeCreateScreenState();
}

class _VehicleMakeCreateScreenState extends State<VehicleMakeCreateScreen> {
  static const _navy = Color(0xFF000080);
  static const _bg   = Color(0xFFF1F5F9);

  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving    = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse('$_apiBaseUrl/master/vehicle-makes/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': _nameCtrl.text.trim()}),
      );
      final data = json.decode(res.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('Vehicle make added successfully')),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ));
        // Return the newly created item to the list screen
        Navigator.pop(context, {'id': data['id'], 'name': data['name']});
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
          context.tr('Add Vehicle Make'),
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card
              Container(
                padding: REdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.07),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon header
                    Row(
                      children: [
                        Container(
                          padding: REdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _navy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.directions_car, color: _navy, size: 26.r),
                        ),
                        SizedBox(width: 14.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Vehicle Make'),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17.sp,
                                  color: const Color(0xFF1e293b)),
                            ),
                            Text(
                              context.tr('e.g. Honda, Toyota, Maruti Suzuki'),
                              style: GoogleFonts.inter(
                                  color: Colors.grey.shade500, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Name field
                    Text(
                      context.tr('Make / Manufacturer Name *'),
                      style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569)),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.inter(fontSize: 15.sp),
                      decoration: InputDecoration(
                        hintText: context.tr('Enter manufacturer name'),
                        hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade400, fontSize: 14.sp),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: Icon(Icons.factory_outlined,
                            color: _navy.withOpacity(0.5), size: 22.r),
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
                        contentPadding:
                            REdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.tr('Name is required')
                          : null,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.tr('This will be shared across all companies globally.'),
                      style: GoogleFonts.inter(
                          color: Colors.grey.shade400, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Save button
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
                                    fontWeight: FontWeight.w700, fontSize: 16.sp)),
                          ],
                        )
                      : Text(
                          context.tr('Save Vehicle Make'),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 16.sp),
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
