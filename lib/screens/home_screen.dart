import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/screens/learning_material_screen.dart';
import 'package:juara_cpns/screens/practice_test_screen.dart';
import 'package:juara_cpns/screens/profile_screen.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';
import 'package:juara_cpns/widgets/section_header.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.2,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('Halo!');
                            }
                            final userData = snapshot.data?.data() as Map<String, dynamic>?;
                            final username = userData?['username'] ?? 'Peserta';
                            return Text(
                              'Halo, $username!',
                              style: AppTheme.textTheme.headlineMedium,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ];
          },
          body: ResponsiveBuilder(
            builder: (context, constraints, screenSize) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 16.0 + bottomPadding,
                ),
                child: screenSize.isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressOverview(),
              const SizedBox(height: 24),
              _buildUpcomingEvents(),
              const SizedBox(height: 24),
              _buildQuickAccess(context),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right column
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatisticsCard(),
              const SizedBox(height: 24),
              _buildLearningPath(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressOverview(),
        const SizedBox(height: 24),
        _buildStatisticsCard(),
        const SizedBox(height: 24),
        _buildQuickAccess(context),
        const SizedBox(height: 24),
        _buildUpcomingEvents(),
        const SizedBox(height: 24),
        _buildLearningPath(),
      ],
    );
  }

  Widget _buildProgressOverview() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Progres Belajar',
                style: AppTheme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            animation: true,
            lineHeight: 12.0,
            animationDuration: 2000,
            percent: 0.68,
            barRadius: const Radius.circular(6),
            progressColor: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TWK'),
              Text('68%'),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            animation: true,
            lineHeight: 12.0,
            animationDuration: 2000,
            percent: 0.42,
            barRadius: const Radius.circular(6),
            progressColor: AppTheme.secondaryColor,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TIU'),
              Text('42%'),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            animation: true,
            lineHeight: 12.0,
            animationDuration: 2000,
            percent: 0.75,
            barRadius: const Radius.circular(6),
            progressColor: AppTheme.accentColor,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TKP'),
              Text('75%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistik Belajar',
                style: AppTheme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle('Soal Dikerjakan', '150', 0.75, AppTheme.primaryColor),
              _buildStatCircle('Akurasi', '75%', 0.75, AppTheme.successColor),
              _buildStatCircle('Waktu', '10h', 0.6, AppTheme.secondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, double percent, Color color) {
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
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
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

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Akses Cepat',
          subtitle: 'Materi persiapan ujian CPNS',
        ),
        ResponsiveBuilder(
          builder: (context, constraints, screenSize) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: screenSize.isDesktop ? 3 : (screenSize.isTablet ? 2 : 2),
              childAspectRatio: 1.1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  'Tryout CPNS',
                  'Latihan soal lengkap dengan pembahasan',
                  'assets/images/exam.png',
                  const Color(0xFF5E60CE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PracticeTestScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  'Materi TWK',
                  'Tes Wawasan Kebangsaan',
                  'images/indonesia.svg',
                  const Color(0xFF64DFDF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningMaterialScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  'Materi TIU',
                  'Tes Intelegensi Umum',
                  'images/brain.svg',
                  const Color(0xFFFF5C8D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningMaterialScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  'Materi TKP',
                  'Tes Karakteristik Pribadi',
                  'images/personality.svg',
                  const Color(0xFFFFBD69),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningMaterialScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
      BuildContext context,
      String title,
      String subtitle,
      String imagePath,
      Color color, {
        VoidCallback? onTap,
      }) {
    return CustomCard(
      padding: const EdgeInsets.all(0),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Coming Soon',
                style: AppTheme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEventItem(
            'Tryout SKD CPNS Nasional',
            'Minggu, 15 Mar 2025 • 09:00 WIB',
            '4 hari lagi',
          ),
          const SizedBox(height: 16),
          _buildEventItem(
            'Webinar Strategi Lolos CPNS 2025',
            'Sabtu, 21 Mar 2025 • 19:00 WIB',
            '10 hari lagi',
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String schedule, String countdown) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 65,
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                schedule,
                style: AppTheme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  countdown,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningPath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Learning Path',
          subtitle: 'Jalur belajar yang direkomendasikan untuk Anda',
        ),
        CustomCard(
          child: Column(
            children: [
              _buildLearningStepItem(
                1,
                'Memahami Dasar TWK',
                'Pancasila, UUD 1945, dan NKRI',
                true, // completed
              ),
              _buildLearningStepItem(
                2,
                'Strategi TIU',
                'Verbal, Numerik, dan Figural',
                true, // completed
              ),
              _buildLearningStepItem(
                3,
                'Teknik TKP',
                'Menjawab soal karakteristik pribadi',
                false, // not completed
              ),
              _buildLearningStepItem(
                4,
                'Latihan Soal SKD',
                'Mengerjakan soal dari tahun-tahun sebelumnya',
                false, // not completed
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStepItem(int step, String title, String description, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed ? AppTheme.successColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: completed
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
                  : Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed ? Colors.grey : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: completed ? Colors.grey : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}