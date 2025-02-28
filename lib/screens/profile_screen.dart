import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juara_cpns/screens/auth_screen.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';
import 'package:juara_cpns/widgets/section_header.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;

  String _getInitials(String fullName) {
    List<String> nameParts = fullName.split(' ');
    String initials = '';

    // Get first letter of first word
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0].toUpperCase();
    }

    // Get first letter of second word (if it exists)
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0].toUpperCase();
    }

    // If we couldn't get two initials, just return the first initial or 'U'
    return initials.isEmpty ? 'U' : initials;
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _profileImageUrl = userData.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Pick the image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User not authenticated'),
              backgroundColor: Colors.red),
        );
        return;
      }

      // Use a unique filename with user ID as the prefix
      final fileName = 'profile_${user.uid}.jpg';

// Create storage reference with a proper path structure
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(user.uid) // Add user ID as a subfolder for better organization
          .child(fileName);

      // Read the image as bytes (works for both web and mobile)
      final bytes = await image.readAsBytes();

      // For uploads, specify metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=86400', // 24 hours caching
      );

      try {
        // Upload with error handling
        final uploadTask = storageRef.putData(bytes, metadata);

        // Listen for state changes, errors, and completion
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            // You could show upload progress here if needed
            // final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          }
        }, onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Upload error: ${e.toString()}'),
                  backgroundColor: Colors.red),
            );
            setState(() {
              _isUploadingImage = false;
            });
          }
        });

        // Wait for upload completion
        await uploadTask;

        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore with the URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImageUrl': downloadUrl,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Update local state
        if (mounted) {
          setState(() {
            _profileImageUrl = downloadUrl;
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          print("Firebase storage error details: $e");

          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings will be available soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final username = userData?['username'] ?? 'User';
          final phoneNumber = userData?['phoneNumber'] ?? '-';
          final email = user.email ?? '';

          return ResponsiveBuilder(
            builder: (context, constraints, screenSize) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.isDesktop ? 48 : 16,
                  vertical: 24,
                ),
                child: screenSize.isDesktop
                    ? _buildDesktopLayout(username, email, phoneNumber)
                    : _buildMobileLayout(username, email, phoneNumber),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
      String username, String email, String phoneNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProfileHeader(username, email),
              const SizedBox(height: 24),
              _buildAccountInfo(username, email, phoneNumber),
              const SizedBox(height: 24),
              _buildProfileMenu(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildStatistics(),
              const SizedBox(height: 24),
              _buildAchievements(),
              const SizedBox(height: 24),
              _buildSubscriptionInfo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String username, String email, String phoneNumber) {
    return Column(
      children: [
        _buildProfileHeader(username, email),
        const SizedBox(height: 24),
        _buildAccountInfo(username, email, phoneNumber),
        const SizedBox(height: 24),
        _buildStatistics(),
        const SizedBox(height: 24),
        _buildAchievements(),
        const SizedBox(height: 24),
        _buildSubscriptionInfo(),
        const SizedBox(height: 24),
        _buildProfileMenu(),
      ],
    );
  }

  // Replace the _buildProfileHeader method with this updated version
  Widget _buildProfileHeader(String username, String email) {
    return CustomCard(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Cover image
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withBlue(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                // Add change profile image button to the top right corner of the header
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _showImageSourceDialog();
                      },
                      tooltip: 'Change profile picture',
                    ),
                  ),
                ),
              ),
              // Profile image
              Positioned(
                bottom: -40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildProfileAvatar(username),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // User info
          Text(
            username,
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active Member',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String username) {
    if (_isUploadingImage) {
      return const CircularProgressIndicator();
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child:
          FadeInImage.assetNetwork(
            placeholder: "assets/images/avatar_placeholder.png",
            image: _profileImageUrl!,
            fit: BoxFit.cover,
            placeholderFit: BoxFit.cover, // Ensure the placeholder also fits properly
            fadeInDuration: const Duration(milliseconds: 300),
            imageErrorBuilder: (context, error, stackTrace) {
              print('Error loading profile image: $error');
              return _buildDefaultAvatar(username);
            },
          ),
        ),
      );
    }

    return _buildDefaultAvatar(username);
  }

  Widget _buildDefaultAvatar(String username) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      child: Text(
        username.isNotEmpty ? _getInitials(username) : 'U',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildAccountInfo(String username, String email, String phoneNumber) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Account Information',
            subtitle: 'Your personal account details',
          ),
          _buildInfoRow(
            Icons.person_outline,
            'Full Name',
            username,
          ),
          const Divider(),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            email,
          ),
          const Divider(),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            phoneNumber,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Edit Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isPrimary: false,
            icon: Icons.edit_outlined,
            disabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: AppTheme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Performance Statistics',
            subtitle: 'Your activity and progress summary',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle(
                'Completed\nTryouts',
                '12',
                0.6,
                AppTheme.primaryColor,
              ),
              _buildStatCircle(
                'Average\nScore',
                '81.5',
                0.82,
                Colors.amber.shade700,
              ),
              _buildStatCircle(
                'Hours\nSpent',
                '28',
                0.45,
                AppTheme.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Performance',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildPerformanceItem(
                'TWK - Tryout 1',
                0.75,
                '75%',
                'Jan 15, 2025',
                Colors.blue.shade700,
              ),
              const SizedBox(height: 12),
              _buildPerformanceItem(
                'TIU - Tryout 2',
                0.68,
                '68%',
                'Jan 20, 2025',
                Colors.orange.shade700,
              ),
              const SizedBox(height: 12),
              _buildPerformanceItem(
                'TKP - Tryout 1',
                0.89,
                '89%',
                'Jan 25, 2025',
                Colors.purple.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(
      String label, String value, double percent, Color color) {
    return CircularPercentIndicator(
      radius: 40.0,
      lineWidth: 8.0,
      animation: true,
      percent: percent,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodySmall,
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildPerformanceItem(
    String title,
    double progress,
    String percentage,
    String date,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: AppTheme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                animation: true,
                lineHeight: 10.0,
                animationDuration: 2000,
                percent: progress,
                barRadius: const Radius.circular(5),
                progressColor: color,
                backgroundColor: Colors.grey.shade200,
                trailing: Text(
                  percentage,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Viewing details for $title'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Achievements',
            subtitle: 'Badges and milestones earned',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAchievementBadge(
                  icon: Icons.school,
                  title: 'Quick Learner',
                  description: 'Completed 5 modules in a day',
                  color: Colors.blue.shade700,
                ),
                _buildAchievementBadge(
                  icon: Icons.timer,
                  title: 'Speed Demon',
                  description: 'Finished tryout 30% faster',
                  color: Colors.orange.shade700,
                ),
                _buildAchievementBadge(
                  icon: Icons.star,
                  title: 'Perfect Score',
                  description: 'Got 100% on TWK module',
                  color: Colors.purple.shade700,
                  isLocked: false,
                ),
                _buildAchievementBadge(
                  icon: Icons.psychology,
                  title: 'TIU Master',
                  description: 'Score 90%+ on 3 TIU tests',
                  color: Colors.grey.shade600,
                  isLocked: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isLocked = false,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color:
                      isLocked ? Colors.grey.shade300 : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isLocked ? Colors.grey.shade500 : color,
                  size: 32,
                ),
              ),
              if (isLocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isLocked ? Colors.grey : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isLocked ? Colors.grey : AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    return CustomCard(
      backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Subscription Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade700,
                  Colors.orange.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade700.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Premium Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Icon(
                      Icons.diamond_outlined,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Valid until March 15, 2025',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Unlimited access to all tryout packages',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Personalized performance analytics',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Renew Plan',
                  isPrimary: false,
                  disabled: false,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Renewal page coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Account Settings',
            subtitle: 'Manage your profile and settings',
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Learning History',
            subtitle: 'View your past learning activities',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Learning history will be available soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Notification settings will be available soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs and support resources',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Help & Support section will be available soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            onTap: _showLogoutConfirmation,
            isLast: true,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
    bool isDestructive = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? AppTheme.errorColor
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDestructive
                              ? AppTheme.errorColor.withOpacity(0.8)
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDestructive
                      ? AppTheme.errorColor
                      : AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(),
      ],
    );
  }


}
