// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();
  
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'Semua';
  String _filterDateRange = 'Hari Ini';
  
  // Analytics
  double _totalSales = 0;
  double _totalPurchases = 0;
  double _totalProfit = 0;
  int _totalTransactions = 0;
  
  List<Transaction> get transactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;
  String get filterDateRange => _filterDateRange;
  
  double get totalSales => _totalSales;
  double get totalPurchases => _totalPurchases;
  double get totalProfit => _totalProfit;
  int get totalTransactions => _totalTransactions;
  double get netCashFlow => _totalSales - _totalPurchases;

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<void> loadTransactions() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _transactions = await _transactionRepository.getAllTransactions();
      _applyFilters();
      await _loadAnalytics();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> refreshTransactions() async {
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      _transactions = await _transactionRepository.getAllTransactions();
      _applyFilters();
      await _loadAnalytics();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  void setFilterByType(String type) {
    _filterType = type;
    _applyFilters();
    _safeNotifyListeners();
  }
  
  void setFilterByDateRange(String range) {
    _filterDateRange = range;
    _applyFilters();
    _safeNotifyListeners();
  }
  
  void _applyFilters() {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    switch (_filterDateRange) {
      case 'Hari Ini':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Bulan Ini':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(2000, 1, 1);
    }
    
    _filteredTransactions = _transactions.where((t) {
      final transactionDate = DateTime.parse(t.transactionDate);
      final isDateValid = transactionDate.isAfter(startDate) && 
                          transactionDate.isBefore(endDate);
      
      if (_filterType == 'Semua') {
        return isDateValid;
      } else {
        return isDateValid && t.type == _filterType;
      }
    }).toList();
  }
  
  Future<void> _loadAnalytics() async {
    try {
      _totalSales = await _transactionRepository.getTotalSalesToday();
      _totalPurchases = await _transactionRepository.getTotalPurchasesToday();
      _totalTransactions = await _transactionRepository.getTotalTransactionsToday();
      
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final report = await _transactionRepository.getProfitLossReport(today, today);
      _totalProfit = report['net_profit'] ?? 0;
    } catch (e) {
      // Silent fail
    }
  }
  
  // Method untuk transaksi pembelian dengan produk baru
  Future<bool> createPurchaseTransactionWithNewProducts({
    required int supplierId,
    required List<TransactionItem> items,
    required List<Map<String, dynamic>> newProducts,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.createPurchaseTransactionWithNewProducts(
        supplierId: supplierId,
        items: items,
        newProducts: newProducts,
        paymentMethod: paymentMethod,
        notes: notes,
        createdBy: createdBy,
      );
      await refreshTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Error in createPurchaseTransactionWithNewProducts: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  // Create purchase transaction (tanpa produk baru)
  Future<bool> createPurchaseTransaction({
    required int supplierId,
    required List<TransactionItem> items,
    required double discount,
    required double tax,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.createPurchaseTransaction(
        supplierId: supplierId,
        items: items,
        discount: discount,
        tax: tax,
        paymentMethod: paymentMethod,
        notes: notes,
        createdBy: createdBy,
      );
      await refreshTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  Future<bool> createSaleTransaction({
    required String customerName,
    required List<TransactionItem> items,
    required double discount,
    required double tax,
    required String paymentMethod,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.createSaleTransaction(
        customerName: customerName,
        items: items,
        discount: discount,
        tax: tax,
        paymentMethod: paymentMethod,
        notes: notes,
        createdBy: createdBy,
      );
      await refreshTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  Future<bool> recordDamagedGoods({
    required int productId,
    required int quantity,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.recordDamagedGoods(
        productId: productId,
        quantity: quantity,
        notes: notes,
        createdBy: createdBy,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  Future<bool> recordExpiredGoods({
    required int productId,
    required int quantity,
    required String notes,
    required String createdBy,
  }) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.recordExpiredGoods(
        productId: productId,
        quantity: quantity,
        notes: notes,
        createdBy: createdBy,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> getTransactionDetails(int transactionId) async {
    try {
      return await _transactionRepository.getTransactionWithDetails(transactionId);
    } catch (e) {
      _errorMessage = e.toString();
      return {'transaction': null, 'items': []};
    }
  }
  
  Future<bool> cancelTransaction(int transactionId) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _safeNotifyListeners();
    
    try {
      await _transactionRepository.cancelTransaction(transactionId);
      await refreshTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
  
  Future<Map<String, double>> getProfitLossReport(String startDate, String endDate) async {
    try {
      return await _transactionRepository.getProfitLossReport(startDate, endDate);
    } catch (e) {
      _errorMessage = e.toString();
      return {};
    }
  }
  
  Map<String, Map<String, double>> getTransactionSummaryForChart() {
    final Map<String, Map<String, double>> summary = {};
    
    for (var transaction in _filteredTransactions) {
      final date = transaction.transactionDate.substring(0, 10);
      
      if (!summary.containsKey(date)) {
        summary[date] = {'pembelian': 0, 'penjualan': 0};
      }
      
      if (transaction.type == 'Pembelian') {
        summary[date]!['pembelian'] = (summary[date]!['pembelian'] ?? 0) + transaction.grandTotal;
      } else {
        summary[date]!['penjualan'] = (summary[date]!['penjualan'] ?? 0) + transaction.grandTotal;
      }
    }
    
    return summary;
  }
  
  void reset() {
    _transactions = [];
    _filteredTransactions = [];
    _isLoading = false;
    _errorMessage = null;
    _filterType = 'Semua';
    _filterDateRange = 'Hari Ini';
    _totalSales = 0;
    _totalPurchases = 0;
    _totalProfit = 0;
    _totalTransactions = 0;
    _safeNotifyListeners();
  }
}