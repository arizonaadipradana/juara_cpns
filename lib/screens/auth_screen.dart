import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/main.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets//custom_button.dart';
import 'package:juara_cpns/widgets//responsive_builder.dart';
import 'package:lottie/lottie.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  String _email = '';
  String _password = '';
  String _username = '';
  String _phoneNumber = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createUserProfile(User user) async {
    try {
      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user profile
        await _firestore.collection('users').doc(user.uid).set({
          'username': _username.trim(),
          'email': _email.trim(),
          'phoneNumber': _phoneNumber.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('User profile created successfully');
      }
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );

        // Update last login timestamp
        if (userCredential.user != null) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Sign up
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );

        // Create user profile in Firestore
        if (userCredential.user != null) {
          await _createUserProfile(userCredential.user!);
        }
      }

      // Navigate to main screen on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication failed'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (error) {
      // Show generic error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });

    // Reset animation and play again
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildForm(BoxConstraints constraints, ScreenSize screenSize) {
    final isWeb = !screenSize.isMobile;
    final formWidth = isWeb ? constraints.maxWidth * 0.4 : constraints.maxWidth;

    return Container(
      width: formWidth,
      constraints: const BoxConstraints(maxWidth: 500),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          margin: EdgeInsets.all(isWeb ? 0 : 20),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 40 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account',
                    style: AppTheme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Please sign in to your account'
                        : 'Fill in your details to get started',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_isLogin)
                    Column(
                      children: [
                        TextFormField(
                          key: const ValueKey('username'),
                          validator: (value) {
                            if (value == null || value.length < 4) {
                              return 'Masukkan minimal 4 karakter';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          onSaved: (value) {
                            _username = value ?? '';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('phoneNumber'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan nomor telepon';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) {
                            _phoneNumber = value ?? '';
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  TextFormField(
                    key: const ValueKey('email'),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    onSaved: (value) {
                      _email = value ?? '';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('password'),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    onSaved: (value) {
                      _password = value ?? '';
                    },
                  ),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgotten password
                        },
                        child: const Text('Lupa Password?'),
                      ),
                    ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: _isLogin ? 'Login' : 'Daftar',
                    onPressed: _submit,
                    isLoading: _isLoading,
                    icon: _isLogin ? Icons.login : Icons.person_add,
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(_isLogin
                          ? 'Belum punya akun? Daftar sekarang'
                          : 'Sudah punya akun? Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: ResponsiveBuilder(
          builder: (context, constraints, screenSize) {
            final isWeb = !screenSize.isMobile;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: isWeb
                      ? Row(
                    children: [
                      // Left Section for Web (Illustration)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Juara CPNS',
                                style: AppTheme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Persiapkan diri Anda untuk tes CPNS dengan materi dan tryout yang komprehensif dan terupdate.',
                                style: AppTheme.textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Add illustration
                              Center(
                                child: Lottie.network(
                                  'https://raw.githubusercontent.com/arizonaadipradana/juara_cpns/refs/heads/master/lib/assets/student_header.json',
                                  height: 500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right Section (Form)
                      Expanded(
                        child: Center(
                          child: _buildForm(constraints, screenSize),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Brand for Mobile
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Brand Logo
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Juara CPNS',
                              style: AppTheme.textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Persiapkan diri untuk sukses CPNS',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Form for Mobile
                      _buildForm(constraints, screenSize),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}