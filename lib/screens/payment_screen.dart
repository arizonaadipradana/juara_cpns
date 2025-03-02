import 'dart:html' as html;
// Import untuk web
import 'dart:js' as js;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juara_cpns/class/app_router.dart';
import 'package:juara_cpns/class/platform_ui.dart';
import 'package:juara_cpns/class/practice_package_model.dart';
import 'package:juara_cpns/class/responsive_layout.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/widgets/custom_card.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

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
  String selectedPaymentMethod = 'bank_transfer';
  bool isProcessing = false;
  String promoCode = '';
  int? promoDiscount;
  bool isValidatingPromo = false;
  String? promoError;
  String? orderId;
  bool isPending = false;
  final TextEditingController _promoController = TextEditingController();

  // Daftar metode pembayaran Midtrans
  final paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'Kartu Kredit/Debit',
      'logo': 'assets/credit_card_logo.png',
      'color': const Color(0xFF1ABC9C),
      'icon': Icons.credit_card,
    },
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank (Virtual Account)',
      'logo': 'assets/bank_transfer_logo.png',
      'color': const Color(0xFF3498DB),
      'icon': Icons.account_balance,
    },
    {
      'id': 'gopay',
      'name': 'GoPay',
      'logo': 'assets/gopay_logo.png',
      'color': const Color(0xFF00AAD2),
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'shopeepay',
      'name': 'ShopeePay',
      'logo': 'assets/shopeepay_logo.png',
      'color': const Color(0xFFEE4D2D),
      'icon': Icons.shopping_bag,
    },
    {
      'id': 'qris',
      'name': 'QRIS',
      'logo': 'assets/qris_logo.png',
      'color': const Color(0xFF9B59B6),
      'icon': Icons.qr_code,
    },
  ];

  // Calculate final price after discount
  int get finalPrice {
    if (promoDiscount == null) return widget.package.price;
    int discountedPrice = widget.package.price - promoDiscount!;
    return discountedPrice > 0 ? discountedPrice : 0;
  }

  // Calculate discount percentage
  String get discountPercentage {
    if (promoDiscount == null) return "0%";
    double percentage = (promoDiscount! / widget.package.price) * 100;
    return "${percentage.toStringAsFixed(0)}%";
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadMidtransScript();
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat script Midtrans Snap.js
  void _loadMidtransScript() {
    if (js.context.hasProperty('snap')) return;

    final scriptElement = html.ScriptElement()
      ..src = 'https://app.sandbox.midtrans.com/snap/snap.js'
      ..type = 'text/javascript'
      ..defer = true;

    html.document.head!.append(scriptElement);

    // Register callback
    js.context['onPaymentResult'] = js.allowInterop((result) {
      _handlePaymentResult(result);
    });
  }

  // Fungsi untuk mendapatkan token SNAP dari backend
  Future<String> _getSnapToken(String orderId) async {
    // Pada implementasi sebenarnya, panggil API backend untuk mendapatkan token
    // Di sini kita hanya melakukan simulasi
    // Tunggu 1 detik untuk simulasi
    await Future.delayed(const Duration(seconds: 1));

    // Contoh token (Pada implementasi sebenarnya, token harus dari backend)
    return 'fake-snap-token-for-demo-${DateTime.now().millisecondsSinceEpoch}';
  }

  // Buka popup Midtrans SNAP
  void _openSnapPopup(String snapToken) {
    js.context.callMethod('snap.pay', [
      snapToken,
      {
        'onSuccess': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [
            {'status': 'success', 'data': result}
          ]);
        }),
        'onPending': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [
            {'status': 'pending', 'data': result}
          ]);
        }),
        'onError': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [
            {'status': 'error', 'data': result}
          ]);
        }),
        'onClose': js.allowInterop(() {
          js.context.callMethod('onPaymentResult', [
            {'status': 'closed'}
          ]);
        }),
      }
    ]);
  }

  // Tangani hasil pembayaran dari Midtrans
  void _handlePaymentResult(dynamic result) async {
    if (orderId == null) return;

    final status = result['status'];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cari dokumen pembayaran berdasarkan orderId
    final paymentSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .get();

    if (paymentSnapshot.docs.isEmpty) return;

    final paymentRef = paymentSnapshot.docs.first.reference;

    switch (status) {
      case 'success':
        // Update status pembayaran menjadi sukses
        await paymentRef.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'transactionData': result['data'],
        });

        // Berikan akses ke paket
        await FirebaseFirestore.instance.collection('user_packages').add({
          'userId': user.uid,
          'packageId': widget.package.id,
          'purchasedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
        });

        if (mounted) {
          setState(() {
            isProcessing = false;
            isPending = false;
          });

          showAnimatedDialog(
            title: 'Pembayaran Berhasil',
            message: 'Selamat! Anda telah berhasil membeli paket tryout ini.',
            onConfirm: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRouter.tryout,
                  arguments: {
                    'type': widget.package.type,
                    'packageId': widget.package.id,
                  });
            },
            confirmText: 'Mulai Tryout',
          );
        }
        break;

      case 'pending':
        // Update status pembayaran menjadi pending
        await paymentRef.update({
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
          'transactionData': result['data'],
        });

        if (mounted) {
          setState(() {
            isProcessing = false;
            isPending = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mohon selesaikan pembayaran Anda'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        break;

      case 'error':
      case 'closed':
        // Update status pembayaran menjadi gagal atau dibatalkan
        await paymentRef.update({
          'status': status == 'error' ? 'failed' : 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
          'errorData': status == 'error' ? result['data'] : null,
        });

        if (mounted) {
          setState(() {
            isProcessing = false;
            isPending = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'error'
                  ? 'Terjadi kesalahan dalam pembayaran'
                  : 'Pembayaran dibatalkan'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        break;
    }
  }

  // Validasi kode promo (sama seperti implementasi yang ada)
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

      if (promoSnapshot.docs.isEmpty) {
        setState(() {
          promoError = 'Kode promo tidak valid atau sudah kadaluarsa';
        });
        return;
      }

      final promoData = promoSnapshot.docs.first.data();
      final discountAmount = promoData['discountAmount'];

      if (discountAmount is! int) {
        throw Exception('Invalid discount amount type');
      }

      setState(() {
        promoDiscount = discountAmount;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Kode promo berhasil digunakan!',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(context.horizontalPadding),
          ),
        );
      }
    } catch (e) {
      setState(() {
        promoError = 'Gagal memvalidasi kode promo. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        isValidatingPromo = false;
      });
    }
  }

  // Proses pembayaran
  Future<void> processPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Buat ID order unik
      final String newOrderId =
          'JC-${DateTime.now().millisecondsSinceEpoch}-${user.uid.substring(0, 5)}';
      setState(() {
        orderId = newOrderId;
      });

      // Buat entri pembayaran di Firestore
      final payment =
          await FirebaseFirestore.instance.collection('payments').add({
        'orderId': newOrderId,
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

      if (kIsWeb) {
        // Untuk web, gunakan Midtrans Snap.js
        try {
          // Dapatkan token SNAP dari backend
          final snapToken = await _getSnapToken(newOrderId);

          // Buka popup Midtrans SNAP
          _openSnapPopup(snapToken);

          // Tunggu hasil pembayaran yang akan ditangani oleh _handlePaymentResult
        } catch (e) {
          // Tangani kegagalan memproses pembayaran web
          await payment.update({
            'status': 'failed',
            'errorMessage': e.toString(),
          });

          rethrow;
        }
      } else {
        // Untuk mobile, kode simulasi yang ada tetap digunakan
        // (Pada implementasi sebenarnya, gunakan midtrans_sdk)

        // Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));

        // Update payment status
        await payment.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Give access to the package
        await FirebaseFirestore.instance.collection('user_packages').add({
          'userId': user.uid,
          'packageId': widget.package.id,
          'purchasedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
        });

        if (mounted) {
          setState(() {
            isProcessing = false;
          });

          showAnimatedDialog(
            title: 'Pembayaran Berhasil',
            message: 'Selamat! Anda telah berhasil membeli paket tryout ini.',
            onConfirm: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRouter.tryout,
                  arguments: {
                    'type': widget.package.type,
                    'packageId': widget.package.id,
                  });
            },
            confirmText: 'Mulai Tryout',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: ${e.toString()}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(context.horizontalPadding),
          ),
        );
      }
    }
  }

  // Tampilkan dialog animasi setelah pembayaran berhasil
  void showAnimatedDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.successColor, size: 28),
            ),
            const SizedBox(width: 12),
            Text(title, style: AppTheme.textTheme.headlineSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Success icon animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: AppTheme.successColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          CustomButton(
            disabled: false,
            text: confirmText,
            onPressed: onConfirm,
            isFullWidth: true,
            isPrimary: true,
            icon: Icons.play_arrow_rounded,
          ),
        ],
        actionsPadding: const EdgeInsets.all(16),
      ),
    );
  }

  // Widget UI untuk pembayaran yang pending
  Widget _buildPendingPaymentInfo() {
    if (!isPending || orderId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: AppTheme.warningColor.withOpacity(0.1),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran Pending',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Silakan selesaikan pembayaran Anda melalui metode yang telah dipilih',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ID: $orderId',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _checkPaymentStatus,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Cek Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Periksa status pembayaran
  Future<void> _checkPaymentStatus() async {
    if (orderId == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Order not found');
      }

      final paymentData = snapshot.docs.first.data();
      final status = paymentData['status'];

      if (status == 'completed') {
        // Pembayaran telah berhasil
        setState(() {
          isPending = false;
        });

        showAnimatedDialog(
          title: 'Pembayaran Berhasil',
          message: 'Selamat! Anda telah berhasil membeli paket tryout ini.',
          onConfirm: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              AppRouter.tryout,
              arguments: {
                'type': widget.package.type,
                'packageId': widget.package.id,
              },
            );
          },
          confirmText: 'Mulai Tryout',
        );
      } else if (status == 'pending') {
        // Masih pending
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pembayaran Anda masih dalam proses. Silakan coba lagi nanti.'),
          ),
        );
      } else {
        // Gagal
        setState(() {
          isPending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Pembayaran gagal atau dibatalkan. Silakan coba lagi.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PlatformUI.isWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  'Pembayaran Paket',
                  style: AppTheme.textTheme.headlineSmall,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppTheme.primaryColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            )
          : AppBar(
              title: const Text('Pembayaran'),
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
            ),
      body: ResponsiveBuilder(
        builder: (context, constraints, screenSize) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: PlatformUI.verticalPadding,
            ),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenSize.isDesktop
                      ? 800
                      : (screenSize.isTablet ? 600 : double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending payment info (if applicable)
                    _buildPendingPaymentInfo(),

                    // Order summary card
                    CustomCard(
                      hasShadow: true,
                      borderRadius: 16,
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ringkasan Pembelian',
                                  style:
                                      AppTheme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Paket Latihan Soal CPNS',
                                  style:
                                      AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.assignment_outlined,
                                        color: AppTheme.accentColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.package.title,
                                            style:
                                                AppTheme.textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 16,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${widget.package.duration} menit',
                                                style: AppTheme
                                                    .textTheme.bodySmall,
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.quiz_outlined,
                                                size: 16,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${widget.package.questionCount} soal',
                                                style: AppTheme
                                                    .textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Harga',
                                      style: AppTheme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Rp ${widget.package.price}',
                                      style: AppTheme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                if (promoDiscount != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.discount_outlined,
                                            size: 16,
                                            color: AppTheme.secondaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Diskon ($discountPercentage)',
                                            style: AppTheme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: AppTheme.secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '- Rp $promoDiscount',
                                        style: AppTheme.textTheme.bodyLarge
                                            ?.copyWith(
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Pembayaran',
                                      style: AppTheme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Rp $finalPrice',
                                      style: AppTheme.textTheme.titleLarge
                                          ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Promo code section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Promo',
                          style: AppTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        CustomCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promoController,
                                      onChanged: (value) {
                                        setState(() {
                                          promoCode = value;
                                          promoError = null;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan kode promo',
                                        errorText: promoError,
                                        prefixIcon:
                                            const Icon(Icons.discount_outlined),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isValidatingPromo
                                          ? null
                                          : validatePromoCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.secondaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: isValidatingPromo
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Gunakan'),
                                    ),
                                  ),
                                ],
                              ),
                              if (promoDiscount != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: AppTheme.successColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Kode promo berhasil digunakan!',
                                              style: AppTheme
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Anda mendapatkan potongan Rp$promoDiscount',
                                              style:
                                                  AppTheme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Payment methods section - Modified for Midtrans
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: AppTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        CustomCard(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            children: [
                              ...paymentMethods.map((method) {
                                bool isSelected =
                                    selectedPaymentMethod == method['id'];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedPaymentMethod =
                                          method['id'] as String;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? method['color'] as Color?
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.2)
                                                : (method['color'] as Color?)
                                                    ?.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            method['icon'] as IconData?,
                                            color: isSelected
                                                ? Colors.white
                                                : method['color'] as Color?,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            method['name'] as String,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ),
                                        Radio(
                                          value: method['id'],
                                          groupValue: selectedPaymentMethod,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPaymentMethod =
                                                  value.toString();
                                            });
                                          },
                                          activeColor: isSelected
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              // Note untuk web
                              if (kIsWeb)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade300)),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: AppTheme.textSecondaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Pembayaran untuk web menggunakan Midtrans akan membuka popup pembayaran. Pastikan popup tidak diblokir oleh browser Anda.',
                                            style: AppTheme.textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Payment button
                    CustomButton(
                      disabled: isProcessing || isPending,
                      text:
                          isPending ? 'Menunggu Pembayaran' : 'Bayar Sekarang',
                      onPressed:
                          isProcessing || isPending ? () {} : processPayment,
                      isLoading: isProcessing,
                      isPrimary: true,
                      isFullWidth: true,
                      icon: isPending ? Icons.access_time : Icons.payment,
                    ),

                    const SizedBox(height: 16),

                    // Payment info
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pembayaran aman & terenkripsi',
                                style: AppTheme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Payment partners - Midtrans logo
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Powered by',
                                  style: AppTheme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Midtrans',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF0063B0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
