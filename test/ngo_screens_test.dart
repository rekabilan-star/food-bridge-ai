import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/data/models/donation_model.dart';
import 'package:mca_app/data/models/user_model.dart';
import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/donation_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/emergency_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/notification_viewmodel.dart';
import 'package:mca_app/core/models/location_model.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';
import 'package:mca_app/presentation/views/ngo/ngo_dashboard_screen.dart';
import 'package:mca_app/presentation/views/ngo/ngo_donation_requests_screen.dart';
import 'package:mca_app/presentation/views/ngo/donation_details_screen.dart';
import 'package:mca_app/presentation/views/ngo/emergency_request_screen.dart';
import 'package:mca_app/presentation/views/ngo/ngo_tracking_screen.dart';
import 'package:mca_app/presentation/views/ngo/ngo_navigation_screen.dart';
import 'package:mca_app/presentation/views/ngo/delivery_confirmation_screen.dart';
import 'package:mca_app/presentation/views/ngo/distribution_proof_screen.dart';
import 'package:mca_app/presentation/views/common/edit_profile_screen.dart';

late AuthViewModel testAuthVM;
late DonationViewModel testDonationVM;
late EmergencyViewModel testEmergencyVM;
late NotificationViewModel testNotificationVM;
late ChatViewModel testChatVM;
late LocationProviderV2 testLocationProvider;

Widget createNgoTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: testAuthVM),
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
        '/chats': (_) => const Scaffold(body: Text('Chats')),
        '/ngo-dashboard': (_) => const Scaffold(body: Text('NGO Dashboard')),
      },
    ),
  );
}

