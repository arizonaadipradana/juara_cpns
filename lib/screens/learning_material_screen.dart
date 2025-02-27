import 'package:flutter/material.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LearningMaterialScreen extends StatefulWidget {
  const LearningMaterialScreen({super.key});

  @override
  State<LearningMaterialScreen> createState() => _LearningMaterialScreenState();
}

class _LearningMaterialScreenState extends State<LearningMaterialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: AppTheme.textTheme.titleMedium,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'TWK'),
            Tab(text: 'TIU'),
            Tab(text: 'TKP'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTWKContent(),
          _buildTIUContent(),
          _buildTKPContent(),
        ],
      ),
    );
  }

  Widget _buildTWKContent() {
    final twkMaterials = [
      {
        'title': 'Pancasila',
        'description': 'Mempelajari sejarah dan nilai-nilai Pancasila',
        'progress': 0.85,
        'image': 'assets/images/pancasila.png',
        'items': 12,
      },
      {
        'title': 'UUD 1945',
        'description': 'Memahami dasar-dasar konstitusi negara',
        'progress': 0.7,
        'image': 'assets/images/constitution.png',
        'items': 15,
      },
      {
        'title': 'Sejarah Indonesia',
        'description': 'Perjalanan sejarah dan perjuangan bangsa',
        'progress': 0.5,
        'image': 'assets/images/history.png',
        'items': 20,
      },
      {
        'title': 'Sistem Pemerintahan',
        'description': 'Struktur dan fungsi lembaga negara',
        'progress': 0.3,
        'image': 'assets/images/government.png',
        'items': 18,
      },
      {
        'title': 'Bela Negara',
        'description': 'Konsep dan implementasi bela negara',
        'progress': 0.1,
        'image': 'assets/images/patriotism.png',
        'items': 10,
      },
    ];

    return _buildMaterialList(twkMaterials, Colors.blue.shade700);
  }

  Widget _buildTIUContent() {
    final tiuMaterials = [
      {
        'title': 'Verbal Analogi',
        'description': 'Memahami hubungan antar kata dan konsep',
        'progress': 0.65,
        'image': 'assets/images/verbal.png',
        'items': 14,
      },
      {
        'title': 'Numerik',
        'description': 'Perhitungan matematika dan analisis numerik',
        'progress': 0.4,
        'image': 'assets/images/math.png',
        'items': 16,
      },
      {
        'title': 'Logika',
        'description': 'Penalaran dan pemecahan masalah logis',
        'progress': 0.55,
        'image': 'assets/images/logic.png',
        'items': 18,
      },
      {
        'title': 'Spasial',
        'description': 'Pemahaman relasi spasial dan visual',
        'progress': 0.3,
        'image': 'assets/images/spatial.png',
        'items': 12,
      },
      {
        'title': 'Figural',
        'description': 'Analisis pola figur dan gambar',
        'progress': 0.2,
        'image': 'assets/images/figure.png',
        'items': 15,
      },
    ];

    return _buildMaterialList(tiuMaterials, Colors.orange.shade700);
  }

  Widget _buildTKPContent() {
    final tkpMaterials = [
      {
        'title': 'Pelayanan Publik',
        'description': 'Etika dan standar pelayanan kepada masyarakat',
        'progress': 0.9,
        'image': 'assets/images/service.png',
        'items': 10,
      },
      {
        'title': 'Sosial Budaya',
        'description': 'Pemahaman keragaman sosial budaya',
        'progress': 0.6,
        'image': 'assets/images/culture.png',
        'items': 12,
      },
      {
        'title': 'Profesionalisme',
        'description': 'Integritas dan profesionalisme ASN',
        'progress': 0.8,
        'image': 'assets/images/professional.png',
        'items': 15,
      },
      {
        'title': 'Jejaring Kerja',
        'description': 'Kemampuan membangun dan memelihara relasi',
        'progress': 0.4,
        'image': 'assets/images/networking.png',
        'items': 8,
      },
      {
        'title': 'Pengambilan Keputusan',
        'description': 'Strategi dan metode pengambilan keputusan',
        'progress': 0.5,
        'image': 'assets/images/decision.png',
        'items': 14,
      },
    ];

    return _buildMaterialList(tkpMaterials, Colors.purple.shade700);
  }

  Widget _buildMaterialList(List<Map<String, dynamic>> materials, Color accentColor) {
    return ResponsiveBuilder(
      builder: (context, constraints, screenSize) {
        return screenSize.isDesktop
            ? GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            return _buildMaterialCard(materials[index], accentColor);
          },
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMaterialCard(materials[index], accentColor),
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material, Color accentColor) {
    final title = material['title'] as String;
    final description = material['description'] as String;
    final progress = material['progress'] as double;
    final imagePath = material['image'] as String;
    final items = material['items'] as int;

    return CustomCard(
      onTap: () {
        _showMaterialDetail(material, accentColor);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 30,
                    height: 30,
                    color: accentColor,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.book,
                      color: accentColor,
                      size: 30,
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
                      style: AppTheme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  lineHeight: 8.0,
                  animation: true,
                  animationDuration: 1000,
                  percent: progress,
                  barRadius: const Radius.circular(4),
                  progressColor: accentColor,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$items modul',
            style: AppTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showMaterialDetail(Map<String, dynamic> material, Color accentColor) {
    final title = material['title'] as String;
    final description = material['description'] as String;

    // Mock data for sub-materials
    final subMaterials = [
      'Pengantar ${title}',
      'Konsep Dasar ${title}',
      'Studi Kasus ${title}',
      'Penerapan ${title} dalam Soal',
      'Latihan Soal ${title}',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.book,
                        color: accentColor,
                        size: 32,
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
                          style: AppTheme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Sub-materials list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: subMaterials.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: accentColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(subMaterials[index]),
                      subtitle: Text(
                        index < 3 ? 'Selesai' : 'Belum selesai',
                        style: TextStyle(
                          color: index < 3 ? AppTheme.successColor : Colors.grey,
                        ),
                      ),
                      trailing: Icon(
                        index < 3 ? Icons.check_circle : Icons.arrow_forward_ios,
                        color: index < 3 ? AppTheme.successColor : Colors.grey,
                      ),
                      onTap: () {
                        // Navigate to detailed material
                        Navigator.pop(context);
                        _showSnackBar('Membuka materi "${subMaterials[index]}"');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}