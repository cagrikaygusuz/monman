import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/database_helper.dart';
import '../models/account.dart';

class AccountsSummaryCard extends StatefulWidget {
  const AccountsSummaryCard({super.key});

  @override
  State<AccountsSummaryCard> createState() => _AccountsSummaryCardState();
}

class _AccountsSummaryCardState extends State<AccountsSummaryCard> {
  List<Account> _accounts = [];
  double _totalBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await DatabaseHelper().getAccounts();
      final totalBalance = await DatabaseHelper().getTotalAccountBalance();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _totalBalance = totalBalance;
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
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Accounts Summary',
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
            else if (_accounts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No accounts yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Add your first account to get started',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${_totalBalance.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _accounts.length > 3 ? 3 : _accounts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return _buildAccountRow(account);
                    },
                  ),
                  if (_accounts.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to accounts page
                        },
                        child: Text('View all ${_accounts.length} accounts'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(Account account) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            _getAccountIcon(account.type),
            color: AppTheme.textSecondary,
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
                  _getAccountTypeName(account.type),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '\$${account.balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: account.balance >= 0
                      ? AppTheme.secondaryColor
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
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

  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.bankAccount:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.loan:
        return 'Loan';
      case AccountType.depositAccount:
        return 'Deposit Account';
    }
  }
}