import 'package:car_wash_mobile/providers/auth_provider.dart';
import 'package:car_wash_mobile/providers/language_provider.dart';
import 'package:car_wash_mobile/screens/job_card_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('new job card form renders its app bar and customer fields', (
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
          builder: (_, _) => const MaterialApp(home: JobCardCreateScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Job Card'), findsWidgets);
    expect(find.text('1. Customer Information'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    final inspectionTab = find.text('Inspection');
    await tester.ensureVisible(inspectionTab);
    await tester.tap(inspectionTab);
    await tester.pumpAndSettle();
    expect(find.text('Tyre'), findsWidgets);
    expect(find.text('Wheel Alignment'), findsOneWidget);
    expect(find.text('Wheel Balancing'), findsOneWidget);
    expect(find.text('Nitrogen Filling'), findsOneWidget);
    expect(find.text('Tyre Repair'), findsOneWidget);
    expect(find.text('Wheel Repair'), findsOneWidget);
    expect(find.text('Tyre Rotation'), findsOneWidget);

    final accessoriesTab = find.text('Accessories');
    await tester.ensureVisible(accessoriesTab);
    await tester.tap(accessoriesTab);
    await tester.pumpAndSettle();
    expect(find.text('Select accessory'), findsOneWidget);
    expect(find.text('Search stock accessories'), findsOneWidget);
    expect(find.text('No accessories added.'), findsOneWidget);

    await tester.ensureVisible(find.text('Pricing'));
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(find.text('Accessories'), findsWidgets);
    expect(find.text('Labour Charge'), findsOneWidget);
    expect(find.text('Extras'), findsOneWidget);
    expect(find.text('Add labour'), findsOneWidget);
    expect(find.text('Add extra'), findsOneWidget);

    final overviewTab = find.text('Overview');
    await tester.ensureVisible(overviewTab);
    await tester.tap(overviewTab);
    await tester.pumpAndSettle();
    expect(find.text('Create Job Card'), findsWidgets);
    expect(find.text('Inspection Details'), findsOneWidget);
    expect(find.text('Cost Overview'), findsOneWidget);
    expect(find.textContaining('Services & Repairs'), findsOneWidget);
    expect(find.text('Schedule & Sign-off'), findsOneWidget);
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('No Damages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lead conversion form renders the prefilled profile', (
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
          builder: (_, _) => MaterialApp(
            home: JobCardCreateScreen(
              initialLead: {
                'id': 54,
                'customer_name': 'Test Customer',
                'phone_number': '9876543210',
                'vehicle_number': 'KL01AB1234',
                'expected_value': 65000,
                'service_interests': [
                  {
                    'service_id': 1,
                    'service_name': 'Test Service',
                    'expected_value': 65000,
                  },
                ],
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Details'), findsWidgets);
    expect(find.text('Test Customer'), findsOneWidget);

    final vehicleTab = find.text('Vehicle Details').first;
    await tester.ensureVisible(vehicleTab);
    await tester.tap(vehicleTab);
    await tester.pumpAndSettle();
    expect(find.text('Engine Number'), findsOneWidget);
    expect(find.text('Chassis Number'), findsOneWidget);

    // Pricing follows Issues and Job Progress in the revised workflow.
    final tab = find.text('Pricing');
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();

    expect(find.textContaining('65000'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
