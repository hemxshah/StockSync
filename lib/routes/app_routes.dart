import 'package:flutter/material.dart';
import 'package:stock_sync/screens/dashboard/manager_homescreen.dart';
import '../screens/products/products_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/products/add_product_screen.dart';

class Routes {
  static const managerHome = '/';
  static const productsList = '/products';
  static const productDetail = '/product';
  static const addProduct = '/product/add';
}

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    Routes.managerHome: (ctx) => const ManagerHomeScreen(),
    Routes.productsList: (ctx) => const ProductsListScreen(),
    Routes.productDetail: (ctx) => const ProductDetailScreen(),
    Routes.addProduct: (ctx) => const AddProductScreen(),
  };
}
