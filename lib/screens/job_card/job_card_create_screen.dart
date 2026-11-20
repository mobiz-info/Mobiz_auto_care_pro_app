import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/job_card_responsive.dart';
import 'controllers/job_card_controller.dart';
import 'widgets/accessories/accessories_tab_view.dart';
import 'widgets/billing/billing_tab_view.dart';
import 'widgets/common/job_card_footer.dart';
import 'widgets/common/section_card.dart';
import 'widgets/customer/customer_profile_card.dart';
import 'widgets/customer/customer_search_card.dart';
import 'widgets/inspection/inspection_tab_view.dart';
import 'widgets/inspection/inspection_summary_tab_view.dart';
import 'widgets/job_progress/job_progress_tab_view.dart';
import 'widgets/overview/overview_tab_view.dart';
import 'widgets/pricing/pricing_tab_view.dart';
import 'widgets/reported_issues/reported_issue_tile.dart';
import 'widgets/reported_issues/reported_issues_card.dart';
import 'widgets/vehicle/vehicle_profile_card.dart';
import 'widgets/vehicle/vehicle_selector_card.dart';
import 'widgets/vehicle/expected_delivery_date_card.dart';

class JobCardCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCustomer;
  final Map<String, dynamic>? initialVehicle;
  final Map<String, dynamic>? initialLead;
  final String? existingJobCardId;
  final int initialTabIndex;

  const JobCardCreateScreen({
    super.key,
    this.initialCustomer,
    this.initialVehicle,
    this.initialLead,
    this.existingJobCardId,
    this.initialTabIndex = 0,
  });

  @override
  State<JobCardCreateScreen> createState() => _JobCardCreateScreenState();
}

