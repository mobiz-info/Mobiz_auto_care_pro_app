import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../services/job_card_service.dart';

Future<Map<String, dynamic>?> showAccessoryPickerDialog({
  required BuildContext context,
  required String token,
}) {
  final currencySymbol = context.read<AuthProvider>().currencySymbol.trim();
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
    ),
    builder: (sheetContext) {
      var query = '';
      List<Map<String, dynamic>> results = [];
      bool searching = false;
      int request = 0;

      return StatefulBuilder(
        builder: (ctx, refresh) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              14.h,
              16.w,
              MediaQuery.viewInsetsOf(ctx).bottom + 16.h,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * .62,
              child: Column(
                children: [
                  Text(
                    ctx.tr('Select accessory'),
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: ctx.tr('Search accessories'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) async {
                      final id = ++request;
                      query = value.trim();
                      if (query.length < 2) {
                        refresh(() {
                          results = [];
                        });
                        return;
                      }
                      refresh(() => searching = true);
                      try {
                        final response = await JobCardService.searchJobCardAccessories(
                          query,
                          token,
                        );
                        if (id != request || !ctx.mounted) return;
                        refresh(() {
                          results = (response['results'] as List? ?? [])
                              .map((item) => Map<String, dynamic>.from(item as Map))
                              .toList();
                          searching = false;
                        });
                      } catch (_) {
                        if (id == request && ctx.mounted) {
                          refresh(() => searching = false);
                        }
                      }
                    },
                  ),
                  SizedBox(height: 8.h),
                  if (searching) const LinearProgressIndicator(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, index) {
                        final item = results[index];
                        return ListTile(
                          title: Text(
                            item['product_name']?.toString() ?? '',
                          ),
                          subtitle: Text(
                            '${item['part_number'] ?? ''} · ${item['current_stock'] ?? 0} ${item['unit'] ?? ''}',
                          ),
                          trailing: Text('$currencySymbol ${item['rate'] ?? 0}'),
                          onTap: () => Navigator.pop(sheetContext, item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
