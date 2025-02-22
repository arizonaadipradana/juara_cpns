import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:juara_cpns/class/practice_package_model.dart';
import 'package:juara_cpns/class/tryout_package_model.dart';
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

  Stream<List<TryoutPackage>> _getTryoutPackages() {
    return FirebaseFirestore.instance
        .collection('tryout_packages')
        .snapshots()
        .map((snapshot) {
      print('Debug: Raw data: ${snapshot.docs.map((doc) => doc.data())}'); // Debug raw data
      return snapshot.docs
          .map((doc) => TryoutPackage.fromMap(doc.data(), doc.id))
          .toList();
    });
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
            _buildPackageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSection() {
    return StreamBuilder<List<TryoutPackage>>(
      stream: _getTryoutPackages(),
      builder: (BuildContext context, AsyncSnapshot<List<TryoutPackage>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final packages = snapshot.data ?? [];

        if (packages.isEmpty) {
          print('Debug: No packages found. Snapshot data: ${snapshot.data}');
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Center(child: Text('Belum ada paket tersedia')),
                  Text('Status: ${snapshot.connectionState}'),
                ],
              ),
            ),
          );
        }

        return Column(
          children: packages
              .map((package) => _buildPackageCard(context, package))
              .toList(),
        );
      },
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
      BuildContext context, TryoutPackage package) {
    final questions = package.questions;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(package.description),
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
                      Text('Durasi: ${package.duration} menit'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (package.isLocked == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            package:
                                package.toPracticePackage(), // Pass the PracticePackage instead of Map
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
                  child: Text(
                    package.isLocked == true
                        ? 'Beli Rp${package.price}'
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
