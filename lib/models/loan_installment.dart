enum InstallmentStatus {
  pending,
  paid,
  overdue,
}

class LoanInstallment {
  final int? id;
  final int loanAccountId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final InstallmentStatus status;
  final int? paidFromAccountId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanInstallment({
    this.id,
    required this.loanAccountId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paidFromAccountId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  LoanInstallment copyWith({
    int? id,
    int? loanAccountId,
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    InstallmentStatus? status,
    int? paidFromAccountId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanInstallment(
      id: id ?? this.id,
      loanAccountId: loanAccountId ?? this.loanAccountId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_account_id': loanAccountId,
      'installment_number': installmentNumber,
      'amount': amount,
      'due_date': dueDate.millisecondsSinceEpoch,
      'paid_date': paidDate?.millisecondsSinceEpoch,
      'status': status.index,
      'paid_from_account_id': paidFromAccountId,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LoanInstallment.fromMap(Map<String, dynamic> map) {
    return LoanInstallment(
      id: map['id'],
      loanAccountId: map['loan_account_id'],
      installmentNumber: map['installment_number'],
      amount: map['amount']?.toDouble() ?? 0.0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']),
      paidDate: map['paid_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['paid_date'])
          : null,
      status: InstallmentStatus.values[map['status'] ?? 0],
      paidFromAccountId: map['paid_from_account_id'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  bool get isOverdue => status == InstallmentStatus.pending && DateTime.now().isAfter(dueDate);
  bool get isPaid => status == InstallmentStatus.paid;
  bool get isPending => status == InstallmentStatus.pending;
}