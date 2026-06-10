// lib/models/transaction_model.dart

class Transaction {
  final int? id;
  final String type; // 'Pembelian' atau 'Penjualan'
  final String transactionDate;
  final int? supplierId; // Untuk pembelian
  final String? supplierName; // Hasil join
  final String? customerName; // Untuk penjualan
  final double totalAmount;
  final double discount;
  final double tax;
  final double grandTotal;
  final String? paymentMethod;
  final String? notes;
  final String createdAt;
  
  // Additional fields untuk summary (tidak disimpan di DB)
  final int? totalItems; // Jumlah item berbeda dalam transaksi
  final int? totalQuantity; // Total quantity semua item

  Transaction({
    this.id,
    required this.type,
    required this.transactionDate,
    this.supplierId,
    this.supplierName,
    this.customerName,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.grandTotal,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.totalItems,
    this.totalQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'transaction_date': transactionDate,
      'supplier_id': supplierId,
      'customer_name': customerName,
      'total_amount': totalAmount,
      'discount': discount,
      'tax': tax,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      transactionDate: map['transaction_date'],
      supplierId: map['supplier_id'],
      supplierName: map['supplier_name'],
      customerName: map['customer_name'],
      totalAmount: map['total_amount'],
      discount: map['discount'] ?? 0,
      tax: map['tax'] ?? 0,
      grandTotal: map['grand_total'],
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      createdAt: map['created_at'],
      totalItems: map['total_items'],
      totalQuantity: map['total_quantity'],
    );
  }

  // Helper method untuk cek tipe transaksi
  bool get isPurchase => type == 'Pembelian';
  bool get isSale => type == 'Penjualan';
  
  // Helper method untuk mendapatkan nama pihak terkait
  String get counterpartyName {
    if (isPurchase) {
      return supplierName ?? 'Supplier Tidak Dikenal';
    } else {
      return customerName ?? 'Pelanggan Umum';
    }
  }
  
  // Helper method untuk format mata uang
  String get formattedGrandTotal => 'Rp ${grandTotal.toStringAsFixed(0)}';
  
  // Helper method untuk mendapatkan icon transaksi
  String get typeIcon => isPurchase ? '📦' : '💰';
  
  // Helper method untuk mendapatkan warna transaksi
  String get typeColor => isPurchase ? 'blue' : 'green';
}