import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lf_app/app.dart';

void main() {
  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify landing page shows app title and action buttons.
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.byIcon(Icons.app_registration), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('Continue as Guest navigates to MainScaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap Continue as Guest via its icon.
    await tester.tap(find.byIcon(Icons.explore));
    await tester.pumpAndSettle();

    // Verify we reached main scaffold showing Home title in AppBar.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('Home')), findsOneWidget);

    // Bottom navigation (on narrow screens) should contain the destinations.
    expect(find.byIcon(Icons.home), findsWidgets);
    expect(find.byIcon(Icons.note_add), findsWidgets);
    expect(find.byIcon(Icons.folder_open), findsWidgets);
    expect(find.byIcon(Icons.search), findsWidgets);
    expect(find.byIcon(Icons.account_circle), findsWidgets);
  });
}
