import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_sync/screens/organization/org_setup_screen.dart';
import 'package:stock_sync/screens/dashboard/manager_homescreen.dart';
import 'package:stock_sync/screens/employee/employee_homescreen.dart';
import 'auth_screen.dart';
import 'email_verification_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) {
          return const AuthScreen();
        }

        // If email not verified, route to verification screen.
        // If you want to force a fresh check, call user.reload() elsewhere
        // (email verification flow should handle resend & next).
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // Listen to user's Firestore document in real-time.
        final userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, userDocSnap) {
            if (userDocSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userDocSnap.hasError) {
              return Scaffold(body: Center(child: Text('Error: ${userDocSnap.error}')));
            }

            final doc = userDocSnap.data;
            // If user doc doesn't exist, send them to org setup / profile creation
            if (doc == null || !doc.exists) {
              return const OrgSetupScreen();
            }

            final data = doc.data() ?? <String, dynamic>{};
            final orgId = (data['org_id'] ?? '') as String;
            final role = (data['role'] ?? '') as String;

            // Role might be 'manager', 'employee', 'pending', or empty
            if (orgId.isEmpty || role.isEmpty || role == 'pending') {
              return const OrgSetupScreen();
            }

            if (role == 'manager') {
              return const ManagerHomeScreen();
            } else {
              return const EmployeeHomeScreen();
            }
          },
        );
      },
    );
  }
}
