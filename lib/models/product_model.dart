// lib/models/product_model.dart
class Product {
  final int? id;
  final String code;
  final String name;
  final String category;
  final int? supplierId;
  final int stock;
  final int minStock;
  final double costPrice;
  final double sellPrice;
  final String? description;
  final String? imagePath;
  final String? supplierName;

  Product({
    this.id,
    required this.code,
    required this.name,
    required this.category,
    this.supplierId,
    required this.stock,
    required this.minStock,
    required this.costPrice,
    required this.sellPrice,
    this.description,
    this.imagePath,
    this.supplierName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'supplier_id': supplierId,
      'stock': stock,
      'min_stock': minStock,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'description': description,
      'image_path': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      supplierId: map['supplier_id'] is int 
          ? map['supplier_id'] 
          : (map['supplier_id'] != null ? int.tryParse(map['supplier_id'].toString()) : null),
      stock: map['stock'] is int 
          ? map['stock'] 
          : (int.tryParse(map['stock'].toString()) ?? 0),
      minStock: map['min_stock'] is int 
          ? map['min_stock'] 
          : (int.tryParse(map['min_stock'].toString()) ?? 0),
      costPrice: map['cost_price'] is double 
          ? map['cost_price'] 
          : (double.tryParse(map['cost_price'].toString()) ?? 0.0),
      sellPrice: map['sell_price'] is double 
          ? map['sell_price'] 
          : (double.tryParse(map['sell_price'].toString()) ?? 0.0),
      description: map['description']?.toString(),
      imagePath: map['image_path']?.toString(),
      supplierName: map['supplier_name']?.toString(),
    );
  }

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? category,
    int? supplierId,
    int? stock,
    int? minStock,
    double? costPrice,
    double? sellPrice,
    String? description,
    String? imagePath,
    String? supplierName,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      supplierId: supplierId ?? this.supplierId,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  double get totalStockValue => stock * costPrice;
  double get potentialProfit => stock * (sellPrice - costPrice);
  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;
}