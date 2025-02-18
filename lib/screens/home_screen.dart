import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Halo!');
            }
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final username = userData?['username'] ?? 'Hello!';
            return Text(
              'Hello, $username!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 20),
                  _buildFeatureGrid(context),
                ],
              ),
            );
          },
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
                Expanded(child: _buildStatItem('Soal Dikerjakan', '150')),
                Expanded(child: _buildStatItem('Akurasi', '75%')),
                Expanded(child: _buildStatItem('Waktu Belajar', '10 jam')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Add this to prevent vertical overflow
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4), // Add spacing between value and label
        Text(
          label,
          textAlign: TextAlign.center, // Center align multi-line text
          style: const TextStyle(fontSize: 12), // Reduce font size
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      childAspectRatio: isTablet ? 1.5 : 1.5,
      // Increased ratio to prevent overflow
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        SingleChildScrollView(
            child: _buildFeatureCard(
          context,
          'Tryout CPNS',
          'Latihan soal lengkap',
          Icons.assignment,
          Colors.blue,
        )),
        SingleChildScrollView(
            child: _buildFeatureCard(
          context,
          'Materi TWK',
          'Tes Wawasan Kebangsaan',
          Icons.book,
          Colors.green,
        )),
        SingleChildScrollView(
          child: _buildFeatureCard(
            context,
            'Materi TIU',
            'Tes Intelegensi Umum',
            Icons.psychology,
            Colors.orange,
          ),
        ),
        SingleChildScrollView(
          child: _buildFeatureCard(
            context,
            'Materi TKP',
            'Tes Karakteristik Pribadi',
            Icons.person_outline,
            Colors.purple,
          ),
        )
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
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            // Add this to prevent vertical overflow
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
                  fontSize: 14, // Slightly reduced font size
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Consistent spacing
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
