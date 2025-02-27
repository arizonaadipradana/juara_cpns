import 'package:flutter/material.dart';
import 'package:juara_cpns/class/platform_ui.dart';
import 'package:juara_cpns/screens/auth_screen.dart';
import 'package:juara_cpns/screens/home_screen.dart';
import 'package:juara_cpns/screens/practice_test_screen.dart';
import 'package:juara_cpns/screens/profile_screen.dart';
import 'package:juara_cpns/screens/learning_material_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JuaraCPNSApp());
}

class JuaraCPNSApp extends StatelessWidget {
  const JuaraCPNSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juara CPNS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PracticeTestScreen(),
    const LearningMaterialScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _controller.reset();
      _selectedIndex = index;
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (PlatformUI.isWeb && constraints.maxWidth > 768) {
          // Web layout with modernized navigation rail
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Row(
              children: [
                WebNavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      color: AppTheme.backgroundColor,
                      child: ResponsiveContainer(
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout with modern bottom navigation
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _screens[_selectedIndex],
              ),
            ),
            bottomNavigationBar: ModernBottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        }
      },
    );
  }
}

// Helper widget for screen transitions
class ScreenTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const ScreenTransition({
    Key? key,
    required this.child,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}