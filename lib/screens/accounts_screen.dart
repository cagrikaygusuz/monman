import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';
import '../providers/app_state_provider.dart';
import '../widgets/add_account_dialog.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // Track expanded state for each account type
  final Map<AccountType, bool> _expandedStates = {
    AccountType.bankAccount: true,
    AccountType.creditCard: true,
    AccountType.loan: true,
    AccountType.depositAccount: true,
  };

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final accounts = appState.accounts;
        final isLoading = appState.isLoading;

        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(isTurkish ? 'Hesaplar' : 'Accounts'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await context.read<AppStateProvider>().loadAllData();
            },
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : accounts.isEmpty
                    ? _buildEmptyState(context, isTurkish)
                    : _buildAccountsByCategory(context, accounts, isTurkish),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddAccountDialog(context),
            backgroundColor: Theme.of(context).primaryColor,
            heroTag: "accounts_fab",
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTurkish) {
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
              isTurkish ? 'Henüz hesap yok' : 'No accounts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isTurkish 
                  ? 'Finansmanınızı yönetmeye başlamak için ilk hesabınızı ekleyin'
                  : 'Add your first account to start managing your finances',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: Text(isTurkish ? 'Hesap Ekle' : 'Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account, bool isTurkish) {
    final appState = context.watch<AppStateProvider>();
    final themeColor = _getAccountColor(account, appState);
    
    return Card(
      color: themeColor,
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDetailScreen(account: account),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _getAccountTypeIcon(account.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getAccountTypeName(account.type, isTurkish),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        account.currency,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: Text(isTurkish ? 'Düzenle' : 'Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _deleteAccount(context, account),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        backgroundColor: Colors.red.withOpacity(0.2),
                      ),
                      child: Text(isTurkish ? 'Sil' : 'Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccountColor(Account account, AppStateProvider appState) {
    if (account.color != null) {
      try {
        final colorValue = int.parse(account.color!.replaceAll('#', ''), radix: 16);
        return Color(0xFF000000 | colorValue);
      } catch (e) {
        return appState.selectedTheme.primaryColor;
      }
    }
    return appState.selectedTheme.primaryColor;
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
        return isTurkish ? 'Banka Hesapları' : 'Bank Accounts';
      case AccountType.creditCard:
        return isTurkish ? 'Kredi Kartları' : 'Credit Cards';
      case AccountType.loan:
        return isTurkish ? 'Krediler' : 'Loans';
      case AccountType.depositAccount:
        return isTurkish ? 'Mevduat Hesapları' : 'Deposit Accounts';
    }
  }

  Widget _buildAccountsByCategory(BuildContext context, List<Account> accounts, bool isTurkish) {
    // Group accounts by type
    final Map<AccountType, List<Account>> groupedAccounts = {};
    for (final account in accounts) {
      if (!groupedAccounts.containsKey(account.type)) {
        groupedAccounts[account.type] = [];
      }
      groupedAccounts[account.type]!.add(account);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        ...groupedAccounts.entries.map((entry) => 
          _buildCategorySection(context, entry.key, entry.value, isTurkish)
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, AccountType type, List<Account> accounts, bool isTurkish) {
    final categoryName = _getAccountTypeName(type, isTurkish);
    final categoryIcon = _getAccountTypeIcon(type);
    final isExpanded = _expandedStates[type] ?? true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedStates[type] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  categoryIcon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${accounts.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isExpanded 
              ? CrossFadeState.showFirst 
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              ...accounts.map((account) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildAccountCard(context, account, isTurkish),
                ),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}