// Create a utility class to handle platform-specific UI logic
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/app_router.dart';
import 'package:juara_cpns/screens/help_screen.dart';

class PlatformUI {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  // Define platform-specific dimensions with more modern spacing
  static double get maxContentWidth => isWeb ? 1120.0 : double.infinity;
  static double get horizontalPadding => isWeb ? 40.0 : 20.0;
  static double get verticalPadding => isWeb ? 32.0 : 20.0;

  // Define platform-specific styles with more modern typography
  static double get headingFontSize => isWeb ? 28.0 : 22.0;
  static double get bodyFontSize => isWeb ? 16.0 : 14.0;

  // Define layout breakpoints
  static bool isDesktop(double width) => width > 1200;
  static bool isTablet(double width) => width > 768 && width <= 1200;
  static bool isMobileWidth(double width) => width <= 768;

  // Container decoration for consistent appearance
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// Custom widgets for responsive container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool applyDecoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.applyDecoration = false,
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
        decoration: applyDecoration ? PlatformUI.containerDecoration : null,
        child: child,
      ),
    );
  }
}

// Custom app bar for different platforms
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const PlatformAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUI.isWeb) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
        toolbarHeight: 68,
        shadowColor: Colors.transparent,
      );
    }

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      shadowColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(PlatformUI.isWeb ? 68.0 : 60.0);
}

// Modern web navigation rail
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'J',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Juara CPNS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
            _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Latihan Soal'),
            _buildNavItem(2, Icons.book_outlined, Icons.book_rounded, 'Materi'),
            _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Profil'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NavButton(
                icon: Icons.help_outline_rounded,
                label: 'Pusat Bantuan',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.help
                  );
                },
                isSelected: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData defaultIcon, IconData selectedIcon, String label) {
    final isSelected = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: NavButton(
        icon: isSelected ? selectedIcon : defaultIcon,
        label: label,
        onTap: () => onDestinationSelected(index),
        isSelected: isSelected,
      ),
    );
  }
}

// Animated navigation button for sidebar
class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const NavButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3F51B5).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF3F51B5) : const Color(0xFF78909C),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                  color: isSelected ? const Color(0xFF3F51B5) : const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Beautiful bottom navigation bar
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
          _buildNavIcon(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Latihan'),
          _buildNavIcon(2, Icons.book_outlined, Icons.book_rounded, 'Materi'),
          _buildNavIcon(3, Icons.person_outline, Icons.person_rounded, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData defaultIcon, IconData selectedIcon, String label) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? selectedIcon : defaultIcon,
            color: isSelected ? const Color(0xFF3F51B5) : const Color(0xFF78909C),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF3F51B5) : const Color(0xFF78909C),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}