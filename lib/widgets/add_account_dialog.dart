import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';

class AddAccountDialog extends StatefulWidget {
  final Account? account;

  const AddAccountDialog({super.key, this.account});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  AccountType _selectedType = AccountType.bankAccount;
  String _selectedCurrency = 'USD';
  
  final List<String> _currencies = ['USD', 'EUR', 'TRY', 'GBP', 'JPY'];

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toStringAsFixed(2);
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final account = Account(
        id: _isEditing ? widget.account!.id : null,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: double.parse(_balanceController.text),
        currency: _selectedCurrency,
        createdAt: _isEditing ? widget.account!.createdAt : now,
        updatedAt: now,
      );
      
      Navigator.of(context).pop(account);
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Edit Account' : 'Add Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Account Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'Enter account name',
                  prefixIcon: Icon(Icons.account_circle_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name';
                  }
                  if (value.trim().length < 2) {
                    return 'Account name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Account Type Dropdown
              DropdownButtonFormField<AccountType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getAccountTypeIcon(type), size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(_getAccountTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Initial Balance Field
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _balanceController,
                      decoration: InputDecoration(
                        labelText: _isEditing ? 'Current Balance' : 'Initial Balance',
                        hintText: '0.00',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a balance';
                        }
                        final balance = double.tryParse(value);
                        if (balance == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Account Type Info
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
                        _getAccountTypeDescription(_selectedType),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Action Buttons
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

  String _getAccountTypeDescription(AccountType type) {
    switch (type) {
      case AccountType.bankAccount:
        return 'Regular checking or savings account from a bank';
      case AccountType.creditCard:
        return 'Credit card account with available credit limit';
      case AccountType.loan:
        return 'Loan account tracking money owed';
      case AccountType.depositAccount:
        return 'High-yield savings or term deposit account';
    }
  }
}