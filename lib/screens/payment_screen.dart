// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:juara_cpns/class/practice_package_model.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';

class PaymentScreen extends StatefulWidget {
  final PracticePackage package;

  const PaymentScreen({
    super.key,
    required this.package,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'bca';
  bool isProcessing = false;

  final paymentMethods = [
    {'id': 'bca', 'name': 'BCA Virtual Account', 'logo': 'assets/bca_logo.png'},
    {'id': 'bni', 'name': 'BNI Virtual Account', 'logo': 'assets/bni_logo.png'},
    {'id': 'mandiri', 'name': 'Mandiri Virtual Account', 'logo': 'assets/mandiri_logo.png'},
  ];

  Future<void> processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create payment record
      final payment = await FirebaseFirestore.instance
          .collection('payments')
          .add({
        'userId': user.uid,
        'packageId': widget.package.id,
        'amount': widget.package.price,
        'status': 'pending',
        'paymentMethod': selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In a real app, you would integrate with a payment gateway here
      // For demo purposes, we'll simulate a successful payment
      await Future.delayed(const Duration(seconds: 2));

      // Update payment status
      await payment.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Give access to the package
      await FirebaseFirestore.instance
          .collection('user_packages')
          .add({
        'userId': user.uid,
        'packageId': widget.package.id,
        'purchasedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Pembayaran Berhasil'),
            content: const Text('Selamat! Anda telah berhasil membeli paket tryout ini.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TryoutScreen(
                        type: widget.package.type,
                        packageId: widget.package.id,
                      ),
                    ),
                  );
                },
                child: const Text('Mulai Tryout'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Pembayaran:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp${widget.package.price}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.map((method) => RadioListTile(
              value: method['id'],
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value.toString();
                });
              },
              title: Row(
                children: [
                  const Icon(Icons.account_balance, size: 32),
                  const SizedBox(width: 12),
                  Text(method['name']!),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isProcessing
                    ? const CircularProgressIndicator()
                    : const Text(
                  'Bayar Sekarang',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}