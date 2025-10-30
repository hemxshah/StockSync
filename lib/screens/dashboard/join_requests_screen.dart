import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // tracks processing state per request doc to prevent double taps
  final Map<String, bool> _processing = {};

  Future<String?> _getOrgId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await _db.collection('users').doc(uid).get();
    return userDoc.data()?['org_id'] as String?;
  }

// Replace existing handler with this exact function (keep imports)
  Future<void> _handleRequestAction({
    required BuildContext context,
    required String orgId,
    required String requestDocId, // join_requests doc id (likely userId)
    required String userId,
    required String action, // 'approved' or 'rejected'
  }) async {
    final db = FirebaseFirestore.instance;
    final reqRef = db.collection('organizations').doc(orgId).collection('join_requests').doc(requestDocId);
    final userRef = db.collection('users').doc(userId);
    final managerUid = FirebaseAuth.instance.currentUser?.uid;
    final snack = ScaffoldMessenger.of(context);

    // show processing
    snack.showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Processing...')
      ]),
      duration: Duration(minutes: 1),
    ));

    try {
      // 1) Try transaction (atomic)
      await db.runTransaction((tx) async {
        final reqSnap = await tx.get(reqRef);
        if (!reqSnap.exists) throw Exception('request_not_found');

        final reqData = reqSnap.data() ?? {};
        final currentStatus = (reqData['status'] ?? '').toString();
        if (action == 'approved' && currentStatus == 'approved') throw Exception('already_approved');
        if (action == 'rejected' && currentStatus == 'rejected') throw Exception('already_rejected');

        final now = FieldValue.serverTimestamp();
        final updatePayload = <String, dynamic>{
          'status': action,
          'updated_at': now,
        };
        if (action == 'approved') {
          updatePayload['approved_by'] = managerUid;
          updatePayload['approved_at'] = now;
        } else if (action == 'rejected') {
          updatePayload['rejected_by'] = managerUid;
          updatePayload['rejected_at'] = now;
        }

        tx.update(reqRef, updatePayload);

        if (action == 'approved') {
          tx.update(userRef, {
            'role': 'employee',
            'org_id': orgId,
            'updated_at': now,
          });
        } else {
          tx.update(userRef, {
            'role': '',
            'org_id': '',
            'updated_at': now,
          });
        }
      });

      // success
      snack.hideCurrentSnackBar();
      snack.showSnackBar(SnackBar(content: Text('Request $action successfully')));

    } on FirebaseException catch (fe) {
      // Firestore-specific error — permission denied, failed-precondition, etc.
      snack.hideCurrentSnackBar();
      snack.showSnackBar(SnackBar(content: Text('Firestore error: ${fe.code} — ${fe.message}')));

      // If permission error, STOP and surface it (do not fallback).
      if (fe.code == 'permission-denied') {
        debugPrint('PERMISSION DENIED: ${fe.message}');
        return;
      }

      // If it's some other error (transient), attempt a safe fallback (non-transactional)
      debugPrint('Transaction failed with FirebaseException: ${fe.code} ${fe.message}. Trying fallback write...');
      try {
        final now = FieldValue.serverTimestamp();
        // update join_request doc
        await reqRef.update({
          'status': action,
          'updated_at': now,
          if (action == 'approved') 'approved_by': managerUid,
          if (action == 'approved') 'approved_at': now,
          if (action == 'rejected') 'rejected_by': managerUid,
          if (action == 'rejected') 'rejected_at': now,
        });

        // update user doc
        if (action == 'approved') {
          await userRef.update({
            'role': 'employee',
            'org_id': orgId,
            'updated_at': now,
          });
        } else {
          await userRef.update({
            'role': '',
            'org_id': '',
            'updated_at': now,
          });
        }

        snack.showSnackBar(SnackBar(content: Text('Request $action (fallback) completed.')));
      } catch (e, st) {
        snack.showSnackBar(SnackBar(content: Text('Fallback write failed: $e')));
        debugPrint('Fallback write error: $e\n$st');
      }

    } catch (e, st) {
      // generic errors (already_approved, request_not_found, etc)
      snack.hideCurrentSnackBar();
      String friendly = e.toString();
      if (friendly.contains('request_not_found')) friendly = 'Request not found.';
      if (friendly.contains('already_approved')) friendly = 'Request already approved.';
      if (friendly.contains('already_rejected')) friendly = 'Request already rejected.';
      snack.showSnackBar(SnackBar(content: Text('Error: $friendly')));
      debugPrint('Unhandled error in approve handler: $e\n$st');
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getOrgId(),
      builder: (context, orgSnap) {
        if (orgSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!orgSnap.hasData || orgSnap.data == null || orgSnap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No organization linked to your account.')),
          );
        }

        final orgId = orgSnap.data!;
        final joinRequestsStream = _db
            .collection('organizations')
            .doc(orgId)
            .collection('join_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: true)
            .snapshots();

        return Scaffold(
          appBar: AppBar(title: const Text('Join Requests')),
          body: StreamBuilder<QuerySnapshot>(
            stream: joinRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // show helpful error (index or permission)
                final err = snapshot.error.toString();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error loading requests: $err'),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No pending join requests.'));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final req = doc.data()! as Map<String, dynamic>;
                  final userName = req['user_name'] ?? 'Unknown';
                  final userEmail = req['user_email'] ?? '';
                  final userId = req['user_id'] ?? doc.id;
                  final docId = doc.id;
                  final processing = _processing[docId] == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(userName),
                      subtitle: Text(userEmail),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: processing
                                ? null
                                : () => _handleRequestAction(
                              orgId: orgId,
                              requestDocId: docId,
                              userId: userId,
                              action: 'approved', context: context,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: processing
                                ? null
                                : () => _handleRequestAction(
                              orgId: orgId,
                              requestDocId: docId,
                              userId: userId,
                              action: 'rejected', context: context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
