import 'package:flutter/foundation.dart';
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
  String promoCode = '';
  int? promoDiscount;
  bool isValidatingPromo = false;
  String? promoError;

  final paymentMethods = [
    {'id': 'bca', 'name': 'BCA Virtual Account', 'logo': 'assets/bca_logo.png'},
    {'id': 'bni', 'name': 'BNI Virtual Account', 'logo': 'assets/bni_logo.png'},
    {'id': 'mandiri', 'name': 'Mandiri Virtual Account', 'logo': 'assets/mandiri_logo.png'},
  ];

  // Calculate final price after discount
  int get finalPrice {
    if (promoDiscount == null) return widget.package.price;
    return widget.package.price - promoDiscount!;
  }

  Future<void> validatePromoCode() async {
    if (promoCode.isEmpty) return;

    setState(() {
      isValidatingPromo = true;
      promoError = null;
      promoDiscount = null;
    });

    try {
      if (kDebugMode) {
        print('Validating promo code: $promoCode');
      }

      final promoSnapshot = await FirebaseFirestore.instance
          .collection('promos')
          .where('code', isEqualTo: promoCode.trim().toUpperCase())
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: Timestamp.now())
          .get();

      if (kDebugMode) {
        print('Found ${promoSnapshot.docs.length} matching promos');
      } // For debugging

      if (promoSnapshot.docs.isEmpty) {
        setState(() {
          promoError = 'Kode promo tidak valid atau sudah kadaluarsa';
        });
        return;
      }

      final promoData = promoSnapshot.docs.first.data();

      // Verify the data type and cast safely
      final discountAmount = promoData['discountAmount'];
      if (discountAmount is! int) {
        throw Exception('Invalid discount amount type: ${discountAmount.runtimeType}');
      }

      setState(() {
        promoDiscount = discountAmount;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode promo berhasil digunakan!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error validating promo: $e');
      } // For debugging
      setState(() {
        promoError = 'Gagal memvalidasi kode promo. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        isValidatingPromo = false;
      });
    }
  }

  Future<void> processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final payment = await FirebaseFirestore.instance
          .collection('payments')
          .add({
        'userId': user.uid,
        'packageId': widget.package.id,
        'originalAmount': widget.package.price,
        'promoCode': promoCode.isNotEmpty ? promoCode : null,
        'promoDiscount': promoDiscount,
        'finalAmount': finalPrice,
        'status': 'pending',
        'paymentMethod': selectedPaymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Simulate payment processing
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Pembayaran Berhasil'),
            content: const Text('Selamat! Anda telah berhasil membeli paket tryout ini.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
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
                    if (promoDiscount != null) ...[
                      Text(
                        'Rp${widget.package.price}',
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Rp$finalPrice',
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
            // Promo code section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kode Promo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                promoCode = value;
                                promoError = null;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Masukkan kode promo',
                              errorText: promoError,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isValidatingPromo ? null : validatePromoCode,
                          child: isValidatingPromo
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Gunakan'),
                        ),
                      ],
                    ),
                    if (promoDiscount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Potongan: Rp$promoDiscount',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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