DonationModel createNgoSampleDonation({
  String id = "ngo-don-001",
  String status = "waiting",
  String foodName = "Surplus Rice & Curry",
}) {
  return DonationModel(
    id: id,
    donorId: "donor-456",
    donorName: "Grand Palace Hotel",
    donorPhone: "+919876543210",
    items: [
      FoodItem(foodName: foodName, category: "Cooked Meals", membersServed: 30),
    ],
    foodName: foodName,
    category: "Cooked Meals",
    membersServed: 30,
    imageUrl: "",
    preparedTime: DateTime.now().subtract(const Duration(hours: 1)),
    bestBeforeTime: DateTime.now().add(const Duration(hours: 3)),
    checklist: QualityChecklist(
      isFreshlyPrepared: true,
      isProperlyPacked: true,
      foodType: "Veg",
      hasAllergens: false,
    ),
    isScheduled: false,
    pickupAddress: "45 Marina Beach Road, Chennai",
    latitude: 13.0475,
    longitude: 80.2520,
    status: status,
    specialInstructions: "Use back delivery gate",
    qrCode: "FDB-QR-NGO-456",
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
    testDonationVM = DonationViewModel();
    testEmergencyVM = EmergencyViewModel();
    testNotificationVM = NotificationViewModel();
    testChatVM = ChatViewModel();
    testLocationProvider = LocationProviderV2();

    testAuthVM.setUser(
      UserModel(
        id: "ngo-partner-1",
        email: "rescue@ngo.org",
        name: "Hope Rescue NGO",
        role: UserRole.ngo,
        phoneNumber: "+919876543210",
        address: "45 Marina Beach Road, Chennai",
        status: "approved",
        availabilityStatus: "Available",
      ),
    );
    testLocationProvider.setManualLocation(
      LocationModel(
        latitude: 13.0827,
        longitude: 80.2707,
        city: "Chennai",
        state: "Tamil Nadu",
        country: "India",
        fullAddress: "HQ Rescue Center, Central Chennai",
        accuracy: 5.0,
        timestamp: DateTime.now(),
      ),
    );
  });

  group('Phase 4: NGO Experience Redesign Tests', () {
    testWidgets('1. NgoDashboardScreen renders header, emergency button, and metrics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      await tester.pumpWidget(createNgoTestApp(const NgoDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Rescue Control"), findsOneWidget);
      expect(find.text("BROADCAST EMERGENCY ALERT"), findsOneWidget);
      expect(find.text("Explore Surplus Opportunities"), findsOneWidget);
      expect(find.text("Active Tasks"), findsOneWidget);
      expect(find.text("Active Rescue Tasks"), findsOneWidget);
    });

    testWidgets('2. NgoDonationRequestsScreen renders opportunities title, search, and AI banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(createNgoTestApp(const NgoDonationRequestsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Nearby Opportunities"), findsOneWidget);
      expect(find.text("Search Surplus Food"), findsOneWidget);
      expect(find.textContaining("Ranked by proximity within 20 KM"), findsOneWidget);
    });

    testWidgets('3. DonationDetailsScreen renders food specs, pickup location, and action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      final sample = createNgoSampleDonation();
      await tester.pumpWidget(createNgoTestApp(DonationDetailsScreen(donation: sample)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Donation Details"), findsOneWidget);
      expect(find.text("Surplus Rice & Curry"), findsOneWidget);
      expect(find.text("Food Information"), findsOneWidget);
      expect(find.text("Pickup Location"), findsOneWidget);
      expect(find.text("Special Instructions"), findsOneWidget);
      expect(find.text("OPEN IN MAPS NAVIGATION"), findsOneWidget);
      expect(find.text("ACCEPT DONATION"), findsOneWidget);
    });

    testWidgets('4. EmergencyRequestScreen renders form fields, GPS button, and broadcast trigger', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1400));
      await tester.pumpWidget(createNgoTestApp(const EmergencyRequestScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Emergency Broadcast"), findsOneWidget);
      expect(find.text("Immediate Community Hunger Need"), findsOneWidget);
      expect(find.text("Request Title"), findsOneWidget);
      expect(find.text("Reason & Context"), findsOneWidget);
      expect(find.text("Members in Need"), findsOneWidget);
      expect(find.text("Distribution / Delivery Address"), findsOneWidget);
      expect(find.text("BROADCAST EMERGENCY ALERT"), findsOneWidget);
    });

    testWidgets('5. NgoTrackingScreen renders map, header pill, and action step', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      final sample = createNgoSampleDonation(status: "accepted");
      await tester.pumpWidget(createNgoTestApp(NgoTrackingScreen(donationId: sample.id)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Rescue Navigation"), findsOneWidget);
    });

    testWidgets('6. NgoNavigationScreen renders map, info panel, and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(createNgoTestApp(const NgoNavigationScreen(donationId: "ngo-don-001")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Navigating to Pickup"), findsOneWidget);
      expect(find.text("Navigating to Food Pickup"), findsOneWidget);
      expect(find.text("OPEN IN GOOGLE MAPS"), findsOneWidget);
      expect(find.text("ARRIVED AT DONOR LOCATION"), findsOneWidget);
    });

    testWidgets('7. DeliveryConfirmationScreen renders photo container, fields, and submit button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1400));
      final sample = createNgoSampleDonation(status: "picked_up");
      await tester.pumpWidget(createNgoTestApp(DeliveryConfirmationScreen(donation: sample)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Confirm Delivery"), findsOneWidget);
      expect(find.text("Distribution Proof Photo"), findsOneWidget);
      expect(find.text("Distribution Location"), findsOneWidget);
      expect(find.text("Actual Members Served"), findsOneWidget);
      expect(find.text("COMPLETE DONATION MISSION"), findsOneWidget);
    });

    testWidgets('8. DistributionProofScreen renders proof step, inputs, and complete button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 900));
      await tester.pumpWidget(createNgoTestApp(const DistributionProofScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Proof of Distribution"), findsOneWidget);
      expect(find.text("Step 7: Proof of Distribution"), findsOneWidget);
      expect(find.text("Approx. Members Served"), findsOneWidget);
      expect(find.text("Distribution Notes"), findsOneWidget);
      expect(find.text("COMPLETE DISTRIBUTION"), findsOneWidget);
    });

    testWidgets('9. EditProfileScreen renders NGO Operational Settings, registration number, and capacity', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      testAuthVM.setUser(
        UserModel(
          id: "ngo-user-1",
          email: "hope@ngo.org",
          name: "Hope Foundation",
          role: UserRole.ngo,
          phoneNumber: "+919876543210",
          address: "45 Rescue Boulevard, Chennai",
          ngoRegistrationNumber: "NGO-TN-2024-8891",
          maxDailyMeals: 150,
          acceptedCategories: ["Cooked Meals", "Raw Groceries"],
          status: "approved",
          availabilityStatus: "Available",
        ),
      );
      testLocationProvider.setManualLocation(
        LocationModel(
          latitude: 13.0827,
          longitude: 80.2707,
          city: "Chennai",
          state: "Tamil Nadu",
          country: "India",
          fullAddress: "HQ Rescue Center, Central Chennai",
          accuracy: 5.0,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createNgoTestApp(const EditProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Edit Profile"), findsOneWidget);
      expect(find.text("NGO Operational Settings"), findsOneWidget);
      expect(find.text("Registration Number"), findsOneWidget);
      expect(find.text("NGO-TN-2024-8891"), findsOneWidget);
      expect(find.text("Max Daily Capacity"), findsOneWidget);
      expect(find.text("150 meals/day"), findsOneWidget);
      expect(find.text("SAVE PROFILE CHANGES"), findsOneWidget);
    });
  });
}
