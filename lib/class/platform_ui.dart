// Create a utility class to handle platform-specific UI logic
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class PlatformUI {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  // Define platform-specific dimensions
  static double get maxContentWidth => isWeb ? 1200.0 : double.infinity;
  static double get horizontalPadding => isWeb ? 32.0 : 16.0;
  static double get verticalPadding => isWeb ? 24.0 : 16.0;

  // Define platform-specific styles
  static double get headingFontSize => isWeb ? 32.0 : 24.0;
  static double get bodyFontSize => isWeb ? 16.0 : 14.0;

  // Define layout breakpoints
  static bool isDesktop(double width) => width > 1024;
  static bool isTablet(double width) => width > 768 && width <= 1024;
  static bool isMobileWidth(double width) => width <= 768;
}

// Custom widget for responsive container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: PlatformUI.maxContentWidth,
        ),
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: PlatformUI.horizontalPadding,
          vertical: PlatformUI.verticalPadding,
        ),
        child: child,
      ),
    );
  }
}

// Custom app bar for different platforms
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const PlatformAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUI.isWeb) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        actions: actions,
        centerTitle: false,
        toolbarHeight: 64,
      );
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(PlatformUI.isWeb ? 64.0 : 56.0);
}

// Custom navigation rail for web
class WebNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const WebNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text('Beranda'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment),
          label: Text('Latihan Soal'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.book),
          label: Text('Materi'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ],
    );
  }
}