import 'package:flutter/material.dart';
import 'package:juara_cpns/screens/home_screen.dart';
import 'package:juara_cpns/screens/payment_callback_screen.dart';
import 'package:juara_cpns/screens/payment_screen.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';
import 'package:juara_cpns/screens/practice_test_screen.dart';
import 'package:juara_cpns/screens/profile_screen.dart';
import 'package:juara_cpns/screens/learning_material_screen.dart';
import 'package:juara_cpns/screens/help_screen.dart';
import 'package:juara_cpns/class/practice_package_model.dart';

class AppRouter {
  static const String home = '/';
  static const String tryout = '/tryout';
  static const String payment = '/payment';
  static const String profile = '/profile';
  static const String practice = '/practice';
  static const String learning = '/learning';
  static const String help = '/help';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final pathSegments = uri.pathSegments;

    // Extract query parameters for payment callbacks
    final queryParams = uri.queryParameters;

    // Handle payment callback routes
    if (pathSegments.isNotEmpty && pathSegments.first == 'payment') {
      if (pathSegments.length > 1) {
        final callbackType = pathSegments[1];

        if (['finish', 'error', 'pending'].contains(callbackType)) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PaymentCallbackScreen(
              callbackType: callbackType,
              orderId: queryParams['order_id'],
              packageId: queryParams['package_id'],
              packageType: queryParams['package_type'],
            ),
          );
        }
      }
    }

    // Handle other routes
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(),
        );

      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        final package = args?['package'] as PracticePackage?;

        if (package == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(
                child: Text('Package information is missing'),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaymentScreen(package: package),
        );

      case tryout:
        final args = settings.arguments as Map<String, dynamic>?;
        final type = args?['type'] as String? ?? 'FULL';
        final packageId = args?['packageId'] as String?;

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TryoutScreen(
            type: type,
            packageId: packageId,
          ),
        );

      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen(),
        );

      case practice:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PracticeTestScreen(),
        );

      case learning:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LearningMaterialScreen(),
        );

      case help:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HelpScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}