import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mca_app/core/theme/app_theme.dart';
import 'package:mca_app/presentation/views/common/widgets/primary_button.dart';
import 'package:mca_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:mca_app/core/providers/location_provider_v2.dart';
import 'package:mca_app/presentation/views/auth/login_screen.dart';
import 'package:mca_app/presentation/views/auth/donor_register_screen.dart';
import 'package:mca_app/presentation/views/auth/ngo_register_screen.dart';
import 'package:mca_app/presentation/views/auth/forgot_password_screen.dart';
import 'package:mca_app/presentation/views/auth/reset_password_screen.dart';
import 'package:mca_app/presentation/views/auth/ngo_approval_pending_screen.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => LocationProviderV2()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
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

  group('Authentication & Registration Screens (Phase 2)', () {
    testWidgets('LoginScreen renders brand header, fields, and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sign In to FoodBridge'), findsOneWidget);
      expect(find.text('Email Address'), findsAtLeastNWidgets(1));
      expect(find.text('Password'), findsAtLeastNWidgets(1));
      expect(find.text('Remember Me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('LoginScreen opens Role Selection BottomSheet on Sign Up tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final signUpTap = find.text('Sign Up');
      expect(signUpTap, findsOneWidget);
      await tester.tap(signUpTap);
      await tester.pumpAndSettle();

      expect(find.text('Create an Account'), findsOneWidget);
      expect(find.text('Register as Donor'), findsOneWidget);
      expect(find.text('Register as NGO Partner'), findsOneWidget);
    });

    testWidgets('DonorRegisterScreen renders header, all fields, and location box', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      await tester.pumpWidget(createTestApp(const DonorRegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Create Donor Account'), findsOneWidget);
      expect(find.text('Join the Rescue Movement'), findsOneWidget);
      expect(find.text('Full Name'), findsAtLeastNWidgets(1));
      expect(find.text('Email Address'), findsAtLeastNWidgets(1));
      expect(find.text('Create Password'), findsAtLeastNWidgets(1));
      expect(find.text('Phone Number'), findsAtLeastNWidgets(1));
      expect(find.text('Pickup Address'), findsAtLeastNWidgets(1));

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('NgoRegisterScreen renders sections, document upload, and capacity chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      await tester.pumpWidget(createTestApp(const NgoRegisterScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NGO Partner Application'), findsOneWidget);
      expect(find.text('Partner with FoodBridge AI'), findsOneWidget);
      expect(find.text('ORGANIZATION DETAILS'), findsOneWidget);
      expect(find.text('IDENTITY VERIFICATION'), findsOneWidget);
      expect(find.text('ACCOUNT & CONTACT'), findsOneWidget);
      expect(find.text('OPERATIONAL CAPACITY'), findsOneWidget);
      expect(find.text('Cooked Meal'), findsOneWidget);
      expect(find.text('Bakery Items'), findsOneWidget);
      expect(find.text('SUBMIT APPLICATION'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders input field and recovery button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestApp(const ForgotPasswordScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Registered Email'), findsOneWidget);
      expect(find.text('SEND RECOVERY CODE'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen renders code input, new password, and submit button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(createTestApp(const ResetPasswordScreen(email: 'donor@test.com')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Verify & Reset'), findsOneWidget);
      expect(find.text('Verify Account'), findsOneWidget);
      expect(find.text('6-Digit Code'), findsOneWidget);
      expect(find.text('New Password'), findsAtLeastNWidgets(1));
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);
    });

    testWidgets('NgoApprovalPendingScreen renders status details and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestApp(const NgoApprovalPendingScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Account Status'), findsOneWidget);
      expect(find.text('Approval Pending'), findsOneWidget);
      expect(find.text('CHECK APPROVAL STATUS'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
    });
  });
}
