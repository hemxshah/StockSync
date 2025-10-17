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

      final org = orgSnap.docs.first;
      final orgId = org.id;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Add pending join request instead of auto joining
      await FirebaseFirestore.instance.collection('organizations').doc(orgId).update({
        'pending_requests': FieldValue.arrayUnion([uid]),
      });

      // update user doc with request state
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'org_id': orgId,
        'role': 'pending',
      });

      _showSnack(
        'Join request sent successfully. A manager will approve your request soon.',
      );

      // You could add a simple dialog to tell them they’ll get access after approval
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Request Sent'),
          content: const Text(
              'Your request has been sent to the organization’s managers. You’ll get access once approved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      _showSnack('Error joining organization: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    if (_checkingOrg) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Setup'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // safely return to previous (e.g., logout confirmation)
            Navigator.pop(context);
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
