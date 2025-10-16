import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';

class SessionController extends StateNotifier<String?> {
  SessionController() : super(null) {
    _init();
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _init() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      state = userDoc['org_id'];
    }
  }
}

final orgIdProvider =
StateNotifierProvider<SessionController, String?>((ref) => SessionController());
