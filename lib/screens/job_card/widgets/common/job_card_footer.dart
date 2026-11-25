import 'package:car_wash_mobile/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/job_card_controller.dart';

class JobCardFooter extends StatelessWidget {
  final TabController formTabs;
  final JobCardController controller;
  final VoidCallback onContinue;
  final VoidCallback onSaveStageAndExit;

  const JobCardFooter({
    super.key,
    required this.formTabs,
    required this.controller,
    required this.onContinue,
    required this.onSaveStageAndExit,
  });

  @override
  Widget build(BuildContext context) {
    final billingCtrl = controller.billingCtrl;
    final isBusy = controller.isSubmitting || billingCtrl.creatingJobCardInvoice;

    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (formTabs.index > 0)
              formTabs.index >= 4 && formTabs.index <= 8
                  ? IconButton(
                      tooltip: context.tr('Back'),
                      onPressed: () => formTabs.index = formTabs.index - 1,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => formTabs.index = formTabs.index - 1,
                      icon: Icon(Icons.arrow_back, size: 16.sp),
                      label: Text(context.tr('Back')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF000080),
                        side: const BorderSide(color: Color(0xFF000080)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                      ),
                    )
            else
              const SizedBox.shrink(),
            if (formTabs.index >= 4 && formTabs.index <= 10)
              TextButton.icon(
                onPressed: isBusy ? null : onSaveStageAndExit,
                icon: Icon(Icons.save_outlined, size: 16.sp),
                label: Text(
                  context.tr('Save & Exit'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onContinue,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        formTabs.index == 12
                            ? (billingCtrl.jobCardInvoice == null
                                ? Icons.receipt_long_outlined
                                : Icons.done)
                            : formTabs.index >= 4 && formTabs.index <= 10
                                ? Icons.save_outlined
                                : Icons.arrow_forward,
                        size: 16.sp,
                      ),
                label: Text(
                  isBusy
                      ? context.tr('Saving...')
                      : formTabs.index == 12
                          ? billingCtrl.jobCardInvoice == null
                              ? context.tr('Create Invoice')
                              : context.tr('Done')
                          : formTabs.index == 11
                              ? context.tr('Proceed to Billing')
                              : formTabs.index == 10
                                  ? context.tr('Continue to Overview')
                                  : formTabs.index == 9
                                      ? context.tr('Continue to Reminders')
                                      : formTabs.index >= 4 && formTabs.index <= 8
                                          ? context.tr('Save & Continue')
                                          : formTabs.index == 3
                                              ? context.tr('Continue to Services')
                                              : formTabs.index == 2
                                                  ? context.tr('View Summary')
                                                  : context.tr('Continue'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
