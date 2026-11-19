import 'package:car_wash_mobile/main.dart';
import 'package:car_wash_mobile/providers/auth_provider.dart';
import 'package:car_wash_mobile/providers/broadcast_provider.dart';
import 'package:car_wash_mobile/providers/dashboard_provider.dart';
import 'package:car_wash_mobile/providers/font_size_provider.dart';
import 'package:car_wash_mobile/providers/invoice_provider.dart';
import 'package:car_wash_mobile/providers/job_card_provider.dart';
import 'package:car_wash_mobile/providers/language_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => FontSizeProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => InvoiceProvider()),
          ChangeNotifierProvider(create: (_) => BroadcastProvider()),
          ChangeNotifierProvider(create: (_) => JobCardProvider()),
        ],
        child: const CarWashApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarWashApp), findsOneWidget);
  });
}
