import 'package:flutter/material.dart';

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
