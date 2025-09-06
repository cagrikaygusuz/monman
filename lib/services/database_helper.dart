import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart' as models;
import '../models/bill_subscription.dart';

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
      version: 1,
      onCreate: _onCreate,
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
        updated_at INTEGER NOT NULL
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}