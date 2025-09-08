import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/bill_subscription.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../providers/app_state_provider.dart';
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
  String _searchQuery = '';
  String _sortBy = 'dueDate'; // dueDate, amount, name
  bool _showOnlyOverdue = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final appState = context.read<AppStateProvider>();
      final isTurkish = appState.selectedLanguage == 'Turkish';
      _showErrorSnackBar(isTurkish ? 'Lütfen önce en az bir hesap ekleyin' : 'Please add at least one account first');
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
          final appState = context.read<AppStateProvider>();
          final isTurkish = appState.selectedLanguage == 'Turkish';
          _showSuccessSnackBar('${result.type == BillSubscriptionType.bill ? (isTurkish ? 'Fatura' : 'Bill') : (isTurkish ? 'Abonelik' : 'Subscription')} ${isTurkish ? 'başarıyla eklendi' : 'added successfully'}');
        }
      } catch (e) {
        if (mounted) {
          final appState = context.read<AppStateProvider>();
          final isTurkish = appState.selectedLanguage == 'Turkish';
          _showErrorSnackBar(isTurkish ? 'Öğe eklenirken hata oluştu: $e' : 'Error adding item: $e');
        }
      }
    }
  }

  Future<void> _payBill(BillSubscription item) async {
    if (_accounts.isEmpty) {
      final appState = context.read<AppStateProvider>();
      final isTurkish = appState.selectedLanguage == 'Turkish';
      _showErrorSnackBar(isTurkish ? 'Ödeme için hesap bulunmuyor' : 'No accounts available for payment');
      return;
    }

    final appState = context.read<AppStateProvider>();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    final selectedAccount = await showDialog<Account>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Ödeme Hesabını Seçin' : 'Select Payment Account'),
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
        _showErrorSnackBar(isTurkish ? 'Seçilen hesapta yetersiz bakiye' : 'Insufficient balance in selected account');
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
          _showSuccessSnackBar(isTurkish ? 'Ödeme başarıyla işlendi' : 'Payment processed successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(isTurkish ? 'Ödeme işlenirken hata oluştu: $e' : 'Error processing payment: $e');
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
    final appState = context.read<AppStateProvider>();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isTurkish ? 'Sil' : 'Delete'} ${item.type == BillSubscriptionType.bill ? (isTurkish ? 'Fatura' : 'Bill') : (isTurkish ? 'Abonelik' : 'Subscription')}'),
        content: Text(isTurkish ? '"${item.name}" öğesini silmek istediğinizden emin misiniz?' : 'Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isTurkish ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().deleteBillSubscription(item.id!);
        await _loadData();
        if (mounted) {
          _showSuccessSnackBar(isTurkish ? 'Öğe başarıyla silindi' : 'Item deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(isTurkish ? 'Öğe silinirken hata oluştu: $e' : 'Error deleting item: $e');
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final selectedLanguage = appState.selectedLanguage;
    final isTurkish = selectedLanguage == 'Turkish';
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isTurkish ? 'Faturalar ve Abonelikler' : 'Bills & Subscriptions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: isTurkish ? 'Faturalar' : 'Bills'),
            Tab(text: isTurkish ? 'Abonelikler' : 'Subscriptions'),
            Tab(text: isTurkish ? 'Takvim' : 'Calendar'),
            Tab(text: isTurkish ? 'Analitikler' : 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(isTurkish),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillsList(isTurkish),
                      _buildSubscriptionsList(isTurkish),
                      _buildCalendarView(isTurkish),
                      _buildAnalyticsView(isTurkish),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBillsList(bool isTurkish) {
    final bills = _billsSubscriptions
        .where((item) => item.type == BillSubscriptionType.bill)
        .toList();

    if (bills.isEmpty) {
      return _buildEmptyState(
        isTurkish ? 'Henüz fatura yok' : 'No bills yet', 
        isTurkish ? 'Ödeme takibi için ilk faturanızı ekleyin' : 'Add your first bill to track payments'
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _buildBillCard(bills[index]),
    );
  }

  Widget _buildSubscriptionsList(bool isTurkish) {
    final subscriptions = _billsSubscriptions
        .where((item) => item.type == BillSubscriptionType.subscription)
        .toList();

    if (subscriptions.isEmpty) {
      return _buildEmptyState(
        isTurkish ? 'Henüz abonelik yok' : 'No subscriptions yet', 
        isTurkish ? 'Ödeme takibi için ilk aboneliğinizi ekleyin' : 'Add your first subscription to track payments'
      );
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
    final appState = context.watch<AppStateProvider>();
    final cardColor = isOverdue ? Colors.red : appState.selectedTheme.primaryColor;

    return Card(
      color: cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.receipt,
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
                        bill.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bill.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (bill.dueDate != null)
                        Builder(
                          builder: (context) {
                            final appState = context.watch<AppStateProvider>();
                            final isTurkish = appState.selectedLanguage == 'Turkish';
                            return Text(
                              isOverdue 
                                  ? (isTurkish ? '${(-daysUntilDue)} gün gecikmiş' : 'Overdue by ${(-daysUntilDue)} days')
                                  : daysUntilDue == 0 
                                      ? (isTurkish ? 'Bugün ödenecek' : 'Due today')
                                      : (isTurkish ? '$daysUntilDue gün içinde ödenecek' : 'Due in $daysUntilDue days'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            );
                          },
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
                            color: Colors.white,
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
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Builder(
                          builder: (context) {
                            final appState = context.watch<AppStateProvider>();
                            final isTurkish = appState.selectedLanguage == 'Turkish';
                            return Text(
                              isTurkish ? 'ÖDENDİ' : 'PAID',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            );
                          },
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
                        backgroundColor: Colors.white,
                        foregroundColor: cardColor,
                      ),
                      child: Builder(
                        builder: (context) {
                          final appState = context.watch<AppStateProvider>();
                          final isTurkish = appState.selectedLanguage == 'Turkish';
                          return Text(
                            isOverdue 
                              ? (isTurkish ? 'ŞİMDİ ÖDE' : 'PAY NOW')
                              : (isTurkish ? 'ÖDE' : 'PAY'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  ),
                if (!bill.isPaid) const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _showItemOptions(bill),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
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
    final appState = context.watch<AppStateProvider>();
    final cardColor = daysUntilNext <= 3 ? Colors.amber : appState.selectedTheme.secondaryColor;

    return Card(
      color: cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.refresh,
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
                        subscription.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subscription.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      if (subscription.frequency != null)
                        Builder(
                          builder: (context) {
                            final appState = context.watch<AppStateProvider>();
                            final isTurkish = appState.selectedLanguage == 'Turkish';
                            return Text(
                              '${_getFrequencyName(subscription.frequency!, isTurkish)} ${isTurkish ? 'abonelik' : 'subscription'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                            );
                          },
                        ),
                      if (subscription.nextDate != null)
                        Builder(
                          builder: (context) {
                            final appState = context.watch<AppStateProvider>();
                            final isTurkish = appState.selectedLanguage == 'Turkish';
                            return Text(
                              daysUntilNext <= 0 
                                  ? (isTurkish ? 'Şimdi ödenecek' : 'Due now')
                                  : (isTurkish ? 'Sonraki ödeme $daysUntilNext gün içinde' : 'Next payment in $daysUntilNext days'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${subscription.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cardColor,
                      ),
                      child: Builder(
                        builder: (context) {
                          final appState = context.watch<AppStateProvider>();
                          final isTurkish = appState.selectedLanguage == 'Turkish';
                          return Text(
                            isTurkish ? 'ŞİMDİ ÖDE' : 'PAY NOW',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  ),
                if (daysUntilNext <= 0) const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => _showItemOptions(subscription),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
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
    final appState = context.read<AppStateProvider>();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(isTurkish ? 'Düzenle' : 'Edit'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditItemDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(isTurkish ? 'Sil' : 'Delete'),
              textColor: Colors.red,
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

  String _getFrequencyName(Frequency frequency, [bool isTurkish = false]) {
    if (isTurkish) {
      switch (frequency) {
        case Frequency.daily:
          return 'Günlük';
        case Frequency.weekly:
          return 'Haftalık';
        case Frequency.monthly:
          return 'Aylık';
        case Frequency.yearly:
          return 'Yıllık';
      }
    } else {
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

  Widget _buildSearchAndFilters(bool isTurkish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: isTurkish ? 'Fatura ve abonelikleri ara...' : 'Search bills and subscriptions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter Row
          Row(
            children: [
              // Sort Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: isTurkish ? 'Sırala' : 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'dueDate', child: Text(isTurkish ? 'Vade Tarihi' : 'Due Date')),
                    DropdownMenuItem(value: 'amount', child: Text(isTurkish ? 'Tutar' : 'Amount')),
                    DropdownMenuItem(value: 'name', child: Text(isTurkish ? 'İsim' : 'Name')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Overdue Filter
              FilterChip(
                label: Text(isTurkish ? 'Sadece Gecikmiş' : 'Overdue Only'),
                selected: _showOnlyOverdue,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyOverdue = selected;
                  });
                },
                selectedColor: Colors.red[100],
                checkmarkColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(bool isTurkish) {
    final upcomingPayments = _getUpcomingPayments();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This Week Section
          Text(
            isTurkish ? 'Bu Hafta' : 'This Week',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...upcomingPayments
              .where((p) => p['daysUntil'] <= 7)
              .map((payment) => _buildPaymentCalendarCard(payment)),
          
          const SizedBox(height: 24),
          
          // Next 30 Days
          Text(
            isTurkish ? 'Gelecek 30 Gün' : 'Next 30 Days',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...upcomingPayments
              .where((p) => p['daysUntil'] > 7 && p['daysUntil'] <= 30)
              .map((payment) => _buildPaymentCalendarCard(payment)),
              
          const SizedBox(height: 24),
          
          // Monthly Summary
          _buildMonthlyPaymentSummary(isTurkish),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView(bool isTurkish) {
    final analytics = _calculateBillsAnalytics();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  isTurkish ? 'Aylık Toplam' : 'Total Monthly',
                  '\$${(analytics['totalMonthly'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  isTurkish ? 'Aktif Faturalar' : 'Active Bills',
                  '${analytics['activeBills']}',
                  Icons.receipt,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  isTurkish ? 'Gecikmiş' : 'Overdue',
                  '${analytics['overdueCount']}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  isTurkish ? 'Ort. Tutar' : 'Avg. Amount',
                  '\$${(analytics['averageAmount'] ?? 0.0).toStringAsFixed(0)}',
                  Icons.analytics,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Category Breakdown
          _buildCategoryBreakdown(isTurkish),
          
          const SizedBox(height: 24),
          
          // Payment History Chart
          _buildPaymentHistoryChart(isTurkish),
          
          const SizedBox(height: 24),
          
          // Spending Insights
          _buildSpendingInsights(isTurkish),
        ],
      ),
    );
  }

  Widget _buildPaymentCalendarCard(Map<String, dynamic> payment) {
    final bill = payment['bill'] as BillSubscription;
    final daysUntil = payment['daysUntil'] as int;
    final isOverdue = daysUntil < 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red : Colors.blue,
          child: Icon(
            bill.type == BillSubscriptionType.bill ? Icons.receipt : Icons.refresh,
            color: Colors.white,
          ),
        ),
        title: Text(bill.name),
        subtitle: Builder(
          builder: (context) {
            final appState = context.watch<AppStateProvider>();
            final isTurkish = appState.selectedLanguage == 'Turkish';
            return Text(
              isOverdue 
                ? (isTurkish ? '${(-daysUntil)} gün gecikmiş' : 'Overdue by ${(-daysUntil)} days')
                : daysUntil == 0 
                  ? (isTurkish ? 'Bugün ödenecek' : 'Due today')
                  : (isTurkish ? '$daysUntil gün içinde ödenecek' : 'Due in $daysUntil days'),
            );
          },
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${bill.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!bill.isPaid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Builder(
                  builder: (context) {
                    final appState = context.watch<AppStateProvider>();
                    final isTurkish = appState.selectedLanguage == 'Turkish';
                    return Text(
                      isOverdue 
                        ? (isTurkish ? 'GECİKMİŞ' : 'OVERDUE') 
                        : (isTurkish ? 'BEKLİYOR' : 'PENDING'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        onTap: () => _payBill(bill),
      ),
    );
  }

  Widget _buildMonthlyPaymentSummary(bool isTurkish) {
    final monthlyTotal = _calculateMonthlyTotal();
    final paidThisMonth = _calculatePaidThisMonth();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Aylık Ödeme Özeti' : 'Monthly Payment Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      isTurkish ? 'Toplam Borç' : 'Total Due',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${monthlyTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      isTurkish ? 'Ödenen' : 'Paid',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${paidThisMonth.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      isTurkish ? 'Kalan' : 'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${(monthlyTotal - paidThisMonth).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: monthlyTotal > 0 ? (paidThisMonth / monthlyTotal) : 0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final appState = context.watch<AppStateProvider>();
                final isTurkish = appState.selectedLanguage == 'Turkish';
                return Text(
                  isTurkish 
                    ? 'Bu ay %${((monthlyTotal > 0 ? (paidThisMonth / monthlyTotal) : 0) * 100).toStringAsFixed(1)} ödendi'
                    : '${((monthlyTotal > 0 ? (paidThisMonth / monthlyTotal) : 0) * 100).toStringAsFixed(1)}% paid this month',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(bool isTurkish) {
    final categoryData = _getCategoryBreakdown(isTurkish);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kategoriye Göre Harcama' : 'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...categoryData.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(category['icon'], color: category['color']),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(category['name']),
                    ),
                    Text(
                      '\$${category['amount'].toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildPaymentHistoryChart(bool isTurkish) {
    final paymentHistory = _getPaymentHistory();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Ödeme Geçmişi (Son 6 Ay)' : 'Payment History (Last 6 Months)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            paymentHistory.isEmpty
                ? Container(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isTurkish ? 'Henüz ödeme geçmişi yok' : 'No payment history yet',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: paymentHistory.length,
                      itemBuilder: (context, index) {
                        final payment = paymentHistory[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green,
                            child: const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            payment['name'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            _formatDate(payment['date'], isTurkish),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Text(
                            '\$${payment['amount'].toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingInsights(bool isTurkish) {
    final insights = _generateSpendingInsights(isTurkish);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Harcama İçgörüleri' : 'Spending Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._generateSpendingInsights(isTurkish).map((insight) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(insight['icon'], color: insight['color']),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight['title'],
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            insight['description'],
                            style: Theme.of(context).textTheme.bodySmall,
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

  // Helper methods for new features
  List<Map<String, dynamic>> _getUpcomingPayments() {
    final now = DateTime.now();
    final payments = <Map<String, dynamic>>[];
    
    for (final bill in _billsSubscriptions) {
      if (!bill.isPaid) {
        final dueDate = bill.dueDate ?? bill.nextDate ?? now;
        final daysUntil = dueDate.difference(now).inDays;
        
        if (daysUntil <= 30) {
          payments.add({
            'bill': bill,
            'daysUntil': daysUntil,
            'dueDate': dueDate,
          });
        }
      }
    }
    
    payments.sort((a, b) => a['daysUntil'].compareTo(b['daysUntil']));
    return payments;
  }

  Map<String, double> _calculateBillsAnalytics() {
    final now = DateTime.now();
    double totalMonthly = 0;
    int activeBills = 0;
    int overdueCount = 0;
    double totalAmount = 0;
    
    for (final bill in _billsSubscriptions) {
      if (bill.type == BillSubscriptionType.subscription) {
        totalMonthly += bill.amount;
      }
      activeBills++;
      totalAmount += bill.amount;
      
      if (!bill.isPaid && bill.dueDate != null && bill.dueDate!.isBefore(now)) {
        overdueCount++;
      }
    }
    
    return {
      'totalMonthly': totalMonthly,
      'activeBills': activeBills.toDouble(),
      'overdueCount': overdueCount.toDouble(),
      'averageAmount': activeBills > 0 ? totalAmount / activeBills : 0,
    };
  }

  double _calculateMonthlyTotal() {
    return _billsSubscriptions
        .where((b) => b.type == BillSubscriptionType.subscription)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  double _calculatePaidThisMonth() {
    final now = DateTime.now();
    return _billsSubscriptions
        .where((b) => 
            b.isPaid && 
            b.dueDate != null && 
            b.dueDate!.month == now.month &&
            b.dueDate!.year == now.year)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  List<Map<String, dynamic>> _getCategoryBreakdown(bool isTurkish) {
    final Map<String, Map<String, dynamic>> categoryTotals = {};
    
    // Group bills by category (this is a simplified approach since we don't have categories linked)
    for (final item in _billsSubscriptions) {
      String categoryKey;
      IconData icon;
      Color color;
      
      // Categorize by name patterns (simplified categorization)
      final name = item.name.toLowerCase();
      if (name.contains('electric') || name.contains('elektrik') || name.contains('gas') || name.contains('gaz') || name.contains('water') || name.contains('su')) {
        categoryKey = isTurkish ? 'Kamu Hizmetleri' : 'Utilities';
        icon = Icons.flash_on;
        color = Colors.yellow[700]!;
      } else if (name.contains('internet') || name.contains('phone') || name.contains('telefon') || name.contains('mobile') || name.contains('wifi')) {
        categoryKey = isTurkish ? 'İnternet ve Telefon' : 'Internet & Phone';
        icon = Icons.wifi;
        color = Colors.blue;
      } else if (name.contains('netflix') || name.contains('spotify') || name.contains('youtube') || name.contains('stream') || name.contains('tv')) {
        categoryKey = isTurkish ? 'Yayın Hizmetleri' : 'Streaming Services';
        icon = Icons.play_circle;
        color = Colors.purple;
      } else if (name.contains('insurance') || name.contains('sigorta') || name.contains('health') || name.contains('sağlık')) {
        categoryKey = isTurkish ? 'Sigorta' : 'Insurance';
        icon = Icons.security;
        color = Colors.green;
      } else {
        categoryKey = isTurkish ? 'Diğer' : 'Other';
        icon = Icons.more_horiz;
        color = Colors.grey;
      }
      
      if (!categoryTotals.containsKey(categoryKey)) {
        categoryTotals[categoryKey] = {
          'name': categoryKey,
          'amount': 0.0,
          'icon': icon,
          'color': color,
        };
      }
      
      categoryTotals[categoryKey]!['amount'] += item.amount;
    }
    
    // Convert to list and sort by amount
    final result = categoryTotals.values.toList();
    result.sort((a, b) => b['amount'].compareTo(a['amount']));
    
    return result;
  }

  List<Map<String, dynamic>> _getPaymentHistory() {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    final paymentHistory = <Map<String, dynamic>>[];
    
    // Get paid bills and subscriptions from the last 6 months
    for (final item in _billsSubscriptions) {
      if (item.isPaid && item.dueDate != null && item.dueDate!.isAfter(sixMonthsAgo)) {
        paymentHistory.add({
          'name': item.name,
          'amount': item.amount,
          'date': item.dueDate!,
          'type': item.type,
        });
      }
    }
    
    // Sort by date (most recent first)
    paymentHistory.sort((a, b) => b['date'].compareTo(a['date']));
    
    return paymentHistory;
  }

  String _formatDate(DateTime date, bool isTurkish) {
    final months = isTurkish
        ? ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Map<String, dynamic>> _generateSpendingInsights(bool isTurkish) {
    final insights = <Map<String, dynamic>>[];
    final analytics = _calculateBillsAnalytics();
    final totalMonthly = analytics['totalMonthly'] ?? 0.0;
    final overdueCount = analytics['overdueCount']?.toInt() ?? 0;
    final activeBills = analytics['activeBills']?.toInt() ?? 0;
    
    // Dynamic insight about subscription costs
    if (totalMonthly > 0) {
      if (totalMonthly > 200) {
        insights.add({
          'title': isTurkish ? 'Yüksek Abonelik Maliyetleri' : 'High Subscription Costs',
          'description': isTurkish 
            ? 'Aylık abonelik harcamanız \$${totalMonthly.toStringAsFixed(0)} - bu oldukça yüksek'
            : 'Your monthly subscription spending is \$${totalMonthly.toStringAsFixed(0)} - this is quite high',
          'icon': Icons.trending_up,
          'color': Colors.red,
        });
      } else if (totalMonthly > 100) {
        insights.add({
          'title': isTurkish ? 'Orta Seviye Harcama' : 'Moderate Spending',
          'description': isTurkish 
            ? 'Aylık abonelik harcamanız \$${totalMonthly.toStringAsFixed(0)} - makul seviyede'
            : 'Your monthly subscription spending is \$${totalMonthly.toStringAsFixed(0)} - reasonable level',
          'icon': Icons.trending_flat,
          'color': Colors.orange,
        });
      } else {
        insights.add({
          'title': isTurkish ? 'Düşük Harcama' : 'Low Spending',
          'description': isTurkish 
            ? 'Aylık abonelik harcamanız \$${totalMonthly.toStringAsFixed(0)} - çok iyi kontrol ediyorsunuz'
            : 'Your monthly subscription spending is \$${totalMonthly.toStringAsFixed(0)} - very well controlled',
          'icon': Icons.trending_down,
          'color': Colors.green,
        });
      }
    }
    
    // Dynamic insight about overdue bills
    if (overdueCount > 0) {
      insights.add({
        'title': isTurkish ? 'Gecikmiş Ödemeler' : 'Overdue Payments',
        'description': isTurkish 
          ? '$overdueCount adet gecikmiş ödemeniz var - bunları öncelikli olarak ödeyin'
          : 'You have $overdueCount overdue payments - prioritize paying these',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }
    
    // Dynamic insight about payment pattern
    if (activeBills > 0) {
      final firstHalfDue = _billsSubscriptions
          .where((b) => b.dueDate != null && b.dueDate!.day <= 15)
          .length;
      final percentage = (firstHalfDue / activeBills * 100).round();
      
      if (percentage > 70) {
        insights.add({
          'title': isTurkish ? 'Ödeme Modeli' : 'Payment Pattern',
          'description': isTurkish 
            ? 'Faturalarınızın %$percentage\'i ayın ilk yarısında vadesi geliyor - nakit akışını planlayın'
            : '$percentage% of your bills are due in the first half of the month - plan your cash flow',
          'icon': Icons.calendar_today,
          'color': Colors.blue,
        });
      }
    }
    
    // Dynamic insight about potential savings
    final subscriptionCount = _billsSubscriptions
        .where((b) => b.type == BillSubscriptionType.subscription)
        .length;
    if (subscriptionCount >= 3) {
      final potentialSavings = (totalMonthly * 0.15).round(); // Estimate 15% savings
      insights.add({
        'title': isTurkish ? 'Potansiyel Tasarruf' : 'Potential Savings',
        'description': isTurkish 
          ? '$subscriptionCount aboneliğiniz var - paketleyerek ayda \$${potentialSavings} tasarruf edebilirsiniz'
          : 'You have $subscriptionCount subscriptions - consider bundling to save \$${potentialSavings}/month',
        'icon': Icons.savings,
        'color': Colors.green,
      });
    }
    
    // If no specific insights, add a general positive message
    if (insights.isEmpty) {
      insights.add({
        'title': isTurkish ? 'İyi Finansal Durum' : 'Good Financial Health',
        'description': isTurkish 
          ? 'Faturalarınız kontrol altında görünüyor - böyle devam edin!'
          : 'Your bills appear to be under control - keep it up!',
        'icon': Icons.thumb_up,
        'color': Colors.green,
      });
    }
    
    return insights;
  }

  Future<void> _showEditItemDialog(BillSubscription item) async {
    final result = await showDialog<BillSubscription>(
      context: context,
      builder: (context) => AddBillSubscriptionDialog(
        accounts: _accounts,
        categories: _categories,
        billSubscription: item, // Pass the existing item for editing
      ),
    );

    if (result != null) {
      try {
        await DatabaseHelper().updateBillSubscription(result);
        await _loadData();
        if (mounted) {
          final appState = context.read<AppStateProvider>();
          final isTurkish = appState.selectedLanguage == 'Turkish';
          _showSuccessSnackBar('${result.type == BillSubscriptionType.bill ? (isTurkish ? 'Fatura' : 'Bill') : (isTurkish ? 'Abonelik' : 'Subscription')} ${isTurkish ? 'başarıyla güncellendi' : 'updated successfully'}');
        }
      } catch (e) {
        if (mounted) {
          final appState = context.read<AppStateProvider>();
          final isTurkish = appState.selectedLanguage == 'Turkish';
          _showErrorSnackBar(isTurkish ? 'Öğe güncellenirken hata oluştu: $e' : 'Error updating item: $e');
        }
      }
    }
  }
}