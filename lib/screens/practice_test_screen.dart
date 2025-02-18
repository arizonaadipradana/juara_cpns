import 'package:flutter/material.dart';

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