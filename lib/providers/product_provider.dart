import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final productListProvider = Provider<List<Product>>((ref) {
  return [
    Product(id: '1', name: 'Shirt', sku: 'SKU001', price: 499.0, stock: 20),
    Product(id: '2', name: 'Jeans', sku: 'SKU002', price: 999.0, stock: 15),
    Product(id: '3', name: 'Kurta', sku: 'SKU003', price: 799.0, stock: 10),
  ];
});
