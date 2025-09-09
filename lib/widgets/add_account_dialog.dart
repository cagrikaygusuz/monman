import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';
import '../providers/app_state_provider.dart';

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
  final _accountNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Credit Card fields
  final _creditLimitController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _currentDebtController = TextEditingController();
  
  // Loan fields
  final _loanAmountController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  
  // Term Deposit fields
  final _principalController = TextEditingController();
  final _monthlyInterestController = TextEditingController();
  final _maturityDaysController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  
  AccountType _selectedType = AccountType.bankAccount;
  String _selectedCurrency = 'USD';
  String? _selectedBank;
  String? _selectedColor;
  DateTime? _lastPaymentDate;
  DateTime? _statementDate;
  DateTime? _loanStartDate;
  DateTime? _loanEndDate;
  DateTime? _maturityStartDate;
  DateTime? _maturityEndDate;
  bool _autoRenewal = false;
  
  final List<String> _currencies = ['USD', 'EUR', 'TRY', 'GBP', 'JPY'];
  final List<Map<String, dynamic>> _accountColors = [
    {'name': 'Blue', 'value': '#2196F3', 'color': Colors.blue},
    {'name': 'Green', 'value': '#4CAF50', 'color': Colors.green},
    {'name': 'Red', 'value': '#F44336', 'color': Colors.red},
    {'name': 'Purple', 'value': '#9C27B0', 'color': Colors.purple},
    {'name': 'Orange', 'value': '#FF9800', 'color': Colors.orange},
    {'name': 'Teal', 'value': '#009688', 'color': Colors.teal},
    {'name': 'Pink', 'value': '#E91E63', 'color': Colors.pink},
    {'name': 'Indigo', 'value': '#3F51B5', 'color': Colors.indigo},
  ];
  final List<String> _turkishBanks = [
    'Türkiye Cumhuriyet Merkez Bankası',
    'Ziraat Bankası',
    'Garanti BBVA',
    'İş Bankası',
    'Yapı Kredi Bankası',
    'Akbank',
    'Vakıfbank',
    'Halkbank',
    'Denizbank',
    'TEB (Türk Ekonomi Bankası)',
    'ING Bank',
    'Finansbank (QNB)',
    'ICBC Turkey Bank',
    'Anadolubank',
    'Alternatifbank',
    'Fibabanka',
    'Odeabank',
    'Şekerbank',
    'Turkish Bank',
    'Burgan Bank',
    'Citibank',
    'HSBC',
    'Standard Chartered',
    'Diğer (Other)',
  ];

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final account = widget.account!;
      _nameController.text = account.name;
      _balanceController.text = account.balance.toStringAsFixed(2);
      _selectedType = account.type;
      _selectedCurrency = account.currency;
      
      // Common fields
      _selectedBank = account.bankName;
      _accountNumberController.text = account.accountNumber ?? '';
      _descriptionController.text = account.description ?? '';
      _selectedColor = account.color;
      
      // Credit Card fields
      _creditLimitController.text = account.creditLimit?.toStringAsFixed(2) ?? '';
      _minimumPaymentController.text = account.minimumPayment?.toStringAsFixed(2) ?? '';
      _currentDebtController.text = account.currentDebt?.toStringAsFixed(2) ?? '';
      _lastPaymentDate = account.lastPaymentDate;
      _statementDate = account.statementDate;
      
      // Loan fields
      _loanAmountController.text = account.loanAmount?.toStringAsFixed(2) ?? '';
      _installmentCountController.text = account.installmentCount?.toString() ?? '';
      _installmentAmountController.text = account.installmentAmount?.toStringAsFixed(2) ?? '';
      _interestRateController.text = account.interestRate?.toString() ?? '';
      _loanStartDate = account.loanStartDate;
      _loanEndDate = account.loanEndDate;
      
      // Term Deposit fields
      _principalController.text = account.principal?.toStringAsFixed(2) ?? '';
      _monthlyInterestController.text = account.monthlyInterest?.toStringAsFixed(2) ?? '';
      _maturityDaysController.text = account.maturityDays?.toString() ?? '';
      _taxPercentageController.text = account.taxPercentage?.toString() ?? '';
      _maturityStartDate = account.maturityStartDate;
      _maturityEndDate = account.maturityEndDate;
      _autoRenewal = account.autoRenewal ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    _descriptionController.dispose();
    _creditLimitController.dispose();
    _minimumPaymentController.dispose();
    _currentDebtController.dispose();
    _loanAmountController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    _interestRateController.dispose();
    _principalController.dispose();
    _monthlyInterestController.dispose();
    _maturityDaysController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  void _calculateMaturityEndDate() {
    if (_maturityStartDate != null && _maturityDaysController.text.isNotEmpty) {
      final days = int.tryParse(_maturityDaysController.text);
      if (days != null && days > 0) {
        setState(() {
          _maturityEndDate = _maturityStartDate!.add(Duration(days: days));
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      
      // Calculate balance based on account type
      double accountBalance = 0.0;
      if (_selectedType == AccountType.bankAccount) {
        accountBalance = _balanceController.text.isEmpty ? 0.0 : double.parse(_balanceController.text);
      } else if (_selectedType == AccountType.creditCard) {
        // For credit cards, balance should be negative if there's debt
        accountBalance = _currentDebtController.text.isEmpty ? 0.0 : -double.parse(_currentDebtController.text);
      } else if (_selectedType == AccountType.loan) {
        // For loans, balance should be negative (debt amount)
        accountBalance = _loanAmountController.text.isEmpty ? 0.0 : -double.parse(_loanAmountController.text);
      } else if (_selectedType == AccountType.depositAccount) {
        // For term deposits, use principal as balance
        accountBalance = _principalController.text.isEmpty ? 0.0 : double.parse(_principalController.text);
      }
      
      // Set default color if none selected
      final accountColor = _selectedColor ?? '#2196F3';
      
      final account = Account(
        id: _isEditing ? widget.account!.id : null,
        name: _nameController.text.trim(),
        type: _selectedType,
        balance: accountBalance,
        currency: _selectedCurrency,
        createdAt: _isEditing ? widget.account!.createdAt : now,
        updatedAt: now,
        
        // Common fields
        bankName: _selectedBank,
        accountNumber: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        color: accountColor,
        
        // Credit Card fields
        creditLimit: _creditLimitController.text.isEmpty ? null : double.tryParse(_creditLimitController.text),
        lastPaymentDate: _lastPaymentDate,
        statementDate: _statementDate,
        minimumPayment: _minimumPaymentController.text.isEmpty ? null : double.tryParse(_minimumPaymentController.text),
        currentDebt: _currentDebtController.text.isEmpty ? null : double.tryParse(_currentDebtController.text),
        
        // Loan fields
        loanAmount: _loanAmountController.text.isEmpty ? null : double.tryParse(_loanAmountController.text),
        installmentCount: _installmentCountController.text.isEmpty ? null : int.tryParse(_installmentCountController.text),
        installmentAmount: _installmentAmountController.text.isEmpty ? null : double.tryParse(_installmentAmountController.text),
        interestRate: _interestRateController.text.isEmpty ? null : double.tryParse(_interestRateController.text),
        loanStartDate: _loanStartDate,
        loanEndDate: _loanEndDate,
        
        // Term Deposit fields
        principal: _principalController.text.isEmpty ? null : double.tryParse(_principalController.text),
        monthlyInterest: _monthlyInterestController.text.isEmpty ? null : double.tryParse(_monthlyInterestController.text),
        maturityDays: _maturityDaysController.text.isEmpty ? null : int.tryParse(_maturityDaysController.text),
        maturityStartDate: _maturityStartDate,
        maturityEndDate: _maturityEndDate,
        taxPercentage: _taxPercentageController.text.isEmpty ? null : double.tryParse(_taxPercentageController.text),
        autoRenewal: _selectedType == AccountType.depositAccount ? _autoRenewal : null,
      );
      
      Navigator.of(context).pop(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: appState.selectedTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isEditing 
                          ? (isTurkish ? 'Hesabı Düzenle' : 'Edit Account')
                          : (isTurkish ? 'Hesap Ekle' : 'Add Account'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Account Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Hesap Adı' : 'Account Name',
                              hintText: isTurkish ? 'Hesap adını girin' : 'Enter account name',
                              prefixIcon: const Icon(Icons.account_circle_outlined),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return isTurkish ? 'Lütfen hesap adı girin' : 'Please enter account name';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Account Type Field
                          DropdownButtonFormField<AccountType>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Hesap Türü' : 'Account Type',
                              prefixIcon: const Icon(Icons.category_outlined),
                            ),
                            items: AccountType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(_getAccountTypeName(type, isTurkish)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Bank Name Field
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Banka' : 'Bank',
                              prefixIcon: const Icon(Icons.account_balance),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(isTurkish ? 'Banka seçin' : 'Select Bank'),
                              ),
                              ..._turkishBanks.map((bank) {
                                return DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBank = value;
                              });
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Initial Balance Field (only for bank accounts)
                          if (_selectedType == AccountType.bankAccount) ...[
                            TextFormField(
                              controller: _balanceController,
                              decoration: InputDecoration(
                                labelText: isTurkish ? 'Başlangıç Bakiyesi' : 'Initial Balance',
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return isTurkish ? 'Lütfen başlangıç bakiyesi girin' : 'Please enter initial balance';
                                }
                                if (double.tryParse(value) == null) {
                                  return isTurkish ? 'Geçerli bir miktar girin' : 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Currency Field
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Para Birimi' : 'Currency',
                              prefixIcon: const Icon(Icons.monetization_on_outlined),
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
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Color Selection
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTurkish ? 'Hesap Rengi' : 'Account Color',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: _accountColors.map((colorData) {
                                    final isSelected = _selectedColor == colorData['value'];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedColor = colorData['value'];
                                        });
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorData['color'],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? Colors.white : Colors.transparent,
                                            width: 3,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: colorData['color'].withOpacity(0.5),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          // Account Number (Optional)
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _accountNumberController,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Hesap Numarası (İsteğe Bağlı)' : 'Account Number (Optional)',
                              hintText: isTurkish ? 'Hesap numaranızı girin' : 'Enter account number',
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                          ),
                          
                          // Type-specific fields
                          ..._buildTypeSpecificFields(isTurkish, appState),

                          // Description (Optional)
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: isTurkish ? 'Açıklama (İsteğe Bağlı)' : 'Description (Optional)',
                              hintText: isTurkish ? 'Bu hesap hakkında notlar' : 'Notes about this account',
                              prefixIcon: const Icon(Icons.note_outlined),
                            ),
                            maxLines: 2,
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
                      child: Text(isTurkish ? 'İptal' : 'Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isEditing 
                          ? (isTurkish ? 'Güncelle' : 'Update')
                          : (isTurkish ? 'Ekle' : 'Add')),
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

  List<Widget> _buildTypeSpecificFields(bool isTurkish, AppStateProvider appState) {
    switch (_selectedType) {
      case AccountType.creditCard:
        return _buildCreditCardFields(isTurkish, appState);
      case AccountType.loan:
        return _buildLoanFields(isTurkish, appState);
      case AccountType.depositAccount:
        return _buildTermDepositFields(isTurkish, appState);
      case AccountType.bankAccount:
      default:
        return [];
    }
  }

  List<Widget> _buildCreditCardFields(bool isTurkish, AppStateProvider appState) {
    return [
      const SizedBox(height: AppSpacing.md),
      Text(
        isTurkish ? 'Kredi Kartı Bilgileri' : 'Credit Card Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: appState.selectedTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: AppSpacing.sm),
      
      TextFormField(
        controller: _creditLimitController,
        decoration: InputDecoration(
          labelText: isTurkish ? 'Kredi Limiti' : 'Credit Limit',
          hintText: '0.00',
          prefixIcon: const Icon(Icons.credit_score),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _minimumPaymentController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Minimum Ödeme' : 'Minimum Payment',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.payment),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _currentDebtController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Mevcut Borç' : 'Current Debt',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.account_balance),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(isTurkish ? 'Son Ödeme Tarihi' : 'Last Payment Date'),
              subtitle: Text(_lastPaymentDate != null 
                  ? '${_lastPaymentDate!.day}/${_lastPaymentDate!.month}/${_lastPaymentDate!.year}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _lastPaymentDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _lastPaymentDate = date;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt),
              title: Text(isTurkish ? 'Hesap Kesim Tarihi' : 'Statement Date'),
              subtitle: Text(_statementDate != null 
                  ? '${_statementDate!.day}/${_statementDate!.month}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _statementDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _statementDate = date;
                  });
                }
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildLoanFields(bool isTurkish, AppStateProvider appState) {
    return [
      const SizedBox(height: AppSpacing.md),
      Text(
        isTurkish ? 'Kredi Bilgileri' : 'Loan Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: appState.selectedTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: AppSpacing.sm),
      
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _loanAmountController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Kredi Tutarı' : 'Loan Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.monetization_on),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _interestRateController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Faiz Oranı (%)' : 'Interest Rate (%)',
                hintText: '0.0',
                prefixIcon: const Icon(Icons.percent),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _installmentCountController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Taksit Sayısı' : 'Installment Count',
                hintText: '0',
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _installmentAmountController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Taksit Tutarı' : 'Installment Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.payment),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow),
              title: Text(isTurkish ? 'Başlangıç Tarihi' : 'Start Date'),
              subtitle: Text(_loanStartDate != null 
                  ? '${_loanStartDate!.day}/${_loanStartDate!.month}/${_loanStartDate!.year}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _loanStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (date != null) {
                  setState(() {
                    _loanStartDate = date;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop),
              title: Text(isTurkish ? 'Bitiş Tarihi' : 'End Date'),
              subtitle: Text(_loanEndDate != null 
                  ? '${_loanEndDate!.day}/${_loanEndDate!.month}/${_loanEndDate!.year}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _loanEndDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                );
                if (date != null) {
                  setState(() {
                    _loanEndDate = date;
                  });
                }
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildTermDepositFields(bool isTurkish, AppStateProvider appState) {
    return [
      const SizedBox(height: AppSpacing.md),
      Text(
        isTurkish ? 'Vadeli Mevduat Bilgileri' : 'Term Deposit Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: appState.selectedTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: AppSpacing.sm),
      
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _principalController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Anapara' : 'Principal',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.savings),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _monthlyInterestController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Aylık Faiz' : 'Monthly Interest',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.trending_up),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _maturityDaysController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Vade Süresi (Gün)' : 'Maturity Days',
                hintText: '0',
                prefixIcon: const Icon(Icons.calendar_view_day),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                _calculateMaturityEndDate();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _taxPercentageController,
              decoration: InputDecoration(
                labelText: isTurkish ? 'Vergi Oranı (%)' : 'Tax Percentage (%)',
                hintText: '0.0',
                prefixIcon: const Icon(Icons.receipt_long),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.start),
              title: Text(isTurkish ? 'Vade Başlangıcı' : 'Maturity Start'),
              subtitle: Text(_maturityStartDate != null 
                  ? '${_maturityStartDate!.day}/${_maturityStartDate!.month}/${_maturityStartDate!.year}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _maturityStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _maturityStartDate = date;
                    _calculateMaturityEndDate();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available),
              title: Text(isTurkish ? 'Vade Bitişi' : 'Maturity End'),
              subtitle: Text(_maturityEndDate != null 
                  ? '${_maturityEndDate!.day}/${_maturityEndDate!.month}/${_maturityEndDate!.year}'
                  : (isTurkish ? 'Seçilmedi' : 'Not selected')),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _maturityEndDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (date != null) {
                  setState(() {
                    _maturityEndDate = date;
                  });
                }
              },
            ),
          ),
        ],
      ),
      
      const SizedBox(height: AppSpacing.md),
      
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(isTurkish ? 'Otomatik Yenileme' : 'Auto Renewal'),
        subtitle: Text(isTurkish 
            ? 'Vade sonunda otomatik olarak yenile'
            : 'Automatically renew at maturity'),
        value: _autoRenewal,
        onChanged: (value) {
          setState(() {
            _autoRenewal = value;
          });
        },
        activeColor: appState.selectedTheme.primaryColor,
      ),
    ];
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
        return isTurkish ? 'Vadeli Mevduat' : 'Term Deposit';
    }
  }
}