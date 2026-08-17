import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/donation_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'presentation/viewmodels/emergency_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/delivery_viewmodel.dart';
import 'presentation/viewmodels/route_optimization_viewmodel.dart';
import 'presentation/viewmodels/notification_viewmodel.dart';
import 'core/providers/location_provider_v2.dart';
import 'core/theme/app_theme.dart';
import 'presentation/views/auth/login_screen.dart';
import 'presentation/views/auth/donor_register_screen.dart';
import 'presentation/views/auth/ngo_register_screen.dart';

import 'presentation/views/donor/donor_dashboard_screen.dart';
import 'presentation/views/ngo/ngo_dashboard_screen.dart';
import 'presentation/views/admin/admin_dashboard_screen.dart';
import 'presentation/views/notifications/notification_center_screen.dart';
import 'presentation/views/chat/chat_list_screen.dart';

import 'presentation/views/common/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Requirement 8: Startup Error Handling
  FlutterError.onError = (details) {
    debugPrint('[STARTUP ERROR] ${details.exception}');
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DonationViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => EmergencyViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => DeliveryViewModel()),
        ChangeNotifierProvider(create: (_) => RouteOptimizationViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => LocationProviderV2()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FoodBridge AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/splash': page = const SplashScreen(); break;
          case '/login': page = const LoginScreen(); break;
          case '/donor-register': page = const DonorRegisterScreen(); break;
          case '/ngo-register': page = const NgoRegisterScreen(); break;
          case '/donor-dashboard': page = const DonorDashboardScreen(); break;
          case '/ngo-dashboard': page = const NgoDashboardScreen(); break;
          case '/admin-dashboard': page = const AdminDashboardScreen(); break;
          case '/notifications': page = const NotificationCenterScreen(); break;
          case '/chats': page = const ChatListScreen(); break;
          default: page = const LoginScreen();
        }
        
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          settings: settings,
        );
      },
    );
  }
}
