import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/donation_viewmodel.dart';
import 'presentation/viewmodels/admin_viewmodel.dart';
import 'presentation/viewmodels/emergency_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/delivery_viewmodel.dart';
import 'presentation/viewmodels/route_optimization_viewmodel.dart';
import 'core/providers/location_provider_v2.dart';
import 'core/theme/app_theme.dart';
import 'presentation/views/auth/login_screen.dart';
import 'data/models/user_model.dart';

import 'presentation/views/donor/donor_dashboard_screen.dart';
import 'presentation/views/ngo/ngo_dashboard_screen.dart';
import 'presentation/views/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return FutureBuilder(
      future: Provider.of<AuthViewModel>(context, listen: false).checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        
        return Consumer<AuthViewModel>(
          builder: (context, auth, _) {
            String initialRoute = '/';
            if (auth.user != null) {
              if (auth.user!.role == UserRole.donor) {
                initialRoute = '/donor-dashboard';
              } else if (auth.user!.role == UserRole.ngo) {
                initialRoute = '/ngo-dashboard';
              }
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'FoodRescue AI',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light,
              initialRoute: initialRoute,
              routes: {
                '/': (context) => const LoginScreen(),
                '/donor-dashboard': (context) => const DonorDashboardScreen(),
                '/ngo-dashboard': (context) => const NgoDashboardScreen(),
                '/admin-dashboard': (context) => const AdminDashboardScreen(),
              },
            );
          },
        );
      },
    );
  }
}
