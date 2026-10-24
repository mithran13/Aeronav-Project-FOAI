// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aero_nav/main.dart';
import 'package:aero_nav/services/flight_file_service.dart';

void main() {
  testWidgets('AeroNavApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => FlightFileService()),
    ],
    child: const AeroNavApp(),
  ),
);
    expect(find.byType(AeroNavApp), findsOneWidget);
  });

  testWidgets('AeroNavApp provides FlightFileService', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => FlightFileService()),
    ],
    child: const AeroNavApp(),
  ),
);

    final context = tester.element(find.byType(AeroNavApp));

    expect(
      () => Provider.of<FlightFileService>(context, listen: false),
      returnsNormally,
    );
  });
}
