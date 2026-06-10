// lib/database/database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('smart_inventory.db');
      return _database!;
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    debugPrint('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) {
        debugPrint('✅ Database opened successfully');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('🔄 Creating database tables...');
    
    // Tabel User 
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        store_name TEXT NOT NULL,
        profile_image TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    debugPrint('✅ Table users created');

    // Tabel Supplier (dengan kolom address)
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        email TEXT NOT NULL,
        address TEXT
      )
    ''');
    debugPrint('✅ Table suppliers created with address column');

    // Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        supplier_id INTEGER,
        stock INTEGER NOT NULL,
        min_stock INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        description TEXT,
        image_path TEXT,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
      )
    ''');
    debugPrint('✅ Table products created');

    // Tabel Transaksi Utama
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        supplier_id INTEGER,
        customer_name TEXT,
        total_amount REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        grand_total REAL NOT NULL,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
      )
    ''');
    debugPrint('✅ Table transactions created');

    // Tabel Detail Transaksi
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('✅ Table transaction_items created');

    // Tabel Riwayat Stok
    await db.execute('''
      CREATE TABLE stock_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        notes TEXT,
        created_by TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
    debugPrint('✅ Table stock_history created');
    
    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_supplier ON products(supplier_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(transaction_date)');
    await db.execute('CREATE INDEX idx_stock_history_product ON stock_history(product_id)');
    await db.execute('CREATE INDEX idx_stock_history_date ON stock_history(date)');
    
    debugPrint('🎉 All database tables created successfully!');
  }

  Future<bool> isUserExist() async {
    try {
      final db = await instance.database;
      final result = await db.query('users', limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking user existence: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final db = await instance.database;
      final result = await db.query('users', limit: 1);
      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  Future<void> clearDatabase() async {
    try {
      final db = await instance.database;
      await db.delete('transaction_items');
      await db.delete('stock_history');
      await db.delete('transactions');
      await db.delete('products');
      await db.delete('suppliers');
      await db.delete('users');
      await db.execute('DELETE FROM sqlite_sequence');
      debugPrint('🗑️ Database cleared and sequences reset');
    } catch (e) {
      debugPrint('❌ Error clearing database: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = await instance.database;
      await db.close();
      _database = null;
      debugPrint('🔒 Database closed');
    } catch (e) {
      debugPrint('❌ Error closing database: $e');
    }
  }
  
  // Helper method untuk SQL increment
  static String sql(String expression) {
    return expression;
  }
}