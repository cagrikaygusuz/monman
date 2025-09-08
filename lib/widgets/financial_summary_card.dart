import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/app_state_provider.dart';

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        final currencySymbol = appState.getCurrencySymbol();
        final totalIncome = appState.totalIncome;
        final totalExpenses = appState.totalExpenses;
        final netBalance = totalIncome - totalExpenses;

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
                      color: appState.selectedTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isTurkish ? 'Mali Özet' : 'Financial Summary',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      isTurkish ? 'Toplam Gelir' : 'Total Income',
                      totalIncome,
                      Colors.green,
                      Icons.trending_up,
                      currencySymbol,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSummaryRow(
                      context,
                      isTurkish ? 'Toplam Gider' : 'Total Expenses',
                      totalExpenses,
                      Colors.red,
                      Icons.trending_down,
                      currencySymbol,
                    ),
                    const Divider(height: AppSpacing.lg * 2),
                    _buildSummaryRow(
                      context,
                      isTurkish ? 'Net Bakiye' : 'Net Balance',
                      netBalance,
                      netBalance >= 0 ? Colors.green : Colors.red,
                      Icons.account_balance_wallet,
                      currencySymbol,
                      isTotal: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
    String currencySymbol, {
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
          '$currencySymbol${amount.toStringAsFixed(2)}',
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