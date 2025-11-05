// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:campuslf/main.dart';

void main() {
  testWidgets('Campus Lost Found app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusLostFoundApp());
    
    expect(find.text('Campus'), findsOneWidget);
    expect(find.text('Lost & Found'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });
}
