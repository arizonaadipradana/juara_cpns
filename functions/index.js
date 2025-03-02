const functions = require('firebase-functions');
const admin = require('firebase-admin');
const midtransClient = require('midtrans-client');

admin.initializeApp();

exports.createTransaction = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  // Create Midtrans Snap API instance
  let snap = new midtransClient.Snap({
    isProduction: false, // Set to true for production
    serverKey: functions.config().midtrans.server_key,
    clientKey: functions.config().midtrans.client_key // Fixed the typo here
  });

  try {
    // Create transaction in Midtrans
    const transaction = await snap.createTransaction({
      transaction_details: {
        order_id: `ORDER-${Date.now()}`,
        gross_amount: data.amount
      },
      customer_details: {
        first_name: data.firstName,
        email: data.email,
        phone: data.phone
      },
      item_details: data.items,
      callbacks: {
        finish: functions.config().midtrans.finish_url || 'https://juara-cpns.web.app/payment/finish',
        error: functions.config().midtrans.error_url || 'https://juara-cpns.web.app/payment/error',
        pending: functions.config().midtrans.pending_url || 'https://juara-cpns.web.app/payment/pending'
      }
    });

    // Store transaction in Firestore
    await admin.firestore().collection('transactions').doc(transaction.order_id).set({
      userId: context.auth.uid,
      amount: data.amount,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      midtransToken: transaction.token,
      redirectUrl: transaction.redirect_url,
      items: data.items
    });

    // Return the transaction token to the client
    return {
      token: transaction.token,
      redirectUrl: transaction.redirect_url,
      orderId: transaction.order_id
    };
  } catch (error) {
    console.error('Midtrans error:', error);
    throw new functions.https.HttpsError('internal', 'Payment processing failed: ' + error.message);
  }
});

exports.midtransNotification = functions.https.onRequest(async (req, res) => {
  try {
    // Verify request method (Midtrans sends POST notifications)
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // Parse notification data
    const notificationData = req.body;
    functions.logger.info('Notification received from Midtrans', notificationData);

    // Create Core API instance for verification
    const core = new midtransClient.CoreApi({
      isProduction: false, // Set to true in production
      serverKey: functions.config().midtrans.server_key,
      clientKey: functions.config().midtrans.client_key // Fixed the typo here
    });

    // Verify and get notification status from Midtrans
    // This step is crucial to ensure the notification is genuinely from Midtrans
    const notification = await core.transaction.notification(notificationData);

    // Extract relevant information
    const orderId = notification.order_id;
    const transactionStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;
    const transactionTime = notification.transaction_time;
    const paymentType = notification.payment_type;

    // Determine transaction status based on Midtrans response
    let status;
    if (transactionStatus === 'capture') {
      if (fraudStatus === 'challenge') {
        status = 'challenge';
      } else if (fraudStatus === 'accept') {
        status = 'success';
      }
    } else if (transactionStatus === 'settlement') {
      status = 'success';
    } else if (transactionStatus === 'cancel' ||
               transactionStatus === 'deny' ||
               transactionStatus === 'expire') {
      status = 'failed';
    } else if (transactionStatus === 'pending') {
      status = 'pending';
    }

    // Get transaction document from Firestore
    const transactionRef = admin.firestore().collection('transactions').doc(orderId);
    const transactionDoc = await transactionRef.get();

    if (!transactionDoc.exists) {
      functions.logger.error('Transaction not found in database', { orderId });
      res.status(404).send('Transaction not found');
      return;
    }

    // Update transaction in Firestore
    await transactionRef.update({
      status: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentType: paymentType,
      transactionTime: transactionTime,
      midtransResponse: notification
    });

    // If the transaction is successful, update user's purchase history
    if (status === 'success') {
      const userId = transactionDoc.data().userId;
      const userRef = admin.firestore().collection('users').doc(userId);

      // Create a transaction record in the user's purchases subcollection
      await userRef.collection('purchases').doc(orderId).set({
        orderId: orderId,
        amount: transactionDoc.data().amount,
        items: transactionDoc.data().items,
        purchaseDate: admin.firestore.Timestamp.fromDate(new Date(transactionTime)),
        paymentType: paymentType
      });

      // Optionally, trigger any post-purchase actions here
      // For example, activating subscriptions, sending emails, etc.
    }

    // Log successful processing
    functions.logger.info('Payment notification processed successfully', {
      orderId: orderId,
      status: status
    });

    // Send success response back to Midtrans
    res.status(200).send('OK');
  } catch (error) {
    // Log the error
    functions.logger.error('Error processing payment notification', {
      error: error.message,
      stack: error.stack
    });

    // Send error response
    res.status(500).send('Error processing notification');
  }
});