import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:js/js.dart';
import 'dart:js' as js;
import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juara_cpns/class/practice_package_model.dart';

// Kelas utama untuk menangani pembayaran
class MidtransPaymentService {
  // URL backend Anda untuk membuat transaksi
  final String _backendUrl = 'https://your-backend-url.com/api';

  // Metode untuk membuat transaksi dan mendapatkan token SNAP
  Future<String> getSnapToken({
    required String orderId,
    required int amount,
    required Map<String, dynamic> customerDetails,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'gross_amount': amount,
          'payment_type': paymentMethod,
          'customer_details': customerDetails,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get snap token: ${response.body}');
      }

      final data = json.decode(response.body);
      return data['snap_token'];
    } catch (e) {
      throw Exception('Error getting snap token: $e');
    }
  }

  // Metode untuk menangani pembayaran berdasarkan platform (web atau mobile)
  Future<Map<String, dynamic>> processPayment({
    required PracticePackage package,
    required String paymentMethod,
    required int finalAmount,
    String? promoCode,
    int? promoDiscount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Buat ID order unik
    final String orderId = 'JC-${DateTime.now().millisecondsSinceEpoch}-${user.uid.substring(0, 5)}';

    // Buat dokumen transaksi di Firestore
    final paymentRef = await FirebaseFirestore.instance
        .collection('payments')
        .add({
      'orderId': orderId,
      'userId': user.uid,
      'packageId': package.id,
      'originalAmount': package.price,
      'promoCode': promoCode,
      'promoDiscount': promoDiscount,
      'finalAmount': finalAmount,
      'status': 'pending',
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Data customer
    Map<String, dynamic> customerDetails = {
      'first_name': user.displayName ?? 'User',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
    };

    if (kIsWeb) {
      // Implementasi untuk Web
      return await _processWebPayment(
        paymentRef: paymentRef,
        orderId: orderId,
        amount: finalAmount,
        customerDetails: customerDetails,
        paymentMethod: paymentMethod,
        package: package,
      );
    } else {
      // Implementasi untuk Mobile menggunakan midtrans_sdk
      throw UnimplementedError('Mobile implementation requires midtrans_sdk');
    }
  }

  // Metode khusus untuk platform Web menggunakan Snap.js
  Future<Map<String, dynamic>> _processWebPayment({
    required DocumentReference paymentRef,
    required String orderId,
    required int amount,
    required Map<String, dynamic> customerDetails,
    required String paymentMethod,
    required PracticePackage package,
  }) async {
    try {
      // 1. Dapatkan token SNAP dari backend
      final snapToken = await getSnapToken(
        orderId: orderId,
        amount: amount,
        customerDetails: customerDetails,
        paymentMethod: paymentMethod,
      );

      // 2. Persiapkan callback untuk menangani hasil pembayaran
      // Ini akan di-register sebagai fungsi global di window
      js.context['onPaymentResult'] = allowInterop((result) {
        _handlePaymentResult(result, paymentRef, package);
      });

      // 3. Buka Snap.js popup
      _openSnapPopup(snapToken);

      // 4. Kembalikan status awal (pending)
      return {
        'status': 'pending',
        'message': 'Pembayaran sedang diproses',
        'orderId': orderId,
      };
    } catch (e) {
      await paymentRef.update({'status': 'failed', 'errorMessage': e.toString()});
      throw Exception('Payment process failed: $e');
    }
  }

  // Fungsi untuk membuka popup Midtrans SNAP
  void _openSnapPopup(String snapToken) {
    // Pastikan script Snap.js sudah dimuat
    _loadSnapJs(() {
      // Panggil snap.pay dengan token
      js.context.callMethod('snapPay', [snapToken]);
    });
  }

  // Fungsi untuk memuat script Snap.js jika belum dimuat
  void _loadSnapJs(Function callback) {
    // Periksa apakah Snap.js sudah dimuat
    if (js.context.hasProperty('snap')) {
      callback();
      return;
    }

    // Muat Snap.js
    final scriptElement = html.ScriptElement()
      ..src = 'https://app.sandbox.midtrans.com/snap/snap.js'
      ..type = 'text/javascript'
      ..defer = true;

    scriptElement.onLoad.listen((event) {
      // Inisialisasi Snap
      js.context.callMethod('snap.configure', [{
        'clientKey': 'YOUR_MIDTRANS_CLIENT_KEY',
        'onSuccess': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [{'status': 'success', 'data': result}]);
        }),
        'onPending': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [{'status': 'pending', 'data': result}]);
        }),
        'onError': js.allowInterop((result) {
          js.context.callMethod('onPaymentResult', [{'status': 'error', 'data': result}]);
        }),
        'onClose': js.allowInterop(() {
          js.context.callMethod('onPaymentResult', [{'status': 'closed'}]);
        }),
      }]);

      callback();
    });

    html.document.head!.append(scriptElement);
  }

  // Handler untuk menangani hasil pembayaran dari Snap.js
  void _handlePaymentResult(dynamic result, DocumentReference paymentRef, PracticePackage package) async {
    try {
      final status = result['status'];
      final user = FirebaseAuth.instance.currentUser;

      switch (status) {
        case 'success':
        // Update status pembayaran menjadi sukses
          await paymentRef.update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'transactionData': result['data'],
          });

          // Berikan akses ke paket
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('user_packages')
                .add({
              'userId': user.uid,
              'packageId': package.id,
              'purchasedAt': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 30)),
              ),
            });
          }
          break;

        case 'pending':
        // Update status pembayaran menjadi pending
          await paymentRef.update({
            'status': 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
            'transactionData': result['data'],
          });
          break;

        case 'error':
        // Update status pembayaran menjadi gagal
          await paymentRef.update({
            'status': 'failed',
            'updatedAt': FieldValue.serverTimestamp(),
            'errorData': result['data'],
          });
          break;

        case 'closed':
        // Pengguna menutup popup pembayaran
          await paymentRef.update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
      }
    } catch (e) {
      print('Error handling payment result: $e');
      await paymentRef.update({
        'status': 'error_processing',
        'errorMessage': e.toString(),
      });
    }
  }

  // Metode untuk memeriksa status pembayaran
  Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Order not found');
      }

      final paymentData = snapshot.docs.first.data();
      return {
        'status': paymentData['status'],
        'packageId': paymentData['packageId'],
        'amount': paymentData['finalAmount'],
      };
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }
}