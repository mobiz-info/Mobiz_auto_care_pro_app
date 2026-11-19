import 'package:car_wash_mobile/providers/auth_provider.dart';
import 'package:car_wash_mobile/providers/language_provider.dart';
import 'package:car_wash_mobile/screens/job_quotation_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets(
    'quotation form renders engine and chassis fields and vehicle damage inspection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) =>
                const MaterialApp(home: JobQuotationFormScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Vehicle Details tab
      final vehicleTab = find.text('Vehicle Details');
      expect(vehicleTab, findsOneWidget);
      await tester.tap(vehicleTab);
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Number *'), findsOneWidget);
      expect(find.text('Engine Number'), findsOneWidget);
      expect(find.text('Chassis Number'), findsOneWidget);

      // Tap Inspection tab
      final inspectionTab = find.text('Inspection');
      expect(inspectionTab, findsOneWidget);
      await tester.ensureVisible(inspectionTab);
      await tester.tap(inspectionTab);
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Damage Inspection'), findsOneWidget);
      expect(find.text('Front'), findsWidgets);
      expect(find.text('Rear'), findsWidgets);
      expect(find.text('Left'), findsWidgets);
      expect(find.text('Right'), findsWidgets);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Controls'), findsWidgets);
      expect(find.text('Front Seats'), findsWidgets);
      expect(find.text('Passenger Side'), findsWidgets);
      expect(find.text('Rear Cabin'), findsWidgets);
      expect(find.text('Floor and Console'), findsWidgets);
      expect(find.textContaining('Drag to draw'), findsWidgets);

      // Scroll down to see category chips
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Tyre'), findsWidgets);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quotation form renders pricing tab matching job order pricing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(home: JobQuotationFormScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Accessories tab exists in TabBar and can be opened
    final accessoriesTab = find.text('Accessories');
    expect(accessoriesTab, findsOneWidget);
    await tester.ensureVisible(accessoriesTab);
    await tester.tap(accessoriesTab);
    await tester.pumpAndSettle();
    expect(find.text('Accessories & Parts'), findsOneWidget);
    expect(find.text('Select accessory'), findsOneWidget);
    expect(find.text('Search stock accessories'), findsOneWidget);
    expect(find.text('No accessories added yet.'), findsOneWidget);

    // Verify Pricing tab exists in TabBar
    final pricingTab = find.text('Pricing');
    expect(pricingTab, findsOneWidget);

    // Tap Pricing tab
    await tester.ensureVisible(pricingTab);
    await tester.tap(pricingTab);
    await tester.pumpAndSettle();

    // Verify top section on Pricing tab
    expect(find.text('Services & Repairs Pricing'), findsOneWidget);

    // Verify footer shows Save Draft on Pricing tab
    expect(find.text('Save Draft'), findsOneWidget);

    final pricingList = find.byKey(const ValueKey('quotation_pricing_list'));
    expect(pricingList, findsOneWidget);

    // Scroll down to see Labour Charge
    await tester.drag(pricingList, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Labour Charge'), findsOneWidget);
    expect(find.text('Labour Description *'), findsOneWidget);

    // Scroll down to see Extras
    await tester.drag(pricingList, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Extras'), findsOneWidget);
    expect(find.text('Extra Description *'), findsOneWidget);

    // Scroll down further to see Schedule & Sign-off and Grand Total
    await tester.drag(pricingList, const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Schedule & Sign-off'), findsOneWidget);
    await tester.drag(pricingList, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.textContaining('Grand Total:'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'quotation form pre-populates lead services into reported issues tab',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final leadWithServices = {
        'id': 'lead-123',
        'customer_name': 'Test Lead Customer',
        'phone_number': '9876543210',
        'vehicle_number': 'KL-07-CD-1234',
        'service_interests': [
          {
            'id': 'int-1',
            'service_id': 'svc-1',
            'category_name': 'Ac Service',
            'service_name': 'Compressor Work',
            'expected_value': 1500.0,
          },
          {
            'id': 'int-2',
            'service_id': 'svc-2',
            'category_name': 'Washing and Cleaning',
            'service_name': 'Full Body Wash',
            'expected_value': 800.0,
          },
        ],
      };

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: JobQuotationFormScreen(lead: leadWithServices),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Services & Issues tab
      final issuesTab = find.text('Services & Issues');
      expect(issuesTab, findsOneWidget);
      await tester.ensureVisible(issuesTab);
      await tester.tap(issuesTab);
      await tester.pumpAndSettle();

      // Verify reported issues from lead services appear
      expect(find.text('Services & Issues'), findsWidgets);
      expect(find.textContaining('Compressor Work'), findsWidgets);
      expect(find.textContaining('Full Body Wash'), findsWidgets);

      // Tap Pricing tab
      final pricingTab = find.text('Pricing');
      expect(pricingTab, findsOneWidget);
      await tester.ensureVisible(pricingTab);
      await tester.tap(pricingTab);
      await tester.pumpAndSettle();

      // Verify Services & Repairs Pricing contains both services
      expect(find.text('Services & Repairs Pricing'), findsOneWidget);
      expect(find.textContaining('Compressor Work'), findsWidgets);
      expect(find.textContaining('Full Body Wash'), findsWidgets);

      expect(tester.takeException(), isNull);
    },
  );
}
