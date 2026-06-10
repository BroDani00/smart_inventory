// lib/screens/supplier_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../providers/supplier_provider.dart';
import '../../models/supplier_model.dart';
import '../../widgets/app_bar.dart';
import 'add_edit_supplier_screen.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ Gunakan Future.microtask untuk memastikan load data setelah build selesai
    Future.microtask(() {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      await supplierProvider.loadSuppliers();
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      await supplierProvider.refreshSuppliers();
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
    }
  }

  List<Supplier> _getFilteredSuppliers(List<Supplier> suppliers) {
    if (_searchQuery.isEmpty) return suppliers;
    
    return suppliers.where((s) =>
        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.contact.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (s.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
  }

  void _showSupplierDetail(Supplier supplier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Supplier",
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.accentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: isDark ? Colors.white24 : Colors.black12),
              const SizedBox(height: 16),
              
              _buildDetailRow("Nama Supplier", supplier.name),
              const SizedBox(height: 12),
              _buildDetailRow("Nomor Telepon", supplier.contact),
              const SizedBox(height: 12),
              _buildDetailRow("Email", supplier.email),
              
              if (supplier.hasAddress) ...[
                const SizedBox(height: 12),
                _buildDetailRow("Alamat", supplier.address!, isMultiline: true),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Tutup"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editSupplier(supplier);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text("Edit"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSupplier(supplier.id!, supplier.name);
                      },
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text("Hapus"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSupplier(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Supplier"),
        content: Text(
          "Apakah Anda yakin ingin menghapus supplier '$name'?",
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
      try {
        final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
        final success = await supplierProvider.deleteSupplier(id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? "Supplier berhasil dihapus" : "Gagal menghapus supplier"),
              backgroundColor: success ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, supplierProvider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final filteredSuppliers = _getFilteredSuppliers(supplierProvider.suppliers);
        
        debugPrint('🏗️ Building SupplierScreen with ${filteredSuppliers.length} suppliers');
        
        return Scaffold(
          body: Column(
            children: [
              CustomAppBar(
                title: "Data Supplier",
              ),
              
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
                      hintText: "Cari supplier...",
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () => setState(() => _searchQuery = ''),
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
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
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 14, color: AppColors.accentLight),
                          const SizedBox(width: 4),
                          Text(
                            "Total: ${supplierProvider.supplierCount} Supplier",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredSuppliers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  size: 80,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Tidak ada supplier",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tambahkan supplier untuk produk Anda",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AddEditSupplierScreen(),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        await _refreshData();
                                      }
                                    } catch (e) {
                                      debugPrint('❌ Navigation error: $e');
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Tambah Supplier"),
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
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                              itemCount: filteredSuppliers.length,
                              itemBuilder: (context, index) {
                                final supplier = filteredSuppliers[index];
                                return _buildSupplierCardWithSlidable(supplier, isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              try {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditSupplierScreen(),
                  ),
                );
                if (result == true && mounted) {
                  await _refreshData();
                }
              } catch (e) {
                debugPrint('❌ Navigation error: $e');
              }
            },
            backgroundColor: AppColors.accentLight,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Tambah Supplier"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildSupplierCardWithSlidable(Supplier supplier, bool isDark) {
    return Slidable(
      key: ValueKey(supplier.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editSupplier(supplier),
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _deleteSupplier(supplier.id!, supplier.name),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Hapus',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSupplierDetail(supplier),
        borderRadius: BorderRadius.circular(20),
        child: _buildSupplierCard(supplier, isDark),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier, bool isDark) {
    final hasAddress = supplier.hasAddress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.cyanGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        supplier.contact,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.email_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          supplier.email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (hasAddress) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.accentLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            supplier.address!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.accentLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.accentLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSupplier(Supplier supplier) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditSupplierScreen(supplier: supplier),
        ),
      );
      if (result == true && mounted) {
        await _refreshData();
      }
    } catch (e) {
      debugPrint('❌ Error editing supplier: $e');
    }
  }
}