import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final int minQuantity;
  final String category;
  final String managerId;
  final String? imageUrl;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.minQuantity,
    required this.category,
    required this.managerId,
    this.imageUrl,
    required this.updatedAt,
  });

  factory Product.fromMap(String id, Map<String, dynamic> m) {
    final updatedAtRaw = m['updated_at'];
    DateTime updatedAt;
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    } else if (updatedAtRaw is DateTime) {
      updatedAt = updatedAtRaw;
    } else {
      updatedAt = DateTime.now();
    }

    return Product(
      id: id,
      name: m['name'] ?? '',
      description: m['description'],
      quantity: (m['quantity'] ?? 0) as int,
      minQuantity: (m['min_quantity'] ?? 0) as int,
      category: m['category'] ?? '',
      managerId: m['manager_id'] ?? '',
      imageUrl: m['image_url'],
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'min_quantity': minQuantity,
    'category': category,
    'manager_id': managerId,
    'image_url': imageUrl,
    'updated_at': FieldValue.serverTimestamp(),
  };
}
