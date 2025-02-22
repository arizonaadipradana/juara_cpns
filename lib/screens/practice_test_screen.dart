import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/practice_package_model.dart';
import 'package:juara_cpns/screens/payment_screen.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';

class PracticeTestScreen extends StatelessWidget {
  const PracticeTestScreen({super.key});

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

  Stream<DocumentSnapshot> _getTryoutPackage(String packageId) {
    return FirebaseFirestore.instance
        .collection('tryout_packages')
        .doc(packageId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Soal'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic if needed
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildPracticeSection(
              title: 'TWK - Tes Wawasan Kebangsaan',
              type: 'TWK',
            ),
            _buildPracticeSection(
              title: 'TIU - Tes Intelegensi Umum',
              type: 'TIU',
            ),
            _buildPracticeSection(
              title: 'TKP - Tes Karakteristik Pribadi',
              type: 'TKP',
            ),
            const Divider(height: 32),
            const Text(
              'Paket Tryout Lengkap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPackageSection( type: "paket-1"),
            _buildPackageSection(type: "paket-2")
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSection({
    required String type,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StreamBuilder<DocumentSnapshot>(
            stream: _getTryoutPackage(type),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Paket tidak tersedia'));
              }

              final packageData =
              snapshot.data!.data() as Map<String, dynamic>;
              return _buildPackageCard(context, packageData);
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildPracticeSection({
    required String title,
    required String type,
  }) {
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
            StreamBuilder<List<PracticePackage>>(
              stream: _getPackagesByType(type),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final packages = snapshot.data ?? [];

                if (packages.isEmpty) {
                  return const Center(
                    child: Text('Belum ada paket tersedia'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment),
                      ),
                      title: Text(package.title),
                      subtitle: Text(
                        '${package.questionCount} Soal • Durasi ${package.duration} Menit',
                      ),
                      trailing: package.isLocked
                          ? Text('Rp${package.price}')
                          : const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to TryoutScreen or PaymentScreen based on isLocked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => package.isLocked
                                ? PaymentScreen(package: package)
                                : TryoutScreen(
                                    type: type,
                                    packageId: package.id,
                                  ),
                          ),
                        );
                      },
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

  Widget _buildPackageCard(
      BuildContext context, Map<String, dynamic> packageData) {
    final questions = packageData['questions'] as Map<String, dynamic>;

    // Create a PracticePackage instance from the package data
    final package = PracticePackage(
      id: packageData['id'] ?? '',
      title: packageData['name'] ?? 'Paket Tryout',
      type: 'FULL',
      questionCount: (questions['TWK'] ?? 0) +
          (questions['TIU'] ?? 0) +
          (questions['TKP'] ?? 0),
      duration: packageData['duration'] ?? 0,
      isLocked: packageData['isLocked'] ?? true,
      price: packageData['price'] ?? 0,
      order: packageData['order'] ?? 0,
      isActive: packageData['isActive'] ?? true,
      lastUpdated: (packageData['lastUpdated'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              packageData['name'] ?? 'Paket Tryout',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(packageData['description'] ?? ''),
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
                      Text('Durasi: ${packageData['duration']} menit'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (packageData['isLocked'] == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            package:
                                package, // Pass the PracticePackage instead of Map
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TryoutScreen(
                            type: 'FULL',
                            packageId: packageData['id'],
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    packageData['isLocked'] == true
                        ? 'Beli Rp${packageData['price']}'
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
