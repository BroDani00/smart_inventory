import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/stock_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/stock_history_model.dart';
import '../../widgets/app_bar.dart';

class MutasiScreen extends StatefulWidget {
  final bool showBackButton;
  
  const MutasiScreen({super.key, this.showBackButton = false});

  @override
  State<MutasiScreen> createState() => _MutasiScreenState();
}

class _MutasiScreenState extends State<MutasiScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String _selectedTimeRange = 'Semua';
  
  final List<Map<String, dynamic>> _filterTypes = [
    {'value': 'Semua', 'label': 'Semua', 'icon': Icons.filter_list_rounded, 'color': AppColors.accentLight},
    {'value': 'Masuk', 'label': 'Masuk', 'icon': Icons.arrow_downward_rounded, 'color': Colors.green},
    {'value': 'Keluar', 'label': 'Keluar', 'icon': Icons.arrow_upward_rounded, 'color': Colors.red},
    {'value': 'Rusak', 'label': 'Rusak', 'icon': Icons.warning_amber_rounded, 'color': Colors.orange},
    {'value': 'Expired', 'label': 'Expired', 'icon': Icons.hourglass_empty_rounded, 'color': Colors.purple},
  ];
  
  final List<Map<String, dynamic>> _timeRanges = [
    {'value': 'Semua', 'label': 'Semua', 'icon': Icons.calendar_today_rounded},
    {'value': 'Hari Ini', 'label': 'Hari Ini', 'icon': Icons.today_rounded},
    {'value': 'Kemarin', 'label': 'Kemarin', 'icon': Icons.calendar_view_day_rounded},
    {'value': 'Minggu Ini', 'label': 'Minggu Ini', 'icon': Icons.calendar_view_week_rounded},
    {'value': 'Bulan Ini', 'label': 'Bulan Ini', 'icon': Icons.calendar_view_month_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      stockProvider.loadStockHistory(),
      productProvider.loadProducts(),
    ]);
  }

  Future<void> _refreshData() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      stockProvider.refreshStockHistory(),
      productProvider.refreshProducts(),
    ]);
  }

  Map<String, dynamic> get _selectedFilterItem {
    return _filterTypes.firstWhere(
      (f) => f['value'] == _selectedFilter,
      orElse: () => _filterTypes.first,
    );
  }

  Map<String, dynamic> get _selectedTimeRangeItem {
    return _timeRanges.firstWhere(
      (t) => t['value'] == _selectedTimeRange,
      orElse: () => _timeRanges.first,
    );
  }

  List<StockHistory> _getFilteredHistory(List<StockHistory> history) {
    var filtered = history;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((h) =>
          h.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.notes.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((h) => h.type == _selectedFilter).toList();
    }
    
    if (_selectedTimeRange != 'Semua') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      filtered = filtered.where((h) {
        final historyDate = DateTime.tryParse(h.date);
        if (historyDate == null) return false;
        
        switch (_selectedTimeRange) {
          case 'Hari Ini':
            return historyDate.year == today.year &&
                   historyDate.month == today.month &&
                   historyDate.day == today.day;
          case 'Kemarin':
            final yesterday = today.subtract(const Duration(days: 1));
            return historyDate.year == yesterday.year &&
                   historyDate.month == yesterday.month &&
                   historyDate.day == yesterday.day;
          case 'Minggu Ini':
            final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
            return historyDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                   historyDate.isBefore(startOfWeek.add(const Duration(days: 7)));
          case 'Bulan Ini':
            return historyDate.year == today.year && historyDate.month == today.month;
          default:
            return true;
        }
      }).toList();
    }
    
    return filtered;
  }

  Map<String, List<StockHistory>> _groupHistoryByDate(List<StockHistory> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    
    final Map<String, List<StockHistory>> grouped = {
      'Hari Ini': [],
      'Kemarin': [],
      'Minggu Ini': [],
      'Bulan Ini': [],
      'Lebih Lama': [],
    };
    
    for (var item in history) {
      final itemDate = DateTime.tryParse(item.date);
      if (itemDate == null) continue;
      
      if (itemDate.year == today.year && 
          itemDate.month == today.month && 
          itemDate.day == today.day) {
        grouped['Hari Ini']!.add(item);
      } else if (itemDate.year == yesterday.year && 
                 itemDate.month == yesterday.month && 
                 itemDate.day == yesterday.day) {
        grouped['Kemarin']!.add(item);
      } else if (itemDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 itemDate.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        grouped['Minggu Ini']!.add(item);
      } else if (itemDate.year == now.year && itemDate.month == now.month) {
        grouped['Bulan Ini']!.add(item);
      } else {
        grouped['Lebih Lama']!.add(item);
      }
    }
    
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  double _getProductCostPrice(int productId) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.getProductById(productId);
    return product?.costPrice ?? 0;
  }

  double _getProductSellPrice(int productId) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.getProductById(productId);
    return product?.sellPrice ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredHistory = _getFilteredHistory(stockProvider.stockHistory);
    final groupedHistory = _groupHistoryByDate(filteredHistory);
    
    return Scaffold(
      body: Column(
        children: [
          // CustomAppBar dengan tombol back
          CustomAppBar(
            title: "Mutasi Stok",
            showBackButton: widget.showBackButton,
          ),
          
          // Search Bar with Filter Icons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
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
                        hintText: "Cari produk...",
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
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  selectedValue: _selectedFilter,
                  items: _filterTypes,
                  onChanged: (value) => setState(() => _selectedFilter = value),
                  icon: _selectedFilterItem['icon'] as IconData,
                  color: _selectedFilterItem['color'] as Color,
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  selectedValue: _selectedTimeRange,
                  items: _timeRanges,
                  onChanged: (value) => setState(() => _selectedTimeRange = value),
                  icon: _selectedTimeRangeItem['icon'] as IconData,
                  color: AppColors.accentLight,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // History List
          Expanded(
            child: stockProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tidak ada riwayat mutasi",
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Belum ada aktivitas stok yang tercatat",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: groupedHistory.keys.length,
                          itemBuilder: (context, index) {
                            final groupTitle = groupedHistory.keys.elementAt(index);
                            final items = groupedHistory[groupTitle]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
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
                                        groupTitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white24 : Colors.black12,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "${items.length}",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...items.map((item) => _buildHistoryItem(item)),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String selectedValue,
    required List<Map<String, dynamic>> items,
    required Function(String) onChanged,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopupMenuButton<String>(
      initialValue: selectedValue,
      offset: const Offset(0, 50),
      onSelected: onChanged,
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = item['value'] == selectedValue;
          return PopupMenuItem<String>(
            value: item['value'] as String,
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: item['color'] ?? color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? AppColors.accentLight : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.accentLight,
                  ),
              ],
            ),
          );
        }).toList();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? AppColors.cardDark : Colors.white,
      elevation: 8,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(StockHistory item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(item.type);
    final typeIcon = _getTypeIcon(item.type);
    
    final costPrice = _getProductCostPrice(item.productId);
    final sellPrice = _getProductSellPrice(item.productId);
    final totalCostValue = costPrice * item.quantity;
    final totalSellValue = sellPrice * item.quantity;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailDialog(item, totalCostValue, totalSellValue),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    typeIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${item.quantity} Unit",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.attach_money_rounded, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            "Nilai: ${AppFormatters.toRupiah(totalSellValue)}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.notes,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(item.date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateOnly(item.date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
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
  }
  
  void _showDetailDialog(StockHistory item, double totalCostValue, double totalSellValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(item.type);
    
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
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getTypeIcon(item.type),
                      color: typeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          item.type,
                          style: GoogleFonts.plusJakartaSans(
                            color: typeColor,
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
              _buildDetailRow("Jumlah", "${item.quantity} Unit"),
              const SizedBox(height: 12),
              _buildDetailRow("Nilai Modal", AppFormatters.toRupiah(totalCostValue)),
              const SizedBox(height: 12),
              _buildDetailRow("Nilai Jual", AppFormatters.toRupiah(totalSellValue)),
              const SizedBox(height: 12),
              _buildDetailRow("Tanggal", AppFormatters.formatDate(item.date)),
              const SizedBox(height: 12),
              _buildDetailRow("Catatan", item.notes.isNotEmpty ? item.notes : "Tidak ada catatan"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: typeColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Tutup",
                    style: TextStyle(color: typeColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
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
          ),
        ),
      ],
    );
  }
  
  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }
  
  String _formatDateOnly(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day}/${dateTime.month}";
    } catch (e) {
      return "";
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Masuk':
        return Colors.green;
      case 'Keluar':
        return Colors.red;
      case 'Rusak':
        return Colors.orange;
      case 'Expired':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Masuk':
        return Icons.arrow_downward_rounded;
      case 'Keluar':
        return Icons.arrow_upward_rounded;
      case 'Rusak':
        return Icons.warning_amber_rounded;
      case 'Expired':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.history_rounded;
    }
  }
}