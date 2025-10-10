class AppUser{
  final String id;
  final String name;
  final String email;
  final String role;
  final String orgId;
  final String? fcmToken;

  AppUser({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.role, 
    required this.orgId, 
    this.fcmToken,});

    factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
      id: id, 
      name: map['name'] ?? "", 
      email: map['email'] ?? "", 
      role: map['role'] ?? "", 
      orgId: map['orgId'] ?? "",
      fcmToken: map['fcm_token'],);

    Map<String,dynamic> toMap()=> {
      'name' : name,
      'email' : email,
      'role' : role,
      'orgId' : orgId,
      'fcmToken' : fcmToken
    };
}