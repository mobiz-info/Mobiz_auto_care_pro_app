import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_wash_mobile/widgets/automotive_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  testWidgets('Automotive components render correctly', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestableWidget(
        AutomotiveCardContainer(
          onTap: () => tapped = true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AutomotiveIdBadge(idText: 'JC-1001'),
              const VehiclePlateBadge(plateNumber: 'KL 07 CD 5678'),
              AutomotiveStatusPill(
                status: 'In Progress',
                onTap: () {},
                showDropdownArrow: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('JC-1001'), findsOneWidget);
    expect(find.text('KL 07 CD 5678'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);

    await tester.tap(find.text('JC-1001'));
    expect(tapped, isTrue);
  });
}
