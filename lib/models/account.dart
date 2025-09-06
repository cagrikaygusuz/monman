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

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    );
  }
}