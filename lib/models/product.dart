class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      sku: json['sku'],
      price: json['price'].toDouble(),
      stock: json['stock'],
    );
  }
}
