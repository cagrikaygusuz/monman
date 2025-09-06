import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_theme.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../services/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<models.Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        DatabaseHelper().getTransactions(),
        DatabaseHelper().getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _transactions = futures[0] as List<models.Transaction>;
          _categories = futures[1] as List<Category>;
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
    if (_selectedDateRange == null) return _transactions;
    
    return _transactions.where((transaction) {
      final date = transaction.date;
      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Statistics & Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDateRange != null) _buildDateRangeCard(),
                      _buildOverviewCards(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildIncomeVsExpensesChart(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCategoryBreakdownChart(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMonthlyTrendChart(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildCategoryReports(),
                    ],
                  ),
                ),
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

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.date_range, color: AppTheme.primaryColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Period: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                });
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final income = _filteredTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final expenses = _filteredTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final balance = income - expenses;
    final transactionCount = _filteredTransactions.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Income',
            '\$${income.toStringAsFixed(2)}',
            AppTheme.secondaryColor,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Total Expenses',
            '\$${expenses.toStringAsFixed(2)}',
            AppTheme.errorColor,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Net Balance',
            '\$${balance.toStringAsFixed(2)}',
            balance >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            'Transactions',
            transactionCount.toString(),
            AppTheme.primaryColor,
            Icons.receipt_long,
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

  Widget _buildIncomeVsExpensesChart() {
    final income = _filteredTransactions
        .where((t) => t.type == models.TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final expenses = _filteredTransactions
        .where((t) => t.type == models.TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    if (income == 0 && expenses == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs Expenses',
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
                      value: income,
                      title: 'Income\n\$${income.toStringAsFixed(0)}',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: AppTheme.errorColor,
                      value: expenses,
                      title: 'Expenses\n\$${expenses.toStringAsFixed(0)}',
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

  Widget _buildCategoryBreakdownChart() {
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

    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
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
              'Expenses by Category',
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
                      title: '${category.key}\n\$${category.value.toStringAsFixed(0)}',
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

  Widget _buildMonthlyTrendChart() {
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

    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
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
              'Monthly Trend',
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
                _buildLegendItem('Income', AppTheme.secondaryColor),
                const SizedBox(width: AppSpacing.lg),
                _buildLegendItem('Expenses', AppTheme.errorColor),
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

  Widget _buildCategoryReports() {
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

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Reports',
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
      });
    }
  }
}