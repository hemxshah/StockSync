import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controller/product_controller.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/empty_state.dart';
import '../../models/product.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(title: 'No products', subtitle: 'Add your first product using the + button.');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
              return ProductListTile(product: p);
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 6,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              ShimmerWidget.circle(size: 64),
              const SizedBox(width: 12),
              Expanded(child: ShimmerWidget.rect(height: 18)),
            ]),
          ),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/product/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductListTile extends StatelessWidget {
  final Product product;
  const ProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isLow = product.quantity <= product.minQuantity;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)));
        },
        leading: Hero(
          tag: 'prod-${product.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl ?? '',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) => ShimmerWidget.rect(width: 64, height: 64),
              errorWidget: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: Colors.grey.shade200,
                child: Icon(Icons.image, color: Colors.grey[400]),
              ),
            ),
          ),
        ),

        title: Text(product.name),
        subtitle: Text('Qty: ${product.quantity} • Min: ${product.minQuantity}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLow) Container(padding: const EdgeInsets.symmetric(horizontal:8,vertical:6), decoration: BoxDecoration(color: Colors.orange.shade100,borderRadius: BorderRadius.circular(8)), child: Text('Low', style: TextStyle(color: Colors.orange.shade800))),
            const SizedBox(height: 6),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
