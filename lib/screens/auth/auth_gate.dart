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

  Future<Widget> _determineNextScreen(User user) async {
    await user.reload();

    // 🟡 Email not verified
    if (!user.emailVerified) {
      return const EmailVerificationScreen();
    }

    // 🔵 Get Firestore user document
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      // No Firestore record yet — treat as new user
      return const OrgSetupScreen();
    }

    final data = userDoc.data() ?? {};
    final orgId = data['org_id'] ?? '';
    final role = data['role'] ?? '';

    if (orgId.isEmpty || role.isEmpty || role == 'pending') {
      // User hasn’t joined or created an org yet
      return const OrgSetupScreen();
    }

    // ✅ User has an organization — direct them to their dashboard
    if (role == 'manager') {
      return const ManagerHomeScreen();
    } else {
      return const EmployeeHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔹 Loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 Not logged in
        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        // 🔹 Logged in — decide next screen asynchronously
        final user = snapshot.data!;
        return FutureBuilder<Widget>(
          future: _determineNextScreen(user),
          builder: (context, futureSnap) {
            if (futureSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (futureSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${futureSnap.error}'),
                ),
              );
            }

            return futureSnap.data ?? const AuthScreen();
          },
        );
      },
    );
  }
}
