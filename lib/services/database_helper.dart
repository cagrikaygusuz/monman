import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as models;
import '../models/bill_subscription.dart';
import '../models/loan_installment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'monman.db');
    
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        bank_name TEXT,
        account_number TEXT,
        description TEXT,
        -- Credit Card fields
        credit_limit REAL,
        last_payment_date INTEGER,
        statement_date INTEGER,
        minimum_payment REAL,
        current_debt REAL,
        -- Loan fields
        loan_amount REAL,
        installment_count INTEGER,
        installment_amount REAL,
        interest_rate REAL,
        loan_start_date INTEGER,
        loan_end_date INTEGER,
        -- Term Deposit fields
        principal REAL,
        monthly_interest REAL,
        maturity_days INTEGER,
        maturity_start_date INTEGER,
        maturity_end_date INTEGER,
        tax_percentage REAL,
        auto_renewal INTEGER DEFAULT 0,
        -- Additional field
        color TEXT
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        color TEXT NOT NULL,
        icon TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category_id INTEGER,
        account_id INTEGER NOT NULL,
        to_account_id INTEGER,
        date INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (to_account_id) REFERENCES accounts (id)
      )
    ''');

    // Create bills_subscriptions table
    await db.execute('''
      CREATE TABLE bills_subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        category_id INTEGER,
        account_id INTEGER,
        due_date INTEGER,
        frequency INTEGER,
        next_date INTEGER,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Create loan_installments table
    await db.execute('''
      CREATE TABLE loan_installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_account_id INTEGER NOT NULL,
        installment_number INTEGER NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER NOT NULL,
        paid_date INTEGER,
        status INTEGER NOT NULL DEFAULT 0,
        paid_from_account_id INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (loan_account_id) REFERENCES accounts (id),
        FOREIGN KEY (paid_from_account_id) REFERENCES accounts (id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Income categories
    final incomeCategories = [
      {'name': 'Salary', 'type': 0, 'color': '#4CAF50'},
      {'name': 'Freelance', 'type': 0, 'color': '#2196F3'},
      {'name': 'Investment', 'type': 0, 'color': '#FF9800'},
      {'name': 'Other Income', 'type': 0, 'color': '#9C27B0'},
    ];

    // Expense categories
    final expenseCategories = [
      {'name': 'Food & Dining', 'type': 1, 'color': '#F44336'},
      {'name': 'Transportation', 'type': 1, 'color': '#E91E63'},
      {'name': 'Shopping', 'type': 1, 'color': '#9C27B0'},
      {'name': 'Entertainment', 'type': 1, 'color': '#673AB7'},
      {'name': 'Health & Fitness', 'type': 1, 'color': '#3F51B5'},
      {'name': 'Education', 'type': 1, 'color': '#2196F3'},
      {'name': 'Utilities', 'type': 1, 'color': '#009688'},
      {'name': 'Other Expenses', 'type': 1, 'color': '#795548'},
    ];

    // Bills & Subscriptions categories
    final billsCategories = [
      {'name': 'Utilities', 'type': 2, 'color': '#FF5722'},
      {'name': 'Internet & Phone', 'type': 2, 'color': '#607D8B'},
      {'name': 'Insurance', 'type': 2, 'color': '#FF9800'},
      {'name': 'Subscriptions', 'type': 2, 'color': '#8BC34A'},
    ];

    for (final category in [...incomeCategories, ...expenseCategories, ...billsCategories]) {
      await db.insert('categories', {
        ...category,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for enhanced account details
      await db.execute('ALTER TABLE accounts ADD COLUMN bank_name TEXT');
      await db.execute('ALTER TABLE accounts ADD COLUMN account_number TEXT');
      await db.execute('ALTER TABLE accounts ADD COLUMN description TEXT');
      
      // Credit Card fields
      await db.execute('ALTER TABLE accounts ADD COLUMN credit_limit REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN last_payment_date INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN statement_date INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN minimum_payment REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN current_debt REAL');
      
      // Loan fields
      await db.execute('ALTER TABLE accounts ADD COLUMN loan_amount REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN installment_count INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN installment_amount REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN interest_rate REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN loan_start_date INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN loan_end_date INTEGER');
      
      // Term Deposit fields
      await db.execute('ALTER TABLE accounts ADD COLUMN principal REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN monthly_interest REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN maturity_days INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN maturity_start_date INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN maturity_end_date INTEGER');
      await db.execute('ALTER TABLE accounts ADD COLUMN tax_percentage REAL');
      await db.execute('ALTER TABLE accounts ADD COLUMN auto_renewal INTEGER DEFAULT 0');
    }
    
    if (oldVersion < 3) {
      // Add color field for accounts
      await db.execute('ALTER TABLE accounts ADD COLUMN color TEXT');
    }
    
    if (oldVersion < 4) {
      // Create loan_installments table
      await db.execute('''
        CREATE TABLE loan_installments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          loan_account_id INTEGER NOT NULL,
          installment_number INTEGER NOT NULL,
          amount REAL NOT NULL,
          due_date INTEGER NOT NULL,
          paid_date INTEGER,
          status INTEGER NOT NULL DEFAULT 0,
          paid_from_account_id INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (loan_account_id) REFERENCES accounts (id),
          FOREIGN KEY (paid_from_account_id) REFERENCES accounts (id)
        )
      ''');
    }
  }

  // Account operations
  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getAccount(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories({CategoryType? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (type != null) {
      maps = await db.query(
        'categories',
        where: 'type = ?',
        whereArgs: [type.index],
      );
    } else {
      maps = await db.query('categories');
    }
    
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction operations
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<models.Transaction>> getTransactions({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
    models.TransactionType? type,
    int? accountId,
    int? categoryId,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.index);
    }

    if (accountId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'account_id = ?';
      whereArgs.add(accountId);
    }

    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bill/Subscription operations
  Future<int> insertBillSubscription(BillSubscription billSubscription) async {
    final db = await database;
    return await db.insert('bills_subscriptions', billSubscription.toMap());
  }

  Future<List<BillSubscription>> getBillsSubscriptions({
    BillSubscriptionType? type,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (type != null) {
      maps = await db.query(
        'bills_subscriptions',
        where: 'type = ?',
        whereArgs: [type.index],
      );
    } else {
      maps = await db.query('bills_subscriptions');
    }
    
    return List.generate(maps.length, (i) => BillSubscription.fromMap(maps[i]));
  }

  Future<int> updateBillSubscription(BillSubscription billSubscription) async {
    final db = await database;
    return await db.update(
      'bills_subscriptions',
      billSubscription.toMap(),
      where: 'id = ?',
      whereArgs: [billSubscription.id],
    );
  }

  Future<int> deleteBillSubscription(int id) async {
    final db = await database;
    return await db.delete(
      'bills_subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Summary methods
  Future<Map<String, double>> getFinancialSummary() async {
    final db = await database;
    
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [models.TransactionType.income.index],
    );
    
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      [models.TransactionType.expense.index],
    );
    
    final totalIncome = (incomeResult.first['total'] as double?) ?? 0.0;
    final totalExpenses = (expenseResult.first['total'] as double?) ?? 0.0;
    final balance = totalIncome - totalExpenses;
    
    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'balance': balance,
    };
  }

  Future<double> getTotalAccountBalance() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM accounts');
    return (result.first['total'] as double?) ?? 0.0;
  }

  // Loan Installment operations
  Future<int> insertLoanInstallment(LoanInstallment installment) async {
    final db = await database;
    return await db.insert('loan_installments', installment.toMap());
  }

  Future<List<LoanInstallment>> getLoanInstallments({int? loanAccountId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    
    if (loanAccountId != null) {
      maps = await db.query(
        'loan_installments',
        where: 'loan_account_id = ?',
        whereArgs: [loanAccountId],
        orderBy: 'installment_number ASC',
      );
    } else {
      maps = await db.query(
        'loan_installments', 
        orderBy: 'due_date ASC',
      );
    }
    
    return List.generate(maps.length, (i) => LoanInstallment.fromMap(maps[i]));
  }

  Future<int> updateLoanInstallment(LoanInstallment installment) async {
    final db = await database;
    return await db.update(
      'loan_installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  Future<int> deleteLoanInstallment(int id) async {
    final db = await database;
    return await db.delete(
      'loan_installments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<LoanInstallment>> getUpcomingInstallments({int? days}) async {
    final db = await database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days ?? 30));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_installments',
      where: 'status = ? AND due_date >= ? AND due_date <= ?',
      whereArgs: [
        InstallmentStatus.pending.index,
        now.millisecondsSinceEpoch,
        futureDate.millisecondsSinceEpoch,
      ],
      orderBy: 'due_date ASC',
    );
    
    return List.generate(maps.length, (i) => LoanInstallment.fromMap(maps[i]));
  }

  Future<List<LoanInstallment>> getOverdueInstallments() async {
    final db = await database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_installments',
      where: 'status = ? AND due_date < ?',
      whereArgs: [
        InstallmentStatus.pending.index,
        now.millisecondsSinceEpoch,
      ],
      orderBy: 'due_date ASC',
    );
    
    return List.generate(maps.length, (i) => LoanInstallment.fromMap(maps[i]));
  }

  Future<void> generateLoanInstallments(Account loanAccount) async {
    if (loanAccount.type != AccountType.loan || 
        loanAccount.installmentCount == null || 
        loanAccount.installmentAmount == null ||
        loanAccount.loanStartDate == null) {
      return;
    }

    // Check if installments already exist
    final existingInstallments = await getLoanInstallments(loanAccountId: loanAccount.id!);
    if (existingInstallments.isNotEmpty) {
      return; // Already generated
    }

    final now = DateTime.now();
    final startDate = loanAccount.loanStartDate!;
    
    for (int i = 1; i <= loanAccount.installmentCount!; i++) {
      // Calculate due date (monthly payments by default)
      final dueDate = DateTime(
        startDate.year,
        startDate.month + i,
        startDate.day,
      );
      
      final installment = LoanInstallment(
        loanAccountId: loanAccount.id!,
        installmentNumber: i,
        amount: loanAccount.installmentAmount!,
        dueDate: dueDate,
        status: InstallmentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      
      await insertLoanInstallment(installment);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}