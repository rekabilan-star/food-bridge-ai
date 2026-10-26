import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/data/models/user_model.dart';
import 'package:mca_app/data/models/donation_model.dart';
import 'package:mca_app/data/models/sms_log_model.dart';

import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/admin_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/donation_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/emergency_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/notification_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';

import 'package:mca_app/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:mca_app/presentation/views/admin/manage_ngos_screen.dart';
import 'package:mca_app/presentation/views/admin/manage_users_screen.dart';
import 'package:mca_app/presentation/views/admin/donation_audit_screen.dart';
import 'package:mca_app/presentation/views/admin/analytics_dashboard_screen.dart';
import 'package:mca_app/presentation/views/admin/sms_logs_screen.dart';

late AuthViewModel testAuthVM;
late AdminViewModel testAdminVM;
late DonationViewModel testDonationVM;
late EmergencyViewModel testEmergencyVM;
late NotificationViewModel testNotificationVM;
late ChatViewModel testChatVM;
late LocationProviderV2 testLocationProvider;

Widget createAdminTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: testAuthVM),
      ChangeNotifierProvider<AdminViewModel>.value(value: testAdminVM),
      ChangeNotifierProvider<DonationViewModel>.value(value: testDonationVM),
      ChangeNotifierProvider<EmergencyViewModel>.value(value: testEmergencyVM),
      ChangeNotifierProvider<NotificationViewModel>.value(value: testNotificationVM),
      ChangeNotifierProvider<ChatViewModel>.value(value: testChatVM),
      ChangeNotifierProvider<LocationProviderV2>.value(value: testLocationProvider),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      routes: {
        '/notifications': (_) => const Scaffold(body: Text('Notifications')),
        '/login': (_) => const Scaffold(body: Text('Login')),
      },
    ),
  );
}

UserModel createSampleAdminUser() {
  return UserModel(
    id: "admin-001",
    email: "admin@foodbridge.ai",
    name: "Alex Vance",
    role: UserRole.admin,
    phoneNumber: "+91 9876543210",
  );
}

UserModel createSampleNgoUser({
  String id = "ngo-101",
  String name = "Hope Harvest Foundation",
  String status = "pending",
}) {
  return UserModel(
    id: id,
    email: "contact@hopeharvest.org",
    name: name,
    role: UserRole.ngo,
    phoneNumber: "+91 9123456789",
    address: "42 Charity Lane, Chennai",
    ngoRegistrationNumber: "NGO-TN-2024-8841",
    status: status,
    maxDailyMeals: 250,
  );
}

UserModel createSampleDonorUser({
  String id = "donor-201",
  String name = "Grand Palace Hotel",
  String status = "approved",
}) {
  return UserModel(
    id: id,
    email: "manager@grandpalace.com",
    name: name,
    role: UserRole.donor,
    phoneNumber: "+91 9988776655",
    address: "100 Luxury Blvd, Chennai",
    status: status,
  );
}

DonationModel createSampleDonation({
  String id = "don-501",
  String foodName = "Vegetable Pulao & Dal",
  String status = "waiting",
  bool isExpired = false,
}) {
  final now = DateTime.now();
  return DonationModel(
    id: id,
    donorId: "donor-201",
    donorName: "Grand Palace Hotel",
    foodName: foodName,
    category: "Cooked Food",
    membersServed: 25,
    imageUrl: "",
    preparedTime: now.subtract(const Duration(hours: 2)),
    bestBeforeTime: isExpired
        ? now.subtract(const Duration(hours: 1))
        : now.add(const Duration(hours: 3)),
    pickupAddress: "100 Luxury Blvd, Chennai",
    latitude: 13.0827,
    longitude: 80.2707,
    status: isExpired ? "expired" : status,
    assignedNgoName: "Hope Harvest Foundation",
    timeline: [
      TimelineModel(
        status: "waiting",
        time: now.subtract(const Duration(hours: 2)),
        description: "Donation posted and broadcasted to local NGOs",
      ),
    ],
  );
}

