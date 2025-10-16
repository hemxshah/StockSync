import 'package:flutter/material.dart';
import 'package:stock_sync/services/firestore_services.dart';
import '../../models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/shimmer_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  Product? product;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (widget.productId == null) return;
    _fs.orgId = 'demoOrg';
    try {
      product = await _fs.getProduct(widget.productId!);
    } catch (e) {
      // handle
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () {})],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : product == null
          ? const Center(child: Text('Product not found'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (product!.imageUrl != null && product!.imageUrl!.isNotEmpty)
              Hero(
                tag: 'prod-${product!.id}',
                child: CachedNetworkImage(
                  imageUrl: product!.imageUrl!,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 220, child: ShimmerWidget.rect(height: 220)),
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey.shade100,
                child: const Icon(Icons.image, size: 96),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product!.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(product!.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Row(children: [
                  _MetricBox(label: 'Quantity', value: '${product!.quantity}'),
                  const SizedBox(width: 12),
                  _MetricBox(label: 'Min Quantity', value: '${product!.minQuantity}'),
                ]),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // manual poke
                  },
                  icon: const Icon(Icons.notification_important),
                  label: const Text('Poke Manager'),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ]),
      ),
    );
  }
}
