import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belajar_flutter/app.dart';
import 'package:belajar_flutter/screens/poker/setup_screen.dart';
import 'package:belajar_flutter/screens/poker/table_screen.dart';

void main() {
  testWidgets('Poker Chip Simulator smoke test', (WidgetTester tester) async {
    // Set a landscape test screen size
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify Setup Screen is present
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('TEXAS HOLD\'EM CHIP SIMULATOR'), findsOneWidget);
    expect(find.text('MULAI MEJA POKER'), findsOneWidget);

    // Tap Start Game button
    await tester.tap(find.text('MULAI MEJA POKER'));
    await tester.pumpAndSettle();

    // Verify Table Screen is opened
    expect(find.byType(TableScreen), findsOneWidget);
    expect(find.textContaining('Blinds:'), findsOneWidget);
  });
}
