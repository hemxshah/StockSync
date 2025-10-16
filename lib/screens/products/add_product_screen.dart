import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/primary_button.dart';
import 'package:stock_sync/services/firestore_services.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  String _category = 'General';
  File? _imageFile;
  bool _loading = false;

  final FirestoreService _fs = FirestoreService();

  Future<void> pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (x == null) return;
    setState(() => _imageFile = File(x.path));
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text.trim()) ?? 0,
        'min_quantity': int.tryParse(_minCtrl.text.trim()) ?? 0,
        'category': _category,
        'manager_id': 'manager_placeholder',
      };
      _fs.orgId = 'demoOrg';
      await _fs.addProduct(data, imageFile: _imageFile);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _minCtrl, decoration: const InputDecoration(labelText: 'Min Quantity'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Cement', child: Text('Cement')),
                DropdownMenuItem(value: 'Paints', child: Text('Paints')),
              ],
              onChanged: (v) => setState(() => _category = v!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            Text('Product Image (optional)', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImage,
              child: _imageFile == null
                  ? Container(height: 140, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.add_a_photo)))
                  : Image.file(_imageFile!, height: 140, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Add Product', onPressed: submit, loading: _loading),
          ]),
        ),
      ),
    );
  }
}
