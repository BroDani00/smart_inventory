// lib/repositories/transaction_repository.dart
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import '../models/stock_history_model.dart'; // ✅ DIPERLUKAN untuk stock history
import 'product_repository.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ProductRepository _productRepo = ProductRepository();

  // ==================== TRANSAKSI PEMBELIAN DENGAN PRODUK BARU ====================
  
  Future<int> createPurchaseTransactionWithNewProducts({
    required int supplierId,
    required List<TransactionItem> items,
    required List<Map<String, dynamic>> newProducts,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    final db = await _dbHelper.database;
    
    // Hitung total amount
    double totalAmount = items.fold(0, (sum, item) => sum + item.subtotal);
    double grandTotal = totalAmount;
    
    final now = DateTime.now().toIso8601String();
    
    return await db.transaction((txn) async {
      debugPrint('📦 Memulai transaksi pembelian dengan ${newProducts.length} produk baru');
      
      // 1. Simpan produk baru terlebih dahulu dan catat mapping ID
      final Map<int, int> newProductIdMap = {};
      
      for (var newProduct in newProducts) {
        final productMap = {
          'code': newProduct['code'],
          'name': newProduct['name'],
          'category': newProduct['category'],
          'supplier_id': supplierId,
          'stock': newProduct['stock'],
          'min_stock': 5,
          'cost_price': newProduct['costPrice'],
          'sell_price': newProduct['sellPrice'],
          'description': '',
          'image_path': '',
        };
        
        final productId = await txn.insert('products', productMap);
        debugPrint('✅ Produk baru disimpan: ${newProduct['name']} (ID: $productId)');
        
        // Simpan mapping dari ID sementara (negatif) ke ID asli
        for (var item in items) {
          if (item.productId < 0 && item.productCode == newProduct['code']) {
            newProductIdMap[item.productId] = productId;
            debugPrint('📌 Mapping ID sementara ${item.productId} -> ID asli $productId');
            break;
          }
        }
        
        // ✅ Catat stock history untuk produk baru (menggunakan StockHistory model)
        if (newProduct['stock'] > 0) {
          final stockMovement = StockHistory(
            id: null,
            productId: productId,
            productName: newProduct['name'],
            type: 'Masuk',
            quantity: newProduct['stock'],
            date: now,
            referenceId: null,
            referenceType: 'adjustment',
            notes: 'Stok awal dari pembelian supplier',
            createdBy: createdBy,
          );
          await txn.insert('stock_history', stockMovement.toMap());
          debugPrint('📊 Stok awal produk baru: ${newProduct['stock']} unit');
        }
      }
      
      // 2. Update item dengan productId yang benar
      final List<TransactionItem> updatedItems = [];
      
      for (var item in items) {
        if (item.productId < 0 && newProductIdMap.containsKey(item.productId)) {
          // Produk baru - ganti dengan ID asli
          updatedItems.add(TransactionItem(
            id: item.id,
            transactionId: item.transactionId,
            productId: newProductIdMap[item.productId]!,
            productName: item.productName,
            productCode: item.productCode,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            subtotal: item.subtotal,
          ));
          debugPrint('🔄 Update item produk baru: ${item.productName} (ID: ${newProductIdMap[item.productId]})');
        } else if (item.productId > 0) {
          // Produk yang sudah ada
          updatedItems.add(item);
          debugPrint('📦 Item produk lama: ${item.productName} (ID: ${item.productId})');
        }
      }
      
      // 3. Insert transaksi utama
      final transaction = {
        'type': 'Pembelian',
        'transaction_date': now,
        'supplier_id': supplierId,
        'customer_name': null,
        'total_amount': totalAmount,
        'discount': 0,
        'tax': 0,
        'grand_total': grandTotal,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': now,
      };
      
      final transactionId = await txn.insert('transactions', transaction);
      debugPrint('✅ Transaksi pembelian disimpan (ID: $transactionId)');
      
      // 4. Insert detail items dan update stok produk
      for (var item in updatedItems) {
        // Insert transaction item
        final itemMap = {
          'transaction_id': transactionId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
        };
        await txn.insert('transaction_items', itemMap);
        
        // Update stok produk (stok bertambah)
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantity, item.productId],
        );
        debugPrint('📦 Stok produk ID ${item.productId} bertambah ${item.quantity}');
        
        // ✅ Catat ke stock_history (menggunakan StockHistory model)
        final stockMovement = StockHistory(
          id: null,
          productId: item.productId,
          productName: item.productName ?? 'Produk',
          type: 'Masuk',
          quantity: item.quantity,
          date: now,
          referenceId: transactionId,
          referenceType: 'transaction',
          notes: 'Pembelian dari supplier',
          createdBy: createdBy,
        );
        await txn.insert('stock_history', stockMovement.toMap());
      }
      
      debugPrint('🎉 Transaksi pembelian selesai!');
      return transactionId;
    });
  }

  // ==================== TRANSAKSI PEMBELIAN (TANPA PRODUK BARU) ====================
  
  Future<int> createPurchaseTransaction({
    required int supplierId,
    required List<TransactionItem> items,
    required double discount,
    required double tax,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    final db = await _dbHelper.database;
    
    double totalAmount = items.fold(0, (sum, item) => sum + item.subtotal);
    double grandTotal = totalAmount - discount + tax;
    
    final now = DateTime.now().toIso8601String();
    
    final transaction = {
      'type': 'Pembelian',
      'transaction_date': now,
      'supplier_id': supplierId,
      'customer_name': null,
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': now,
    };
    
    return await db.transaction((txn) async {
      debugPrint('📦 Memulai transaksi pembelian dengan ${items.length} item');
      
      final transactionId = await txn.insert('transactions', transaction);
      debugPrint('✅ Transaksi pembelian disimpan (ID: $transactionId)');
      
      for (var item in items) {
        // Insert transaction item
        final itemMap = {
          'transaction_id': transactionId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
        };
        await txn.insert('transaction_items', itemMap);
        
        // Update stok produk
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantity, item.productId],
        );
        
        // ✅ Catat ke stock_history (menggunakan StockHistory model)
        final stockMovement = StockHistory(
          id: null,
          productId: item.productId,
          productName: item.productName ?? 'Produk',
          type: 'Masuk',
          quantity: item.quantity,
          date: now,
          referenceId: transactionId,
          referenceType: 'transaction',
          notes: 'Pembelian dari supplier',
          createdBy: createdBy,
        );
        await txn.insert('stock_history', stockMovement.toMap());
        
        debugPrint('📦 Stok produk ID ${item.productId} bertambah ${item.quantity}');
      }
      
      debugPrint('🎉 Transaksi pembelian selesai!');
      return transactionId;
    });
  }

  // ==================== TRANSAKSI PENJUALAN ====================
  
  Future<int> createSaleTransaction({
    required String customerName,
    required List<TransactionItem> items,
    required double discount,
    required double tax,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    final db = await _dbHelper.database;
    
    double totalAmount = items.fold(0, (sum, item) => sum + item.subtotal);
    double grandTotal = totalAmount - discount + tax;
    
    // Cek stok sebelum transaksi
    for (var item in items) {
      final product = await _productRepo.getProductById(item.productId);
      if (product == null) {
        throw Exception('Produk dengan ID ${item.productId} tidak ditemukan');
      }
      if (product.stock < item.quantity) {
        throw Exception('Stok ${product.name} tidak mencukupi (tersedia: ${product.stock}, diminta: ${item.quantity})');
      }
    }
    
    final now = DateTime.now().toIso8601String();
    
    final transaction = {
      'type': 'Penjualan',
      'transaction_date': now,
      'supplier_id': null,
      'customer_name': customerName,
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': now,
    };
    
    return await db.transaction((txn) async {
      debugPrint('💰 Memulai transaksi penjualan untuk customer: $customerName');
      
      final transactionId = await txn.insert('transactions', transaction);
      debugPrint('✅ Transaksi penjualan disimpan (ID: $transactionId)');
      
      for (var item in items) {
        // Insert transaction item
        final itemMap = {
          'transaction_id': transactionId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
        };
        await txn.insert('transaction_items', itemMap);
        
        // Update stok produk (stok berkurang)
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
        
        // ✅ Catat ke stock_history (menggunakan StockHistory model)
        final stockMovement = StockHistory(
          id: null,
          productId: item.productId,
          productName: item.productName ?? 'Produk',
          type: 'Keluar',
          quantity: item.quantity,
          date: now,
          referenceId: transactionId,
          referenceType: 'transaction',
          notes: 'Penjualan ke $customerName',
          createdBy: createdBy,
        );
        await txn.insert('stock_history', stockMovement.toMap());
        
        debugPrint('📦 Stok produk ID ${item.productId} berkurang ${item.quantity}');
      }
      
      debugPrint('🎉 Transaksi penjualan selesai!');
      return transactionId;
    });
  }

  // ==================== MUTASI STOK MANUAL ====================
  
  Future<void> recordDamagedGoods({
    required int productId,
    required int quantity,
    required String notes,
    required String createdBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final product = await _productRepo.getProductById(productId);
    if (product == null) {
      throw Exception('Produk tidak ditemukan');
    }
    if (product.stock < quantity) {
      throw Exception('Stok tidak mencukupi');
    }
    
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock - ? WHERE id = ?',
        [quantity, productId],
      );
      
      // ✅ Catat ke stock_history (menggunakan StockHistory model)
      final stockMovement = StockHistory(
        id: null,
        productId: productId,
        productName: product.name,
        type: 'Rusak',
        quantity: quantity,
        date: now,
        referenceId: null,
        referenceType: 'adjustment',
        notes: notes.isEmpty ? 'Barang rusak' : notes,
        createdBy: createdBy,
      );
      await txn.insert('stock_history', stockMovement.toMap());
      
      debugPrint('⚠️ Barang rusak dicatat: Produk ID $productId, quantity $quantity');
    });
  }
  
  Future<void> recordExpiredGoods({
    required int productId,
    required int quantity,
    required String notes,
    required String createdBy,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final product = await _productRepo.getProductById(productId);
    if (product == null) {
      throw Exception('Produk tidak ditemukan');
    }
    if (product.stock < quantity) {
      throw Exception('Stok tidak mencukupi');
    }
    
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock - ? WHERE id = ?',
        [quantity, productId],
      );
      
      // ✅ Catat ke stock_history (menggunakan StockHistory model)
      final stockMovement = StockHistory(
        id: null,
        productId: productId,
        productName: product.name,
        type: 'Expired',
        quantity: quantity,
        date: now,
        referenceId: null,
        referenceType: 'adjustment',
        notes: notes.isEmpty ? 'Barang kadaluarsa' : notes,
        createdBy: createdBy,
      );
      await txn.insert('stock_history', stockMovement.toMap());
      
      debugPrint('⏰ Barang expired dicatat: Produk ID $productId, quantity $quantity');
    });
  }

  // ==================== GET DATA TRANSAKSI ====================
  
  Future<List<Transaction>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        s.name as supplier_name,
        COUNT(DISTINCT ti.id) as total_items,
        COALESCE(SUM(ti.quantity), 0) as total_quantity
      FROM transactions t
      LEFT JOIN suppliers s ON t.supplier_id = s.id
      LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
      GROUP BY t.id
      ORDER BY t.transaction_date DESC
    ''');
    return maps.map((x) => Transaction.fromMap(x)).toList();
  }
  
  Future<Map<String, dynamic>> getTransactionWithDetails(int transactionId) async {
    final db = await _dbHelper.database;
    
    final transactionMap = await db.rawQuery('''
      SELECT 
        t.*,
        s.name as supplier_name,
        COUNT(DISTINCT ti.id) as total_items,
        COALESCE(SUM(ti.quantity), 0) as total_quantity
      FROM transactions t
      LEFT JOIN suppliers s ON t.supplier_id = s.id
      LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
      WHERE t.id = ?
      GROUP BY t.id
    ''', [transactionId]);
    
    if (transactionMap.isEmpty) {
      throw Exception('Transaksi tidak ditemukan');
    }
    
    final transaction = Transaction.fromMap(transactionMap.first);
    
    final itemsMap = await db.rawQuery('''
      SELECT 
        ti.*,
        p.name as product_name,
        p.code as product_code,
        p.cost_price
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);
    
    final items = itemsMap.map((x) => TransactionItem.fromMap(x)).toList();
    
    return {
      'transaction': transaction,
      'items': items,
    };
  }
  
  Future<List<Transaction>> getTransactionsByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        s.name as supplier_name,
        COUNT(DISTINCT ti.id) as total_items,
        COALESCE(SUM(ti.quantity), 0) as total_quantity
      FROM transactions t
      LEFT JOIN suppliers s ON t.supplier_id = s.id
      LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
      WHERE t.transaction_date BETWEEN ? AND ?
      GROUP BY t.id
      ORDER BY t.transaction_date DESC
    ''', [startDate, endDate]);
    return maps.map((x) => Transaction.fromMap(x)).toList();
  }
  
  Future<List<Transaction>> getTransactionsByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        s.name as supplier_name,
        COUNT(DISTINCT ti.id) as total_items,
        COALESCE(SUM(ti.quantity), 0) as total_quantity
      FROM transactions t
      LEFT JOIN suppliers s ON t.supplier_id = s.id
      LEFT JOIN transaction_items ti ON t.id = ti.transaction_id
      WHERE t.type = ?
      GROUP BY t.id
      ORDER BY t.transaction_date DESC
    ''', [type]);
    return maps.map((x) => Transaction.fromMap(x)).toList();
  }

  // ==================== STATISTIK DAN LAPORAN ====================
  
  Future<double> getTotalSalesToday() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total), 0) as total
      FROM transactions
      WHERE type = 'Penjualan' AND transaction_date LIKE ?
    ''', ['$today%']);
    return (result.first['total'] ?? 0) as double;
  }
  
  Future<double> getTotalPurchasesToday() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total), 0) as total
      FROM transactions
      WHERE type = 'Pembelian' AND transaction_date LIKE ?
    ''', ['$today%']);
    return (result.first['total'] ?? 0) as double;
  }
  
  Future<int> getTotalTransactionsToday() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM transactions
      WHERE transaction_date LIKE ?
    ''', ['$today%']);
    return (result.first['total'] ?? 0) as int;
  }
  
  Future<Map<String, double>> getProfitLossReport(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    
    // Total penjualan
    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total), 0) as total_sales
      FROM transactions
      WHERE type = 'Penjualan' 
        AND transaction_date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    final totalSales = salesResult.first['total_sales'] as double;
    
    // Harga pokok penjualan (HPP)
    final hppResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.quantity * p.cost_price), 0) as total_hpp
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      JOIN products p ON ti.product_id = p.id
      WHERE t.type = 'Penjualan'
        AND t.transaction_date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    final totalHpp = hppResult.first['total_hpp'] as double;
    
    // Total pembelian (pengeluaran)
    final purchaseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total), 0) as total_purchases
      FROM transactions
      WHERE type = 'Pembelian'
        AND transaction_date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    final totalPurchases = purchaseResult.first['total_purchases'] as double;
    
    // Kerugian karena rusak & expired
    final lossResult = await db.rawQuery('''
      SELECT COALESCE(SUM(sh.quantity * p.cost_price), 0) as total_loss
      FROM stock_history sh
      JOIN products p ON sh.product_id = p.id
      WHERE sh.type IN ('Rusak', 'Expired')
        AND sh.date BETWEEN ? AND ?
    ''', [startDate, endDate]);
    final totalLoss = lossResult.first['total_loss'] as double;
    
    final grossProfit = totalSales - totalHpp;
    final netProfit = grossProfit - totalLoss - totalPurchases;
    
    return {
      'total_sales': totalSales,
      'total_hpp': totalHpp,
      'gross_profit': grossProfit,
      'total_purchases': totalPurchases,
      'total_loss': totalLoss,
      'net_profit': netProfit,
    };
  }

  // ==================== PEMBATALAN TRANSAKSI ====================
  
  Future<void> cancelTransaction(int transactionId) async {
    final db = await _dbHelper.database;
    final transactionDetail = await getTransactionWithDetails(transactionId);
    final transactionData = transactionDetail['transaction'] as Transaction;
    final items = transactionDetail['items'] as List<TransactionItem>;
    
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      
      for (var item in items) {
        if (transactionData.type == 'Penjualan') {
          // Penjualan dibatalkan -> stok kembali
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
          
          // ✅ Catat ke stock_history
          final stockMovement = StockHistory(
            id: null,
            productId: item.productId,
            productName: item.productName ?? 'Produk',
            type: 'Masuk',
            quantity: item.quantity,
            date: now,
            referenceId: transactionId,
            referenceType: 'cancellation',
            notes: 'Pembatalan penjualan #$transactionId',
            createdBy: 'system',
          );
          await txn.insert('stock_history', stockMovement.toMap());
        } else {
          // Pembelian dibatalkan -> stok berkurang
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.productId],
          );
          
          // ✅ Catat ke stock_history
          final stockMovement = StockHistory(
            id: null,
            productId: item.productId,
            productName: item.productName ?? 'Produk',
            type: 'Keluar',
            quantity: item.quantity,
            date: now,
            referenceId: transactionId,
            referenceType: 'cancellation',
            notes: 'Pembatalan pembelian #$transactionId',
            createdBy: 'system',
          );
          await txn.insert('stock_history', stockMovement.toMap());
        }
      }
      
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
      debugPrint('🗑️ Transaksi ID $transactionId dibatalkan');
    });
  }
}