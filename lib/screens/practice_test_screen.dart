import 'package:flutter/material.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';

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
          _buildTestCategory(context, 'TWK - Tes Wawasan Kebangsaan', 'TWK'),
          _buildTestCategory(context, 'TIU - Tes Intelegensi Umum', 'TIU'),
          _buildTestCategory(context, 'TKP - Tes Karakteristik Pribadi', 'TKP'),
          _buildTestCategory(context, 'Tryout Lengkap', 'FULL'),
        ],
      ),
    );
  }

  Widget _buildTestCategory(BuildContext context, String title, String type) {
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TryoutScreen(type: type)));
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
