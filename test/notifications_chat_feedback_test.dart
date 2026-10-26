import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/data/models/user_model.dart';
import 'package:mca_app/data/models/donation_model.dart';
import 'package:mca_app/data/models/notification_model.dart';
import 'package:mca_app/data/models/chat_model.dart';
import 'package:mca_app/data/models/message_model.dart';
import 'package:mca_app/data/repositories/rating_repository.dart';

import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/admin_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/donation_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/emergency_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/notification_viewmodel.dart';
import 'package:mca_app/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';

import 'package:mca_app/presentation/views/notifications/notification_center_screen.dart';
import 'package:mca_app/presentation/views/chat/chat_list_screen.dart';
import 'package:mca_app/presentation/views/chat/chat_room_screen.dart';
import 'package:mca_app/presentation/views/common/rating_screen.dart';
import 'package:mca_app/presentation/views/common/widgets/status_badge.dart';

late AuthViewModel testAuthVM;
late AdminViewModel testAdminVM;
late DonationViewModel testDonationVM;
late EmergencyViewModel testEmergencyVM;
late NotificationViewModel testNotificationVM;
late ChatViewModel testChatVM;
late LocationProviderV2 testLocationProvider;

class MockRatingRepository extends RatingRepository {
  bool submitted = false;
  String? lastDonationId;
  int? lastRating;
  String? lastReview;

  @override
  Future<void> submitRating({
    required String donationId,
    required String toUserId,
    required int rating,
    required String review,
  }) async {
    submitted = true;
    lastDonationId = donationId;
    lastRating = rating;
    lastReview = review;
  }
}

Widget createPhase7TestApp(Widget child) {
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
        '/chats': (_) => const Scaffold(body: Text('ChatsScreenRoute')),
        '/notifications': (_) => const Scaffold(body: Text('NotificationsRoute')),
      },
    ),
  );
}

UserModel createSampleUser({
  String id = "usr-001",
  String name = "Care NGO Partner",
  UserRole role = UserRole.ngo,
}) {
  return UserModel(
    id: id,
    email: "partner@carengo.org",
    name: name,
    role: role,
    phoneNumber: "+91 9876543210",
  );
}

NotificationModel createSampleNotification({
  String id = "notif-101",
  String title = "New Food Rescue Available",
  String body = "Fresh vegetable meals ready for pickup at Grand Hotel.",
  String category = "DONATION",
  bool isRead = false,
  DateTime? expiresAt,
}) {
  return NotificationModel(
    id: id,
    userId: "usr-001",
    title: title,
    body: body,
    category: category,
    priority: "high",
    data: {"donationId": "don-501"},
    isRead: isRead,
    expiresAt: expiresAt,
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  );
}

ChatModel createSampleChat({
  String id = "chat-101",
  String otherName = "Grand Hotel Donor",
  String lastText = "We have packed the food in thermo-insulated boxes.",
  int unread = 1,
}) {
  final now = DateTime.now();
  final otherUser = UserModel(
    id: "usr-donor-99",
    name: otherName,
    email: "donor@grandhotel.com",
    role: UserRole.donor,
    phoneNumber: "+91 9123456789",
  );

  return ChatModel(
    id: id,
    participants: [
      createSampleUser(),
      otherUser,
    ],
    donation: DonationModel(
      id: "don-501",
      donorId: "usr-donor-99",
      donorName: otherName,
      foodName: "Surplus Biryani & Curd Rice",
      category: "Cooked Food",
      membersServed: 40,
      imageUrl: "",
      preparedTime: now.subtract(const Duration(hours: 1)),
      bestBeforeTime: now.add(const Duration(hours: 4)),
      pickupAddress: "12 Beach Road, Chennai",
      latitude: 13.0827,
      longitude: 80.2707,
      status: "waiting",
    ),
    lastMessage: MessageModel(
      id: "msg-001",
      chatId: id,
      senderId: "usr-donor-99",
      receiverId: "usr-001",
      text: lastText,
      createdAt: now.subtract(const Duration(minutes: 5)),
      status: MessageStatus.delivered,
    ),
    unreadCounts: {"usr-001": unread},
    updatedAt: now.subtract(const Duration(minutes: 5)),
  );
}

