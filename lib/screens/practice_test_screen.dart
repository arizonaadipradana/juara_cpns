import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/practice_package_model.dart';
import 'package:juara_cpns/class/tryout_package_model.dart';
import 'package:juara_cpns/screens/payment_screen.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';
import 'package:juara_cpns/widgets/section_header.dart';
import 'package:shimmer/shimmer.dart';

class PracticeTestScreen extends StatefulWidget {
  const PracticeTestScreen({super.key});

  @override
  State<PracticeTestScreen> createState() => _PracticeTestScreenState();
}

class _PracticeTestScreenState extends State<PracticeTestScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  final TryoutPackageService _packageService = TryoutPackageService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 500 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 500 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  Stream<List<PracticePackage>> _getPackagesByType(String type) {
    return FirebaseFirestore.instance
        .collection('practice_packages')
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PracticePackage.fromMap(doc.data(), doc.id))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Latihan Soal'),
        elevation: 0,
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
        mini: true,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.arrow_upward),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic if needed
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: ResponsiveBuilder(
          builder: (context, constraints, screenSize) {
            return screenSize.isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Tryout packages
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Paket Tryout Lengkap',
                  subtitle: 'Latihan soal dengan format ujian sebenarnya',
                ),
                _buildTryoutPackageSection(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column - Practice sections by category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Latihan per Kategori',
                  subtitle: 'Fokus pada area yang perlu ditingkatkan',
                ),
                _buildPracticeSection(
                  title: 'TWK - Tes Wawasan Kebangsaan',
                  type: 'TWK',
                  color: Colors.blue.shade700,
                  icon: Icons.public,
                ),
                const SizedBox(height: 24),
                _buildPracticeSection(
                  title: 'TIU - Tes Intelegensi Umum',
                  type: 'TIU',
                  color: Colors.orange.shade700,
                  icon: Icons.psychology,
                ),
                const SizedBox(height: 24),
                _buildPracticeSection(
                  title: 'TKP - Tes Karakteristik Pribadi',
                  type: 'TKP',
                  color: Colors.purple.shade700,
                  icon: Icons.person_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Paket Tryout Lengkap',
            subtitle: 'Latihan soal dengan format ujian sebenarnya',
          ),
          _buildTryoutPackageSection(),
          const SizedBox(height: 24),

          const SectionHeader(
            title: 'Latihan per Kategori',
            subtitle: 'Fokus pada area yang perlu ditingkatkan',
          ),
          _buildPracticeSection(
            title: 'TWK - Tes Wawasan Kebangsaan',
            type: 'TWK',
            color: Colors.blue.shade700,
            icon: Icons.public,
          ),
          const SizedBox(height: 24),
          _buildPracticeSection(
            title: 'TIU - Tes Intelegensi Umum',
            type: 'TIU',
            color: Colors.orange.shade700,
            icon: Icons.psychology,
          ),
          const SizedBox(height: 24),
          _buildPracticeSection(
            title: 'TKP - Tes Karakteristik Pribadi',
            type: 'TKP',
            color: Colors.purple.shade700,
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTryoutPackageSection() {
    return StreamBuilder<List<TryoutPackage>>(
      stream: _packageService.getTryoutPackages(),
      builder: (BuildContext context, AsyncSnapshot<List<TryoutPackage>> snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPackages();
        }

        final packages = snapshot.data ?? [];

        if (packages.isEmpty) {
          return _buildEmptyPackages();
        }

        return ResponsiveBuilder(
          builder: (context, constraints, screenSize) {
            if (screenSize.isDesktop) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  return _buildTryoutPackageCard(context, packages[index]);
                },
              );
            } else {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTryoutPackageCard(context, packages[index]),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingPackages() {
    return ResponsiveBuilder(
      builder: (context, constraints, screenSize) {
        if (screenSize.isDesktop) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildShimmerCard();
            },
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildShimmerCard(),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CustomCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fix for the unbounded height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24), // Fixed height instead of Spacer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPackages() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada paket tersedia',
              style: AppTheme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Paket tryout akan segera hadir. Silakan cek kembali nanti.',
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: AppTheme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Coba Lagi',
              onPressed: () {
                setState(() {});
              },
              isPrimary: false,
              isFullWidth: false,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryoutPackageCard(BuildContext context, TryoutPackage package) {
    final questions = package.questions;

    // Calculate total questions
    final totalQuestions = questions.values.fold<int>(0, (sum, count) => sum + count);

    return CustomCard(
      onTap: () {
        if (package.isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                package: package.toPracticePackage(),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TryoutScreen(
                type: 'FULL',
                packageId: package.id,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fix for the unbounded height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge for premium or free packages
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: package.isLocked
                    ? Colors.amber.shade700
                    : AppTheme.successColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                package.isLocked ? 'PREMIUM' : 'GRATIS',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Package title
            Text(
              package.name,
              style: AppTheme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Package description
            Text(
              package.description,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16), // Fixed spacing instead of Spacer
            // Package details
            // Question details by type
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuestionTypeChip('TWK', questions['TWK'] ?? 0, Colors.blue.shade700),
                _buildQuestionTypeChip('TIU', questions['TIU'] ?? 0, Colors.orange.shade700),
                _buildQuestionTypeChip('TKP', questions['TKP'] ?? 0, Colors.purple.shade700),
              ],
            ),
            const SizedBox(height: 12),
            // Duration and total questions
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${package.duration} menit',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalQuestions soal',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (package.isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Rp${package.price}',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Action button
            CustomButton(
              text: package.isLocked ? 'Beli Sekarang' : 'Mulai Tryout',
              isPrimary: true,
              isFullWidth: true,
              icon: package.isLocked ? Icons.shopping_cart_outlined : Icons.play_arrow_outlined,
              onPressed: () {
                if (package.isLocked) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        package: package.toPracticePackage(),
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TryoutScreen(
                        type: 'FULL',
                        packageId: package.id,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeChip(String type, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$type: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPracticeSection({
    required String title,
    required String type,
    required Color color,
    required IconData icon,
  }) {
    return CustomCard(
      backgroundColor: color.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTheme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<PracticePackage>>(
            stream: _getPackagesByType(type),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPractices();
              }

              final packages = snapshot.data ?? [];

              if (packages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Belum ada paket tersedia'),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  return _buildPracticeItem(context, package, color);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPractices() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              width: 200,
              height: 12,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: Container(
              width: 60,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPracticeItem(BuildContext context, PracticePackage package, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to TryoutScreen or PaymentScreen based on isLocked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => package.isLocked
                  ? PaymentScreen(package: package)
                  : TryoutScreen(
                type: package.type,
                packageId: package.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 24,
                child: Icon(
                  Icons.assignment_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.title,
                      style: AppTheme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${package.questionCount} Soal • Durasi ${package.duration} Menit',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (package.isLocked)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp${package.price}',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'GRATIS',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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