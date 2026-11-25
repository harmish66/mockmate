class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
  });

  final int id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String description;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.parse(json['price'].toString()),
      stock: json['stock'] is int
          ? json['stock'] as int
          : int.parse(json['stock']?.toString() ?? '0'),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'description': description,
    };
  }
}