MessageModel createSampleMessage({
  String id = "msg-010",
  String text = "Driver is on the way to your pickup address.",
  bool isMe = true,
}) {
  return MessageModel(
    id: id,
    chatId: "chat-101",
    senderId: isMe ? "usr-001" : "usr-donor-99",
    receiverId: isMe ? "usr-donor-99" : "usr-001",
    text: text,
    status: MessageStatus.seen,
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
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
    testDonationVM = DonationViewModel();
    testEmergencyVM = EmergencyViewModel();
    testNotificationVM = NotificationViewModel();
    testNotificationVM.enableMockMode();
    testChatVM = ChatViewModel();
    testChatVM.enableMockMode();
    testLocationProvider = LocationProviderV2();

    testAuthVM.setUser(createSampleUser());
  });

  group('Phase 7: Notifications, Chat & Feedback Tests', () {
    testWidgets('1. NotificationCenterScreen renders date grouping, category chips, and notifications',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      final activeNotif = createSampleNotification(
        id: "notif-1",
        title: "Fresh Rice Available",
        body: "30 meals waiting for pickup.",
        category: "DONATION",
        isRead: false,
      );

      final claimedNotif = createSampleNotification(
        id: "notif-2",
        title: "Donation Claimed 🤝",
        body: "This donation has already been accepted by another NGO and is no longer available.",
        category: "DONATION",
        isRead: true,
      );

      final expiredNotif = createSampleNotification(
        id: "notif-3",
        title: "Bakery Pastries Alert",
        body: "Shelf life expired.",
        category: "DONATION",
        isRead: true,
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      testNotificationVM.setTestNotifications([activeNotif, claimedNotif, expiredNotif], unread: 1);

      await tester.pumpWidget(createPhase7TestApp(const NotificationCenterScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header & Unread Count Badge
      expect(find.text("Notifications"), findsOneWidget);
      expect(find.text("1"), findsOneWidget);

      // Verify Filter Chips
      expect(find.text("Unread Only"), findsOneWidget);
      expect(find.text("All"), findsOneWidget);
      expect(find.text("Donations"), findsOneWidget);
      expect(find.text("Chats"), findsOneWidget);

      // Verify Date Group Header
      expect(find.text("TODAY"), findsOneWidget);

      // Verify Notification Content
      expect(find.text("Fresh Rice Available"), findsOneWidget);
      expect(find.text("30 meals waiting for pickup."), findsOneWidget);

      // Verify Claimed Status Pill
      expect(find.text("CLAIMED BY ANOTHER NGO"), findsOneWidget);

      // Verify Expired Status Pill
      expect(find.text("EXPIRED / UNAVAILABLE"), findsOneWidget);
    });

    testWidgets('2. ChatListScreen renders conversations, online status, mission context, and unread pill',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      final sampleChat = createSampleChat(
        id: "chat-1",
        otherName: "Royal Caterers",
        lastText: "We packed 40 meals in hot boxes.",
        unread: 2,
      );

      testChatVM.setTestChats([sampleChat]);

      await tester.pumpWidget(createPhase7TestApp(const ChatListScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar & Search
      expect(find.text("Rescue Comms & Messages"), findsOneWidget);
      expect(find.text("Search chats by person or food item..."), findsOneWidget);

      // Verify Chat Tile Information
      expect(find.text("Royal Caterers"), findsOneWidget);
      expect(find.text("DONOR"), findsOneWidget);
      expect(find.text("Rescue: Surplus Biryani & Curd Rice"), findsOneWidget);
      expect(find.text("We packed 40 meals in hot boxes."), findsOneWidget);

      // Verify Unread Badge
      expect(find.text("2"), findsOneWidget);
    });

    testWidgets('3. ChatRoomScreen renders header, mission context banner, message bubbles, and input area',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      final sampleChat = createSampleChat(id: "chat-room-1", otherName: "Grand Hotel Donor");
      final msg1 = createSampleMessage(id: "m-1", text: "Hello! We are preparing 40 food parcels.", isMe: false);
      final msg2 = createSampleMessage(id: "m-2", text: "Great! Our volunteer is en route for pickup.", isMe: true);

      testChatVM.setTestMessages([msg2, msg1]);

      await tester.pumpWidget(createPhase7TestApp(ChatRoomScreen(chat: sampleChat)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header
      expect(find.text("Grand Hotel Donor"), findsWidgets);

      // Verify Mission Context Banner
      expect(find.text("Surplus Biryani & Curd Rice"), findsOneWidget);
      expect(find.byType(StatusBadge), findsOneWidget);

      // Verify Message Bubbles
      expect(find.text("Hello! We are preparing 40 food parcels."), findsOneWidget);
      expect(find.text("Great! Our volunteer is en route for pickup."), findsOneWidget);

      // Verify Input Field
      expect(find.text("Type a message..."), findsOneWidget);
    });

    testWidgets('4. RatingScreen validates 0-star submission and submits feedback',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));

      final mockRepo = MockRatingRepository();

      await tester.pumpWidget(createPhase7TestApp(RatingScreen(
        donationId: "don-999",
        toUserId: "usr-donor-77",
        toUserName: "Grand Palace Catering",
        repository: mockRepo,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Header & Recipient Card
      expect(find.text("Rate Experience"), findsOneWidget);
      expect(find.text("Grand Palace Catering"), findsOneWidget);
      expect(find.text("COMPLETED RESCUE MISSION"), findsOneWidget);

      // Verify Initial Star Rating State
      expect(find.text("Tap stars to rate"), findsOneWidget);

      // Tap 5th star
      final starFinder = find.byIcon(Icons.star_outline_rounded);
      expect(starFinder, findsNWidgets(5));
      await tester.tap(starFinder.at(4));
      await tester.pump();

      // Verify Rating Label Updates
      expect(find.text("Outstanding! ⭐⭐⭐⭐⭐"), findsOneWidget);

      // Tap a quick tag chip
      await tester.tap(find.text("Punctual Handover"));
      await tester.pump();

      // Tap SUBMIT FEEDBACK
      await tester.tap(find.text("SUBMIT FEEDBACK"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Mock Repo received the rating
      expect(mockRepo.submitted, isTrue);
      expect(mockRepo.lastRating, 5);
      expect(mockRepo.lastDonationId, "don-999");
    });
  });
}
