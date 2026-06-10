import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../models/stock_history_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_bar.dart';

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  String _selectedPeriod = 'Hari Ini';
  final List<String> _periodOptions = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final stockProvider = Provider.of<StockProvider>(context);
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Data untuk analisis
    final products = productProvider.products;
    final suppliers = supplierProvider.suppliers;
    final stockHistory = stockProvider.stockHistory;

    // Filter data berdasarkan periode
    final filteredHistory = _getFilteredHistory(stockHistory);
    
    // Data untuk grafik
    final chartData = _getChartData(filteredHistory);
    
    // Total pergerakan stok berdasarkan filter
    final totalStockIn = filteredHistory
        .where((h) => h.type == 'Masuk')
        .fold(0, (sum, h) => sum + h.quantity);
    final totalStockOut = filteredHistory
        .where((h) => h.type == 'Keluar')
        .fold(0, (sum, h) => sum + h.quantity);
    final totalStockMovement = totalStockIn + totalStockOut;

    // Top 5 produk dengan stok terbanyak (tidak terpengaruh filter)
    final topStockProducts = [...products]
      ..sort((a, b) => b.stock.compareTo(a.stock));
    final top5Stock = topStockProducts.take(5).toList();

    // Top 5 produk dengan nilai tertinggi (tidak terpengaruh filter)
    final topValueProducts = [...products]
      ..sort((a, b) => (b.stock * b.sellPrice).compareTo(a.stock * a.sellPrice));
    final top5Value = topValueProducts.take(5).toList();

    // Top 5 produk dengan margin keuntungan tertinggi
    final topMarginProducts = [...products]
      ..sort((a, b) => ((b.sellPrice - b.costPrice) / b.costPrice)
          .compareTo((a.sellPrice - a.costPrice) / a.costPrice));
    final top5Margin = topMarginProducts.take(5).toList();

    // Top 5 supplier dengan produk terbanyak
    final topSuppliers = [...suppliers]
      ..sort((a, b) => 
        products.where((p) => p.supplierId == b.id).length
            .compareTo(products.where((p) => p.supplierId == a.id).length)
      );
    final top5Suppliers = topSuppliers.take(5).toList();

    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(
            title: "Analisis Bisnis",
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Periode
                  _buildFilterSection(),
                  const SizedBox(height: 20),

                  // Grafik Batang
                  _buildBarChart(chartData, isDark),
                  const SizedBox(height: 24),

                  // 3 Card Pergerakan Stok
                  _buildMovementCards(totalStockIn, totalStockOut, totalStockMovement, isDark),
                  const SizedBox(height: 24),

                  // Produk dengan Stok Terbanyak
                  _buildSectionTitle("Produk dengan Stok Terbanyak", Icons.warehouse_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Column(
                      children: top5Stock.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final product = entry.value;
                        return _buildListItem(
                          context: context,
                          rank: idx + 1,
                          name: product.name,
                          value: "${product.stock} unit",
                          color: Colors.orange,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Produk dengan Nilai Tertinggi
                  _buildSectionTitle("Produk dengan Nilai Tertinggi", Icons.attach_money_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Column(
                      children: top5Value.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final product = entry.value;
                        final totalValue = product.stock * product.sellPrice;
                        return _buildListItem(
                          context: context,
                          rank: idx + 1,
                          name: product.name,
                          value: AppFormatters.toRupiah(totalValue),
                          color: Colors.green,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Produk dengan Margin Laba Tertinggi
                  _buildSectionTitle("Produk dengan Margin Laba Tertinggi", Icons.percent_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Column(
                      children: top5Margin.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final product = entry.value;
                        final margin = ((product.sellPrice - product.costPrice) / product.costPrice) * 100;
                        return _buildListItem(
                          context: context,
                          rank: idx + 1,
                          name: product.name,
                          value: "${margin.toStringAsFixed(1)}%",
                          color: Colors.blue,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distribusi Supplier
                  _buildSectionTitle("Supplier dengan Produk Terbanyak", Icons.business_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Column(
                      children: top5Suppliers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final supplier = entry.value;
                        final productCount = products.where((p) => p.supplierId == supplier.id).length;
                        return _buildListItem(
                          context: context,
                          rank: idx + 1,
                          name: supplier.name,
                          value: "$productCount produk",
                          color: Colors.cyan,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accentLight),
          const SizedBox(width: 12),
          const Text("Periode:", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentLight),
                isExpanded: true,
                items: _periodOptions.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(
                      period,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPeriod = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCards(int totalMasuk, int totalKeluar, int totalMovement, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
            child: Column(
              children: [
                const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  "$totalMasuk",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text("Stok Masuk", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            child: Column(
              children: [
                const Icon(Icons.remove_shopping_cart_rounded, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  "$totalKeluar",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text("Stok Keluar", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassCard(
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            child: Column(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  "$totalMovement",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text("Total Mutasi", style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<StockHistory> _getFilteredHistory(List<StockHistory> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return history.where((h) {
      final historyDate = DateTime.tryParse(h.date);
      if (historyDate == null) return false;
      
      switch (_selectedPeriod) {
        case 'Hari Ini':
          return historyDate.year == today.year &&
                 historyDate.month == today.month &&
                 historyDate.day == today.day;
        case 'Minggu Ini':
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          return historyDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 historyDate.isBefore(startOfWeek.add(const Duration(days: 7)));
        case 'Bulan Ini':
          return historyDate.year == today.year && historyDate.month == today.month;
        case 'Tahun Ini':
          return historyDate.year == today.year;
        default:
          return true;
      }
    }).toList();
  }

  List<ChartData> _getChartData(List<StockHistory> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<String, ChartData> dataMap = {};
    
    switch (_selectedPeriod) {
      case 'Hari Ini':
        // Data per jam (6 jam terakhir)
        for (int i = 6; i >= 0; i--) {
          final hour = now.hour - i;
          if (hour >= 0) {
            dataMap['$hour:00'] = ChartData('$hour:00', 0, 0);
          }
        }
        
        for (var item in history) {
          final date = DateTime.tryParse(item.date);
          if (date != null && date.day == today.day) {
            final hourKey = '${date.hour}:00';
            if (dataMap.containsKey(hourKey)) {
              final current = dataMap[hourKey]!;
              if (item.type == 'Masuk') {
                dataMap[hourKey] = ChartData(
                  hourKey,
                  current.masuk + item.quantity,
                  current.keluar,
                );
              } else {
                dataMap[hourKey] = ChartData(
                  hourKey,
                  current.masuk,
                  current.keluar + item.quantity,
                );
              }
            }
          }
        }
        break;
        
      case 'Minggu Ini':
        final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        for (var day in days) {
          dataMap[day] = ChartData(day, 0, 0);
        }
        
        for (var item in history) {
          final date = DateTime.tryParse(item.date);
          if (date != null) {
            final dayName = _getDayName(date.weekday);
            if (dataMap.containsKey(dayName)) {
              final current = dataMap[dayName]!;
              if (item.type == 'Masuk') {
                dataMap[dayName] = ChartData(
                  dayName,
                  current.masuk + item.quantity,
                  current.keluar,
                );
              } else {
                dataMap[dayName] = ChartData(
                  dayName,
                  current.masuk,
                  current.keluar + item.quantity,
                );
              }
            }
          }
        }
        break;
        
      case 'Bulan Ini':
        // Hitung jumlah minggu dalam bulan ini (bisa 4 atau 5 minggu)
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        final weeksInMonth = ((lastDayOfMonth.day - 1) ~/ 7) + 1;
        
        // Inisialisasi data untuk setiap minggu
        for (int i = 1; i <= weeksInMonth; i++) {
          dataMap['Minggu $i'] = ChartData('Minggu $i', 0, 0);
        }
        
        for (var item in history) {
          final date = DateTime.tryParse(item.date);
          if (date != null && date.year == now.year && date.month == now.month) {
            final weekNumber = ((date.day - 1) ~/ 7) + 1;
            final weekKey = 'Minggu $weekNumber';
            
            if (dataMap.containsKey(weekKey)) {
              final current = dataMap[weekKey]!;
              if (item.type == 'Masuk') {
                dataMap[weekKey] = ChartData(
                  weekKey,
                  current.masuk + item.quantity,
                  current.keluar,
                );
              } else {
                dataMap[weekKey] = ChartData(
                  weekKey,
                  current.masuk,
                  current.keluar + item.quantity,
                );
              }
            }
          }
        }
        break;
        
      case 'Tahun Ini':
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        for (var month in months) {
          dataMap[month] = ChartData(month, 0, 0);
        }
        
        for (var item in history) {
          final date = DateTime.tryParse(item.date);
          if (date != null && date.year == now.year) {
            final monthName = months[date.month - 1];
            if (dataMap.containsKey(monthName)) {
              final current = dataMap[monthName]!;
              if (item.type == 'Masuk') {
                dataMap[monthName] = ChartData(
                  monthName,
                  current.masuk + item.quantity,
                  current.keluar,
                );
              } else {
                dataMap[monthName] = ChartData(
                  monthName,
                  current.masuk,
                  current.keluar + item.quantity,
                );
              }
            }
          }
        }
        break;
    }
    
    return dataMap.values.toList();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }

  double get _maxY {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final allData = _getChartData(_getFilteredHistory(stockProvider.stockHistory));
    if (allData.isEmpty) return 100;
    final maxValue = allData.map((e) => e.masuk > e.keluar ? e.masuk : e.keluar).reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.1).toDouble();
  }

  Widget _buildBarChart(List<ChartData> data, bool isDark) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: const Center(
          child: Text('Belum ada data untuk periode ini'),
        ),
      );
    }

    final maxYValue = _maxY;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Grafik Pergerakan Stok",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPeriod,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.accentLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _buildLegendItem(Colors.green, "Stok Masuk"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, "Stok Keluar"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxYValue,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final chartData = data[groupIndex];
                      final isMasuk = rodIndex == 0;
                      return BarTooltipItem(
                        '${chartData.label}\n',
                        const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${isMasuk ? "Masuk" : "Keluar"}: ${isMasuk ? chartData.masuk : chartData.keluar} unit',
                            style: TextStyle(
                              color: isMasuk ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[index].label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final chartData = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: chartData.masuk.toDouble(),
                        color: Colors.green,
                        width: _selectedPeriod == 'Tahun Ini' ? 12 : 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: chartData.keluar.toDouble(),
                        color: Colors.red,
                        width: _selectedPeriod == 'Tahun Ini' ? 12 : 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
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
        Icon(icon, size: 20, color: AppColors.accentLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required int rank,
    required String name,
    required String value,
    required Color color,
    bool showRank = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white24 : Colors.black12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (showRank) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "$rank",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class untuk chart data
class ChartData {
  final String label;
  final int masuk;
  final int keluar;

  ChartData(this.label, this.masuk, this.keluar);
}