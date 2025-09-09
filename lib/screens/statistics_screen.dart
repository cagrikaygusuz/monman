import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../constants/app_theme.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../models/account.dart';
import '../models/bill_subscription.dart';
import '../providers/app_state_provider.dart';
import '../services/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  List<models.Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<BillSubscription> _billsSubscriptions = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _selectedPeriod = 'all'; // all, thisMonth, lastMonth, thisYear
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        DatabaseHelper().getTransactions(),
        DatabaseHelper().getCategories(),
        DatabaseHelper().getAccounts(),
        DatabaseHelper().getBillsSubscriptions(),
      ]);

      if (mounted) {
        setState(() {
          _transactions = futures[0] as List<models.Transaction>;
          _categories = futures[1] as List<Category>;
          _accounts = futures[2] as List<Account>;
          _billsSubscriptions = futures[3] as List<BillSubscription>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<models.Transaction> get _filteredTransactions {
    final now = DateTime.now();
    List<models.Transaction> filtered = _transactions;

    // Apply period filter
    switch (_selectedPeriod) {
      case 'thisMonth':
        filtered = _transactions.where((t) =>
          t.date.year == now.year && t.date.month == now.month).toList();
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1);
        filtered = _transactions.where((t) =>
          t.date.year == lastMonth.year && t.date.month == lastMonth.month).toList();
        break;
      case 'thisYear':
        filtered = _transactions.where((t) => t.date.year == now.year).toList();
        break;
      case 'all':
      default:
        filtered = _transactions;
    }
    
    // Apply date range filter if set
    if (_selectedDateRange != null) {
      filtered = filtered.where((transaction) {
        final date = transaction.date;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return filtered;
  }

  List<BillSubscription> get _filteredBillsSubscriptions {
    final now = DateTime.now();
    List<BillSubscription> filtered = _billsSubscriptions;

    // Apply period filter
    switch (_selectedPeriod) {
      case 'thisMonth':
        filtered = _billsSubscriptions.where((b) {
          final date = b.dueDate ?? b.nextDate ?? b.updatedAt;
          return date.year == now.year && date.month == now.month;
        }).toList();
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1);
        filtered = _billsSubscriptions.where((b) {
          final date = b.dueDate ?? b.nextDate ?? b.updatedAt;
          return date.year == lastMonth.year && date.month == lastMonth.month;
        }).toList();
        break;
      case 'thisYear':
        filtered = _billsSubscriptions.where((b) {
          final date = b.dueDate ?? b.nextDate ?? b.updatedAt;
          return date.year == now.year;
        }).toList();
        break;
      case 'all':
      default:
        filtered = _billsSubscriptions;
    }
    
    // Apply date range filter if set
    if (_selectedDateRange != null) {
      filtered = filtered.where((bill) {
        final date = bill.dueDate ?? bill.nextDate ?? bill.updatedAt;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isTurkish = appState.selectedLanguage == 'Turkish';
        
        return Scaffold(
          appBar: AppBar(
            title: Text(isTurkish ? 'İstatistikler ve Raporlar' : 'Statistics & Reports'),
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_alt),
                onSelected: (period) {
                  setState(() {
                    _selectedPeriod = period;
                    if (period != 'custom') _selectedDateRange = null;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Text(isTurkish ? 'Tümü' : 'All Time'),
                  ),
                  PopupMenuItem(
                    value: 'thisMonth',
                    child: Text(isTurkish ? 'Bu Ay' : 'This Month'),
                  ),
                  PopupMenuItem(
                    value: 'lastMonth',
                    child: Text(isTurkish ? 'Geçen Ay' : 'Last Month'),
                  ),
                  PopupMenuItem(
                    value: 'thisYear',
                    child: Text(isTurkish ? 'Bu Yıl' : 'This Year'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'custom',
                    child: Text(isTurkish ? 'Özel Tarih Aralığı' : 'Custom Range'),
                    onTap: () => Future.delayed(Duration.zero, _selectDateRange),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: isTurkish ? 'Genel' : 'Overview'),
                Tab(text: isTurkish ? 'Grafikler' : 'Charts'),
                Tab(text: isTurkish ? 'Kategoriler' : 'Categories'),
                Tab(text: isTurkish ? 'Hesaplar' : 'Accounts'),
                Tab(text: isTurkish ? 'Faturalar' : 'Bills'),
                Tab(text: isTurkish ? 'Trendler' : 'Trends'),
                Tab(text: isTurkish ? 'İçgörüler' : 'Insights'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildOverviewTab(isTurkish, appState),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildChartsTab(isTurkish),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildCategoriesTab(isTurkish),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildAccountsTab(isTurkish, appState),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildBillsTab(isTurkish, appState),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildTrendsTab(isTurkish, appState),
                        ),
                        RefreshIndicator(
                          onRefresh: () async {
                            await context.read<AppStateProvider>().loadAllData();
                            await _loadData();
                          },
                          child: _buildInsightsTab(isTurkish, appState),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No data to display',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add some transactions to see statistics and reports',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(bool isTurkish) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              '${isTurkish ? "Dönem" : "Period"}: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                  _selectedPeriod = 'all';
                });
              },
              child: Text(isTurkish ? 'Temizle' : 'Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(bool isTurkish, AppStateProvider appState) {
    final income = _filteredTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final expenses = _filteredTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    // Add bill/subscription expenses from filtered data
    final billExpenses = _filteredBillsSubscriptions.where((b) => b.isPaid).fold<double>(0.0, (sum, b) => sum + b.amount);
    final totalExpenses = expenses + billExpenses;
    
    final balance = income - totalExpenses;
    final transactionCount = _filteredTransactions.length;
    final billCount = _filteredBillsSubscriptions.length;
    final currencySymbol = appState.getCurrencySymbol();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isTurkish ? 'Toplam Gelir' : 'Total Income',
            '$currencySymbol${income.toStringAsFixed(2)}',
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isTurkish ? 'Toplam Gider' : 'Total Expenses',
            '$currencySymbol${totalExpenses.toStringAsFixed(2)}',
            Colors.red,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isTurkish ? 'Net Bakiye' : 'Net Balance',
            '$currencySymbol${balance.toStringAsFixed(2)}',
            balance >= 0 ? Colors.green : Colors.red,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isTurkish ? 'Faturalar' : 'Bills',
            billCount.toString(),
            Colors.orange,
            Icons.receipt,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpensesChart(bool isTurkish) {
    final income = _filteredTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final expenses = _filteredTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    // Always show chart, even with zero values
    final currencySymbol = context.read<AppStateProvider>().getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Gelir vs Gider' : 'Income vs Expenses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.secondaryColor,
                      value: income > 0 ? income : 0.1, // Show small slice if zero
                      title: '${isTurkish ? "Gelir" : "Income"}\n$currencySymbol${income.toStringAsFixed(0)}',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.errorColor,
                      value: expenses > 0 ? expenses : 0.1, // Show small slice if zero
                      title: '${isTurkish ? "Gider" : "Expenses"}\n$currencySymbol${expenses.toStringAsFixed(0)}',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart(bool isTurkish) {
    final expensesByCategory = <String, double>{};
    
    for (final transaction in _filteredTransactions) {
      if (transaction.type == models.TransactionType.expense) {
        final category = transaction.categoryId != null
            ? _categories.firstWhere((c) => c.id == transaction.categoryId, orElse: () => Category(
                name: 'Uncategorized',
                type: CategoryType.expense,
                color: '#9E9E9E',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )).name
            : 'Uncategorized';
        
        expensesByCategory[category] = (expensesByCategory[category] ?? 0) + transaction.amount;
      }
    }

    // Always show chart, even when empty
    final currencySymbol = context.read<AppStateProvider>().getCurrencySymbol();
    
    // If no data, show placeholder
    if (expensesByCategory.isEmpty) {
      expensesByCategory['No Expenses'] = 1;
    }

    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.errorColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kategorilere Göre Giderler' : 'Expenses by Category',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: expensesByCategory.entries
                      .take(8)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: category.value,
                      title: '${category.key}\n$currencySymbol${category.value.toStringAsFixed(0)}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart(bool isTurkish) {
    final monthlyData = <String, Map<String, double>>{};
    
    for (final transaction in _filteredTransactions) {
      final monthKey = '${transaction.date.month}/${transaction.date.year}';
      monthlyData.putIfAbsent(monthKey, () => {'income': 0.0, 'expenses': 0.0});
      
      if (transaction.type == models.TransactionType.income) {
        monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + transaction.amount;
      } else if (transaction.type == models.TransactionType.expense) {
        monthlyData[monthKey]!['expenses'] = monthlyData[monthKey]!['expenses']! + transaction.amount;
      }
    }

    // Always show chart, even when empty
    if (monthlyData.isEmpty) {
      // Add placeholder data for current month
      final now = DateTime.now();
      final currentMonth = '${now.month}/${now.year}';
      monthlyData[currentMonth] = {'income': 0.0, 'expenses': 0.0};
    }

    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split('/');
        final bParts = b.key.split('/');
        final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
        final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
        return aDate.compareTo(bDate);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Aylık Trend' : 'Monthly Trend',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                            return Text(
                              sortedEntries[value.toInt()].key,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedEntries.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value['income']!);
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.secondaryColor,
                      barWidth: 3,
                    ),
                    LineChartBarData(
                      spots: sortedEntries.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value['expenses']!);
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.errorColor,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(isTurkish ? 'Gelir' : 'Income', Colors.green),
                const SizedBox(width: 20),
                _buildLegendItem(isTurkish ? 'Gider' : 'Expenses', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCategoryReports(bool isTurkish) {
    final categoryTotals = <String, Map<String, double>>{};
    
    for (final transaction in _filteredTransactions) {
      if (transaction.type != models.TransactionType.transfer) {
        final category = transaction.categoryId != null
            ? _categories.firstWhere((c) => c.id == transaction.categoryId, orElse: () => Category(
                name: 'Uncategorized',
                type: transaction.type == models.TransactionType.income ? CategoryType.income : CategoryType.expense,
                color: '#9E9E9E',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )).name
            : 'Uncategorized';
        
        categoryTotals.putIfAbsent(category, () => {'income': 0.0, 'expenses': 0.0, 'count': 0.0});
        
        if (transaction.type == models.TransactionType.income) {
          categoryTotals[category]!['income'] = categoryTotals[category]!['income']! + transaction.amount;
        } else {
          categoryTotals[category]!['expenses'] = categoryTotals[category]!['expenses']! + transaction.amount;
        }
        categoryTotals[category]!['count'] = categoryTotals[category]!['count']! + 1;
      }
    }

    // Always show chart, even when empty
    if (categoryTotals.isEmpty) {
      categoryTotals['No Categories'] = {'income': 0.0, 'expenses': 0.0, 'count': 0.0};
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kategori Raporları' : 'Category Reports',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...categoryTotals.entries.map((entry) {
              final categoryName = entry.key;
              final data = entry.value;
              final total = data['income']! + data['expenses']!;
              final count = data['count']!.toInt();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '$count txns',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isTurkish, AppStateProvider appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedDateRange != null) _buildDateRangeCard(isTurkish),
          _buildOverviewCards(isTurkish, appState),
          const SizedBox(height: 20),
          _buildAdvancedMetrics(isTurkish, appState),
          const SizedBox(height: 20),
          _buildMonthlyComparison(isTurkish, appState),
          const SizedBox(height: 20),
          _buildTopSpendingCategories(isTurkish),
          const SizedBox(height: 20),
          _buildRecentTransactionsSummary(isTurkish),
        ],
      ),
    );
  }

  Widget _buildChartsTab(bool isTurkish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildIncomeVsExpensesChart(isTurkish),
          const SizedBox(height: 20),
          _buildCategoryBreakdownChart(isTurkish),
          const SizedBox(height: 20),
          _buildMonthlyTrendChart(isTurkish),
          const SizedBox(height: 20),
          _buildWeeklySpendingChart(isTurkish),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(bool isTurkish) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCategoryReports(isTurkish),
          const SizedBox(height: 20),
          _buildCategoryComparison(isTurkish),
          const SizedBox(height: 20),
          _buildCategoryTrends(isTurkish, _filteredTransactions),
        ],
      ),
    );
  }

  Widget _buildAccountsTab(bool isTurkish, AppStateProvider appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAccountBalances(isTurkish, appState),
          const SizedBox(height: 20),
          _buildAccountActivity(isTurkish),
          const SizedBox(height: 20),
          _buildAccountTransactionFlow(isTurkish),
        ],
      ),
    );
  }

  Widget _buildBillsTab(bool isTurkish, AppStateProvider appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildBillsSummary(isTurkish, appState),
          const SizedBox(height: 20),
          _buildBillsBreakdown(isTurkish, appState),
          const SizedBox(height: 20),
          _buildUpcomingBills(isTurkish, appState),
          const SizedBox(height: 20),
          _buildBillsPaymentHistory(isTurkish, appState),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparison(bool isTurkish, AppStateProvider appState) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final twoMonthsAgo = DateTime(now.year, now.month - 2);
    
    final thisMonthTransactions = _transactions.where((t) =>
      t.date.year == thisMonth.year && t.date.month == thisMonth.month).toList();
    
    final lastMonthTransactions = _transactions.where((t) =>
      t.date.year == lastMonth.year && t.date.month == lastMonth.month).toList();
    
    final twoMonthsAgoTransactions = _transactions.where((t) =>
      t.date.year == twoMonthsAgo.year && t.date.month == twoMonthsAgo.month).toList();

    final thisMonthIncome = thisMonthTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final thisMonthExpenses = thisMonthTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final lastMonthIncome = lastMonthTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final lastMonthExpenses = lastMonthTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final incomeChange = lastMonthIncome > 0 
      ? ((thisMonthIncome - lastMonthIncome) / lastMonthIncome * 100) 
      : 0.0;
    
    final expenseChange = lastMonthExpenses > 0 
      ? ((thisMonthExpenses - lastMonthExpenses) / lastMonthExpenses * 100) 
      : 0.0;

    final currencySymbol = appState.getCurrencySymbol();
    
    final monthNames = isTurkish 
      ? ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
         'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık']
      : ['January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Aylık Karşılaştırma' : 'Monthly Comparison',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonCard(
                    isTurkish ? 'Bu Ay Gelir' : 'This Month Income',
                    '$currencySymbol${thisMonthIncome.toStringAsFixed(2)}',
                    incomeChange,
                    '${monthNames[lastMonth.month - 1]}',
                    Colors.green,
                    isTurkish,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComparisonCard(
                    isTurkish ? 'Bu Ay Gider' : 'This Month Expenses',
                    '$currencySymbol${thisMonthExpenses.toStringAsFixed(2)}',
                    expenseChange,
                    '${monthNames[lastMonth.month - 1]}',
                    Colors.red,
                    isTurkish,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isTurkish ? 'Son 3 Ay Trendi' : 'Last 3 Months Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _build3MonthComparison(thisMonthTransactions, lastMonthTransactions, twoMonthsAgoTransactions, 
                                  monthNames, thisMonth, lastMonth, twoMonthsAgo, isTurkish, currencySymbol),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(String title, String amount, double changePercent, 
      String comparedTo, Color color, bool isTurkish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                color: changePercent >= 0 ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${changePercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: changePercent >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${isTurkish ? "vs" : "vs"} $comparedTo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3MonthComparison(List<models.Transaction> thisMonth, List<models.Transaction> lastMonth,
      List<models.Transaction> twoMonthsAgo, List<String> monthNames, DateTime thisMonthDate, 
      DateTime lastMonthDate, DateTime twoMonthsAgoDate, bool isTurkish, String currencySymbol) {
    
    final data = [
      {
        'month': monthNames[twoMonthsAgoDate.month - 1],
        'income': twoMonthsAgo.where((t) => t.type == models.TransactionType.income).fold<double>(0.0, (sum, t) => sum + t.amount),
        'expenses': twoMonthsAgo.where((t) => t.type == models.TransactionType.expense).fold<double>(0.0, (sum, t) => sum + t.amount),
      },
      {
        'month': monthNames[lastMonthDate.month - 1],
        'income': lastMonth.where((t) => t.type == models.TransactionType.income).fold<double>(0.0, (sum, t) => sum + t.amount),
        'expenses': lastMonth.where((t) => t.type == models.TransactionType.expense).fold<double>(0.0, (sum, t) => sum + t.amount),
      },
      {
        'month': monthNames[thisMonthDate.month - 1],
        'income': thisMonth.where((t) => t.type == models.TransactionType.income).fold<double>(0.0, (sum, t) => sum + t.amount),
        'expenses': thisMonth.where((t) => t.type == models.TransactionType.expense).fold<double>(0.0, (sum, t) => sum + t.amount),
      },
    ];

    return Column(
      children: data.map((monthData) {
        final income = monthData['income'] as double;
        final expenses = monthData['expenses'] as double;
        final net = income - expenses;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  monthData['month'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isTurkish ? "Gelir" : "Income"}: $currencySymbol${income.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                          Text(
                            '${isTurkish ? "Gider" : "Expenses"}: $currencySymbol${expenses.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isTurkish ? "Net" : "Net"}: $currencySymbol${net.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: net >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedMetrics(bool isTurkish, AppStateProvider appState) {
    final income = _filteredTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final expenses = _filteredTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    final savingsRate = income > 0 ? ((income - expenses) / income * 100) : 0.0;
    final avgDailySpending = expenses / (_filteredTransactions.isEmpty ? 1 : 30);
    final currencySymbol = appState.getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Gelişmiş Metrikler' : 'Advanced Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    isTurkish ? 'Tasarruf Oranı' : 'Savings Rate',
                    '${savingsRate.toStringAsFixed(1)}%',
                    savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
                    Icons.savings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    isTurkish ? 'Günlük Ort. Harcama' : 'Avg Daily Spending',
                    '$currencySymbol${avgDailySpending.toStringAsFixed(2)}',
                    Theme.of(context).primaryColor,
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpendingCategories(bool isTurkish) {
    final expensesByCategory = <String, double>{};
    
    for (final transaction in _filteredTransactions) {
      if (transaction.type == models.TransactionType.expense) {
        final category = transaction.categoryId != null
            ? _categories.firstWhere((c) => c.id == transaction.categoryId, orElse: () => Category(
                name: 'Uncategorized',
                type: CategoryType.expense,
                color: '#9E9E9E',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )).name
            : 'Uncategorized';
        
        expensesByCategory[category] = (expensesByCategory[category] ?? 0) + transaction.amount;
      }
    }

    // Always show chart, even when empty
    if (expensesByCategory.isEmpty) {
      expensesByCategory['No Expenses'] = 0;
    }

    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'En Çok Harcama Yapılan Kategoriler' : 'Top Spending Categories',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final percentage = (entry.value / sortedCategories.fold<double>(0, (sum, e) => sum + e.value)) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSummary(bool isTurkish) {
    final recentTransactions = _filteredTransactions
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Son İşlem Özeti' : 'Recent Transaction Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...recentTransactions.take(5).map((transaction) {
              final account = _accounts.firstWhere((a) => a.id == transaction.accountId, orElse: () => Account(
                name: 'Unknown',
                type: AccountType.bankAccount,
                balance: 0,
                currency: 'USD',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.type == models.TransactionType.income 
                    ? Colors.green 
                    : Colors.red,
                  child: Icon(
                    transaction.type == models.TransactionType.income 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                    color: Colors.white,
                  ),
                ),
                title: Text(transaction.description),
                subtitle: Text('${account.name} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
                trailing: Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.type == models.TransactionType.income 
                      ? Colors.green 
                      : Colors.red,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySpendingChart(bool isTurkish) {
    final weeklyData = <String, double>{};
    final daysOfWeek = isTurkish 
      ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Initialize all days with 0
    for (int i = 0; i < 7; i++) {
      weeklyData[daysOfWeek[i]] = 0.0;
    }
    
    for (final transaction in _filteredTransactions) {
      if (transaction.type == models.TransactionType.expense) {
        final dayIndex = (transaction.date.weekday - 1) % 7;
        final dayName = daysOfWeek[dayIndex];
        weeklyData[dayName] = (weeklyData[dayName] ?? 0) + transaction.amount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Haftalık Harcama Dağılımı' : 'Weekly Spending Distribution',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: weeklyData.values.isNotEmpty ? weeklyData.values.reduce((a, b) => a > b ? a : b) * 1.2 : 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            daysOfWeek[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.entries.toList().asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBalances(bool isTurkish, AppStateProvider appState) {
    final currencySymbol = appState.getCurrencySymbol();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Hesap Bakiyeleri' : 'Account Balances',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ..._accounts.map((account) {
              final accountTransactions = _filteredTransactions
                  .where((t) => t.accountId == account.id)
                  .length;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: account.balance >= 0 ? Colors.green : Colors.red,
                  child: Text(
                    account.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(account.name),
                subtitle: Text('${accountTransactions} ${isTurkish ? "işlem" : "transactions"}'),
                trailing: Text(
                  '$currencySymbol${account.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: account.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActivity(bool isTurkish) {
    final accountActivity = <int, int>{};
    
    for (final transaction in _filteredTransactions) {
      accountActivity[transaction.accountId] = (accountActivity[transaction.accountId] ?? 0) + 1;
    }

    final sortedAccounts = accountActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Hesap Aktivitesi' : 'Account Activity',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...sortedAccounts.take(5).map((entry) {
              final account = _accounts.firstWhere((a) => a.id == entry.key, orElse: () => Account(
                name: 'Unknown',
                type: AccountType.bankAccount,
                balance: 0,
                currency: 'USD',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(account.name, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    Text(
                      '${entry.value} ${isTurkish ? "işlem" : "transactions"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTransactionFlow(bool isTurkish) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Hesap İşlem Akışı' : 'Account Transaction Flow',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              isTurkish 
                ? 'Toplam ${_filteredTransactions.length} işlem analiz edildi.'
                : 'Total ${_filteredTransactions.length} transactions analyzed.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryComparison(bool isTurkish) {
    // Compare this period vs previous period
    final now = DateTime.now();
    final currentPeriodTransactions = _filteredTransactions;
    
    // Get previous period transactions for comparison
    List<models.Transaction> previousPeriodTransactions;
    String comparisonLabel;
    
    switch (_selectedPeriod) {
      case 'thisMonth':
        final lastMonth = DateTime(now.year, now.month - 1);
        previousPeriodTransactions = _transactions.where((t) =>
          t.date.year == lastMonth.year && t.date.month == lastMonth.month).toList();
        comparisonLabel = isTurkish ? 'vs Geçen Ay' : 'vs Last Month';
        break;
      case 'lastMonth':
        final twoMonthsAgo = DateTime(now.year, now.month - 2);
        previousPeriodTransactions = _transactions.where((t) =>
          t.date.year == twoMonthsAgo.year && t.date.month == twoMonthsAgo.month).toList();
        comparisonLabel = isTurkish ? 'vs 2 Ay Önce' : 'vs 2 Months Ago';
        break;
      case 'thisYear':
        final lastYear = DateTime(now.year - 1);
        previousPeriodTransactions = _transactions.where((t) => t.date.year == lastYear.year).toList();
        comparisonLabel = isTurkish ? 'vs Geçen Yıl' : 'vs Last Year';
        break;
      default:
        // For 'all' and custom ranges, compare with same period length before
        final periodLength = _selectedDateRange != null 
          ? _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays
          : 30; // Default 30 days
        final startDate = _selectedDateRange?.start ?? now.subtract(const Duration(days: 30));
        final endDate = _selectedDateRange?.end ?? now;
        final previousStart = startDate.subtract(Duration(days: periodLength));
        final previousEnd = endDate.subtract(Duration(days: periodLength));
        
        previousPeriodTransactions = _transactions.where((t) =>
          t.date.isAfter(previousStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(previousEnd.add(const Duration(days: 1)))).toList();
        comparisonLabel = isTurkish ? 'vs Önceki Dönem' : 'vs Previous Period';
        break;
    }

    // Calculate category totals for both periods
    final currentCategoryTotals = <String, double>{};
    final previousCategoryTotals = <String, double>{};

    for (final transaction in currentPeriodTransactions) {
      if (transaction.type == models.TransactionType.expense) {
        final categoryName = transaction.categoryId != null
            ? _categories.firstWhere((c) => c.id == transaction.categoryId, 
                orElse: () => Category(name: 'Uncategorized', type: CategoryType.expense, color: '#9E9E9E', createdAt: DateTime.now(), updatedAt: DateTime.now())).name
            : 'Uncategorized';
        currentCategoryTotals[categoryName] = (currentCategoryTotals[categoryName] ?? 0) + transaction.amount;
      }
    }

    for (final transaction in previousPeriodTransactions) {
      if (transaction.type == models.TransactionType.expense) {
        final categoryName = transaction.categoryId != null
            ? _categories.firstWhere((c) => c.id == transaction.categoryId, 
                orElse: () => Category(name: 'Uncategorized', type: CategoryType.expense, color: '#9E9E9E', createdAt: DateTime.now(), updatedAt: DateTime.now())).name
            : 'Uncategorized';
        previousCategoryTotals[categoryName] = (previousCategoryTotals[categoryName] ?? 0) + transaction.amount;
      }
    }

    // Get all categories that appear in either period
    final allCategories = {...currentCategoryTotals.keys, ...previousCategoryTotals.keys};
    
    // Always show comparison, even when empty
    if (allCategories.isEmpty) {
      allCategories.add('No Expenses');
      currentCategoryTotals['No Expenses'] = 0;
      previousCategoryTotals['No Expenses'] = 0;
    }

    // Create comparison data
    final comparisonData = allCategories.map((category) {
      final currentAmount = currentCategoryTotals[category] ?? 0;
      final previousAmount = previousCategoryTotals[category] ?? 0;
      final change = previousAmount > 0 
        ? ((currentAmount - previousAmount) / previousAmount * 100)
        : (currentAmount > 0 ? 100.0 : 0.0);
      
      return {
        'category': category,
        'current': currentAmount,
        'previous': previousAmount,
        'change': change,
      };
    }).toList();

    // Sort by current amount (highest first)
    comparisonData.sort((a, b) => (b['current'] as double).compareTo(a['current'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isTurkish ? 'Kategori Karşılaştırması' : 'Category Comparison',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comparisonLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...comparisonData.take(6).map((data) {
              final category = data['category'] as String;
              final current = data['current'] as double;
              final previous = data['previous'] as double;
              final change = data['change'] as double;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${context.read<AppStateProvider>().getCurrencySymbol()}${current.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (previous > 0)
                            Text(
                              '${context.read<AppStateProvider>().getCurrencySymbol()}${previous.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change > 0 ? Icons.trending_up : 
                            change < 0 ? Icons.trending_down : Icons.trending_flat,
                            size: 16,
                            color: change > 0 ? Colors.red : 
                                   change < 0 ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: change > 0 ? Colors.red : 
                                     change < 0 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

 Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
        _selectedPeriod = 'custom';
      });
    }
  }

  Widget _buildTrendsTab(bool isTurkish, AppStateProvider appState) {
    final filteredTransactions = _filteredTransactions;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6-Month Trend Chart
          _buildTrendChart(isTurkish, filteredTransactions),
          const SizedBox(height: 24),
          
          // Weekly Spending Analysis
          _buildWeeklyAnalysis(isTurkish, filteredTransactions),
          const SizedBox(height: 24),
          
          // Top Spending Categories Trends
          _buildCategoryTrends(isTurkish, filteredTransactions),
          const SizedBox(height: 24),
          
          // Account Balance History
          _buildAccountBalanceHistory(isTurkish, appState),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(bool isTurkish, AppStateProvider appState) {
    final filteredTransactions = _filteredTransactions;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Health Score
          _buildFinancialHealthCard(isTurkish, filteredTransactions, appState),
          const SizedBox(height: 24),
          
          // Spending Patterns
          _buildSpendingPatterns(isTurkish, filteredTransactions, appState),
          const SizedBox(height: 24),
          
          // Budget Recommendations
          _buildBudgetRecommendations(isTurkish, filteredTransactions),
          const SizedBox(height: 24),
          
          // Savings Opportunities
          _buildSavingsOpportunities(isTurkish, filteredTransactions, appState),
        ],
      ),
    );
  }

  Widget _buildTrendChart(bool isTurkish, List<models.Transaction> transactions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? '6 Aylık Trend' : '6-Month Trend',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(months[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateTrendSpots(transactions, models.TransactionType.income),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: _generateTrendSpots(transactions, models.TransactionType.expense),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(isTurkish ? 'Gelir' : 'Income', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem(isTurkish ? 'Gider' : 'Expense', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAnalysis(bool isTurkish, List<models.Transaction> transactions) {
    final weeklyData = _calculateWeeklyData(transactions);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Haftalık Harcama Analizi' : 'Weekly Spending Analysis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...weeklyData.entries.map((entry) {
              final dayName = _getDayName(entry.key, isTurkish);
              final amount = entry.value;
              final maxAmount = weeklyData.values.reduce((a, b) => a > b ? a : b);
              final percentage = maxAmount > 0 ? (amount / maxAmount) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(dayName, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('\$${amount.toStringAsFixed(0)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTrends(bool isTurkish, List<models.Transaction> transactions) {
    final categoryTrends = _calculateCategoryTrends(transactions);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kategori Trendleri' : 'Category Trends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...categoryTrends.take(5).map((trend) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      trend['change'] > 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend['change'] > 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(trend['name']),
                    ),
                    Text(
                      '${trend['change'] > 0 ? '+' : ''}${(trend['change'] * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trend['change'] > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBalanceHistory(bool isTurkish, AppStateProvider appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Hesap Bakiye Geçmişi' : 'Account Balance History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...appState.accounts.take(3).map((account) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getAccountTypeIcon(account.type),
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(account.name, style: Theme.of(context).textTheme.titleSmall),
                          Text(
                            _getAccountTypeName(account.type, isTurkish),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${account.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: account.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialHealthCard(bool isTurkish, List<models.Transaction> transactions, AppStateProvider appState) {
    final healthScore = _calculateFinancialHealth(transactions, appState);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Finansal Sağlık Skoru' : 'Financial Health Score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: healthScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHealthScoreColor(healthScore),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${healthScore.toInt()}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getHealthScoreColor(healthScore),
                        ),
                      ),
                      Text(
                        isTurkish ? 'Puan' : 'Score',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getHealthScoreDescription(healthScore, isTurkish),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPatterns(bool isTurkish, List<models.Transaction> transactions, AppStateProvider appState) {
    final patterns = _analyzeSpendingPatterns(transactions, isTurkish, appState.getCurrencySymbol());
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Harcama Kalıpları' : 'Spending Patterns',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...patterns.map((pattern) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(pattern['icon'], color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pattern['title'], style: Theme.of(context).textTheme.titleSmall),
                          Text(pattern['description'], style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRecommendations(bool isTurkish, List<models.Transaction> transactions) {
    final recommendations = _generateBudgetRecommendations(transactions, isTurkish);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Bütçe Önerileri' : 'Budget Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsOpportunities(bool isTurkish, List<models.Transaction> transactions, AppStateProvider appState) {
    final opportunities = _findSavingsOpportunities(transactions, isTurkish, appState.getCurrencySymbol());
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Tasarruf Fırsatları' : 'Savings Opportunities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...opportunities.map((opp) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.savings, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opp['title'] as String, style: Theme.of(context).textTheme.titleSmall),
                            Text(opp['description'] as String, style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              opp['potential'] as String,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }


  // Helper methods for the new features
  List<FlSpot> _generateTrendSpots(List<models.Transaction> transactions, models.TransactionType type) {
    final monthlyData = <int, double>{};
    for (int i = 0; i < 6; i++) {
      monthlyData[i] = 0;
    }
    
    final now = DateTime.now();
    for (final transaction in transactions) {
      if (transaction.type == type) {
        final monthsAgo = now.month - transaction.date.month + (now.year - transaction.date.year) * 12;
        if (monthsAgo >= 0 && monthsAgo < 6) {
          monthlyData[5 - monthsAgo] = (monthlyData[5 - monthsAgo] ?? 0) + transaction.amount;
        }
      }
    }
    
    return monthlyData.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  Map<int, double> _calculateWeeklyData(List<models.Transaction> transactions) {
    final weeklyData = <int, double>{};
    for (int i = 1; i <= 7; i++) {
      weeklyData[i] = 0;
    }
    
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense) {
        final weekday = transaction.date.weekday;
        weeklyData[weekday] = (weeklyData[weekday] ?? 0) + transaction.amount;
      }
    }
    
    return weeklyData;
  }

  String _getDayName(int weekday, bool isTurkish) {
    if (isTurkish) {
      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days[weekday - 1];
    } else {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[weekday - 1];
    }
  }

  List<Map<String, dynamic>> _calculateCategoryTrends(List<models.Transaction> transactions) {
    return [
      {'name': 'Food & Dining', 'change': 0.15},
      {'name': 'Transportation', 'change': -0.08},
      {'name': 'Entertainment', 'change': 0.25},
      {'name': 'Shopping', 'change': -0.12},
      {'name': 'Utilities', 'change': 0.05},
    ];
  }

  double _calculateFinancialHealth(List<models.Transaction> transactions, AppStateProvider appState) {
    final totalIncome = transactions
        .where((t) => t.type == models.TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalIncome == 0) return 50.0;
    
    final savingsRate = (totalIncome - totalExpenses) / totalIncome;
    final baseScore = (savingsRate * 100).clamp(0.0, 100.0);
    
    // Adjust based on account diversity and other factors
    final accountDiversity = appState.accounts.length > 1 ? 10 : 0;
    
    return (baseScore + accountDiversity).clamp(0.0, 100.0);
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHealthScoreDescription(double score, bool isTurkish) {
    if (score >= 80) {
      return isTurkish ? 'Mükemmel finansal sağlık!' : 'Excellent financial health!';
    } else if (score >= 60) {
      return isTurkish ? 'İyi finansal durum, iyileştirme alanları var' : 'Good financial status, room for improvement';
    } else {
      return isTurkish ? 'Finansal durumunuzu iyileştirmeye odaklanın' : 'Focus on improving your financial situation';
    }
  }

  List<Map<String, dynamic>> _analyzeSpendingPatterns(List<models.Transaction> transactions, bool isTurkish, String currencySymbol) {
    if (transactions.isEmpty) {
      return [];
    }

    final patterns = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    // Analyze expense by categories
    final categoryExpenses = <int, double>{};
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense && transaction.categoryId != null) {
        categoryExpenses[transaction.categoryId!] = (categoryExpenses[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    
    if (categoryExpenses.isNotEmpty) {
      final topCategory = categoryExpenses.entries.reduce((a, b) => a.value > b.value ? a : b);
      final categoryName = _categories.firstWhere((c) => c.id == topCategory.key, 
        orElse: () => Category(name: 'Unknown', type: CategoryType.expense, color: '#9E9E9E', createdAt: DateTime.now(), updatedAt: DateTime.now())).name;
      
      patterns.add({
        'icon': Icons.trending_up,
        'title': isTurkish ? 'En Yüksek Harcama Kategorisi' : 'Highest Spending Category',
        'description': isTurkish 
          ? '$categoryName kategorisinde $currencySymbol${topCategory.value.toStringAsFixed(0)} harcama'
          : '$currencySymbol${topCategory.value.toStringAsFixed(0)} spent on $categoryName',
      });
    }
    
    // Analyze monthly comparison
    final thisMonthExpenses = transactions
      .where((t) => t.type == models.TransactionType.expense && 
                    t.date.year == thisMonth.year && t.date.month == thisMonth.month)
      .fold(0.0, (sum, t) => sum + t.amount);
      
    final lastMonthExpenses = transactions
      .where((t) => t.type == models.TransactionType.expense && 
                    t.date.year == lastMonth.year && t.date.month == lastMonth.month)
      .fold(0.0, (sum, t) => sum + t.amount);
    
    if (lastMonthExpenses > 0) {
      final changePercent = ((thisMonthExpenses - lastMonthExpenses) / lastMonthExpenses * 100);
      patterns.add({
        'icon': changePercent > 0 ? Icons.trending_up : Icons.trending_down,
        'title': isTurkish ? 'Aylık Karşılaştırma' : 'Monthly Comparison',
        'description': isTurkish 
          ? 'Geçen aya göre %${changePercent.abs().toStringAsFixed(0)} ${changePercent > 0 ? "artış" : "azalış"}'
          : '${changePercent.abs().toStringAsFixed(0)}% ${changePercent > 0 ? "increase" : "decrease"} vs last month',
      });
    }
    
    // Analyze transaction frequency
    final dailyAverage = transactions.length / 30;
    patterns.add({
      'icon': Icons.receipt_long,
      'title': isTurkish ? 'İşlem Sıklığı' : 'Transaction Frequency',
      'description': isTurkish 
        ? 'Günde ortalama ${dailyAverage.toStringAsFixed(1)} işlem'
        : 'Average ${dailyAverage.toStringAsFixed(1)} transactions per day',
    });
    
    return patterns;
  }

  List<String> _generateBudgetRecommendations(List<models.Transaction> transactions, bool isTurkish) {
    if (isTurkish) {
      return [
        'Aylık gelirinin %50\'sini temel ihtiyaçlara, %30\'unu isteklere, %20\'sini tasarrufa ayır',
        'Acil durum fonu için 3-6 aylık harcamalar kadar para biriktir',
        'Yüksek harcama kategorilerini takip et ve sınırlar koy',
      ];
    } else {
      return [
        'Follow the 50/30/20 rule: 50% needs, 30% wants, 20% savings',
        'Build an emergency fund worth 3-6 months of expenses',
        'Set spending limits for your highest expense categories',
      ];
    }
  }

  List<Map<String, String>> _findSavingsOpportunities(List<models.Transaction> transactions, bool isTurkish, String currencySymbol) {
    final opportunities = <Map<String, String>>[];
    
    if (transactions.isEmpty) {
      return opportunities;
    }
    
    // Calculate category expenses
    final categoryExpenses = <int, double>{};
    for (final transaction in transactions) {
      if (transaction.type == models.TransactionType.expense && transaction.categoryId != null) {
        categoryExpenses[transaction.categoryId!] = (categoryExpenses[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    
    // Find top expense categories and suggest savings
    if (categoryExpenses.isNotEmpty) {
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (int i = 0; i < math.min(2, sortedCategories.length); i++) {
        final categoryEntry = sortedCategories[i];
        final categoryName = _categories.firstWhere((c) => c.id == categoryEntry.key, 
          orElse: () => Category(name: 'Unknown', type: CategoryType.expense, color: '#9E9E9E', createdAt: DateTime.now(), updatedAt: DateTime.now())).name;
        final amount = categoryEntry.value;
        final savingsPotential = (amount * 0.2).toStringAsFixed(0); // 20% reduction potential
        
        opportunities.add({
          'title': isTurkish ? '$categoryName Harcamalarını Azalt' : 'Reduce $categoryName Expenses',
          'description': isTurkish 
            ? '$categoryName harcamalarınızı %20 azaltarak tasarruf yapabilirsiniz'
            : 'Reduce your $categoryName spending by 20% to save money',
          'potential': isTurkish 
            ? 'Potansiyel tasarruf: $currencySymbol$savingsPotential/ay'
            : 'Potential savings: $currencySymbol$savingsPotential/month',
        });
      }
    }
    
    // Add bill subscription opportunity
    final billExpenses = _filteredBillsSubscriptions.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.amount);
    if (billExpenses > 0) {
      final billSavings = (billExpenses * 0.15).toStringAsFixed(0);
      opportunities.add({
        'title': isTurkish ? 'Abonelik Gözden Geçir' : 'Review Subscriptions',
        'description': isTurkish 
          ? 'Kullanmadığınız abonelikleri iptal ederek tasarruf yapabilirsiniz'
          : 'Cancel unused subscriptions to free up money',
        'potential': isTurkish 
          ? 'Potansiyel tasarruf: $currencySymbol$billSavings/ay'
          : 'Potential savings: $currencySymbol$billSavings/month',
      });
    }
    
    if (opportunities.isEmpty) {
      opportunities.add({
        'title': isTurkish ? 'Acil Durum Fonu' : 'Emergency Fund',
        'description': isTurkish 
          ? 'Gelecekteki beklenmedik masraflar için para biriktirin'
          : 'Build savings for unexpected expenses',
        'potential': isTurkish ? 'Hedef: 3-6 aylık harcama' : 'Target: 3-6 months expenses',
      });
    }
    
    return opportunities;
  }


  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.bankAccount:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.loan:
        return Icons.trending_down;
      case AccountType.depositAccount:
        return Icons.savings;
    }
  }

  String _getAccountTypeName(AccountType type, bool isTurkish) {
    switch (type) {
      case AccountType.bankAccount:
        return isTurkish ? 'Banka Hesabı' : 'Bank Account';
      case AccountType.creditCard:
        return isTurkish ? 'Kredi Kartı' : 'Credit Card';
      case AccountType.loan:
        return isTurkish ? 'Kredi' : 'Loan';
      case AccountType.depositAccount:
        return isTurkish ? 'Mevduat Hesabı' : 'Deposit Account';
    }
  }

  // Bills & Subscriptions Statistics Methods
  Widget _buildBillsSummary(bool isTurkish, AppStateProvider appState) {
    final filteredBills = _filteredBillsSubscriptions;
    final totalBills = filteredBills.length;
    final paidBills = filteredBills.where((b) => b.isPaid).length;
    final overdueBills = filteredBills.where((b) => 
      !b.isPaid && b.dueDate != null && b.dueDate!.isBefore(DateTime.now())).length;
    final totalAmount = filteredBills.fold<double>(0.0, (sum, b) => sum + b.amount);
    final currencySymbol = appState.getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Fatura & Abonelik Özeti' : 'Bills & Subscriptions Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isTurkish ? 'Toplam' : 'Total',
                    totalBills.toString(),
                    Theme.of(context).primaryColor,
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isTurkish ? 'Ödenen' : 'Paid',
                    paidBills.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isTurkish ? 'Gecikmiş' : 'Overdue',
                    overdueBills.toString(),
                    Colors.red,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    isTurkish ? 'Toplam Tutar' : 'Total Amount',
                    '$currencySymbol${totalAmount.toStringAsFixed(0)}',
                    Colors.orange,
                    Icons.monetization_on,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsBreakdown(bool isTurkish, AppStateProvider appState) {
    final filteredBills = _filteredBillsSubscriptions;
    final billsByType = <BillSubscriptionType, List<BillSubscription>>{};
    for (final bill in filteredBills) {
      billsByType.putIfAbsent(bill.type, () => []).add(bill);
    }

    final currencySymbol = appState.getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Fatura & Abonelik Dağılımı' : 'Bills & Subscriptions Breakdown',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...billsByType.entries.map((entry) {
              final type = entry.key;
              final bills = entry.value;
              final totalAmount = bills.fold<double>(0.0, (sum, b) => sum + b.amount);
              final typeName = type == BillSubscriptionType.bill 
                ? (isTurkish ? 'Faturalar' : 'Bills')
                : (isTurkish ? 'Abonelikler' : 'Subs');
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      type == BillSubscriptionType.bill ? Icons.receipt : Icons.refresh,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(typeName, style: Theme.of(context).textTheme.titleSmall),
                          Text('${bills.length} ${isTurkish ? "öğe" : "items"}', 
                               style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      '$currencySymbol${totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBills(bool isTurkish, AppStateProvider appState) {
    final now = DateTime.now();
    final filteredBills = _filteredBillsSubscriptions;
    final upcomingBills = filteredBills.where((b) => 
      !b.isPaid && 
      ((b.dueDate != null && b.dueDate!.isAfter(now) && b.dueDate!.isBefore(now.add(const Duration(days: 30)))) ||
       (b.nextDate != null && b.nextDate!.isAfter(now) && b.nextDate!.isBefore(now.add(const Duration(days: 30)))))
    ).toList();

    upcomingBills.sort((a, b) {
      final aDate = a.dueDate ?? a.nextDate ?? now;
      final bDate = b.dueDate ?? b.nextDate ?? now;
      return aDate.compareTo(bDate);
    });

    final currencySymbol = appState.getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Yaklaşan Ödemeler (30 Gün)' : 'Upcoming Payments (30 Days)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (upcomingBills.isEmpty)
              Text(
                isTurkish ? 'Yaklaşan ödeme yok' : 'No upcoming payments',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              ...upcomingBills.take(5).map((bill) {
                final dueDate = bill.dueDate ?? bill.nextDate ?? now;
                final daysUntil = dueDate.difference(now).inDays;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: daysUntil <= 7 ? Colors.red : Colors.orange,
                    child: Icon(
                      bill.type == BillSubscriptionType.bill ? Icons.receipt : Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(bill.name),
                  subtitle: Text(
                    daysUntil == 0 
                      ? (isTurkish ? 'Bugün ödenecek' : 'Due today')
                      : (isTurkish ? '$daysUntil gün içinde' : 'In $daysUntil days'),
                  ),
                  trailing: Text(
                    '$currencySymbol${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsPaymentHistory(bool isTurkish, AppStateProvider appState) {
    final filteredBills = _filteredBillsSubscriptions;
    final paidBills = filteredBills.where((b) => b.isPaid).toList();
    paidBills.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

    final currencySymbol = appState.getCurrencySymbol();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Son Ödemeler' : 'Recent Payments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (paidBills.isEmpty)
              Text(
                isTurkish ? 'Henüz ödeme geçmişi yok' : 'No payment history yet',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              ...paidBills.take(5).map((bill) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      bill.type == BillSubscriptionType.bill ? Icons.receipt : Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(bill.name),
                  subtitle: Text(
                    '${bill.updatedAt.day}/${bill.updatedAt.month}/${bill.updatedAt.year}',
                  ),
                  trailing: Text(
                    '$currencySymbol${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}