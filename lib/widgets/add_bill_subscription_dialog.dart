import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../models/bill_subscription.dart';
import '../models/account.dart';
import '../models/category.dart';

class AddBillSubscriptionDialog extends StatefulWidget {
  final List<Account> accounts;
  final List<Category> categories;
  final BillSubscription? item;

  const AddBillSubscriptionDialog({
    super.key,
    required this.accounts,
    required this.categories,
    this.item,
  });

  @override
  State<AddBillSubscriptionDialog> createState() => _AddBillSubscriptionDialogState();
}

class _AddBillSubscriptionDialogState extends State<AddBillSubscriptionDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TabController _tabController;
  BillSubscriptionType _selectedType = BillSubscriptionType.bill;
  Account? _selectedAccount;
  Category? _selectedCategory;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  Frequency _selectedFrequency = Frequency.monthly;
  DateTime _selectedNextDate = DateTime.now().add(const Duration(days: 30));

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (_isEditing) {
      _nameController.text = widget.item!.name;
      _amountController.text = widget.item!.amount.toStringAsFixed(2);
      _descriptionController.text = widget.item!.description;
      _selectedType = widget.item!.type;
      if (widget.item!.accountId != null) {
        _selectedAccount = widget.accounts.firstWhere((a) => a.id == widget.item!.accountId);
      }
      if (widget.item!.categoryId != null) {
        _selectedCategory = widget.categories.firstWhere((c) => c.id == widget.item!.categoryId);
      }
      if (widget.item!.dueDate != null) {
        _selectedDueDate = widget.item!.dueDate!;
      }
      if (widget.item!.frequency != null) {
        _selectedFrequency = widget.item!.frequency!;
      }
      if (widget.item!.nextDate != null) {
        _selectedNextDate = widget.item!.nextDate!;
      }
      _tabController.index = _selectedType.index;
    } else {
      _selectedAccount = widget.accounts.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedType = BillSubscriptionType.values[index];
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final item = BillSubscription(
        id: _isEditing ? widget.item!.id : null,
        name: _nameController.text.trim(),
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id,
        accountId: _selectedAccount?.id,
        dueDate: _selectedType == BillSubscriptionType.bill ? _selectedDueDate : null,
        frequency: _selectedType == BillSubscriptionType.subscription ? _selectedFrequency : null,
        nextDate: _selectedType == BillSubscriptionType.subscription ? _selectedNextDate : null,
        isPaid: _isEditing ? widget.item!.isPaid : false,
        createdAt: _isEditing ? widget.item!.createdAt : now,
        updatedAt: now,
      );

      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _isEditing ? 'Edit Item' : 'Add Bill or Subscription',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TabBar(
              controller: _tabController,
              onTap: _onTabChanged,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt, size: 16),
                      SizedBox(width: 4),
                      Text('Bill'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16),
                      SizedBox(width: 4),
                      Text('Subscription'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter bill/subscription name',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount greater than 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter description',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Category Dropdown
                      if (widget.categories.isNotEmpty)
                        DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category (Optional)',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<Category>(
                              value: null,
                              child: Text('No category'),
                            ),
                            ...widget.categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),

                      const SizedBox(height: AppSpacing.md),

                      // Account Dropdown (Optional for bills/subscriptions)
                      DropdownButtonFormField<Account>(
                        value: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Default Account (Optional)',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<Account>(
                            value: null,
                            child: Text('No default account'),
                          ),
                          ...widget.accounts.map((account) {
                            return DropdownMenuItem(
                              value: account,
                              child: Row(
                                children: [
                                  Icon(_getAccountTypeIcon(account.type), size: 16),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      account.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Bill-specific fields
                      if (_selectedType == BillSubscriptionType.bill) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Due Date'),
                          subtitle: Text(
                            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDueDate = date;
                              });
                            }
                          },
                        ),
                      ],

                      // Subscription-specific fields
                      if (_selectedType == BillSubscriptionType.subscription) ...[
                        DropdownButtonFormField<Frequency>(
                          value: _selectedFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                            prefixIcon: Icon(Icons.refresh),
                          ),
                          items: Frequency.values.map((frequency) {
                            return DropdownMenuItem(
                              value: frequency,
                              child: Text(_getFrequencyName(frequency)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFrequency = value!;
                              // Auto-calculate next date based on frequency
                              _selectedNextDate = _calculateNextDate(value, DateTime.now());
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event),
                          title: const Text('Next Payment Date'),
                          subtitle: Text(
                            '${_selectedNextDate.day}/${_selectedNextDate.month}/${_selectedNextDate.year}',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedNextDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedNextDate = date;
                              });
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _selectedType == BillSubscriptionType.bill
                                    ? 'Bills have a specific due date and need to be paid once.'
                                    : 'Subscriptions automatically schedule the next payment based on frequency.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isEditing ? 'Update' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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