class _JobCardCreateScreenState extends State<JobCardCreateScreen>
    with SingleTickerProviderStateMixin {
  late final JobCardController _controller;
  late final TabController _formTabs;

  @override
  void initState() {
    super.initState();
    _controller = JobCardController(
      initialCustomer: widget.initialCustomer,
      initialVehicle: widget.initialVehicle,
      initialLead: widget.initialLead,
      existingJobCardId: widget.existingJobCardId,
      initialTabIndex: widget.initialTabIndex,
    );

    _formTabs = TabController(
      length: 10,
      initialIndex: widget.initialTabIndex.clamp(0, 9),
      vsync: this,
    );

    _formTabs.addListener(() {
      if (mounted) setState(() {});
      if (_formTabs.index == 9) {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          _controller.billingCtrl.loadJobCardInvoice(
            _controller.savedJobCardId ?? widget.existingJobCardId,
            token,
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      _controller.initialize(token);
    });
  }

  @override
  void dispose() {
    _formTabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveStageAndExit() async {
    if (_formTabs.index < 4 || _formTabs.index > 7) return;
    if (!_controller.validateStageDraft(_formTabs.index, onMessage: (msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(msg))),
      );
    })) {
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final res = await _controller.submitJobCard(
      token: token,
      statusOverride: _formTabs.index >= 6 ? 'in_progress' : null,
      onMessage: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(msg))),
        );
      },
    );
    if (res['success'] == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _createJobCardInvoice() async {
    final billingCtrl = _controller.billingCtrl;
    if (billingCtrl.jobCardInvoice != null || billingCtrl.creatingJobCardInvoice) {
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final billingTotal = _controller.pricingCtrl.calculateBillingTotal(_controller.issuesCtrl.reportedIssues);
    final result = await billingCtrl.createJobCardInvoice(
      jobCardId: _controller.savedJobCardId ?? widget.existingJobCardId,
      token: token,
      billingTotal: billingTotal,
      submitJobCard: () async {
        final res = await _controller.submitJobCard(
          token: token,
          keepOpen: true,
          onMessage: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr(msg))),
            );
          },
        );
        return res['success'] == true;
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Invoice ${result['invoice']?['invoice_number'] ?? ''} created'
              : result['message']?.toString() ?? 'Could not create invoice',
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _continueJobCard() async {
    if (_formTabs.index == 0) {
      if (!_controller.snapshotMode &&
          _controller.customerCtrl.selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Please select a customer'))),
        );
        return;
      }
      if (_controller.snapshotMode) {
        if (_controller.customerCtrl.profileName.text.trim().isEmpty ||
            _controller.customerCtrl.profilePhone.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('Complete required customer details')),
            ),
          );
          return;
        }
      }
      _formTabs.animateTo(1);
      return;
    }
    if (_formTabs.index == 1) {
      if (!_controller.snapshotMode &&
          _controller.vehicleCtrl.selectedVehicle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Please select a vehicle'))),
        );
        return;
      }
      if (_controller.snapshotMode &&
          _controller.vehicleCtrl.vehicleNumber.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Complete required vehicle details')),
          ),
        );
        return;
      }
      _formTabs.animateTo(2);
      return;
    }
    if (_formTabs.index == 2) {
      _formTabs.index = 3;
      return;
    }
    // Tab 3: Inspection Summary -> Services & Issues (Tab 4)
    if (_formTabs.index == 3) {
      _formTabs.index = 4;
      return;
    }
    // Tab 4: Services & Issues -> Accessories (Tab 5)
    if (_formTabs.index == 4) {
      if (!_controller.validateStageDraft(4, onMessage: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(msg))),
        );
      })) {
        return;
      }
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final res = await _controller.submitJobCard(
        token: token,
        keepOpen: true,
        onMessage: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(msg))),
          );
        },
      );
      if (res['success'] == true && mounted) {
        _formTabs.index = 5;
      }
      return;
    }
    // Tab 5: Accessories -> Job Progress (Tab 6)
    if (_formTabs.index == 5) {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final res = await _controller.submitJobCard(
        token: token,
        keepOpen: true,
        onMessage: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(msg))),
          );
        },
      );
      if (res['success'] == true && mounted) {
        _formTabs.index = 6;
      }
      return;
    }
    // Tab 6: Job Progress -> Pricing (Tab 7)
    if (_formTabs.index == 6) {
      if (!_controller.validateStageDraft(6, onMessage: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(msg))),
        );
      })) {
        return;
      }
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final res = await _controller.submitJobCard(
        token: token,
        keepOpen: true,
        statusOverride: 'in_progress',
        onMessage: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(msg))),
          );
        },
      );
      if (res['success'] == true && mounted) {
        _formTabs.index = 7;
      }
      return;
    }
    // Tab 7: Pricing -> Overview (Tab 8)
    if (_formTabs.index == 7) {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final res = await _controller.submitJobCard(
        token: token,
        keepOpen: true,
        onMessage: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr(msg))),
          );
        },
      );
      if (res['success'] == true && mounted) {
        _formTabs.index = 8;
      }
      return;
    }
    // Tab 8: Overview -> Billing (Tab 9)
    if (_formTabs.index == 8) {
      _formTabs.index = 9;
      return;
    }
    if (_controller.billingCtrl.jobCardInvoice != null) {
      Navigator.pop(context, true);
      return;
    }
    _createJobCardInvoice();
  }

  Widget _tabScroll(List<Widget> children) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return ChangeNotifierProvider<JobCardController>.value(
      value: _controller,
      child: Theme(
        data: baseTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            labelStyle: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
            hintStyle: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade500,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ),
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF000080)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFD14343)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFD14343)),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              context.tr(
                widget.existingJobCardId != null
                    ? 'Edit Job Card'
                    : 'Create Job Card',
              ),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                color: Colors.white,
              ),
            ),
            bottom: TabBar(
              controller: _formTabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.white24,
              labelPadding: EdgeInsets.symmetric(horizontal: 18.w),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(text: context.tr('Customer Details')),
                Tab(text: context.tr('Vehicle Details')),
                Tab(text: context.tr('Inspection')),
                Tab(text: context.tr('Inspection Summary')),
                Tab(text: context.tr('Services & Complaints')),
                Tab(text: context.tr('Accessories')),
                Tab(text: context.tr('Job Progress')),
                Tab(text: context.tr('Pricing')),
                Tab(text: context.tr('Overview')),
                Tab(text: context.tr('Billing (Invoice)')),
              ],
            ),
          ),
          body: JobCardContent(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _formTabs,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _tabScroll([
                        _controller.snapshotMode
                            ? CustomerProfileCard(controller: _controller.customerCtrl)
                            : CustomerSearchCard(controller: _controller.customerCtrl),
                      ]),
                      _tabScroll([
                        _controller.snapshotMode
                            ? VehicleProfileCard(controller: _controller.vehicleCtrl)
                            : VehicleSelectorCard(customerCtrl: _controller.customerCtrl, vehicleCtrl: _controller.vehicleCtrl),
                      ]),
                      InspectionTabView(
                        controller: _controller.inspectionCtrl,
                        onAddService: (serviceData) {
                          final serviceName = serviceData['name']?.toString() ?? 'Service';
                          _controller.issuesCtrl.reportedIssues.add({
                            'client_key': 'inspect-${DateTime.now().microsecondsSinceEpoch}',
                            '_pricingKey': Object(),
                            '_activityKey': Object(),
                            'category': serviceData['category'],
                            'service': serviceData['service'],
                            'issue': {
                              'id': '',
                              'name': serviceName,
                            },
                            'issue_text': serviceName,
                            'rate': (serviceData['rate'] ?? '').toString(),
                            'quantity': '1',
                            'discount': '',
                            'warranty': '',
                            'remarks': '',
                            'activities': <Map<String, dynamic>>[],
                            'photos': <XFile>[],
                            'existing_photos': <Map<String, dynamic>>[],
                          });
                          _controller.pricingCtrl.notify();
                          _controller.issuesCtrl.notify();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr("Added '$serviceName' to Services & Complaints"),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      InspectionSummaryTabView(
                        controller: _controller.inspectionCtrl,
                      ),
                      _tabScroll([
                        ReportedIssuesCard(rootController: _controller),
                        SizedBox(height: 14.h),
                        SectionCard(
                          title: context.tr('Demanded Services'),
                          fields: [
                            AnimatedBuilder(
                              animation: _controller.issuesCtrl,
                              builder: (context, _) {
                                if (_controller.issuesCtrl.reportedIssues.isEmpty) {
                                  return Text(
                                    context.tr('Added services will appear here.'),
                                  );
                                }
                                return Column(
                                  children: List.generate(
                                    _controller.issuesCtrl.reportedIssues.length,
                                    (index) => ReportedIssueTile(
                                      controller: _controller.issuesCtrl,
                                      index: index,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        ExpectedDeliveryDateCard(controller: _controller),
                      ]),
                      AccessoriesTabView(controller: _controller.pricingCtrl),
                      JobProgressTabView(controller: _controller),
                      PricingTabView(controller: _controller),
                      OverviewTabView(controller: _controller),
                      BillingTabView(controller: _controller),
                    ],
                  ),
                ),
                JobCardFooter(
                  formTabs: _formTabs,
                  controller: _controller,
                  onContinue: _continueJobCard,
                  onSaveStageAndExit: _saveStageAndExit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
