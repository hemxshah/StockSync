import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Replace with actual orgId context in your app
  String? orgId;

  CollectionReference get productsRef =>
      _db.collection('organizations').doc(orgId).collection('products');
  CollectionReference get pokesRef =>
      _db.collection('organizations').doc(orgId).collection('pokes');


  Stream<List<Product>> productsStream() {
    final org = orgId ?? (throw Exception('Org ID not set'));
    return productsRef.orderBy('updated_at', descending: true).snapshots().map(
            (snap) => snap.docs
            .map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addProduct(Map<String, dynamic> data, {File? imageFile}) async {
    final org = orgId ?? (throw Exception('Org ID not set'));
    String? url;
    if (imageFile != null) {
      final ref = _storage.ref().child('orgs/$orgId/products/${const Uuid().v4()}');
      final task = await ref.putFile(imageFile);
      url = await ref.getDownloadURL();
      data['image_url'] = url;
    }
    data['updated_at'] = FieldValue.serverTimestamp();
    await productsRef.add(data);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final ref = productsRef.doc(id);
    await ref.update({...data, 'updated_at': FieldValue.serverTimestamp()});

    // Auto-poke if below minQuantity
    final snap = await ref.get();
    final m = snap.data() as Map<String, dynamic>;
    final qty = (m['quantity'] ?? 0) as int;
    final minQty = (m['min_quantity'] ?? 0) as int;
    if (qty <= minQty) {
      await pokesRef.add({
        'product_id': id,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Product> getProduct(String id) async {
    final doc = await productsRef.doc(id).get();
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
