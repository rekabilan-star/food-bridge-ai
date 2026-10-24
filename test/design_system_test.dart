import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mca_app/core/theme/app_colors.dart';
import 'package:mca_app/core/theme/app_radius.dart';
import 'package:mca_app/core/theme/app_spacing.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/core/theme/app_icons.dart';
import 'package:mca_app/presentation/views/common/widgets/primary_button.dart';
import 'package:mca_app/presentation/views/common/widgets/secondary_button.dart';
import 'package:mca_app/presentation/views/common/widgets/standard_card.dart';
import 'package:mca_app/presentation/views/common/widgets/status_badge.dart';
import 'package:mca_app/presentation/views/common/widgets/section_heading.dart';
import 'package:mca_app/presentation/views/common/widgets/empty_state.dart';
import 'package:mca_app/presentation/views/common/widgets/app_loading_indicator.dart';
import 'package:mca_app/presentation/views/common/widgets/app_page_padding.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('Design System Tokens', () {
    test('AppColors tokens are correctly configured', () {
      expect(AppColors.primary, const Color(0xFF5B21B6));
      expect(AppColors.backgroundLight, const Color(0xFFF8F7FC));
      expect(AppColors.surfaceLight, const Color(0xFFFFFFFF));
      expect(AppColors.textPrimary, const Color(0xFF1E152A));
      expect(AppColors.textSecondary, const Color(0xFF6E657E));
      expect(AppColors.border, const Color(0xFFE5E0F0));
      expect(AppColors.success, const Color(0xFF15803D));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.error, const Color(0xFFDC2626));
      expect(AppColors.info, const Color(0xFF2563EB));
    });

    test('AppSpacing scale strictly follows 8, 12, 16, 20, 24, 32 scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.base, 16.0);
      expect(AppSpacing.lg, 20.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
    });

    test('AppRadius tokens are centered around 12, 16, and 20', () {
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 20.0);
      expect(AppRadius.full, 999.0);
    });

    testWidgets('AppTheme connects tokens to Material 3 light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundLight);
      expect(theme.colorScheme.surface, AppColors.surfaceLight);
      expect(theme.appBarTheme.elevation, 0);
    });
  });

  group('Shared Components Widgets', () {
    testWidgets('PrimaryButton renders and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrimaryButton(
              text: 'Save Donation',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Donation'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton shows loading state and disables tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrimaryButton(
              text: 'Save Donation',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('SecondaryButton renders and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SecondaryButton(
              text: 'Cancel',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.byType(SecondaryButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('StandardCard renders content and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StandardCard(
              onTap: () => tapped = true,
              child: const Text('Card Body'),
            ),
          ),
        ),
      );

      expect(find.text('Card Body'), findsOneWidget);
      await tester.tap(find.text('Card Body'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge formats and displays status label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'waiting'),
                StatusBadge(status: 'completed'),
                StatusBadge(label: 'Custom Badge', color: AppColors.primary),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Waiting for NGO acceptance'), findsOneWidget);
      expect(find.text('Donation Completed'), findsOneWidget);
      expect(find.text('Custom Badge'), findsOneWidget);
    });

    testWidgets('SectionHeading renders title, subtitle and action', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SectionHeading(
              title: 'Active Rescues',
              subtitle: 'Track your deliveries',
              actionText: 'See All',
              onActionTap: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Active Rescues'), findsOneWidget);
      expect(find.text('Track your deliveries'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      await tester.tap(find.text('See All'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('EmptyState renders icon, title, message, and action', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmptyState(
              icon: AppIcons.empty,
              title: 'No Donations Available',
              message: 'Check back soon for new food donations in your area.',
              actionText: 'Refresh Feed',
              onActionPressed: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No Donations Available'), findsOneWidget);
      expect(find.text('Check back soon for new food donations in your area.'), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);

      await tester.tap(find.text('Refresh Feed'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('AppLoadingIndicator renders spinner and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppLoadingIndicator(
              message: 'Loading requests...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading requests...'), findsOneWidget);
    });

    testWidgets('AppPagePadding applies standard padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppPagePadding(
              child: Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Content'), findsOneWidget);
      final paddingWidget = tester.widget<Padding>(find.byType(Padding).first);
      expect(paddingWidget.padding, AppSpacing.pagePadding);
    });

    testWidgets('AppIconContainer renders icon with background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppIconContainer(
              icon: AppIcons.food,
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.food), findsOneWidget);
    });
  });
}
