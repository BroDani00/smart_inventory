import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';
import '../produk/produk_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../mutasi/mutasi_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedInventoryType = 'Harga Jual';
  final List<String> _inventoryTypes = ['Harga Jual', 'Harga Modal', 'Potensi Laba'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _refreshData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    await Future.wait([
      productProvider.refreshProducts(),
      stockProvider.refreshStockHistory(),
      supplierProvider.loadSuppliers(),
    ]);
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToMutasi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MutasiScreen(showBackButton: true)),
    );
  }

  String _getInventoryValue(ProductProvider provider) {
    switch (_selectedInventoryType) {
      case 'Harga Jual':
        return AppFormatters.toRupiah(provider.totalInventoryValueBySell);
      case 'Harga Modal':
        return AppFormatters.toRupiah(provider.totalInventoryValueByCost);
      case 'Potensi Laba':
        return AppFormatters.toRupiah(provider.potentialProfit);
      default:
        return AppFormatters.toRupiah(provider.totalInventoryValueBySell);
    }
  }

  Color _getInventoryValueColor(ProductProvider provider) {
    if (_selectedInventoryType == 'Potensi Laba') {
      return provider.potentialProfit >= 0 ? Colors.green : Colors.red;
    }
    return Colors.white;
  }

  _GreetingInfo _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return _GreetingInfo(
        'Selamat Pagi', 
        '🌅', 
        'Mulai hari dengan mengecek stok gudang!',
        'Pastikan semua stok dalam kondisi baik'
      );
    }
    if (hour >= 11 && hour < 15) {
      return _GreetingInfo(
        'Selamat Siang', 
        '☀️', 
        'Waktunya istirahat siang!',
        'Jangan lupa catat pemasukan stok hari ini'
      );
    }
    if (hour >= 15 && hour < 18) {
      return _GreetingInfo(
        'Selamat Sore', 
        '🌤️', 
        'Semangat sore!',
        'Cek kembali stok yang hampir habis'
      );
    }
    return _GreetingInfo(
      'Selamat Malam', 
      '🌙', 
      'Istirahat yang cukup!',
      'Jangan lupa rekap aktivitas hari ini'
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final totalProducts = productProvider.totalProducts;
    final lowStockCount = productProvider.lowStockCount;
    final supplierCount = supplierProvider.supplierCount;
    final stockInToday = stockProvider.stockInToday;
    final stockOutToday = stockProvider.stockOutToday;
    
    final latestMovements = stockProvider.stockHistory.take(5).toList();
    final greeting = _getGreeting();

    final hasProfileImage = authProvider.currentUser?.profileImage != null && 
        authProvider.currentUser!.profileImage!.isNotEmpty;
    final profileImage = hasProfileImage 
        ? File(authProvider.currentUser!.profileImage!)
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.accentLight,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Premium AppBar
            SliverAppBar(
              expandedHeight: 240,
              collapsedHeight: 70,
              pinned: true,
              floating: false,
              stretch: true,
              backgroundColor: Colors.transparent,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              // Hapus title dan actions dari sini (akan dipindahkan ke flexibleSpace)
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: BoxDecoration(
                    gradient: isDark 
                        ? AppColors.premiumGradientDark 
                        : AppColors.premiumGradientLight,
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                      ),
                      
                      // Logo, Title, and Profile button (dipindahkan dari title dan actions)
                      Positioned(
                        top: 40,
                        left: 24,
                        right: 24,
                        child: Row(
                          children: [
                            // Logo
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.emeraldGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Title
                            Expanded(
                              child: Text(
                                'Smart Inventory',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Profile button
                            GestureDetector(
                              onTap: _navigateToProfile,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: profileImage == null
                                      ? AppColors.emeraldGradient
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  image: profileImage != null
                                      ? DecorationImage(
                                          image: FileImage(profileImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profileImage == null
                                    ? Center(
                                        child: Text(
                                          authProvider.currentUser?.storeName.substring(0, 1).toUpperCase() ?? 'T',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Greeting content (tetap sama persis seperti sebelumnya)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Greeting badge with emoji
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(greeting.emoji, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text(
                                      greeting.greeting,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // User name
                              Text(
                                authProvider.currentUser?.name ?? 'Administrator',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Tagline
                              Text(
                                greeting.tagline,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Sub tagline
                              Text(
                                greeting.subTagline,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              // Store info card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.store_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      authProvider.currentUser?.storeName ?? 'Toko Saya',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Nilai Inventori dengan Dropdown
                    GlassCard(
                      gradientColors: isDark 
                          ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                          : const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Total Nilai",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedInventoryType,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                  underline: const SizedBox(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                                  items: _inventoryTypes.map<DropdownMenuItem<String>>((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          type,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedInventoryType = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getInventoryValue(productProvider),
                            style: GoogleFonts.plusJakartaSans(
                              color: _getInventoryValueColor(productProvider),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_selectedInventoryType == 'Potensi Laba') ...[
                            const SizedBox(height: 4),
                            Text(
                              "Margin Laba: ${productProvider.averageProfitMargin.toStringAsFixed(1)}%",
                              style: GoogleFonts.plusJakartaSans(
                                color: productProvider.averageProfitMargin >= 0 ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMovementBadge(
                                Icons.add_shopping_cart_rounded,
                                "Stok Masuk",
                                "$stockInToday Unit",
                                AppColors.success,
                              ),
                              _buildMovementBadge(
                                Icons.remove_shopping_cart_rounded,
                                "Stok Keluar",
                                "$stockOutToday Unit",
                                AppColors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Card Ringkasan Keuangan
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildFinancialMetric(
                                "Nilai Modal",
                                AppFormatters.toRupiah(productProvider.totalInventoryValueByCost),
                                Icons.shopping_cart_rounded,
                                Colors.blue,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                "Nilai Jual",
                                AppFormatters.toRupiah(productProvider.totalInventoryValueBySell),
                                Icons.attach_money_rounded,
                                Colors.green,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                "Potensi Laba",
                                AppFormatters.toRupiah(productProvider.potentialProfit),
                                Icons.trending_up_rounded,
                                productProvider.potentialProfit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 4 Stat Card dalam 1 baris
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: "Total Produk",
                            value: "$totalProducts",
                            icon: Icons.inventory_2_rounded,
                            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Expanded(
                        //   child: StatCard(
                        //     title: "Total Stok",
                        //     value: "$totalStock Unit",
                        //     icon: Icons.layers_rounded,
                        //     gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
                        //   ),
                        // ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            title: "Stok Kritis",
                            value: "$lowStockCount",
                            icon: Icons.warning_amber_rounded,
                            gradientColors: [AppColors.warning, const Color(0xFFB45309)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            title: "Supplier",
                            value: "$supplierCount",
                            icon: Icons.people_rounded,
                            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Ringkasan Mutasi Terbaru
                    if (latestMovements.isNotEmpty) ...[
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: AppColors.emeraldGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Mutasi Stok Terbaru",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _navigateToMutasi,
                            child: Text(
                              "Lihat Semua",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.accentLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...latestMovements.map((movement) => 
                        _buildRecentMovementCard(movement, isDark)
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Alert Stok Kritis
                    if (lowStockCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.dangerGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Stok Menipis!",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "$lowStockCount produk perlu segera diisi ulang",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...productProvider.products
                          .where((p) => p.stock <= p.minStock)
                          .take(3)
                          .map((product) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cardDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.inventory_rounded, color: AppColors.danger),
                                  ),
                                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    "Sisa: ${product.stock} unit (Min: ${product.minStock})",
                                    style: const TextStyle(color: AppColors.danger),
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(productId: product.id!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                                    label: const Text("Isi Stok"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                      if (productProvider.products.where((p) => p.stock <= p.minStock).length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                "Dan ${productProvider.products.where((p) => p.stock <= p.minStock).length - 3} produk lainnya",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.accentLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMovementCard(movement, bool isDark) {
    final typeColor = movement.type == 'Masuk' ? Colors.green : 
                      movement.type == 'Keluar' ? Colors.red :
                      movement.type == 'Rusak' ? Colors.orange : Colors.purple;
    final typeIcon = movement.type == 'Masuk' ? Icons.arrow_downward_rounded :
                     movement.type == 'Keluar' ? Icons.arrow_upward_rounded :
                     movement.type == 'Rusak' ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.productName,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${movement.type} • ${movement.quantity} Unit",
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: typeColor),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(movement.date),
            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return "${difference.inDays} hari lalu";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} jam lalu";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} menit lalu";
      } else {
        return "Baru saja";
      }
    } catch (e) {
      return "";
    }
  }

  Widget _buildFinancialMetric(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMovementBadge(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _GreetingInfo {
  final String greeting;
  final String emoji;
  final String tagline;
  final String subTagline;
  
  const _GreetingInfo(this.greeting, this.emoji, this.tagline, this.subTagline);
}