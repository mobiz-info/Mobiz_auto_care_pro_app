import 'job_card_workflow_screen.dart';
import 'package:car_wash_mobile/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'bills_screen.dart';
import 'bluetooth_printer_screen.dart';
import 'book_now_screen.dart';
import 'bookings_list_screen.dart';
import 'collection_screen.dart';
import 'new_job_screen.dart';
import 'receipts_screen.dart';
import 'vehicle_search_screen.dart';
import 'edit_customer_screen.dart';
import 'customers_screen.dart';
import 'schemes_screen.dart';
import 'reports_screen.dart';
import 'broadcast_screen.dart';
import 'complaints_screen.dart';
import 'language_screen.dart';
import 'font_size_screen.dart';
import '../config/country_config.dart';
import '../config/app_defaults.dart';
import 'expense_screen.dart';
import 'supplier_screen.dart';
import 'staff_leave_screen.dart';
import 'payslip_screen.dart';
import 'purchase_request_screen.dart';
import 'expense_head_screen.dart';
import 'extras_screen.dart';
import 'booking_settings_screen.dart';
import 'customer_collection_screen.dart';
import '../services/api_service.dart';
import 'stock_management_screen.dart';
import 'stock_item_screen.dart';
import 'supplier_payables_screen.dart';
import 'purchase_invoice_create_screen.dart';
import 'insurance_screen.dart';
import 'vehicle_make_screen.dart';
import 'vehicle_brand_screen.dart';
import 'leads_screen.dart';
import 'quotation_list_screen.dart';




