import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../dashboard/manager_homescreen.dart';
import '../employee/employee_homescreen.dart';

class OrgSetupScreen extends StatefulWidget {
  const OrgSetupScreen({super.key});

  @override
  State<OrgSetupScreen> createState() => _OrgSetupScreenState();
}

class _OrgSetupScreenState extends State<OrgSetupScreen> {
  final _orgNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _loading = false;



  @override
  void initState() {
    super.initState();
  }


  /// ✅ Create new organization
  Future<void> _createOrganization() async {
    final orgName = _orgNameController.text.trim();
    if (orgName.isEmpty) {
      _showSnack('Please enter organization name.');
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final orgId = FirebaseFirestore.instance.collection('organizations').doc().id;
      final inviteCode = _generateInviteCode();

      await FirebaseFirestore.instance.collection('organizations').doc(orgId).set({
        'name': orgName,
        'invite_code': inviteCode,
        'managers': [uid],
        'pending_requests': [],
        'created_by': uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'org_id': orgId,
        'role': 'manager',
      });

      if (!mounted) return;
      _showInviteDialog(inviteCode);
    } catch (e) {
      _showSnack('Error creating organization: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ✅ Request to join organization (not instant join)
  Future<void> _joinOrganization() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Enter an invite code to join.');
      return;
    }

    setState(() => _loading = true);
    try {
      final orgSnap = await FirebaseFirestore.instance
          .collection('organizations')
          .where('invite_code', isEqualTo: code)
          .limit(1)
          .get();

      if (orgSnap.docs.isEmpty) {
        _showSnack('Invalid invite code.');
        return;
      }

      final orgDoc = orgSnap.docs.first;
      final orgId = orgDoc.id;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userName = userDoc.data()?['name'] ?? '';
      final userEmail = userDoc.data()?['email'] ?? '';

      final reqRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('join_requests')
          .doc(uid); // canonical id = uid

      // transaction ensures atomic check-and-create (no duplicates)
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(reqRef);
        if (snapshot.exists) {
          final existing = snapshot.data()!;
          final status = existing['status'] ?? '';
          if (status == 'pending') throw Exception('already_pending');
          if (status == 'approved') throw Exception('already_approved');
          if (status == 'rejected') throw Exception('previously_rejected');
        }

        tx.set(reqRef, {
          'user_id': uid,
          'user_name': userName,
          'user_email': userEmail,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });

      // update user role -> pending (optional: you may choose to delay setting org_id till approval)
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'pending',
        'org_id': orgId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      _showSnack('Join request sent! Waiting for manager approval.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('already_pending')) {
        _showSnack('You already have a pending request.');
      } else if (msg.contains('already_approved')) {
        _showSnack('Your request has already been approved.');
      } else if (msg.contains('previously_rejected')) {
        _showSnack('Your previous request was rejected. Contact your manager.');
      } else {
        _showSnack('Error joining organization: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Future<void> _joinOrganization() async {
  //   final code = _inviteCodeController.text.trim();
  //   if (code.isEmpty) {
  //     _showSnack('Enter an invite code to join.');
  //     return;
  //   }
  //
  //   setState(() => _loading = true);
  //   try {
  //     final orgSnap = await FirebaseFirestore.instance
  //         .collection('organizations')
  //         .where('invite_code', isEqualTo: code)
  //         .limit(1)
  //         .get();
  //
  //     if (orgSnap.docs.isEmpty) {
  //       _showSnack('Invalid invite code.');
  //       return;
  //     }
  //
  //     final orgDoc = orgSnap.docs.first;
  //     final orgId = orgDoc.id;
  //     final uid = FirebaseAuth.instance.currentUser!.uid;
  //
  //     // 1) Check if user already is a member or has a pending/approved request
  //     final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  //     final existingOrgId = userDoc.data()?['org_id'] ?? '';
  //     final existingRole = userDoc.data()?['role'] ?? '';
  //
  //     if (existingOrgId == orgId && (existingRole == 'employee' || existingRole == 'manager')) {
  //       _showSnack('You are already a member of this organization.');
  //       return;
  //     }
  //
  //     // 2) Check join_requests for same user in this org (pending/approved)
  //     final existingRequests = await FirebaseFirestore.instance
  //         .collection('organizations')
  //         .doc(orgId)
  //         .collection('join_requests')
  //         .where('user_id', isEqualTo: uid)
  //         .get();
  //
  //     if (existingRequests.docs.isNotEmpty) {
  //       final status = existingRequests.docs.first.data()['status'] ?? '';
  //       if (status == 'pending') {
  //         _showSnack('You already have a pending request. Please wait for approval.');
  //         return;
  //       } else if (status == 'approved') {
  //         _showSnack('Your request was already approved. Please refresh or re-login.');
  //         return;
  //       } else if (status == 'rejected') {
  //         // optionally allow re-request: fall through or show message
  //         _showSnack('Your previous request was rejected. Contact manager or retry.');
  //         return;
  //       }
  //     }
  //
  //     // 3) Create new join request
  //     final userName = userDoc.data()?['name'] ?? '';
  //     final userEmail = userDoc.data()?['email'] ?? '';
  //
  //     await FirebaseFirestore.instance
  //         .collection('organizations')
  //         .doc(orgId)
  //         .collection('join_requests')
  //         .add({
  //       'user_id': uid,
  //       'user_name': userName,
  //       'user_email': userEmail,
  //       'status': 'pending',
  //       'created_at': FieldValue.serverTimestamp(),
  //       'updated_at': FieldValue.serverTimestamp(),
  //     });
  //
  //     // Update user record role => pending and link org_id (optional: you may prefer not to set org_id until approved)
  //     await FirebaseFirestore.instance.collection('users').doc(uid).update({
  //       'role': 'pending',
  //       'org_id': orgId,
  //       'updated_at': FieldValue.serverTimestamp(),
  //     });
  //
  //     _showSnack('Join request sent! Waiting for manager approval.');
  //   } catch (e) {
  //     _showSnack('Error joining organization: $e');
  //   } finally {
  //     if (mounted) setState(() => _loading = false);
  //   }
  // }



  /// 🔹 Generate random invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(timestamp + i) % chars.length]).join();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// ✅ Invite Code Dialog after creation
  void _showInviteDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Organization Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this invite code with your team:'),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy, color: Colors.blueAccent),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    _showSnack('Code copied to clipboard!');
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share, color: Colors.green),
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(text: 'Join my organization on StockSync! Code: $code'),
                    );
                  },
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ManagerHomeScreen()),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show splash/loading screen during org check
    // if (_checkingOrg) {
    //   return const Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(),
    //     ),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Setup'),
        automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Go Back'),
                  content: const Text('Do you want to go back to the login screen? This will sign you out.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut(); // ✅ Important: log out user
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              }
            },
          ),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _createOrganization,
              icon: const Icon(Icons.business),
              label: Text(_loading ? 'Creating...' : 'Create Organization'),
            ),
            const Divider(height: 40),
            TextField(
              controller: _inviteCodeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _joinOrganization,
              icon: const Icon(Icons.group_add),
              label: Text(_loading ? 'Joining...' : 'Join Organization'),
            ),
          ],
        ),
      ),
    );
  }
}
