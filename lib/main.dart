import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:juara_cpns/class/app_router.dart';
import 'package:juara_cpns/class/platform_ui.dart';
import 'package:juara_cpns/screens/auth_screen.dart';
import 'package:juara_cpns/screens/home_screen.dart';
import 'package:juara_cpns/screens/information_screen.dart';
import 'package:juara_cpns/screens/profile_screen.dart';
import 'package:juara_cpns/screens/practice_test_screen.dart';
import 'package:juara_cpns/screens/learning_material_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    // Get current path for initial route (for web)
    String initialRoute = '/';
    if (PlatformUI.isWeb) {
      final path = html.window.location.pathname;
      if (path != null && path.isNotEmpty && path != '/') {
        initialRoute = path;
      }
    }

    return MaterialApp(
      title: 'Juara CPNS',
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.hasData) {
            // User is logged in, check if profile is complete
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userSnapshot.data!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final userData = snapshot.data?.data();
                final isProfileComplete = userData?['isProfileComplete'] ?? false;

                if (isProfileComplete) {
                  return const MainScreen();
                } else {
                  return const InformationScreen();
                }
              },
            );
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

    // Update URL path based on selected index
    String path = '/';
    switch (index) {
      case 0:
        path = AppRouter.home;
        break;
      case 1:
        path = AppRouter.practice;
        break;
      case 2:
        path = AppRouter.learning;
        break;
      case 3:
        path = AppRouter.profile;
        break;
    }

    // This updates the URL without actually navigating
    if (PlatformUI.isWeb) {
      // Update browser URL
      html.window.history.pushState(null, '', path);
    }

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