// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../providers/product_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'produk/produk_screen.dart';
import 'supplier/supplier_screen.dart';
import 'analisis/analisis_screen.dart';
import 'transaksi/add_transaction.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isDataLoaded = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProdukScreen(),
    SupplierScreen(),
    AnalisisScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'outline': Icons.dashboard_outlined, 'filled': Icons.dashboard_rounded, 'label': 'Dasbor'},
    {'outline': Icons.inventory_2_outlined, 'filled': Icons.inventory_2_rounded, 'label': 'Produk'},
    {'outline': Icons.business_outlined, 'filled': Icons.business_rounded, 'label': 'Supplier'},
    {'outline': Icons.analytics_outlined, 'filled': Icons.analytics_rounded, 'label': 'Analisis'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_isDataLoaded) return;
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await Future.wait([
      authProvider.loadUserProfile(),
      productProvider.loadProducts(),
      supplierProvider.loadSuppliers(),
      stockProvider.loadStockHistory(),
    ]);
    
    if (mounted) {
      setState(() {
        _isDataLoaded = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TransactionTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, _navItems[0]),
                _buildNavItem(1, _navItems[1]),
                
                // Center FAB placeholder (empty space)
                const SizedBox(width: 56),
                
                _buildNavItem(2, _navItems[2]),
                _buildNavItem(3, _navItems[3]),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          onPressed: _showTransactionDialog,
          elevation: 4,
          backgroundColor: isDark ? AppColors.accentDark : AppColors.accentLight,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, Map<String, dynamic> item) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item['filled'] : item['outline'],
              color: isSelected ? AppColors.accentLight : (isDark ? Colors.white54 : Colors.black54),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item['label'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.accentLight : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet untuk memilih tipe transaksi
class _TransactionTypeBottomSheet extends StatelessWidget {
  const _TransactionTypeBottomSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Pilih Jenis Transaksi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Pembelian Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildTransactionOption(
              context: context,
              title: 'Pembelian',
              subtitle: 'Membeli barang dari supplier',
              icon: Icons.shopping_cart_rounded,
              gradient: AppColors.purpleGradient,
              type: 'Pembelian',
              isDark: isDark,
            ),
          ),
          
          // Penjualan Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildTransactionOption(
              context: context,
              title: 'Penjualan',
              subtitle: 'Menjual barang ke customer',
              icon: Icons.attach_money_rounded,
              gradient: AppColors.emeraldGradient,
              type: 'Penjualan',
              isDark: isDark,
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTransactionOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required String type,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionScreen(transactionType: type),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}