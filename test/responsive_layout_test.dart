import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/donation_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/emergency_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/notification_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/admin_viewmodel.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';
import 'package:mca_app/presentation/views/donor/donor_dashboard_screen.dart';
import 'package:mca_app/presentation/views/ngo/ngo_dashboard_screen.dart';
import 'package:mca_app/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:mca_app/presentation/views/admin/analytics_dashboard_screen.dart';
import 'package:mca_app/presentation/views/common/widgets/stat_card.dart';
import 'package:mca_app/presentation/views/common/widgets/floating_bottom_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createApp(Widget screen, {double textScale = 1.0, Size size = const Size(360, 780)}) {
    final authVM = AuthViewModel();
    final donVM = DonationViewModel();
    final emVM = EmergencyViewModel();
    final notVM = NotificationViewModel()..enableMockMode();
    final chatVM = ChatViewModel()..enableMockMode();
    final admVM = AdminViewModel()..enableMockMode();
    final locProv = LocationProviderV2();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authVM),
        ChangeNotifierProvider.value(value: donVM),
        ChangeNotifierProvider.value(value: emVM),
        ChangeNotifierProvider.value(value: notVM),
        ChangeNotifierProvider.value(value: chatVM),
        ChangeNotifierProvider.value(value: admVM),
        ChangeNotifierProvider.value(value: locProv),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        routes: {
          '/notifications': (_) => const Scaffold(body: Text('Notifications')),
          '/chats': (_) => const Scaffold(body: Text('Chats')),
          '/login': (_) => const Scaffold(body: Text('Login')),
        },
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
  }

  group('Poco M2 and Narrow Screen Layout Responsiveness Tests', () {
    testWidgets('DonorDashboardScreen and FloatingBottomNav render without overflow on Poco M2 (360x780)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createApp(const DonorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FloatingBottomNav), findsOneWidget);
      expect(find.text('Donations'), findsAtLeastNWidgets(1));
    });

    testWidgets('NgoDashboardScreen app bar renders without overflow on Poco M2 (360x780)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createApp(const NgoDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rescue Control'), findsOneWidget);
    });

    testWidgets('AdminDashboardScreen and StatCards render without overflow on Poco M2 with 1.15x text scale', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createApp(const AdminDashboardScreen(), textScale: 1.15));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Operations Center'), findsOneWidget);
      expect(find.byType(StatCard), findsWidgets);
    });

    testWidgets('AnalyticsDashboardScreen renders cleanly at narrow 340dp width with 1.2x text scale', (tester) async {
      tester.view.physicalSize = const Size(680, 1440);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createApp(
        const AnalyticsDashboardScreen(),
        size: const Size(340, 720),
        textScale: 1.2,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('System Analytics & Metrics'), findsOneWidget);
    });

    testWidgets('FloatingBottomNav renders without overflow on ultra narrow 320dp width', (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNav(
              currentIndex: 0,
              onTap: (_) {},
              onAddTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Donations'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('StatCard with long label and trendText renders within tight 100x120 container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 120,
                child: StatCard(
                  value: '1,250',
                  label: 'Very Long StatCard Label That Truncates',
                  icon: Icons.eco_rounded,
                  trendText: 'Action Needed',
                  isPositiveTrend: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1,250'), findsOneWidget);
      expect(find.text('Action Needed'), findsOneWidget);
    });
  });
}
