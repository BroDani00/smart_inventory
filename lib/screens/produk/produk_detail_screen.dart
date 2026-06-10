// lib/screens/produk/produk_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/glass_card.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedAction = 'Masuk';
  bool _isLoading = false;
  Product? _product;
  
  final List<Map<String, dynamic>> _actionTypes = [
    {'name': 'Masuk', 'color': Colors.green, 'icon': Icons.add_shopping_cart_rounded},
    {'name': 'Keluar', 'color': Colors.red, 'icon': Icons.remove_shopping_cart_rounded},
    {'name': 'Rusak', 'color': Colors.orange, 'icon': Icons.warning_amber_rounded},
    {'name': 'Expired', 'color': Colors.purple, 'icon': Icons.hourglass_empty_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }
  
  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (productProvider.products.isEmpty) {
      await productProvider.loadProducts();
    }
    
    final product = productProvider.getProductById(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _recordStockMovement() async {
    final quantity = int.tryParse(_quantityController.text);
    
    if (quantity == null || quantity <= 0) {
      if (mounted) {
        _showSnackBar('Masukkan jumlah yang valid', Colors.orange);
      }
      return;
    }

    setState(() => _isLoading = true);

    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    final success = await stockProvider.recordStockMovement(
      productId: widget.productId,
      type: _selectedAction,
      quantity: quantity,
      notes: _notesController.text.trim().isEmpty ? "Tidak ada catatan" : _notesController.text.trim(),
      createdBy: 'user',
    );

    if (mounted) {
      if (success) {
        await productProvider.refreshProducts();
        
        final updatedProduct = productProvider.getProductById(widget.productId);
        setState(() {
          _product = updatedProduct;
        });
        
        _quantityController.clear();
        _notesController.clear();
        _showSnackBar('$_selectedAction stok berhasil dicatat', Colors.green);
      } else {
        _showSnackBar('Gagal mencatat $_selectedAction stok', Colors.red);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _editProduct() async {
    if (_product == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: _product),
      ),
    );
    
    if (result == true && mounted) {
      await _loadProduct();
    }
  }

  Future<void> _deleteProduct() async {
    if (_product == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: Text(
          "Apakah Anda yakin ingin menghapus produk '${_product!.name}'?",
          style: GoogleFonts.plusJakartaSans(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(_product!.id!);
      
      if (mounted) {
        if (success) {
          _showSnackBar('Produk berhasil dihapus', Colors.green);
          Navigator.pop(context, true);
        } else {
          _showSnackBar('Gagal menghapus produk', Colors.red);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final product = _product!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = product.stock <= product.minStock;
    final hasImagePath = product.imagePath != null && product.imagePath!.isNotEmpty; // ✅ Perbaikan null check

    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            title: product.name,
            showBackButton: true,
            menuItems: [
              AppBarMenuItem(
                value: 'edit',
                label: 'Edit Produk',
                icon: Icons.edit_rounded,
                iconColor: AppColors.warning,
                onTap: _editProduct,
              ),
              AppBarMenuItem(
                value: 'delete',
                label: 'Hapus Produk',
                icon: Icons.delete_rounded,
                iconColor: AppColors.danger,
                onTap: _deleteProduct,
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Section
                        Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: hasImagePath
                                  ? null
                                  : (isLowStock
                                      ? AppColors.dangerGradient
                                      : AppColors.emeraldGradient),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: (isLowStock ? AppColors.danger : AppColors.accentLight)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              image: hasImagePath
                                  ? DecorationImage(
                                      image: FileImage(File(product.imagePath!)), // ✅ Perbaikan null check
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !hasImagePath // ✅ Perbaikan null check
                                ? Center(
                                    child: Text(
                                      product.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 56,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Product Code & Category
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                title: "Kode Produk",
                                value: product.code,
                                icon: Icons.barcode_reader,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                title: "Kategori",
                                value: product.category,
                                icon: Icons.category_rounded,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Stock Status Card
                        GlassCard(
                          gradientColors: isLowStock
                              ? [AppColors.danger, const Color(0xFFB91C1C)]
                              : [AppColors.success, const Color(0xFF047857)],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStockMetric(
                                "Stok Saat Ini",
                                "${product.stock} Unit",
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              _buildStockMetric(
                                "Batas Minimum",
                                "${product.minStock} Unit",
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              _buildStockMetric(
                                "Status",
                                isLowStock ? "Kritis" : "Aman",
                                valueColor: isLowStock ? AppColors.danger : AppColors.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Price Card
                        GlassCard(
                          gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B)],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPriceMetric(
                                "Harga Modal",
                                product.costPrice,
                                Icons.shopping_cart_rounded,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              _buildPriceMetric(
                                "Harga Jual",
                                product.sellPrice,
                                Icons.price_change_rounded,
                                isSellingPrice: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stock Movement Section
                        Text(
                          "Penyesuaian Stok",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Action Type Chips
                        Wrap(
                          spacing: 8,
                          children: _actionTypes.map((action) {
                            final isSelected = _selectedAction == action['name'];
                            return FilterChip(
                              selected: isSelected,
                              label: Text(action['name']),
                              avatar: Icon(
                                action['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : action['color'],
                              ),
                              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                              selectedColor: action['color'],
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : action['color'],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedAction = action['name'];
                                });
                              },
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : action['color'].withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        
                        // Quantity Field
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white : AppColors.primaryLight,
                          ),
                          decoration: InputDecoration(
                            labelText: "Jumlah",
                            hintText: "Masukkan jumlah stok",
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.accentLight),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.cardDark : Colors.white,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: isDark ? AppColors.textLight : AppColors.textMuted,
                            ),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: isDark ? AppColors.textLight : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Notes Field
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? Colors.white : AppColors.primaryLight,
                          ),
                          decoration: InputDecoration(
                            labelText: "Catatan (Opsional)",
                            hintText: "Tambahkan catatan untuk mutasi stok ini",
                            prefixIcon: const Icon(Icons.note_add_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.accentLight),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.cardDark : Colors.white,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: isDark ? AppColors.textLight : AppColors.textMuted,
                            ),
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: isDark ? AppColors.textLight : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _recordStockMovement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _actionTypes.firstWhere(
                                (a) => a['name'] == _selectedAction,
                              )['color'],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "${_selectedAction.toUpperCase()} STOK",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.primaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockMetric(String title, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceMetric(String title, double price, IconData icon, {bool isSellingPrice = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppFormatters.toRupiah(price),
          style: GoogleFonts.plusJakartaSans(
            color: isSellingPrice ? AppColors.accentLight : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}