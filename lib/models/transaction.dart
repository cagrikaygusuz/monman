enum TransactionType {
  income,
  expense,
  transfer,
}

class Transaction {
  final int? id;
  final TransactionType type;
  final double amount;
  final String description;
  final int? categoryId;
  final int accountId;
  final int? toAccountId; // For transfers
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? description,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: TransactionType.values[map['type']],
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      categoryId: map['category_id'],
      accountId: map['account_id'],
      toAccountId: map['to_account_id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}