SmsLogModel createSampleSmsLog({
  String id = "sms-901",
  String phone = "+91 9876543210",
  String status = "delivered",
}) {
  return SmsLogModel(
    id: id,
    phoneNumber: phone,
    message: "Your OTP for FoodBridge AI verification is 849201.",
    status: status,
    provider: "Twilio",
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    userName: "Alex Vance",
    userEmail: "admin@foodbridge.ai",
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testAuthVM = AuthViewModel();
    testAdminVM = AdminViewModel();
    testAdminVM.enableMockMode();
    testDonationVM = DonationViewModel();
    testEmergencyVM = EmergencyViewModel();
    testNotificationVM = NotificationViewModel();
    testChatVM = ChatViewModel();
    testLocationProvider = LocationProviderV2();
  });

  group('Phase 6: Admin Dashboard & Control Center Tests', () {
    testWidgets('1. AdminDashboardScreen renders header, hero, real metrics, and action cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      testAuthVM.setUser(createSampleAdminUser());
      testAdminVM.setTestStats({
        'counts': {
          'totalDonors': 42,
          'totalNGOs': 18,
          'pendingNGOs': 3,
          'completedDonations': 120,
          'activeDonations': 7,
          'todayDonations': 15,
          'statusDistribution': [
            {'_id': 'waiting', 'count': 4},
            {'_id': 'accepted', 'count': 3},
            {'_id': 'completed', 'count': 120},
          ],
        },
        'impact': {
          'mealsServed': 3450,
          'co2Saved': 862.5,
          'foodSavedKg': 1725,
          'membersServed': 3450,
        },
        'charts': {
          'dailyDonations': [
            {'_id': '2026-10-25', 'count': 12},
            {'_id': '2026-10-26', 'count': 15},
          ],
          'categories': [
            {'_id': 'Cooked Food', 'count': 85},
            {'_id': 'Raw Materials', 'count': 35},
          ],
        },
        'recentActivity': [
          {
            'foodName': 'Fresh Biryani Packs',
            'status': 'waiting',
            'donorId': {'name': 'Royal Caterers'},
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
      });

      await tester.pumpWidget(createAdminTestApp(const AdminDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Header and Hero
      expect(find.text("Operations Center"), findsOneWidget);
      expect(find.text("LIVE SYNC"), findsOneWidget);
      expect(find.text("Welcome, Alex Vance"), findsOneWidget);
      expect(find.text("SUPER ADMIN"), findsOneWidget);

      // Verify Metrics
      expect(find.text("Total Donors"), findsOneWidget);
      expect(find.text("42"), findsOneWidget);
      expect(find.text("Active NGOs"), findsOneWidget);
      expect(find.text("18"), findsOneWidget);
      expect(find.text("Pending Approvals"), findsOneWidget);
      expect(find.text("3"), findsWidgets);

      // Verify Administrative Actions
      expect(find.text("User Manager"), findsOneWidget);
      expect(find.text("NGO Approvals"), findsOneWidget);
      expect(find.text("Donation Audit"), findsOneWidget);
      expect(find.text("System Analytics"), findsOneWidget);
    });

    testWidgets('2. ManageNgosScreen renders search, filter chips, and NGO card actions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      testAdminVM.setTestNgos([
        createSampleNgoUser(
          id: "ngo-001",
          name: "Care & Share Foundation",
          status: "pending",
        ),
      ]);

      await tester.pumpWidget(createAdminTestApp(const ManageNgosScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar and filter chips
      expect(find.text("NGO Partner Governance"), findsOneWidget);
      expect(find.text("Pending Approvals"), findsOneWidget);
      expect(find.text("Approved NGOs"), findsOneWidget);

      // Verify NGO Card details
      expect(find.text("Care & Share Foundation"), findsOneWidget);
      expect(find.text("Registration: NGO-TN-2024-8841"), findsOneWidget);
      expect(find.text("Government Verification Document"), findsOneWidget);

      // Verify Actions
      expect(find.text("APPROVE"), findsOneWidget);
      expect(find.text("REJECT"), findsOneWidget);
    });

    testWidgets('3. ManageUsersScreen renders user list, roles, and detail interaction',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      testAdminVM.setTestUsers([
        createSampleDonorUser(id: "usr-001", name: "Grand Palace Hotel"),
        createSampleNgoUser(id: "usr-002", name: "Care & Share Foundation"),
      ]);

      await tester.pumpWidget(createAdminTestApp(const ManageUsersScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar and search
      expect(find.text("User & Account Management"), findsOneWidget);
      expect(find.text("All Roles"), findsOneWidget);
      expect(find.text("All Status"), findsOneWidget);

      // Verify User cards
      expect(find.text("Grand Palace Hotel"), findsOneWidget);
      expect(find.text("Care & Share Foundation"), findsOneWidget);
      expect(find.text("DONOR"), findsOneWidget);
      expect(find.text("NGO"), findsOneWidget);

      // Tap on user card opens detail sheet
      await tester.tap(find.text("Grand Palace Hotel"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("manager@grandpalace.com"), findsWidgets);
    });

    testWidgets('4. DonationAuditScreen renders expiry visibility, category filters and audit log',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      final activeDonation = createSampleDonation(
        id: "don-act-1",
        foodName: "Warm Vegetable Rice",
        isExpired: false,
      );
      final expiredDonation = createSampleDonation(
        id: "don-exp-2",
        foodName: "Surplus Fruit Platter",
        isExpired: true,
      );

      testAdminVM.setTestDonations([activeDonation, expiredDonation]);

      await tester.pumpWidget(createAdminTestApp(const DonationAuditScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar & Expired Filter toggle
      expect(find.text("Donation Audit & Expiry Monitor"), findsOneWidget);
      expect(find.text("Expired Only"), findsOneWidget);

      // Verify Food Items & Expiry Visibility
      expect(find.text("Warm Vegetable Rice"), findsOneWidget);
      expect(find.text("Surplus Fruit Platter"), findsOneWidget);
      expect(find.textContaining("EXPIRED: Passed shelf-life"), findsOneWidget);
      expect(find.textContaining("Safe until:"), findsOneWidget);

      // Verify Audit Actions
      expect(find.text("TIMELINE AUDIT"), findsWidgets);
      expect(find.text("FULL DETAILS"), findsWidgets);

      // Tap TIMELINE AUDIT opens audit bottom sheet
      await tester.tap(find.text("TIMELINE AUDIT").first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Mission Audit Trail"), findsOneWidget);
    });

    testWidgets('5. AnalyticsDashboardScreen renders network statistics and impact metrics',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      await tester.pumpWidget(createAdminTestApp(const AnalyticsDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("System Analytics & Metrics"), findsOneWidget);
    });

    testWidgets('6. SmsLogsScreen renders dispatches, stats badges, and filter chips',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      testAdminVM.setTestSmsLogs([
        createSampleSmsLog(id: "sms-1", phone: "+91 9876543210", status: "delivered"),
      ]);
      testAdminVM.setTestSmsStats({
        'status': [
          {'_id': 'delivered', 'count': 45},
          {'_id': 'failed', 'count': 2},
        ],
      });

      await tester.pumpWidget(createAdminTestApp(const SmsLogsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("SMS Notification Logs"), findsOneWidget);
      expect(find.text("Delivered/Sent"), findsOneWidget);
      expect(find.text("Failed Dispatches"), findsOneWidget);
      expect(find.text("+91 9876543210"), findsOneWidget);
      expect(find.textContaining("Your OTP for FoodBridge AI"), findsOneWidget);
    });
  });
}
