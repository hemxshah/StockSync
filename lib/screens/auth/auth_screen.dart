import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'email_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submit() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final name = nameCtrl.text.trim();

    if (!isLogin && name.isEmpty) {
      _showSnack('Please enter your full name.');
      return;
    }

    if (email.isEmpty || pass.isEmpty) {
      _showSnack('Please fill all fields.');
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        // LOGIN FLOW
        final cred = await auth.signInWithEmailAndPassword(email: email, password: pass);

        if (!cred.user!.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
          return;
        }
      } else {
        // SIGNUP FLOW
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: pass);

        await db.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'org_id': '',
          'role': '',
          'userVerificationStatus': 'unverified',
          'fcm_token': null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        await cred.user!.sendEmailVerification();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Authentication failed.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              // --- Header Section ---
              Column(
                children: [
                  Text(
                    'StockSync',
                    style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Smart Inventory. Simplified.',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),

              // --- Card Form Container ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isLogin ? 'Welcome Back 👋' : 'Create Your Account 🧾',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Name Field (Signup only) ---
                    if (!isLogin)
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    if (!isLogin) const SizedBox(height: 16),

                    // --- Email ---
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Password ---
                    TextField(
                      controller: passCtrl,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() {
                            hidePassword = !hidePassword;
                          }),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- Action Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(isLogin ? 'Login' : 'Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Switch Mode ---
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "Don’t have an account? Sign Up"
                            : "Already registered? Log In",
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- Footer ---
              Text(
                '© ${DateTime.now().year} Ambalal Shah & Sons',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
