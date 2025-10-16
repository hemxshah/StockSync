import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stock_sync/screens/auth/auth_gate.dart';
import 'package:stock_sync/screens/dashboard/manager_homescreen.dart';
import 'package:stock_sync/screens/employee/employee_homescreen.dart';
import 'package:stock_sync/screens/organization/org_setup_screen.dart';
import 'package:stock_sync/core/app_theme.dart';
import 'firebase_options.dart';

// 🔔 Local notifications instance
final FlutterLocalNotificationsPlugin _localNotifications =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  _setupNotifications(); // ✅ setup FCM + local notifications

  runApp(const StockSyncApp());
}

// ------------------ FCM + Notification Setup ------------------
Future<void> _setupNotifications() async {
  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission();

  // Get current FCM token
  final token = await FirebaseMessaging.instance.getToken();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  // ✅ Store token in Firestore for push notifications
  if (uid != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcm_token': token,
    });
  }

  // 🔁 Update token automatically when refreshed
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final newUid = FirebaseAuth.instance.currentUser?.uid;
    if (newUid != null) {
      await FirebaseFirestore.instance.collection('users').doc(newUid).update({
        'fcm_token': newToken,
      });
    }
  });

  // Initialize local notifications
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);
  await _localNotifications.initialize(initSettings);

  // Show local notification when app is in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notif = message.notification;
    if (notif != null) {
      await _localNotifications.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'stock_channel',
            'Stock Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

// ------------------ Main App ------------------
class StockSyncApp extends StatelessWidget {
  const StockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        '/org': (_) => const OrgSetupScreen(),
        '/manager': (_) => const ManagerHomeScreen(),
        '/employee': (_) => const EmployeeHomeScreen(),
      },
    );
  }
}
