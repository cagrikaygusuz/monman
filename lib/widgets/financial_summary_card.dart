import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/database_helper.dart';

class FinancialSummaryCard extends StatefulWidget {
  const FinancialSummaryCard({super.key});

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard> {
  Map<String, double>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await DatabaseHelper().getFinancialSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Financial Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  _buildSummaryRow(
                    'Total Income',
                    _summary?['income'] ?? 0.0,
                    AppTheme.secondaryColor,
                    Icons.trending_up,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryRow(
                    'Total Expenses',
                    _summary?['expenses'] ?? 0.0,
                    AppTheme.errorColor,
                    Icons.trending_down,
                  ),
                  const Divider(height: AppSpacing.lg * 2),
                  _buildSummaryRow(
                    'Net Balance',
                    _summary?['balance'] ?? 0.0,
                    (_summary?['balance'] ?? 0.0) >= 0
                        ? AppTheme.secondaryColor
                        : AppTheme.errorColor,
                    Icons.account_balance_wallet,
                    isTotal: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
        ),
      ],
    );
  }
}