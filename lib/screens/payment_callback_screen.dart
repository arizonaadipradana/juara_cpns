import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/custom_button.dart';
import 'package:juara_cpns/screens/tryout_screen.dart';

class PaymentCallbackScreen extends StatefulWidget {
  final String callbackType; // 'finish', 'error', or 'pending'
  final String? orderId;
  final String? packageId;
  final String? packageType;

  const PaymentCallbackScreen({
    Key? key,
    required this.callbackType,
    this.orderId,
    this.packageId,
    this.packageType,
  }) : super(key: key);

  @override
  _PaymentCallbackScreenState createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends State<PaymentCallbackScreen> {
  bool isLoading = true;
  String? paymentStatus;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    try {
      if (widget.orderId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Order ID tidak ditemukan';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('orderId', isEqualTo: widget.orderId)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Transaksi tidak ditemukan';
        });
        return;
      }

      final paymentData = snapshot.docs.first.data();

      setState(() {
        isLoading = false;
        paymentStatus = paymentData['status'];
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Status Pembayaran'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Memeriksa status pembayaran...',
                  style: AppTheme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ] else if (errorMessage != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppTheme.errorColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Terjadi Kesalahan',
                  style: AppTheme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: AppTheme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                CustomButton(
                  text: 'Kembali ke Beranda',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  isPrimary: true,
                  isFullWidth: true,
                ),
              ] else if (paymentStatus == 'success' || paymentStatus == 'completed') ...[
                _buildSuccessContent(context),
              ] else if (paymentStatus == 'pending') ...[
                _buildPendingContent(context),
              ] else ...[
                _buildFailedContent(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.successColor,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Pembayaran Berhasil!',
          style: AppTheme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Terima kasih, pembayaran Anda telah berhasil diproses. Anda sekarang dapat mengakses paket yang telah dibeli.',
          style: AppTheme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        CustomButton(
          text: 'Mulai Tryout',
          onPressed: () {
            if (widget.packageId != null && widget.packageType != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TryoutScreen(
                    type: widget.packageType!,
                    packageId: widget.packageId!,
                  ),
                ),
              );
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          isPrimary: true,
          isFullWidth: true,
          icon: Icons.play_arrow_rounded,
        ),
      ],
    );
  }

  Widget _buildPendingContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.access_time,
            size: 80,
            color: AppTheme.warningColor,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Pembayaran Tertunda',
          style: AppTheme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Silakan selesaikan pembayaran Anda sesuai instruksi yang diberikan. Kami akan memproses pembayaran Anda segera setelah dikonfirmasi.',
          style: AppTheme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        CustomButton(
          text: 'Periksa Status Pembayaran',
          onPressed: _checkPaymentStatus,
          isPrimary: false,
          isFullWidth: true,
          icon: Icons.refresh,
        ),
        SizedBox(height: 16),
        CustomButton(
          text: 'Kembali ke Beranda',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          isPrimary: true,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildFailedContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cancel_outlined,
            size: 80,
            color: AppTheme.errorColor,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Pembayaran Gagal',
          style: AppTheme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Maaf, pembayaran Anda tidak dapat diproses saat ini. Silakan coba lagi nanti atau gunakan metode pembayaran lain.',
          style: AppTheme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        CustomButton(
          text: 'Coba Lagi',
          onPressed: () {
            Navigator.of(context).pop();
          },
          isPrimary: true,
          isFullWidth: true,
          icon: Icons.refresh,
        ),
        SizedBox(height: 16),
        CustomButton(
          text: 'Kembali ke Beranda',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          isPrimary: false,
          isFullWidth: true,
        ),
      ],
    );
  }
}