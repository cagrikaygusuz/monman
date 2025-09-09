import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';
import '../providers/app_state_provider.dart';

class AccountsSummaryCard extends StatelessWidget {
  const AccountsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        final currencySymbol = appState.getCurrencySymbol();
        final accounts = appState.accounts;
        final totalBalance = appState.totalBalance;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: appState.selectedTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isTurkish ? 'Hesap Özeti' : 'Account Summary',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (accounts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      isTurkish 
                          ? 'Henüz hesap eklenmedi'
                          : 'No accounts added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            color: appState.selectedTheme.secondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isTurkish ? 'Toplam Bakiye' : 'Total Balance',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Text(
                            '$currencySymbol${totalBalance.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: totalBalance >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      ...accounts.take(3).map((account) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              _getAccountTypeIcon(account.type),
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                account.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '$currencySymbol${account.balance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: account.balance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      )),
                      if (accounts.length > 3) ...[
                        const SizedBox(height: AppSpacing.xs),
                        InkWell(
                          onTap: () {
                            // Navigate to accounts tab in main navigation
                            final mainNavState = context.findAncestorStateOfType<NavigatorState>();
                            if (mainNavState != null) {
                              // Find the parent widget and trigger accounts tab
                              // For now, show a dialog with all accounts
                              _showAllAccountsDialog(context, accounts, isTurkish, appState);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                Text(
                                  isTurkish 
                                      ? '+${accounts.length - 3} hesap daha'
                                      : '+${accounts.length - 3} more accounts',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: appState.selectedTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: appState.selectedTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  void _showAllAccountsDialog(BuildContext context, List<Account> accounts, bool isTurkish, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTurkish ? 'Tüm Hesaplar' : 'All Accounts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAccountTypeIcon(account.type),
                            color: appState.selectedTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  _getAccountTypeName(account.type, isTurkish),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${appState.getCurrencySymbol()}${account.balance.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: account.balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}