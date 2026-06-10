// lib/providers/supplier_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _supplierRepository = SupplierRepository();
  
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isRefreshing = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get supplierCount => _suppliers.length;

  SupplierProvider() {
    debugPrint('🏗️ SupplierProvider created');
  }

  @override
  void dispose() {
    debugPrint('🗑️ SupplierProvider disposed');
    _isDisposed = true;
    super.dispose();
  }

  // ✅ Safe notify listeners - menggunakan Timer untuk delay
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    // Gunakan Timer untuk memastikan tidak dipanggil saat build phase
    Timer(const Duration(milliseconds: 10), () {
      if (!_isDisposed && hasListeners) {
        notifyListeners();
      }
    });
  }

  // Method untuk load data
  Future<void> loadSuppliers() async {
    if (_isDisposed) return;
    if (_isLoading || _isRefreshing) {
      debugPrint('📊 Already loading or refreshing, skipping...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;

    try {
      debugPrint('📊 Fetching suppliers from repository...');
      final newSuppliers = await _supplierRepository.getAllSuppliers();
      _suppliers = newSuppliers;
      debugPrint('📊 Loaded ${_suppliers.length} suppliers');
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading suppliers: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      _safeNotifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // Method untuk refresh data
  Future<void> refreshSuppliers() async {
    if (_isDisposed) return;
    if (_isRefreshing) {
      debugPrint('🔄 Already refreshing, skipping...');
      return;
    }
    
    debugPrint('🔄 Refresh suppliers started');
    _isRefreshing = true;
    _isLoading = true;

    try {
      final newSuppliers = await _supplierRepository.getAllSuppliers();
      _suppliers = newSuppliers;
      debugPrint('🔄 Refresh completed: ${_suppliers.length} suppliers');
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error refreshing suppliers: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      _safeNotifyListeners();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
    }
  }

  // Add supplier
  Future<bool> addSupplier(Supplier supplier) async {
    debugPrint('➕ addSupplier called for: ${supplier.name}');
    
    if (_isDisposed) return false;
    if (_isLoading || _isRefreshing) return false;
    
    _isLoading = true;

    try {
      final id = await _supplierRepository.addSupplier(supplier);
      debugPrint('➕ Supplier added with id: $id');
      
      if (id > 0) {
        await refreshSuppliers();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding supplier: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Update supplier
  Future<bool> updateSupplier(Supplier supplier) async {
    debugPrint('✏️ updateSupplier called for: ${supplier.name} (id: ${supplier.id})');
    
    if (_isDisposed) return false;
    if (_isLoading || _isRefreshing) return false;
    
    _isLoading = true;

    try {
      final result = await _supplierRepository.updateSupplier(supplier);
      debugPrint('✏️ Update result: $result');
      
      if (result > 0) {
        await refreshSuppliers();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating supplier: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Delete supplier
  Future<bool> deleteSupplier(int id) async {
    debugPrint('🗑️ deleteSupplier called for id: $id');
    
    if (_isDisposed) return false;
    if (_isLoading || _isRefreshing) return false;
    
    _isLoading = true;

    try {
      final result = await _supplierRepository.deleteSupplier(id);
      debugPrint('🗑️ Delete result: $result');
      
      if (result > 0) {
        _suppliers.removeWhere((s) => s.id == id);
        _safeNotifyListeners();
        Future.microtask(() => refreshSuppliers());
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting supplier: $e');
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
  
  void reset() {
    if (_isDisposed) return;
    debugPrint('🔄 SupplierProvider reset');
    _suppliers = [];
    _isLoading = false;
    _errorMessage = null;
    _isRefreshing = false;
    _safeNotifyListeners();
  }
}