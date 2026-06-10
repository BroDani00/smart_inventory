// lib/screens/produk/produk_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_inventory/models/product_model.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/app_bar.dart';
import 'add_edit_product_screen.dart';
import 'produk_detail_screen.dart';

class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  
  @override
  void initState() {
    super.initState();
    // ✅ Gunakan addPostFrameCallback untuk menghindari build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    await Future.wait([
      productProvider.loadProducts(),
      supplierProvider.loadSuppliers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get unique categories
    final categories = ['Semua', ...{...productProvider.products.map((p) => p.category)}];
    final filteredProducts = productProvider.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Custom App Bar
          CustomAppBar(
            title: "Katalog Produk",
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(),
                decoration: InputDecoration(
                  hintText: "Cari produk berdasarkan nama atau SKU...",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                    selectedColor: AppColors.accentLight,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : null,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.black12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Product List
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tidak ada produk ditemukan",
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _addProduct(),
                              icon: const Icon(Icons.add),
                              label: const Text("Tambah Produk"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentLight,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isLow = product.stock <= product.minStock;
                            final hasImagePath = product.imagePath != null && product.imagePath!.isNotEmpty; // ✅ Perbaikan null check
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Slidable(
                                key: ValueKey(product.id),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _editProduct(product),
                                      backgroundColor: AppColors.warning,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit_rounded,
                                      label: 'Edit',
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    SlidableAction(
                                      onPressed: (_) => _deleteProduct(product.id!),
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_rounded,
                                      label: 'Hapus',
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => _viewProductDetail(product),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.cardDark : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isLow 
                                            ? AppColors.danger.withValues(alpha: 0.3) 
                                            : (isDark ? Colors.white10 : Colors.black12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Product Image Placeholder
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            gradient: hasImagePath
                                                ? null
                                                : (isLow 
                                                    ? AppColors.dangerGradient 
                                                    : AppColors.emeraldGradient),
                                            borderRadius: BorderRadius.circular(16),
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
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Product Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${product.code} • ${product.category}",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white54 : Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentLight.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      AppFormatters.toRupiah(product.sellPrice),
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: AppColors.accentLight,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isLow) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.danger.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        "Stok Menipis",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors.danger,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Stock Info
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${product.stock} Unit",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isLow ? AppColors.danger : null,
                                              ),
                                            ),
                                            if (isLow)
                                              Text(
                                                "Min: ${product.minStock}",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppColors.accentLight,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Tambah Produk"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
  
  Future<void> _refreshData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    await Future.wait([
      productProvider.refreshProducts(),
      supplierProvider.refreshSuppliers(),
    ]);
  }
  
  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProductScreen(),
      ),
    ).then((_) => _refreshData());
  }
  
  void _editProduct(Product product) { // ✅ Tambahkan tipe data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: product),
      ),
    ).then((_) => _refreshData());
  }
  
  void _deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Apakah Anda yakin ingin menghapus produk ini? Tindakan ini tidak dapat dibatalkan."),
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
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(id);
      
      // ✅ Perbaikan: Cek mounted sebelum menggunakan context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Produk berhasil dihapus" : "Gagal menghapus produk"),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          await _refreshData();
        }
      }
    }
  }
  
  void _viewProductDetail(Product product) { // ✅ Tambahkan tipe data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.id!),
      ),
    );
  }
}