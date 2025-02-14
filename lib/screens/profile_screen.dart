import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nama Pengguna',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      children: [
        _buildMenuItem('Edit Profil', Icons.edit),
        _buildMenuItem('Riwayat Latihan', Icons.history),
        _buildMenuItem('Pengaturan', Icons.settings),
        _buildMenuItem('Bantuan', Icons.help),
        _buildMenuItem('Keluar', Icons.exit_to_app),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Handle menu item tap
      },
    );
  }
}