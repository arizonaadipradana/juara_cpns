import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';
import 'package:juara_cpns/screens/payment_screen.dart';

class PracticeTestScreen extends StatelessWidget {
  const PracticeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Soal'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Changed from StreamBuilder to FutureBuilder and fetch specific document
        future: FirebaseFirestore.instance
            .collection('tryout_packages')
            .doc('paket-1')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Paket tidak tersedia'));
          }

          final packageData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSingleTypeTests(context, 'TWK - Tes Wawasan Kebangsaan', 'TWK'),
              _buildSingleTypeTests(context, 'TIU - Tes Intelegensi Umum', 'TIU'),
              _buildSingleTypeTests(context, 'TKP - Tes Karakteristik Pribadi', 'TKP'),
              const Divider(height: 32),
              const Text(
                'Paket Tryout Lengkap',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPackageCard(context, packageData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSingleTypeTests(BuildContext context, String title, String type) {
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
                        builder: (context) => TryoutScreen(
                          type: type,
                          packageId: null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, Map<String, dynamic> package) {
    final questions = package['questions'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package['name'] ?? 'Paket Tryout',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(package['description'] ?? ''),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TWK: ${questions['TWK']} soal'),
                      Text('TIU: ${questions['TIU']} soal'),
                      Text('TKP: ${questions['TKP']} soal'),
                      Text('Durasi: ${package['duration']} menit'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (package['isLocked'] == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            package: package,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TryoutScreen(
                            type: 'FULL',
                            packageId: package['id'],
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    package['isLocked'] == true
                        ? 'Beli Rp${package['price']}'
                        : 'Mulai',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}