import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juara_cpns/main.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  var _isLoading = false;
  String _university = '';
  String _major = '';
  String _address = '';

  @override
  void initState() {
    super.initState();
    _checkUserInfo();
  }

  Future<void> _checkUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        final data = userData.data();

        if (data != null) {
          setState(() {
            _university = data['university'] ?? '';
            _major = data['major'] ?? '';
            _address = data['address'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update user profile with additional information
        await _firestore.collection('users').doc(user.uid).update({
          'university': _university.trim(),
          'major': _major.trim(),
          'address': _address.trim(),
          'isProfileComplete': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Navigate to main screen on success
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
          );
        }
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
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

  Widget _buildForm(BoxConstraints constraints, ScreenSize screenSize) {
    final isWeb = !screenSize.isMobile;
    final formWidth = isWeb ? constraints.maxWidth * 0.4 : constraints.maxWidth;

    return Container(
      width: formWidth,
      constraints: const BoxConstraints(maxWidth: 500),
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
                  'Complete Your Profile',
                  style: AppTheme.textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide additional information to personalize your experience',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // University Field
                TextFormField(
                  key: const ValueKey('university'),
                  initialValue: _university,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your university';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Asal Universitas',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  onSaved: (value) {
                    _university = value ?? '';
                  },
                ),
                const SizedBox(height: 16),

                // Major Field
                TextFormField(
                  key: const ValueKey('major'),
                  initialValue: _major,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your major';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Jurusan',
                    prefixIcon: Icon(Icons.subject_outlined),
                  ),
                  onSaved: (value) {
                    _major = value ?? '';
                  },
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  key: const ValueKey('address'),
                  initialValue: _address,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Domisili Anda Sekarang',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  maxLines: 2,
                  onSaved: (value) {
                    _address = value ?? '';
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Continue',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward,
                ),
              ],
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
                                'Hampir Selesai!',
                                style: AppTheme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Lengkapi profile Anda untuk mendapatkan pengalaman belajar yang lebih personal dan terarah.',
                                style: AppTheme.textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Illustration Container
                              Center(
                                child: Container(
                                  height: 300,
                                  width: 300,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(150),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 150,
                                    color: AppTheme.primaryColor,
                                  ),
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
                                Icons.person_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lengkapi Profil Anda',
                              style: AppTheme.textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan informasi untuk pengalaman belajar yang lebih baik',
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