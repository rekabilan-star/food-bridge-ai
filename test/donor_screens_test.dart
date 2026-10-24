import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/data/models/donation_model.dart';
import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/donation_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/emergency_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/notification_viewmodel.dart';
import 'package:mca_app/core/models/location_model.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';
import 'package:mca_app/presentation/views/common/widgets/donation_card.dart';
import 'package:mca_app/presentation/views/common/widgets/modern_text_field.dart';
import 'package:mca_app/presentation/views/common/widgets/status_badge.dart';
import 'package:mca_app/presentation/views/donor/donor_dashboard_screen.dart';
import 'package:mca_app/presentation/views/donor/donate_food_screen.dart';
import 'package:mca_app/presentation/views/common/donation_history_screen.dart';
import 'package:mca_app/presentation/views/common/donation_tracking_screen.dart';
import 'package:mca_app/presentation/views/common/rating_screen.dart';
import 'package:mca_app/presentation/views/donor/qr_display_screen.dart';

final testAuthVM = AuthViewModel();
final testDonationVM = DonationViewModel();
final testEmergencyVM = EmergencyViewModel();
final testNotificationVM = NotificationViewModel();
final testChatVM = ChatViewModel();
final testLocationProvider = LocationProviderV2();

Widget createDonorTestApp(Widget child) {
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
      },
    ),
  );
}

DonationModel createSampleDonation({
  String id = "don-001",
  String status = "waiting",
  String foodName = "Fresh Vegetable Biryani",
}) {
  return DonationModel(
    id: id,
    donorId: "donor-123",
    items: [
      FoodItem(foodName: foodName, category: "Vegetarian", membersServed: 8),
    ],
    foodName: foodName,
    category: "Vegetarian",
    membersServed: 8,
    imageUrl: "",
    preparedTime: DateTime.now().subtract(const Duration(hours: 1)),
    bestBeforeTime: DateTime.now().add(const Duration(hours: 4)),
    checklist: QualityChecklist(
      isFreshlyPrepared: true,
      isProperlyPacked: true,
      foodType: "Veg",
      hasAllergens: false,
    ),
    isScheduled: false,
    pickupAddress: "123 Green Avenue, Anna Nagar, Chennai",
    latitude: 13.0827,
    longitude: 80.2707,
    status: status,
    qrCode: "FDB-QR-SAMPLE-123",
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3: Donor Experience Redesign Tests', () {
    testWidgets('DonationCard renders title, subtitle, StatusBadge, and ETA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 450));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DonationCard(
              title: "Hot Meals (Curry & Rice)",
              subtitle: "10 Servings • Cooked Meal",
              status: "waiting",
              timeAgo: "10 mins ago",
              etaText: "15 mins",
              distanceText: "1.2 km away",
              onTrackTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Hot Meals (Curry & Rice)"), findsOneWidget);
      expect(find.text("10 Servings • Cooked Meal"), findsOneWidget);
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.text("10 mins ago"), findsOneWidget);
      expect(find.text("ETA: 15 mins"), findsOneWidget);
      expect(find.text("Track Live"), findsOneWidget);
    });

    testWidgets('DonorDashboardScreen renders hero banner, metrics, and empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      await tester.pumpWidget(createDonorTestApp(const DonorDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("FoodBridge AI"), findsOneWidget);
      expect(find.text("Share Surplus Food"), findsOneWidget);
      expect(find.text("DONATE FOOD NOW"), findsOneWidget);
      expect(find.text("Donations"), findsAtLeastNWidgets(1));
      expect(find.text("Meals Shared"), findsOneWidget);
      expect(find.text("Impact Score"), findsOneWidget);
      expect(find.text("Active Donations"), findsOneWidget);
      expect(find.text("View All"), findsOneWidget);
    });

    testWidgets('DonateFoodScreen renders Step 1 form fields and photo upload', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      testLocationProvider.setManualLocation(LocationModel(
        latitude: 13.0827,
        longitude: 80.2707,
        accuracy: 5.0,
        fullAddress: "Anna Nagar, Chennai",
        timestamp: DateTime.now(),
      ));
      await tester.pumpWidget(createDonorTestApp(const DonateFoodScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Donate Food"), findsOneWidget);
      expect(find.text("Food Details"), findsOneWidget);
      expect(find.text("Location"), findsOneWidget);
      expect(find.text("Review"), findsOneWidget);
      expect(find.text("Food Type"), findsOneWidget);
      expect(find.text("Quantity"), findsAtLeastNWidgets(1));
      expect(find.text("Food Category"), findsOneWidget);
      expect(find.text("Prepared On"), findsOneWidget);
      expect(find.text("Best Before"), findsOneWidget);
      expect(find.text("Add Photo"), findsOneWidget);
      expect(find.text("Next: Location"), findsOneWidget);
    });

    testWidgets('DonationHistoryScreen renders search field and filter chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createDonorTestApp(const DonationHistoryScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Donation History"), findsOneWidget);
      expect(find.text("All"), findsOneWidget);
      expect(find.text("Active"), findsOneWidget);
      expect(find.text("Completed"), findsOneWidget);
      expect(find.byType(ModernTextField), findsOneWidget);
    });

    testWidgets('DonationTrackingScreen renders status stepper and mission title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createDonorTestApp(const DonationTrackingScreen(donationId: "sample-123")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Track Rescue Mission"), findsOneWidget);
    });

    testWidgets('RatingScreen renders recipient, star ratings, review field, and submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createDonorTestApp(const RatingScreen(
        donationId: "don-999",
        toUserId: "ngo-456",
        toUserName: "Akshaya Patra Foundation",
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Rate Experience"), findsOneWidget);
      expect(find.text("Akshaya Patra Foundation"), findsOneWidget);
      expect(find.text("Tap stars to rate"), findsOneWidget);
      expect(find.text("SUBMIT FEEDBACK"), findsOneWidget);

      // Tap 5 stars
      final starIcons = find.byIcon(Icons.star_outline_rounded);
      expect(starIcons, findsNWidgets(5));
      await tester.tap(starIcons.last);
      await tester.pump();

      expect(find.text("Outstanding! ⭐⭐⭐⭐⭐"), findsOneWidget);
    });

    testWidgets('QrDisplayScreen renders QR container, food name, and verification note', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      final sample = createSampleDonation(id: "don-abc-123", foodName: "Fresh Veg Pulao");

      await tester.pumpWidget(createDonorTestApp(QrDisplayScreen(donation: sample)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Pickup Verification"), findsOneWidget);
      expect(find.text("Show this QR to the NGO Partner"), findsOneWidget);
      expect(find.text("Fresh Veg Pulao"), findsOneWidget);
      expect(find.text("Donation ID: #ABC123"), findsOneWidget);
      expect(find.text("Waiting for NGO pickup scan..."), findsOneWidget);
    });
  });
}
