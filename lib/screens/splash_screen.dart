import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/auth_screen.dart';
import 'organization/org_setup_screen.dart';
import 'dashboard/manager_homescreen.dart';
import 'employee/employee_homescreen.dart';
import '../widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    await Future.delayed(const Duration(seconds: 1)); // small splash delay

    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    final userDoc =
    await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists || userDoc['org_id'] == '') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OrgSetupScreen()));
      return;
    }

    final role = userDoc['role'];
    if (role == 'manager' || role == 'owner') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ManagerHomeScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingIndicator(),
    );
  }
}
