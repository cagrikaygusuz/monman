enum AccountType {
  bankAccount,
  creditCard,
  loan,
  depositAccount,
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Common fields
  final String? bankName;
  final String? accountNumber;
  final String? description;
  final String? color;
  
  // Credit Card specific fields
  final double? creditLimit;
  final DateTime? lastPaymentDate;
  final DateTime? statementDate;
  final double? minimumPayment;
  final double? currentDebt;
  
  // Loan specific fields
  final double? loanAmount;
  final int? installmentCount;
  final double? installmentAmount;
  final double? interestRate;
  final DateTime? loanStartDate;
  final DateTime? loanEndDate;
  
  // Term Deposit specific fields
  final double? principal;
  final double? monthlyInterest;
  final int? maturityDays;
  final DateTime? maturityStartDate;
  final DateTime? maturityEndDate;
  final double? taxPercentage;
  final bool? autoRenewal;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
    this.bankName,
    this.accountNumber,
    this.description,
    this.color,
    // Credit Card fields
    this.creditLimit,
    this.lastPaymentDate,
    this.statementDate,
    this.minimumPayment,
    this.currentDebt,
    // Loan fields
    this.loanAmount,
    this.installmentCount,
    this.installmentAmount,
    this.interestRate,
    this.loanStartDate,
    this.loanEndDate,
    // Term Deposit fields
    this.principal,
    this.monthlyInterest,
    this.maturityDays,
    this.maturityStartDate,
    this.maturityEndDate,
    this.taxPercentage,
    this.autoRenewal,
  });

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bankName,
    String? accountNumber,
    String? description,
    String? color,
    // Credit Card fields
    double? creditLimit,
    DateTime? lastPaymentDate,
    DateTime? statementDate,
    double? minimumPayment,
    double? currentDebt,
    // Loan fields
    double? loanAmount,
    int? installmentCount,
    double? installmentAmount,
    double? interestRate,
    DateTime? loanStartDate,
    DateTime? loanEndDate,
    // Term Deposit fields
    double? principal,
    double? monthlyInterest,
    int? maturityDays,
    DateTime? maturityStartDate,
    DateTime? maturityEndDate,
    double? taxPercentage,
    bool? autoRenewal,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      description: description ?? this.description,
      color: color ?? this.color,
      // Credit Card fields
      creditLimit: creditLimit ?? this.creditLimit,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      statementDate: statementDate ?? this.statementDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      currentDebt: currentDebt ?? this.currentDebt,
      // Loan fields
      loanAmount: loanAmount ?? this.loanAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      interestRate: interestRate ?? this.interestRate,
      loanStartDate: loanStartDate ?? this.loanStartDate,
      loanEndDate: loanEndDate ?? this.loanEndDate,
      // Term Deposit fields
      principal: principal ?? this.principal,
      monthlyInterest: monthlyInterest ?? this.monthlyInterest,
      maturityDays: maturityDays ?? this.maturityDays,
      maturityStartDate: maturityStartDate ?? this.maturityStartDate,
      maturityEndDate: maturityEndDate ?? this.maturityEndDate,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      autoRenewal: autoRenewal ?? this.autoRenewal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'bank_name': bankName,
      'account_number': accountNumber,
      'description': description,
      'color': color,
      // Credit Card fields
      'credit_limit': creditLimit,
      'last_payment_date': lastPaymentDate?.millisecondsSinceEpoch,
      'statement_date': statementDate?.millisecondsSinceEpoch,
      'minimum_payment': minimumPayment,
      'current_debt': currentDebt,
      // Loan fields
      'loan_amount': loanAmount,
      'installment_count': installmentCount,
      'installment_amount': installmentAmount,
      'interest_rate': interestRate,
      'loan_start_date': loanStartDate?.millisecondsSinceEpoch,
      'loan_end_date': loanEndDate?.millisecondsSinceEpoch,
      // Term Deposit fields
      'principal': principal,
      'monthly_interest': monthlyInterest,
      'maturity_days': maturityDays,
      'maturity_start_date': maturityStartDate?.millisecondsSinceEpoch,
      'maturity_end_date': maturityEndDate?.millisecondsSinceEpoch,
      'tax_percentage': taxPercentage,
      'auto_renewal': autoRenewal == true ? 1 : 0,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values[map['type']],
      balance: map['balance']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      bankName: map['bank_name'],
      accountNumber: map['account_number'],
      description: map['description'],
      color: map['color'],
      // Credit Card fields
      creditLimit: map['credit_limit']?.toDouble(),
      lastPaymentDate: map['last_payment_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_payment_date'])
          : null,
      statementDate: map['statement_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['statement_date'])
          : null,
      minimumPayment: map['minimum_payment']?.toDouble(),
      currentDebt: map['current_debt']?.toDouble(),
      // Loan fields
      loanAmount: map['loan_amount']?.toDouble(),
      installmentCount: map['installment_count'],
      installmentAmount: map['installment_amount']?.toDouble(),
      interestRate: map['interest_rate']?.toDouble(),
      loanStartDate: map['loan_start_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['loan_start_date'])
          : null,
      loanEndDate: map['loan_end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['loan_end_date'])
          : null,
      // Term Deposit fields
      principal: map['principal']?.toDouble(),
      monthlyInterest: map['monthly_interest']?.toDouble(),
      maturityDays: map['maturity_days'],
      maturityStartDate: map['maturity_start_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['maturity_start_date'])
          : null,
      maturityEndDate: map['maturity_end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['maturity_end_date'])
          : null,
      taxPercentage: map['tax_percentage']?.toDouble(),
      autoRenewal: map['auto_renewal'] == 1,
    );
  }
}