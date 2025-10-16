import 'package:flutter/material.dart';

class ManagerProductsTab extends StatelessWidget {
  const ManagerProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your product list UI; kept minimal for now
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: open add product dialog/screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(child: Text('Product list will appear here')),
          ),
        ],
      ),
    );
  }
}
