import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String orgId;
  final String userVerificationStatus;
  final String? fcmToken;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.orgId,
    required this.userVerificationStatus,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Firestore -> AppUser
  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
    id: id,
    name: map['name'] ?? "",
    email: map['email'] ?? "",
    role: map['role'] ?? "",
    orgId: map['org_id'] ?? "",
    userVerificationStatus: map['userVerificationStatus'] ?? "unverified",
    fcmToken: map['fcm_token'],
    createdAt: map['created_at'],
    updatedAt: map['updated_at'],
  );

  // Convert AppUser -> Firestore map
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
    'org_id': orgId,
    'userVerificationStatus': userVerificationStatus,
    'fcm_token': fcmToken,
    'created_at': createdAt ?? FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
  };

  // For quick empty placeholder
  factory AppUser.empty() => AppUser(
    id: '',
    name: '',
    email: '',
    role: '',
    orgId: '',
    userVerificationStatus: 'unverified',
  );
}