class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // --- state ---

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  // --- navigation ---
  final List<Map<String, dynamic>> _branchMenuItems = [
    {
      'title': 'New Job',
      'icon': Icons.add_circle_outline,
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'Job Card',
      'icon': Icons.assignment_outlined,
      'color': Color(0xFF0284C7),
    },
    {'title': 'Leads', 'icon': Icons.leaderboard_outlined, 'color': Color(0xFF16A34A)},
    {'title': 'Quotations', 'icon': Icons.request_quote_outlined, 'color': Color(0xFF7C3AED)},
    {
      'title': 'Book Now',
      'icon': Icons.calendar_today,
      'color': Color(0xFFF97316),
    },
    {'title': 'Bookings', 'icon': Icons.event_note, 'color': Color(0xFF8B5CF6)},
    {'title': 'Bill', 'icon': Icons.receipt_long, 'color': Color(0xFF22C55E)},
    {
      'title': 'Outstanding',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Collection',
      'icon': Icons.monetization_on_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Receipt',
      'icon': Icons.receipt_outlined,
      'color': Color(0xFF0F766E),
    },
    {
      'title': 'Customers',
      'icon': Icons.people_outline,
      'color': Color(0xFFA855F7),
    },
    {
      'title': 'Schemes',
      'icon': Icons.card_giftcard,
      'color': Color(0xFFEC4899),
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications_outlined,
      'color': Color(0xFF00BFFF),
    },
    {'title': 'Reports', 'icon': Icons.bar_chart, 'color': Color(0xFF14B8A6)},
    {
      'title': 'Vehicle',
      'icon': Icons.directions_car,
      'color': Color(0xFF6366F1),
    },
    {
      'title': 'Expense',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Suppliers',
      'icon': Icons.business_outlined,
      'color': Color(0xFF0F766E),
    },
    {
      'title': 'Supplier Payables',
      'icon': Icons.payments_outlined,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Purchase Entry',
      'icon': Icons.add_shopping_cart_outlined,
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'Staff Leaves',
      'icon': Icons.calendar_month_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Payslips',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF0F766E),
    },
    /*
    {
      'title': 'Purchase Req',
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF6366F1),
    },
    */
 
    {
      'title': 'Complaints',
      'icon': Icons.assignment_late_outlined,
      'color': Color(0xFFF43F5E),
    },
    {
      'title': 'Insurance',
      'icon': Icons.shield_outlined,
      'color': Color(0xFF059669),
    },
    {
      'title': 'Master',
      'icon': Icons.tune_outlined,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'Stock Items',
      'icon': Icons.inventory_outlined,
      'color': Color(0xFF0D9488),
    },
    {
      'title': 'Stock Management',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFF0284C7),
    },
    {
      'title': 'Language',
      'icon': Icons.language,
      'color': Color(0xFF92400E),
    },
    {
      'title': 'Font Size',
      'icon': Icons.format_size,
      'color': Color(0xFF4F46E5),
    },
  ];


  final List<Map<String, dynamic>> _companyMenuItems = [
    {
      'title': 'New Job',
      'icon': Icons.add_circle_outline,
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'Job Card',
      'icon': Icons.assignment_outlined,
      'color': Color(0xFF0284C7),
    },
    {'title': 'Leads', 'icon': Icons.leaderboard_outlined, 'color': Color(0xFF16A34A)},
    {'title': 'Quotations', 'icon': Icons.request_quote_outlined, 'color': Color(0xFF7C3AED)},
    {
      'title': 'Book Now',
      'icon': Icons.calendar_today,
      'color': Color(0xFFF97316),
    },
    {
      'title': 'Schemes',
      'icon': Icons.card_giftcard,
      'color': Color(0xFFEC4899),
    },
    {'title': 'Reports', 'icon': Icons.bar_chart, 'color': Color(0xFF14B8A6)},
    {'title': 'Bookings', 'icon': Icons.event_note, 'color': Color(0xFF8B5CF6)},
    {'title': 'Bill', 'icon': Icons.receipt_long, 'color': Color(0xFF22C55E)},
    {
      'title': 'Outstanding',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Collection',
      'icon': Icons.monetization_on_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Receipt',
      'icon': Icons.receipt_outlined,
      'color': Color(0xFF0F766E),
    },
    {
      'title': 'Customers',
      'icon': Icons.people_outline,
      'color': Color(0xFFA855F7),
    },
    {
      'title': 'Vehicle',
      'icon': Icons.directions_car,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Expense',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Suppliers',
      'icon': Icons.business_outlined,
      'color': Color(0xFF0F766E),
    },
    {
      'title': 'Supplier Payables',
      'icon': Icons.payments_outlined,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Purchase Entry',
      'icon': Icons.add_shopping_cart_outlined,
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'Staff Leaves',
      'icon': Icons.calendar_month_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'title': 'Payslips',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF0F766E),
    },
    /*
    {
      'title': 'Purchase Req',
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF6366F1),
    },
    */
    {
      'title': 'Expense Heads',
      'icon': Icons.label_outline,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Stock Items',
      'icon': Icons.inventory_outlined,
      'color': Color(0xFF0D9488),
    },
    {
      'title': 'Stock Management',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFF0284C7),
    },
    {
      'title': 'Extras',
      'icon': Icons.more_horiz_outlined,
      'color': const Color(0xFFEC4899),
    },
   
    {
      'title': 'Complaints',
      'icon': Icons.assignment_late_outlined,
      'color': Color(0xFFF43F5E),
    },
    {
      'title': 'Insurance',
      'icon': Icons.shield_outlined,
      'color': Color(0xFF059669),
    },
    {
      'title': 'Master',
      'icon': Icons.tune_outlined,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'Booking Settings',
      'icon': Icons.settings_applications,
      'color': Color(0xFF000080),
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications_outlined,
      'color': Color(0xFF00BFFF),
    },
    {
      'title': 'Language',
      'icon': Icons.language,
      'color': Color(0xFF92400E),
    },
    {
      'title': 'Font Size',
      'icon': Icons.format_size,
      'color': Color(0xFF4F46E5),
    },
  ];


  void _navigate(BuildContext context, String title) {
    final routes = <String, Widget>{
      'New Job': NewJobScreen(),
      'Job Card': const JobCardWorkflowScreen(),
      'Leads': const LeadsScreen(),
      'Quotations': const QuotationListScreen(),
      'Book Now': BookNowScreen(),

      'Bookings': const BookingsListScreen(),
      'Bill': BillsScreen(),
      'Outstanding': const CollectionScreen(),
      'Collection': const CustomerCollectionScreen(),
      'Receipt': const ReceiptsScreen(),
      'Vehicle': const VehicleSearchScreen(),
      'Edit Customer': const EditCustomerScreen(),
      'Customers': const CustomersScreen(),
      'Reports': const ReportsScreen(),
      'Schemes': const SchemesScreen(),
      'Notifications': BroadcastScreen(),
      'Complaints': const ComplaintsScreen(),
      'Language': const LanguageScreen(),
      'Font Size': const FontSizeScreen(),
      'Expense': ExpenseScreen(),
      'Suppliers': const SupplierScreen(),
      'Supplier Payables': const SupplierPayablesScreen(),
      'Purchase Entry': const PurchaseInvoiceCreateScreen(),
      'Staff Leaves': const StaffLeaveScreen(),
      'Payslips': const PayslipScreen(),
      'Purchase Req': const PurchaseRequestScreen(),
      'Purchase': const PurchaseRequestScreen(),
      'Expense Heads': const ExpenseHeadScreen(),
      'Stock Management': const StockManagementScreen(initialCategory: 'ALL'),
      'Stock Items': const StockItemScreen(),
      'Oil Stock': const StockManagementScreen(initialCategory: 'OIL'),
      'Extras': const ExtrasScreen(),
      'Booking Settings': const BookingSettingsScreen(),
      'Insurance': const InsuranceScreen(),
      'Vehicle Make': const VehicleMakeScreen(),
      'Vehicle Brand': const VehicleBrandScreen(),
    };

    // Master menu opens bottom sheet with sub-items
    if (title == 'Master') {
      _showMasterBottomSheet(context);
      return;
    }

    final screen = routes[title];
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void _showMasterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Master'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Manage vehicle master data'),
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _masterSheetTile(
                  ctx,
                  icon: Icons.directions_car,
                  color: const Color(0xFF6366F1),
                  title: context.tr('Vehicle Make'),
                  subtitle: context.tr('Manage brands like Honda, Toyota'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VehicleMakeScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _masterSheetTile(
                  ctx,
                  icon: Icons.car_repair,
                  color: const Color(0xFF0EA5E9),
                  title: context.tr('Vehicle Brand / Model'),
                  subtitle: context.tr('Manage models like City, Corolla'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VehicleBrandScreen()));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _masterSheetTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF1e293b))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }


  // ─── helpers ────────────────────────────────────────────────────────────────

  // ─── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = (auth.displayName?.isNotEmpty == true)
        ? auth.displayName!
        : (auth.companyName?.isNotEmpty == true)
        ? auth.companyName!
        : (auth.username ?? 'Admin');
    final isBranch = auth.isBranchAdmin;
    final isCompany = auth.isCompanyAdmin;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9),

      // ── Drawer ──────────────────────────────────────────────────────────
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: REdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF000080), Color(0xFF0000CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      ApiService.appIconPath,
                      width: 56.w,
                      height: 56.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: REdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        context.tr(isBranch ? 'Branch Admin' : 'Company Admin'),
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable menu items ────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: REdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerItem(
                      Icons.dashboard_outlined,
                      'Dashboard',
                      () => Navigator.pop(context),
                    ),
                    _drawerItem(Icons.assignment_outlined, 'Job Card', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JobCardWorkflowScreen()),
                      );
                    }),
                    _drawerItem(Icons.leaderboard_outlined, 'Leads', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsScreen()));
                    }),
                    _drawerItem(Icons.request_quote_outlined, 'Quotations', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotationListScreen()));
                    }),
                    if (!isCompany) ...[
                      _drawerItem(Icons.receipt_long_outlined, 'Bills', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BillsScreen()),
                        );
                      }),
                      _drawerItem(Icons.print_outlined, 'Printer Setup', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()),
                        );
                      }),
                    ],
                    _drawerItem(Icons.calendar_today_outlined, 'Bookings', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingsListScreen(),
                        ),
                      );
                    }),
                    _drawerItem(
                      Icons.account_balance_wallet_outlined,
                      'Outstanding',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CollectionScreen()),
                        );
                      },
                    ),
                    _drawerItem(Icons.receipt_outlined, 'Receipt', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReceiptsScreen()),
                      );
                    }),
                    _drawerItem(Icons.bar_chart_outlined, 'Reports', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    }),
                    _drawerItem(Icons.card_giftcard_outlined, 'Schemes', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SchemesScreen()),
                      );
                    }),
                    _drawerItem(Icons.people_outline, 'Customers', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomersScreen()),
                      );
                    }),
                    _drawerItem(Icons.notifications_outlined, 'Notifications', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BroadcastScreen()),
                      );
                    }),
                    _drawerItem(Icons.account_balance_wallet_outlined, 'Expense', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseScreen()),
                      );
                    }),
                    _drawerItem(Icons.business_outlined, 'Suppliers', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupplierScreen()),
                      );
                    }),
                    _drawerItem(Icons.payments_outlined, 'Supplier Payables', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupplierPayablesScreen()),
                      );
                    }),
                    _drawerItem(Icons.add_shopping_cart_outlined, 'Purchase Entry', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PurchaseInvoiceCreateScreen()),
                      );
                    }),
                    if (isCompany) ...[
                      _drawerItem(Icons.calendar_month_outlined, 'Staff Leaves', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StaffLeaveScreen()),
                        );
                      }),
                      _drawerItem(Icons.payments_outlined, 'Payslips', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PayslipScreen()),
                        );
                      }),
                    ],
                    if (isCompany) ...[
                      _drawerItem(Icons.label_outline, 'Expense Heads', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExpenseHeadScreen()),
                        );
                      }),
                      _drawerItem(Icons.more_horiz_outlined, 'Extras', () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExtrasScreen()),
                        );
                      }),
                    ],
                    _drawerItem(
                      Icons.inventory_outlined,
                      'Stock Items',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StockItemScreen()),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.inventory_2_outlined,
                      'Stock Management',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StockManagementScreen()),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.directions_car_outlined,
                      'Vehicle Search',

                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehicleSearchScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.assignment_late_outlined,
                      'Complaints',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ComplaintsScreen(),
                          ),
                        );
                      },
                    ),
                    if (auth.hasInsuranceModule)
                      _drawerItem(
                        Icons.shield_outlined,
                        'Insurance',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InsuranceScreen(),
                            ),
                          );
                        },
                      ),
                    _masterDrawerSection(context),
                    _drawerItem(
                      Icons.language_outlined,
                      'Language',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LanguageScreen(),
                          ),
                        );
                      },
                    ),
                    _drawerItem(
                      Icons.format_size_outlined,
                      'Font Size',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FontSizeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Fixed bottom: Logout + version ───────────────────────────
              Divider(height: 1.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade600,
                    size: 20.r,
                  ),
                ),
                title: Text(
                  context.tr('Logout'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                    fontSize: 15.sp,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      title: Text(
                        context.tr('Logout'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.sp),
                      ),
                      content: Text(
                        context.tr('Are you sure you want to logout?'),
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14.sp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            context.tr('Cancel'),
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            context.tr('Logout'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                  }
                },
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  context.tr('Car wash ${CountryConfig.current.displayName} V $kAppVersion'),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              ApiService.appIconPath,
              width: 24.w,
              height: 24.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10.w),
            Text(
              ApiService.appName,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Welcome Card ────────────────────────────────────────────
            _buildWelcomeCard(displayName, isBranch),
            SizedBox(height: 20.h),

            // ── Quick Menu ──────────────────────────────────────────────
            buildSectionTitle(context.tr('Quick Menu'), Icons.grid_view_outlined),
            SizedBox(height: 10.h),
            _buildMenuGrid(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ─── Welcome Card ────────────────────────────────────────────────────────

  Widget _buildWelcomeCard(String name, bool isBranch) {
    return Container(
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000080), Color(0xFF0000B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000080).withOpacity(0.25),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('Welcome Back')} 👋',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: REdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    context.tr(isBranch ? 'Branch Admin' : 'Company Admin'),
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: REdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Invoices ────────────────────────────────────────────────────

  // ─── Quick Menu Grid ─────────────────────────────────────────────────────
  Widget _buildMenuGrid() {
    final auth = context.read<AuthProvider>();
    final menuItems = auth.isCompanyAdmin
        ? _companyMenuItems
        : _branchMenuItems;
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.95,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final title = item['title'] as String;
        if (title.isEmpty) {
          return const SizedBox.shrink();
        }
        final isBroadcast = title == 'Notifications';
        final isInsurance = title == 'Insurance';
        final isEnabled = (!isBroadcast || auth.canBroadcast) &&
            (!isInsurance || auth.hasInsuranceModule);
        final color = isEnabled ? (item['color'] as Color) : Colors.grey;
        
        return InkWell(
          onTap: isEnabled ? () => _navigate(context, title) : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: REdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'], color: color, size: 26.r),
                ),
                SizedBox(height: 10.h),
                Text(
                  context.tr(item['title']),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Color(0xFF334155) : Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Section Title ────────────────────────────────────────────────────────

  // ─── Drawer Item ──────────────────────────────────────────────────────────
  Widget _masterDrawerSection(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.tune_outlined, color: Color(0xFF7C3AED), size: 22),
      title: Text(
        context.tr('Master'),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1e293b),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      children: [
        ListTile(
          leading: Icon(Icons.directions_car, color: Color(0xFF6366F1), size: 20),
          title: Text(
            context.tr('Vehicle Make'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleMakeScreen()));
          },
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
        ),
        ListTile(
          leading: Icon(Icons.car_repair, color: Color(0xFF0EA5E9), size: 20),
          title: Text(
            context.tr('Vehicle Brand'),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleBrandScreen()));
          },
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
        ),
      ],
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF000080), size: 22.r),
      title: Text(
        context.tr(label),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          color: Color(0xFF1e293b),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    );
  }
}
