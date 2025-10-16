import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_sync/screens/organization/org_setup_screen.dart';
import 'auth_screen.dart';
import 'email_verification_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AuthScreen();
        }
        final user = snapshot.data!;
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }
        return const OrgSetupScreen();
      },
    );
  }
}
