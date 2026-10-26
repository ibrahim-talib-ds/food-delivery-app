import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_state.dart';
import 'features/customer/cart_state.dart';
import 'features/customer/location_state.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/customer/customer_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthState();
  await auth.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => LocationState()),
      ],
      child: const FoodDeliveryApp(),
    ),
  );
}

class FoodDeliveryApp extends StatelessWidget {
  const FoodDeliveryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF112A1F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFF3E5AB),
          surface: Color(0xFF112A1F),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const _RootGate(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    // If the user is logged in, go straight to Customer Shell
    if (auth.isLoggedIn) {
      return const CustomerShell();
    }

    // Otherwise show the Welcome Screen
    return const WelcomeScreen();
  }
}
