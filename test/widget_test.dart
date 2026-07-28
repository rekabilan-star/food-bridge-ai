import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mca_app/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen title is present.
    expect(find.text('Smart Food Waste\nManagement System'), findsOneWidget);
    
    // Verify that the login button is present.
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
