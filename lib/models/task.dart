import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Task {
  final String taskId;
  final String title;
  final String description;
  final String assignedTo;
  final String assignedBy;
  final String status; // pending | in_progress | completed | verified
  final String? relatedPokeId; // if this task came from a poke
  final String productId;
  final int? recountQuantity; // optional, when recounting stock
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.productId,
    required this.createdAt,
    this.relatedPokeId,
    this.recountQuantity,
    this.completedAt,
  });

  factory Task.fromMap(String id, Map<String, dynamic> m) => Task(
        taskId: id,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        assignedTo: m['assigned_to'] ?? '',
        assignedBy: m['assigned_by'] ?? '',
        status: m['status'] ?? 'pending',
        relatedPokeId: m['related_poke_id'],
        productId: m['product_id'] ?? '',
        recountQuantity: m['recount_quantity'],
        createdAt: (m['created_at'] as Timestamp).toDate(),
        completedAt: m['completed_at'] != null
            ? (m['completed_at'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'assigned_by': assignedBy,
        'status': status,
        'related_poke_id': relatedPokeId,
        'product_id': productId,
        'recount_quantity': recountQuantity,
        'created_at': Timestamp.fromDate(createdAt),
        'completed_at':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}
