import 'package:cloud_firestore/cloud_firestore.dart';
class Product {

final String productId;
final String productName;
final String productDescription;
final int quantity;
final int minQuantity;
final String category;
final String managerId;
final DateTime updatedAt;
final String? imageUrl;

  Product({
    required this.productId, 
    required this.productName, 
    required this.productDescription, 
    required this.quantity, 
    required this.minQuantity, 
    required this.category, 
    required this.managerId, 
    required this.updatedAt, 
    this.imageUrl});

factory Product.fromMap(String id, Map<String, dynamic> map)=>Product(
  productId: id, 
  productName: map['productName'] ?? '', 
  productDescription: map['productDescription'] ?? '', 
  quantity: map['quantity'] ?? '', 
  minQuantity: map['min_quantity'] ?? '', 
  category: map['category'] ?? '', 
  managerId: map['manager_id'] ?? '', 
  updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
  imageUrl: map['image_url']);

Map<String, dynamic> toMap()=> {
'product_name' : productName,
'product_description' : productDescription,
'quantity' : quantity,
'min_quantity' : minQuantity,
'category' : category,
'manager_id' : managerId,
'updated_at' : Timestamp.fromDate(updatedAt),
};
    

}