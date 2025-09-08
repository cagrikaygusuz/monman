import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../models/transaction.dart' as models;
import '../models/account.dart';
import '../models/category.dart';
import '../providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Account> accounts;
  final List<Category> categories;
  final models.Transaction? transaction;

  const AddTransactionDialog({
    super.key,
    required this.accounts,
    required this.categories,
    this.transaction,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late TabController _tabController;
  models.TransactionType _selectedType = models.TransactionType.income;
  Account? _selectedAccount;
  Account? _selectedToAccount; // For transfers
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (_isEditing) {
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toStringAsFixed(2);
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedType = widget.transaction!.type;
      _selectedAccount = widget.accounts.firstWhere((a) => a.id == widget.transaction!.accountId);
      if (widget.transaction!.categoryId != null) {
        _selectedCategory = widget.categories.firstWhere((c) => c.id == widget.transaction!.categoryId);
      }
      _selectedDate = widget.transaction!.date;
      _tabController.index = _selectedType.index;
    } else {
      _selectedAccount = widget.accounts.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedType = models.TransactionType.values[index];
      _selectedCategory = null; // Reset category when type changes
    });
  }

  List<Category> get _availableCategories {
    switch (_selectedType) {
      case models.TransactionType.income:
        return widget.categories.where((c) => c.type == CategoryType.income).toList();
      case models.TransactionType.expense:
        return widget.categories.where((c) => c.type == CategoryType.expense).toList();
      case models.TransactionType.transfer:
        return []; // No categories for transfers
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final transaction = models.Transaction(
        id: _isEditing ? widget.transaction!.id : null,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory?.id,
        accountId: _selectedAccount!.id!,
        toAccountId: _selectedToAccount?.id,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: _isEditing ? widget.transaction!.createdAt : now,
        updatedAt: now,
      );

      Navigator.of(context).pop(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 500),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: appState.selectedTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _isEditing ? 'Edit Transaction' : 'Add Transaction',
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
                      Icon(Icons.add_circle_outline, size: 16),
                      SizedBox(width: 4),
                      Text('Income'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_circle_outline, size: 16),
                      SizedBox(width: 4),
                      Text('Expense'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 16),
                      SizedBox(width: 4),
                      Text('Transfer'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter transaction description',
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

                      // Account Dropdown
                      DropdownButtonFormField<Account>(
                        value: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        items: widget.accounts.map((account) {
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
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      ),

                      if (_selectedType == models.TransactionType.transfer) ...[
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<Account>(
                          value: _selectedToAccount,
                          decoration: const InputDecoration(
                            labelText: 'To Account',
                            prefixIcon: Icon(Icons.call_received),
                          ),
                          items: widget.accounts
                              .where((a) => a.id != _selectedAccount?.id)
                              .map((account) {
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
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedToAccount = value;
                            });
                          },
                          validator: (value) {
                            if (_selectedType == models.TransactionType.transfer && value == null) {
                              return 'Please select a destination account';
                            }
                            return null;
                          },
                        ),
                      ],

                      if (_availableCategories.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          selectedItemBuilder: (context) {
                            return [
                              const Text('No category'),
                              ..._availableCategories.map((category) {
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Color(
                                        int.parse(category.color.substring(1), radix: 16) + 0xFF000000
                                      ),
                                      radius: 8,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                );
                              }),
                            ];
                          },
                          items: [
                            const DropdownMenuItem<Category>(
                              value: null,
                              child: Text('No category'),
                            ),
                            ..._availableCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Color(
                                        int.parse(category.color.substring(1), radix: 16) + 0xFF000000
                                      ),
                                      radius: 8,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Date Field
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Add any additional notes',
                          prefixIcon: Icon(Icons.note_outlined),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
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
}