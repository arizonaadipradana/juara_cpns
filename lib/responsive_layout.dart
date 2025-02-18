import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktopLayout ?? tabletLayout ?? mobileLayout;
        }

        if (constraints.maxWidth >= 600) {
          return tabletLayout ?? mobileLayout;
        }

        return mobileLayout;
      },
    );
  }
}

extension MediaQueryExtension on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get screenPadding => MediaQuery.of(this).padding;
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 1200;
  double get horizontalPadding => isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
}

class ResponsiveSizing {
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (context.isDesktop) return baseSize * 1.2;
    if (context.isTablet) return baseSize * 1.1;
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (context.isDesktop) {
      return const EdgeInsets.all(32.0);
    }
    if (context.isTablet) {
      return const EdgeInsets.all(24.0);
    }
    return const EdgeInsets.all(16.0);
  }
}