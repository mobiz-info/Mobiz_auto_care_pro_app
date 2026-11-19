import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:car_wash_mobile/widgets/job_card_responsive.dart';

void main() {
  group('JobCardResponsive', () {
    test('uses one column below tablet width', () {
      expect(JobCardResponsive.columnsFor(599), 1);
      expect(JobCardResponsive.isTabletWidth(599), isFalse);
    });

    test('uses two columns from tablet width', () {
      expect(JobCardResponsive.columnsFor(600), 2);
      expect(JobCardResponsive.isTabletWidth(600), isTrue);
    });

    test('caps wide tablet content', () {
      expect(JobCardResponsive.contentMaxWidth, 1100);
    });

    for (final size in const [
      Size(360, 780),
      Size(430, 932),
      Size(768, 1024),
      Size(1024, 768),
    ]) {
      testWidgets('lays out cards at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: JobCardResponsiveList(
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  key: ValueKey('card-$index'),
                  height: 120,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final first = tester.getRect(find.byKey(const ValueKey('card-0')));
        final second = tester.getRect(find.byKey(const ValueKey('card-1')));
        expect(first.width, greaterThan(0));
        expect(second.width, greaterThan(0));
        if (size.width < JobCardResponsive.tabletBreakpoint) {
          expect(second.top, greaterThan(first.top));
        } else {
          expect(second.top, first.top);
          expect(second.left, greaterThan(first.left));
        }
      });
    }
  });
}
