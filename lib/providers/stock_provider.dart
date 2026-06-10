// lib/providers/stock_provider.dart
import 'package:flutter/material.dart';
import '../models/stock_history_model.dart';
import '../repositories/stock_repository.dart';
import '../repositories/product_repository.dart';

class StockProvider with ChangeNotifier {
  final StockRepository _stockRepository = StockRepository();
  final ProductRepository _productRepository = ProductRepository();
  
  List<StockHistory> _stockHistory = [];
  List<StockHistory> _filteredHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'Semua';

  List<StockHistory> get stockHistory => _filteredHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  // Analytics
  int _stockInToday = 0;
  int _stockOutToday = 0;
  double _totalLossFromDamage = 0;
  double _totalLossFromExpired = 0;
  
  int get stockInToday => _stockInToday;
  int get stockOutToday => _stockOutToday;
  double get totalLossFromDamage => _totalLossFromDamage;
  double get totalLossFromExpired => _totalLossFromExpired;
  double get totalLoss => _totalLossFromDamage + _totalLossFromExpired;

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Load all stock history
  Future<void> loadStockHistory() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _stockHistory = await _stockRepository.getAllStockHistory();
      _applyFilter();
      await _loadTodayStats();
      await _loadLossStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Force reload stock history (untuk refresh setelah ada perubahan)
  Future<void> refreshStockHistory() async {
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      _stockHistory = await _stockRepository.getAllStockHistory();
      _applyFilter();
      await _loadTodayStats();
      await _loadLossStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Apply filter
  void setFilter(String type) {
    _filterType = type;
    _applyFilter();
    _safeNotifyListeners();
  }

  void _applyFilter() {
    if (_filterType == 'Semua') {
      _filteredHistory = List.from(_stockHistory);
    } else {
      _filteredHistory = _stockHistory
          .where((h) => h.type == _filterType)
          .toList();
    }
  }

  // Record stock movement (manual adjustment)
  Future<bool> recordStockMovement({
    required int productId,
    required String type,
    required int quantity,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        throw Exception('Produk tidak ditemukan');
      }

      int newStock = product.stock;
      if (type == 'Masuk') {
        newStock += quantity;
      } else if (type == 'Keluar' || type == 'Rusak' || type == 'Expired') {
        newStock -= quantity;
        if (newStock < 0) newStock = 0;
      }

      // Update product stock
      await _productRepository.updateProductStock(productId, newStock);

      // ✅ Perbaiki: Gunakan StockHistory object
      final stockMovement = StockHistory(
        id: null,
        productId: productId,
        productName: product.name,
        type: type,
        quantity: quantity,
        date: DateTime.now().toIso8601String(),
        referenceId: null,
        referenceType: 'adjustment',
        notes: notes,
        createdBy: createdBy,
      );
      await _stockRepository.addStockMovement(stockMovement);

      // Refresh semua data yang terkait
      await _refreshAllRelatedData();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Refresh semua data yang terkait dengan stok
  Future<void> _refreshAllRelatedData() async {
    // Reload stock history
    await refreshStockHistory();
  }

  // Load today's statistics
  Future<void> _loadTodayStats() async {
    try {
      _stockInToday = await _stockRepository.getStockInToday();
      _stockOutToday = await _stockRepository.getStockOutToday();
    } catch (e) {
      // Silent fail for stats
    }
  }
  
  // Load loss statistics
  Future<void> _loadLossStats() async {
    try {
      _totalLossFromDamage = await _stockRepository.getTotalLossFromDamageAndExpired();
    } catch (e) {
      // Silent fail for stats
    }
  }

  // Get stock history for specific product
  Future<List<StockHistory>> getProductStockHistory(int productId) async {
    try {
      return await _stockRepository.getStockHistoryByProduct(productId);
    } catch (e) {
      return [];
    }
  }
  
  // Get stock history by transaction
  Future<List<StockHistory>> getStockHistoryByTransaction(int transactionId) async {
    try {
      return await _stockRepository.getStockHistoryByTransaction(transactionId);
    } catch (e) {
      return [];
    }
  }

  // Get last 7 days movement for chart
  Future<Map<String, Map<String, int>>> getLast7DaysMovement() async {
    final Map<String, Map<String, int>> result = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      
      result[dateStr] = {
        'masuk': 0,
        'keluar': 0,
        'rusak': 0,
        'expired': 0,
      };
    }
    
    for (var history in _stockHistory) {
      final historyDate = history.date.substring(0, 10);
      if (result.containsKey(historyDate)) {
        switch (history.type) {
          case 'Masuk':
            result[historyDate]!['masuk'] = (result[historyDate]!['masuk'] ?? 0) + history.quantity;
            break;
          case 'Keluar':
            result[historyDate]!['keluar'] = (result[historyDate]!['keluar'] ?? 0) + history.quantity;
            break;
          case 'Rusak':
            result[historyDate]!['rusak'] = (result[historyDate]!['rusak'] ?? 0) + history.quantity;
            break;
          case 'Expired':
            result[historyDate]!['expired'] = (result[historyDate]!['expired'] ?? 0) + history.quantity;
            break;
        }
      }
    }
    
    return result;
  }
  
  // Get stock summary by type
  Map<String, int> getStockSummary() {
    final summary = {
      'Masuk': 0,
      'Keluar': 0,
      'Rusak': 0,
      'Expired': 0,
    };
    
    for (var history in _stockHistory) {
      summary[history.type] = (summary[history.type] ?? 0) + history.quantity;
    }
    
    return summary;
  }
  
  // Reset provider (for logout)
  void reset() {
    _stockHistory = [];
    _filteredHistory = [];
    _isLoading = false;
    _errorMessage = null;
    _filterType = 'Semua';
    _stockInToday = 0;
    _stockOutToday = 0;
    _totalLossFromDamage = 0;
    _totalLossFromExpired = 0;
    _safeNotifyListeners();
  }
}