import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../organization/org_setup_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool emailVerified = false;
  bool loading = false;
  bool emailSent = false;
  bool polling = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmailOnce();
    _startVerificationPolling();
  }

  /// ✅ Send only once on entry
  Future<void> _sendVerificationEmailOnce() async {
    if (emailSent) return; // prevent multiple sends
    try {
      await auth.currentUser!.sendEmailVerification();
      setState(() => emailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  /// ✅ Poll for verification status every 5s, update Firestore + local UI
  Future<void> _startVerificationPolling() async {
    if (polling) return;
    polling = true;

    while (mounted && !emailVerified) {
      await Future.delayed(const Duration(seconds: 5));
      await auth.currentUser!.reload();
      final verified = auth.currentUser!.emailVerified;

      if (verified) {
        setState(() => emailVerified = true);
        final uid = auth.currentUser!.uid;

        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'userVerificationStatus': 'verified',
          'updated_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Email verified! You can continue.')),
          );
        }
        break; // stop loop
      }
    }

    polling = false;
  }

  /// ✅ Trigger manual resend if user didn’t get the mail
  Future<void> _resendEmail() async {
    try {
      await auth.currentUser!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email re-sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// ✅ Next button: check latest state + Firestore fallback
  Future<void> _goToNext() async {
    setState(() => loading = true);
    await auth.currentUser!.reload();
    final verified = auth.currentUser!.emailVerified;

    if (!verified) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email first.')),
      );
      return;
    }

    // ensure Firestore has verified flag too
    final uid = auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'userVerificationStatus': 'verified',
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OrgSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await auth.signOut();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                emailVerified ? Icons.verified_rounded : Icons.email_outlined,
                color: emailVerified ? Colors.green : Colors.blueAccent,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                emailVerified
                    ? 'Your email is verified!'
                    : 'A verification link has been sent to:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                userEmail,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Resend button if not yet verified
              if (!emailVerified)
                ElevatedButton.icon(
                  onPressed: _resendEmail,
                  icon: const Icon(Icons.email),
                  label: const Text('Resend Email'),
                ),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: loading ? null : _goToNext,
                icon: const Icon(Icons.arrow_forward),
                label: loading
                    ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
