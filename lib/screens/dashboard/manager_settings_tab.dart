import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../screens/auth/auth_gate.dart';
import 'join_requests_screen.dart';

class ManagerSettingsTab extends StatelessWidget {
  const ManagerSettingsTab({super.key});

  Future<DocumentSnapshot?> _fetchOrgDocForManager() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final q = await FirebaseFirestore.instance
        .collection('organizations')
        .where('managers', arrayContains: uid)
        .limit(1)
        .get();
    return q.docs.isEmpty ? null : q.docs.first;
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _fetchOrgDocForManager(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data == null || !snap.data!.exists) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Organization not found.'),
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => _logout(context),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final inviteCode = data['invite_code'] ?? 'N/A';
        final orgName = data['name'] ?? 'Organization';
        final orgId = snap.data!.id;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orgName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text('Invite Code', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  SelectableText(
                    inviteCode,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Copy code',
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                    },
                  ),
                  IconButton(
                    tooltip: 'Share code',
                    icon: const Icon(Icons.share, color: Colors.green),
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(text: 'Join my StockSync org! Code: $inviteCode'),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // --- Join Requests tile with real-time badge ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(orgId)
                    .collection('join_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, reqSnap) {
                  final pendingCount = (reqSnap.hasData) ? reqSnap.data!.docs.length : 0;

                  return ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: const Text('View Join Requests'),
                    subtitle: const Text('Approve or reject new member requests'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pendingCount.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JoinRequestsScreen()),
                      );
                    },
                  );
                },
              ),

              const Spacer(),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style:
                  ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.redAccent),
                  onPressed: () => _logout(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
