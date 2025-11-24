import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cartologistics_users_app/appInfo/app_info.dart';
import 'package:cartologistics_users_app/appInfo/auth_provider.dart';
import 'package:cartologistics_users_app/authentication/register_screen.dart';
import 'package:cartologistics_users_app/global/global_var.dart';
import 'package:cartologistics_users_app/pages/blocked_screen.dart';
import 'package:cartologistics_users_app/pages/home_page.dart';

late Size mq;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeConfiguration();
  await Firebase.initializeApp();
  await Permission.locationWhenInUse.isDenied.then((valueOfPermission) {
    if (valueOfPermission) {
      Permission.locationWhenInUse.request();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoClass()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider())
      ],
      child: MaterialApp(
        title: 'Uber User App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthCheck(),
      ),
    );
  }
}

Future<void> _initializeConfiguration() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (err) {
    debugPrint("dotenv: failed to load .env file. Falling back to defaults. Error: $err");
  }

  _applyEnvValue(
    dotenv.env['STRIPE_SECRET_KEY'],
    (value) => stripeSecretAPIKey = value,
  );

  _applyEnvValue(
    dotenv.env['STRIPE_PUBLISHABLE_KEY'],
    (value) => stripePublishedKey = value,
  );

  _applyEnvValue(
    dotenv.env['GOOGLE_MAPS_API_KEY'],
    (value) => googleMapKey = value,
  );

  Stripe.publishableKey = stripePublishedKey;
  if (stripePublishedKey.isEmpty) {
    debugPrint('Stripe publishable key is empty. Update .env or global_var.dart to enable payments.');
  }
}

void _applyEnvValue(String? envValue, void Function(String) setter) {
  final trimmedValue = envValue?.trim();
  if (trimmedValue != null && trimmedValue.isNotEmpty) {
    setter(trimmedValue);
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AuthenticationProvider via Provider
    final authProvider =
        Provider.of<AuthenticationProvider>(context, listen: false);

    return FutureBuilder<User?>(
      future: FirebaseAuth.instance
          .authStateChanges()
          .first, // Check if Firebase user exists
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Show loading indicator
        }

        // If user is not logged in, navigate to RegisterScreen
        if (!snapshot.hasData || snapshot.data == null) {
          return const RegisterScreen();
        }

        // If user is logged in, first check if the driver is blocked
        return FutureBuilder<bool>(
          future: authProvider
              .checkIfUserIsBlocked(), // Check if the driver is blocked
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SafeArea(
                child: Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data == true) {
              // If the driver is blocked, show an appropriate message
              return const BlockedScreen();
            }
            // If the driver is not blocked, check for profile completeness
            return FutureBuilder<bool>(
              future: authProvider
                  .checkUserFieldsFilled(), // Check if the profile fields are filled
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SafeArea(
                    child: Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data == true) {
                  // If profile is complete, navigate to the dashboard
                  return const HomePage();
                } else {
                  // If profile is incomplete, navigate to the registration screen
                  return const RegisterScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}
