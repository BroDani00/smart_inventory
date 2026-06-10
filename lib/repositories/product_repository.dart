// lib/repositories/product_repository.dart
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all products with supplier name
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT products.*, suppliers.name AS supplier_name 
      FROM products 
      LEFT JOIN suppliers ON products.supplier_id = suppliers.id
      ORDER BY products.id DESC
    ''');
    return maps.map((x) => Product.fromMap(x)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT products.*, suppliers.name AS supplier_name 
      FROM products 
      LEFT JOIN suppliers ON products.supplier_id = suppliers.id
      WHERE products.id = ?
    ''', [id]);
    
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT products.*, suppliers.name AS supplier_name 
      FROM products 
      LEFT JOIN suppliers ON products.supplier_id = suppliers.id
      WHERE products.stock <= products.min_stock
      ORDER BY products.stock ASC
    ''');
    return maps.map((x) => Product.fromMap(x)).toList();
  }

  // Add product
  Future<int> addProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  // Update product
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Update product stock only
  Future<int> updateProductStock(int productId, int newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Delete product
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    // Check if product has transactions
    final transactions = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM transaction_items 
      WHERE product_id = ?
    ''', [id]);
    
    if ((transactions.first['count'] as int) > 0) {
      throw Exception('Tidak bisa menghapus produk yang sudah memiliki transaksi');
    }
    
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Get total products count
  Future<int> getTotalProductsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  // Get total inventory value (based on cost price)
  Future<double> getTotalInventoryValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(stock * cost_price) as total FROM products'
    );
    return (result.first['total'] ?? 0) as double;
  }

  // Get product profit margin
  Future<double> getProductProfitMargin(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        (sell_price - cost_price) / cost_price * 100 as margin
      FROM products 
      WHERE id = ?
    ''', [productId]);
    
    if (result.isNotEmpty && result.first['margin'] != null) {
      return result.first['margin'] as double;
    }
    return 0.0;
  }
    // Tambahkan method untuk bulk update stock
  Future<void> updateMultipleProductStock(Map<int, int> stockUpdates) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var entry in stockUpdates.entries) {
        await txn.update(
          'products',
          {'stock': entry.value},
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  // Tambahkan method untuk get multiple products by ids
  Future<Map<int, Product>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT products.*, suppliers.name AS supplier_name 
      FROM products 
      LEFT JOIN suppliers ON products.supplier_id = suppliers.id
      WHERE products.id IN (${ids.join(',')})
    ''');
    
    return {
      for (var map in maps) 
        map['id'] as int: Product.fromMap(map)
    };
  }

  Future<void> debugPrintAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    debugPrint('📊 DATABASE PRODUCTS: ${maps.length} products');
    for (var map in maps) {
      debugPrint('   - ID: ${map['id']}, Name: ${map['name']}, Code: ${map['code']}');
    }
  }
}