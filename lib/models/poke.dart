import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Poke {
  final String pokeId;
  final String productId;
  final String productName;
  final String pokedBy; // employee or system
  final String pokedTo; // usually a manager
  final String status; // pending | in_progress | resolved | repoked
  final String message;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime autoRepokeAt; // next scheduled repoke time

  Poke({
    required this.pokeId,
    required this.productId,
    required this.productName,
    required this.pokedBy,
    required this.pokedTo,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.lastUpdated,
    required this.autoRepokeAt,
  });

  factory Poke.fromMap(String id, Map<String, dynamic> m) => Poke(
        pokeId: id,
        productId: m['product_id'] ?? '',
        productName: m['product_name'] ?? '',
        pokedBy: m['poked_by'] ?? '',
        pokedTo: m['poked_to'] ?? '',
        status: m['status'] ?? 'pending',
        message: m['message'] ?? '',
        createdAt: (m['created_at'] as Timestamp).toDate(),
        lastUpdated: (m['last_updated'] as Timestamp).toDate(),
        autoRepokeAt: (m['auto_repoke_at'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'poked_by': pokedBy,
        'poked_to': pokedTo,
        'status': status,
        'message': message,
        'created_at': Timestamp.fromDate(createdAt),
        'last_updated': Timestamp.fromDate(lastUpdated),
        'auto_repoke_at': Timestamp.fromDate(autoRepokeAt),
      };
}
