import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  String _email = '';
  String _password = '';
  String _username = '';
  String _phoneNumber = '';

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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
      // Show generic error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Juara CPNS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                  prefixIcon: Icon(Icons.person),
                                ),
                                onSaved: (value) {
                                  _username = value ?? '';
                                },
                              ),
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
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                onSaved: (value) {
                                  _phoneNumber = value ?? '';
                                },
                              ),
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
                            labelText: 'Alamat email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          onSaved: (value) {
                            _email = value ?? '';
                          },
                        ),
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
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          onSaved: (value) {
                            _password = value ?? '';
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: Text(_isLogin ? 'Login' : 'Signup'),
                          ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(_isLogin
                              ? 'Belum punya akun? klik disini untuk Daftar'
                              : 'Aku sudah punya akun'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
