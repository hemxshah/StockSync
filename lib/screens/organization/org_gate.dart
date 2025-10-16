import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stock_sync/screens/dashboard/manager_homescreen.dart';
import 'package:stock_sync/screens/employee/employee_homescreen.dart';
import 'package:stock_sync/screens/organization/org_setup_screen.dart';

class OrgGate extends StatelessWidget {
  const OrgGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null) {
          return const OrgSetupScreen();
        }

        final orgId = data['org_id'];
        final role = data['role'];

        if (orgId == null || (orgId is String && orgId.isEmpty)) {
          return const OrgSetupScreen();
        }

        if (role == 'manager') {
          return const ManagerHomeScreen();
        } else if (role == 'employee') {
          return const EmployeeHomeScreen();
        } else {
          return const OrgSetupScreen();
        }
      },
    );
  }
}
