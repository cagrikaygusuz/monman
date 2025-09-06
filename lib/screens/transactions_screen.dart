import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/transaction.dart' as models;
import '../models/account.dart';
import '../models/category.dart';
import '../providers/app_state_provider.dart';
import '../widgets/add_transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with TickerProviderStateMixin {
  // Filter variables
  models.TransactionType? _selectedType;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTimeRange? _selectedDateRange;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddTransactionDialog(BuildContext context) async {
    final appState = context.read<AppStateProvider>();
    
    if (appState.accounts.isEmpty) {
      _showErrorSnackBar(context, 'Please add at least one account first');
      return;
    }

    final result = await showDialog<models.Transaction>(
      context: context,
      builder: (context) => AddTransactionDialog(
        accounts: appState.accounts,
        categories: appState.categories,
      ),
    );

    if (result != null) {
      try {
        await appState.addTransaction(result);
        
        // Update account balance
        final account = appState.accounts.firstWhere((a) => a.id == result.accountId);
        double newBalance = account.balance;
        
        switch (result.type) {
          case models.TransactionType.income:
            newBalance += result.amount;
            break;
          case models.TransactionType.expense:
            newBalance -= result.amount;
            break;
          case models.TransactionType.transfer:
            if (result.toAccountId != null) {
              // Update source account (subtract)
              final updatedFromAccount = account.copyWith(
                balance: newBalance - result.amount,
                updatedAt: DateTime.now(),
              );
              await appState.updateAccount(updatedFromAccount);
              
              // Update destination account (add)
              final toAccount = appState.accounts.firstWhere((a) => a.id == result.toAccountId);
              final updatedToAccount = toAccount.copyWith(
                balance: toAccount.balance + result.amount,
                updatedAt: DateTime.now(),
              );
              await appState.updateAccount(updatedToAccount);
              return;
            }
            break;
        }
        
        // Update the account balance for income/expense
        final updatedAccount = account.copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        );
        await appState.updateAccount(updatedAccount);
        
        if (context.mounted) {
          _showSuccessSnackBar(context, 'Transaction added successfully');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Error adding transaction: $e');
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

  List<models.Transaction> _getFilteredTransactions(List<models.Transaction> transactions) {
    return transactions.where((transaction) {
      if (_selectedType != null && transaction.type != _selectedType) return false;
      if (_selectedAccount != null && transaction.accountId != _selectedAccount!.id) return false;
      if (_selectedCategory != null && transaction.categoryId != _selectedCategory!.id) return false;
      if (_selectedDateRange != null) {
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        if (transactionDate.isBefore(start) || transactionDate.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final transactions = appState.transactions;
        final accounts = appState.accounts;
        final categories = appState.categories;
        final isLoading = appState.isLoading;
        final selectedLanguage = appState.selectedLanguage;

        final filteredTransactions = _getFilteredTransactions(transactions);
        
        final incomeTransactions = filteredTransactions
            .where((t) => t.type == models.TransactionType.income)
            .toList();
        final expenseTransactions = filteredTransactions
            .where((t) => t.type == models.TransactionType.expense)
            .toList();
        final transferTransactions = filteredTransactions
            .where((t) => t.type == models.TransactionType.transfer)
            .toList();

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(selectedLanguage == 'Turkish' ? 'İşlemler' : 'Transactions'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context, accounts, categories),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: selectedLanguage == 'Turkish' ? 'Hepsi' : 'All'),
                Tab(text: selectedLanguage == 'Turkish' ? 'Gelir' : 'Income'),
                Tab(text: selectedLanguage == 'Turkish' ? 'Gider' : 'Expense'),
                Tab(text: selectedLanguage == 'Turkish' ? 'Transfer' : 'Transfer'),
              ],
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(context, filteredTransactions, accounts, selectedLanguage),
                    _buildTransactionList(context, incomeTransactions, accounts, selectedLanguage),
                    _buildTransactionList(context, expenseTransactions, accounts, selectedLanguage),
                    _buildTransactionList(context, transferTransactions, accounts, selectedLanguage),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTransactionDialog(context),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<models.Transaction> transactions,
    List<Account> accounts,
    String selectedLanguage,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context, selectedLanguage);
    }

    // Group transactions by date
    final Map<String, List<models.Transaction>> groupedTransactions = {};
    for (final transaction in transactions) {
      final dateKey = '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}';
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a.split('/').reversed.join('-'));
        final dateB = DateTime.parse(b.split('/').reversed.join('-'));
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayTransactions = groupedTransactions[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...dayTransactions.map((transaction) {
              final account = accounts.firstWhere((a) => a.id == transaction.accountId);
              return _buildTransactionCard(context, transaction, account, accounts, selectedLanguage);
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String selectedLanguage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              selectedLanguage == 'Turkish' ? 'Henüz işlem yok' : 'No transactions yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              selectedLanguage == 'Turkish' 
                  ? 'İlk işleminizi ekleyin'
                  : 'Add your first transaction',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showAddTransactionDialog(context),
              icon: const Icon(Icons.add),
              label: Text(selectedLanguage == 'Turkish' ? 'İşlem Ekle' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    models.Transaction transaction,
    Account account,
    List<Account> accounts,
    String selectedLanguage,
  ) {
    final isIncome = transaction.type == models.TransactionType.income;
    final isExpense = transaction.type == models.TransactionType.expense;
    final isTransfer = transaction.type == models.TransactionType.transfer;
    
    final currencySymbol = context.read<AppStateProvider>().getCurrencySymbol();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isIncome
                  ? AppTheme.secondaryColor.withOpacity(0.1)
                  : isExpense
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.warningColor.withOpacity(0.1),
              child: Icon(
                isIncome
                    ? Icons.add_circle_outline
                    : isExpense
                        ? Icons.remove_circle_outline
                        : Icons.swap_horiz,
                color: isIncome
                    ? AppTheme.secondaryColor
                    : isExpense
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  if (isTransfer && transaction.toAccountId != null) ...[
                    Text(
                      '${selectedLanguage == 'Turkish' ? 'Alıcı' : 'To'}: ${accounts.firstWhere((a) => a.id == transaction.toAccountId).name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isIncome
                            ? AppTheme.secondaryColor
                            : isExpense
                                ? AppTheme.errorColor
                                : AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, List<Account> accounts, List<Category> categories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Transaction Type Filter
                  DropdownButtonFormField<models.TransactionType?>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      const DropdownMenuItem<models.TransactionType?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...models.TransactionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Account Filter
                  DropdownButtonFormField<Account?>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem<Account?>(
                        value: null,
                        child: Text('All Accounts'),
                      ),
                      ...accounts.map((account) {
                        return DropdownMenuItem(
                          value: account,
                          child: Text(account.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedAccount = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedAccount = null;
                _selectedCategory = null;
                _selectedDateRange = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Apply filters
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}