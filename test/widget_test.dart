import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/core/theme/app_colors.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  testWidgets('App theme and brand identity smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Text('FoodBridge AI'),
          ),
        ),
      ),
    );

    expect(find.text('FoodBridge AI'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('FoodBridge AI'))).colorScheme.primary,
      AppColors.primary,
    );
  });
}
