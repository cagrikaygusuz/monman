import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/bill_subscription.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/database_helper.dart';
import '../widgets/add_bill_subscription_dialog.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with TickerProviderStateMixin {
  List<BillSubscription> _billsSubscriptions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        DatabaseHelper().getBillsSubscriptions(),
        DatabaseHelper().getAccounts(),
        DatabaseHelper().getCategories(type: CategoryType.billSubscription),
      ]);

      if (mounted) {
        setState(() {
          _billsSubscriptions = futures[0] as List<BillSubscription>;
          _accounts = futures[1] as List<Account>;
          _categories = futures[2] as List<Category>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading data: $e');
      }
    }
  }

  Future<void> _showAddDialog() async {
    if (_accounts.isEmpty) {
      _showErrorSnackBar('Please add at least one account first');
      return;
    }

    final result = await showDialog<BillSubscription>(
      context: context,
      builder: (context) => AddBillSubscriptionDialog(
        accounts: _accounts,
        categories: _categories,
      ),
    );

    if (result != null) {
      try {
        await DatabaseHelper().insertBillSubscription(result);
        await _loadData();
        if (mounted) {
          _showSuccessSnackBar('${result.type == BillSubscriptionType.bill ? 'Bill' : 'Subscription'} added successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error adding item: $e');
        }
      }
    }
  }

  Future<void> _payBill(BillSubscription item) async {
    if (_accounts.isEmpty) {
      _showErrorSnackBar('No accounts available for payment');
      return;
    }

    final selectedAccount = await showDialog<Account>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _accounts.map((account) {
            return ListTile(
              leading: Icon(_getAccountTypeIcon(account.type)),
              title: Text(account.name),
              subtitle: Text('\$${account.balance.toStringAsFixed(2)}'),
              onTap: () => Navigator.of(context).pop(account),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedAccount != null) {
      if (selectedAccount.balance < item.amount) {
        _showErrorSnackBar('Insufficient balance in selected account');
        return;
      }

      try {
        // Mark as paid and update next date for subscriptions
        final updatedItem = item.copyWith(
          isPaid: true,
          nextDate: item.type == BillSubscriptionType.subscription
              ? _calculateNextDate(item.frequency!, DateTime.now())
              : null,
        );
        
        await DatabaseHelper().updateBillSubscription(updatedItem);
        
        // Update account balance
        final updatedAccount = selectedAccount.copyWith(
          balance: selectedAccount.balance - item.amount,
          updatedAt: DateTime.now(),
        );
        await DatabaseHelper().updateAccount(updatedAccount);

        await _loadData();
        if (mounted) {
          _showSuccessSnackBar('Payment processed successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error processing payment: $e');
        }
      }
    }
  }

  DateTime _calculateNextDate(Frequency frequency, DateTime currentDate) {
    switch (frequency) {
      case Frequency.daily:
        return currentDate.add(const Duration(days: 1));
      case Frequency.weekly:
        return currentDate.add(const Duration(days: 7));
      case Frequency.monthly:
        return DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      case Frequency.yearly:
        return DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
    }
  }

  Future<void> _deleteItem(BillSubscription item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.type == BillSubscriptionType.bill ? 'Bill' : 'Subscription'}'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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
        await DatabaseHelper().deleteBillSubscription(item.id!);
        await _loadData();
        if (mounted) {
          _showSuccessSnackBar('Item deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting item: $e');
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bills & Subscriptions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bills'),
            Tab(text: 'Subscriptions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillsList(),
                _buildSubscriptionsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBillsList() {
    final bills = _billsSubscriptions
        .where((item) => item.type == BillSubscriptionType.bill)
        .toList();

    if (bills.isEmpty) {
      return _buildEmptyState('No bills yet', 'Add your first bill to track payments');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _buildBillCard(bills[index]),
    );
  }

  Widget _buildSubscriptionsList() {
    final subscriptions = _billsSubscriptions
        .where((item) => item.type == BillSubscriptionType.subscription)
        .toList();

    if (subscriptions.isEmpty) {
      return _buildEmptyState('No subscriptions yet', 'Add your first subscription to track payments');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: subscriptions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _buildSubscriptionCard(subscriptions[index]),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(BillSubscription bill) {
    final isOverdue = bill.dueDate != null && 
                     DateTime.now().isAfter(bill.dueDate!) && 
                     !bill.isPaid;
    final daysUntilDue = bill.dueDate != null 
        ? bill.dueDate!.difference(DateTime.now()).inDays 
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOverdue 
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.receipt,
                    color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        bill.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (bill.dueDate != null)
                        Text(
                          isOverdue 
                              ? 'Overdue by ${(-daysUntilDue)} days'
                              : daysUntilDue == 0 
                                  ? 'Due today'
                                  : 'Due in $daysUntilDue days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
                                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${bill.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (bill.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'PAID',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (!bill.isPaid)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _payBill(bill),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                      ),
                      child: Text(isOverdue ? 'PAY NOW' : 'PAY'),
                    ),
                  ),
                if (!bill.isPaid) const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _showItemOptions(bill),
                  child: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BillSubscription subscription) {
    final daysUntilNext = subscription.nextDate != null 
        ? subscription.nextDate!.difference(DateTime.now()).inDays 
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                  child: Icon(
                    Icons.refresh,
                    color: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subscription.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (subscription.frequency != null)
                        Text(
                          '${_getFrequencyName(subscription.frequency!)} subscription',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      if (subscription.nextDate != null)
                        Text(
                          daysUntilNext <= 0 
                              ? 'Due now'
                              : 'Next payment in $daysUntilNext days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: daysUntilNext <= 3 ? AppTheme.warningColor : AppTheme.textSecondary,
                                fontWeight: daysUntilNext <= 3 ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${subscription.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (daysUntilNext <= 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _payBill(subscription),
                      child: const Text('PAY NOW'),
                    ),
                  ),
                if (daysUntilNext <= 0) const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _showItemOptions(subscription),
                  child: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemOptions(BillSubscription item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete'),
              textColor: AppTheme.errorColor,
              onTap: () {
                Navigator.of(context).pop();
                _deleteItem(item);
              },
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

  String _getFrequencyName(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 'Daily';
      case Frequency.weekly:
        return 'Weekly';
      case Frequency.monthly:
        return 'Monthly';
      case Frequency.yearly:
        return 'Yearly';
    }
  }
}