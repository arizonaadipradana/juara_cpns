import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juara CPNS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang di Juara CPNS!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatisticsCard(),
            const SizedBox(height: 20),
            _buildFeatureGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Belajar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Soal Dikerjakan', '150'),
                _buildStatItem('Akurasi', '75%'),
                _buildStatItem('Waktu Belajar', '10 jam'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildFeatureCard(
          context,
          'Tryout CPNS',
          'Latihan soal lengkap',
          Icons.assignment,
          Colors.blue,
        ),
        _buildFeatureCard(
          context,
          'Materi TWK',
          'Tes Wawasan Kebangsaan',
          Icons.book,
          Colors.green,
        ),
        _buildFeatureCard(
          context,
          'Materi TIU',
          'Tes Intelegensi Umum',
          Icons.psychology,
          Colors.orange,
        ),
        _buildFeatureCard(
          context,
          'Materi TKP',
          'Tes Karakteristik Pribadi',
          Icons.person_outline,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to feature
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PracticeTestScreen extends StatelessWidget {
  const PracticeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Soal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTestCategory('TWK - Tes Wawasan Kebangsaan'),
          _buildTestCategory('TIU - Tes Intelegensi Umum'),
          _buildTestCategory('TKP - Tes Karakteristik Pribadi'),
          _buildTestCategory('Tryout Lengkap'),
        ],
      ),
    );
  }

  Widget _buildTestCategory(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment),
                  ),
                  title: Text('Paket ${index + 1}'),
                  subtitle: const Text('30 Soal • Durasi 30 Menit'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to test
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class LearningMaterialScreen extends StatelessWidget {
  const LearningMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Pembelajaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMaterialCategory(
            'TWK - Tes Wawasan Kebangsaan',
            [
              'Pancasila',
              'UUD 1945',
              'Sejarah Indonesia',
              'Sistem Pemerintahan',
            ],
          ),
          _buildMaterialCategory(
            'TIU - Tes Intelegensi Umum',
            [
              'Verbal Analogi',
              'Numerik',
              'Logika',
              'Spasial',
            ],
          ),
          _buildMaterialCategory(
            'TKP - Tes Karakteristik Pribadi',
            [
              'Pelayanan Publik',
              'Sosial Budaya',
              'Profesionalisme',
              'Jejaring Kerja',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCategory(String title, List<String> subjects) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: subjects.map((subject) {
          return ListTile(
            leading: const Icon(Icons.book),
            title: Text(subject),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to material detail
            },
          );
        }).toList(),
      ),
    );
  }
}