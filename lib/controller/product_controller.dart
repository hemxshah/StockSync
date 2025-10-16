import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/product.dart';
import '../services/firestore_services.dart';
import 'session_controller.dart';

/// --- Firestore Service Provider ---
/// Dynamically updates FirestoreService with the orgId of the logged-in user.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final service = FirestoreService();

  // Watch orgId from SessionController
  final orgId = ref.watch(orgIdProvider);

  if (orgId != null) {
    service.orgId = orgId;
  }

  return service;
});

/// --- Products Stream Provider ---
/// Streams product list in real-time for the current organization.
final productsStreamProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final orgId = ref.watch(orgIdProvider);
  final service = ref.watch(firestoreServiceProvider);

  // Wait until orgId is loaded
  if (orgId == null) {
    return const Stream.empty();
  }

  service.orgId = orgId;
  return service.productsStream();
});

/// --- ProductNotifier ---
/// Handles CRUD operations + optimistic updates.
class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final Ref ref;
  final FirestoreService fs;

  ProductNotifier(this.ref, this.fs) : super(const AsyncLoading()) {
    _listen();
  }

  /// Listen to Firestore stream and sync with state.
  void _listen() {
    final orgId = ref.read(orgIdProvider);
    if (orgId == null) return;
    fs.orgId = orgId;

    fs.productsStream().listen((list) {
      state = AsyncData(list);
    }, onError: (e, st) {
      state = AsyncError(e, st);
    });
  }

  /// Add product with optimistic UI update
  Future<void> addProduct(Product p) async {
    final prev = state.value ?? [];
    state = AsyncData([...prev, p]);

    try {
      await fs.addProduct(p.toMap());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Update product
  Future<void> updateProduct(Product p) async {
    final list = [...?state.value];
    final idx = list.indexWhere((x) => x.id == p.id);
    if (idx != -1) list[idx] = p;
    state = AsyncData(list);
    await fs.updateProduct(p.id, p.toMap());
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    final list = [...?state.value];
    state = AsyncData(list.where((x) => x.id != id).toList());
    await fs.productsRef.doc(id).delete();
  }
}

/// --- ProductNotifier Provider ---
/// Main access point for CRUD + state across UI.
final productNotifierProvider =
StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final fs = ref.watch(firestoreServiceProvider);
  return ProductNotifier(ref, fs);
});
