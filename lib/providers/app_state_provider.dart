import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bill_subscription.dart';
import '../services/database_helper.dart';

class AppStateProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<BillSubscription> _billsSubscriptions = [];
  
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<BillSubscription> get billsSubscriptions => _billsSubscriptions;
  
  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;

  double get totalBalance {
    return _accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        DatabaseHelper().getAccounts(),
        DatabaseHelper().getTransactions(),
        DatabaseHelper().getCategories(),
        DatabaseHelper().getBillsSubscriptions(),
        _loadPreferences(),
      ]);

      _accounts = futures[0] as List<Account>;
      _transactions = futures[1] as List<Transaction>;
      _categories = futures[2] as List<Category>;
      _billsSubscriptions = futures[3] as List<BillSubscription>;
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('language') ?? 'English';
    _selectedCurrency = prefs.getString('currency') ?? 'USD';
  }

  Future<void> addAccount(Account account) async {
    try {
      await DatabaseHelper().insertAccount(account);
      await loadAllData();
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await DatabaseHelper().updateAccount(account);
      await loadAllData();
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(int accountId) async {
    try {
      await DatabaseHelper().deleteAccount(accountId);
      await loadAllData();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await DatabaseHelper().insertTransaction(transaction);
      await loadAllData();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await DatabaseHelper().updateTransaction(transaction);
      await loadAllData();
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    try {
      await DatabaseHelper().deleteTransaction(transactionId);
      await loadAllData();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> addBillSubscription(BillSubscription item) async {
    try {
      await DatabaseHelper().insertBillSubscription(item);
      await loadAllData();
    } catch (e) {
      debugPrint('Error adding bill/subscription: $e');
      rethrow;
    }
  }

  Future<void> updateBillSubscription(BillSubscription item) async {
    try {
      await DatabaseHelper().updateBillSubscription(item);
      await loadAllData();
    } catch (e) {
      debugPrint('Error updating bill/subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteBillSubscription(int itemId) async {
    try {
      await DatabaseHelper().deleteBillSubscription(itemId);
      await loadAllData();
    } catch (e) {
      debugPrint('Error deleting bill/subscription: $e');
      rethrow;
    }
  }

  void updateLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void updateCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  String getCurrencySymbol() {
    switch (_selectedCurrency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'TRY':
        return '₺';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '\$';
    }
  }
}