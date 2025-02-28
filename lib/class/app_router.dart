import 'package:flutter/material.dart';
import 'package:juara_cpns/screens/home_screen.dart';
import 'package:juara_cpns/screens/payment_callback_screen.dart';
import 'package:juara_cpns/screens/payment_screen.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';
import 'package:juara_cpns/class/practice_package_model.dart';

class AppRouter {
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
      case '/':
        return MaterialPageRoute(builder: (_) => HomeScreen());

      case '/payment':
        final args = settings.arguments as Map<String, dynamic>;
        final package = args['package'] as PracticePackage;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(package: package),
        );

      case '/tryout':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TryoutScreen(
            type: args['type'],
            packageId: args['packageId'],
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}