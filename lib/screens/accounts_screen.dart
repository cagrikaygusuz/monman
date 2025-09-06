import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';
import '../providers/app_state_provider.dart';
import '../widgets/add_account_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _showAddAccountDialog(BuildContext context) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );

    if (result != null) {
      try {
        await context.read<AppStateProvider>().addAccount(result);
        if (context.mounted) {
          _showSuccessSnackBar(context, 'Account added successfully');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Error adding account: $e');
        }
      }
    }
  }

  Future<void> _showEditAccountDialog(BuildContext context, Account account) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (context) => AddAccountDialog(account: account),
    );

    if (result != null) {
      try {
        await context.read<AppStateProvider>().updateAccount(result);
        if (context.mounted) {
          _showSuccessSnackBar(context, 'Account updated successfully');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Error updating account: $e');
        }
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<AppStateProvider>().deleteAccount(account.id!);
        if (context.mounted) {
          _showSuccessSnackBar(context, 'Account deleted successfully');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Error deleting account: $e');
        }
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final accounts = appState.accounts;
        final isLoading = appState.isLoading;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Accounts'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : accounts.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: accounts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _buildAccountCard(context, accounts[index]),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddAccountDialog(context),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No accounts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first account to start managing your finances',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    _getAccountTypeIcon(account.type),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _getAccountTypeName(account.type),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${context.read<AppStateProvider>().getCurrencySymbol()}${account.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: account.balance >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      account.currency,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditAccountDialog(context, account),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteAccount(context, account),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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