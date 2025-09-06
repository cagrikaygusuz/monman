enum BillSubscriptionType {
  bill,
  subscription,
}

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class BillSubscription {
  final int? id;
  final String name;
  final BillSubscriptionType type;
  final double amount;
  final String description;
  final int? categoryId;
  final int? accountId;
  final DateTime? dueDate; // For bills
  final Frequency? frequency; // For subscriptions
  final DateTime? nextDate; // For subscriptions
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  BillSubscription({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.description,
    this.categoryId,
    this.accountId,
    this.dueDate,
    this.frequency,
    this.nextDate,
    this.isPaid = false,
    required this.createdAt,
    required this.updatedAt,
  });

  BillSubscription copyWith({
    int? id,
    String? name,
    BillSubscriptionType? type,
    double? amount,
    String? description,
    int? categoryId,
    int? accountId,
    DateTime? dueDate,
    Frequency? frequency,
    DateTime? nextDate,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillSubscription(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'account_id': accountId,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'frequency': frequency?.index,
      'next_date': nextDate?.millisecondsSinceEpoch,
      'is_paid': isPaid ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BillSubscription.fromMap(Map<String, dynamic> map) {
    return BillSubscription(
      id: map['id'],
      name: map['name'],
      type: BillSubscriptionType.values[map['type']],
      amount: map['amount']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      categoryId: map['category_id'],
      accountId: map['account_id'],
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
      frequency: map['frequency'] != null
          ? Frequency.values[map['frequency']]
          : null,
      nextDate: map['next_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['next_date'])
          : null,
      isPaid: map['is_paid'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}