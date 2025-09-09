import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bill_subscription.dart';
import '../models/loan_installment.dart';
import '../models/app_theme_template.dart';
import '../models/user_profile.dart';
import '../services/database_helper.dart';

class AppStateProvider extends ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<BillSubscription> _billsSubscriptions = [];
  List<LoanInstallment> _loanInstallments = [];
  UserProfile? _userProfile;
  
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  String _selectedThemeId = 'modern_blue';
  bool _isDarkMode = false;
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
  List<BillSubscription> get billsSubscriptions => _billsSubscriptions;
  List<LoanInstallment> get loanInstallments => _loanInstallments;
  UserProfile? get userProfile => _userProfile;
  
  String get selectedLanguage => _selectedLanguage;
  String get selectedCurrency => _selectedCurrency;
  String get selectedThemeId => _selectedThemeId;
  bool get isDarkMode => _isDarkMode;
  AppThemeTemplate get selectedTheme => AppThemeTemplates.getById(_getEffectiveThemeId());
  ThemeData get themeData => selectedTheme.toThemeData();
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
        DatabaseHelper().getLoanInstallments(),
        DatabaseHelper().getUserProfile(),
        _loadPreferences(),
      ]);

      _accounts = futures[0] as List<Account>;
      _transactions = futures[1] as List<Transaction>;
      _categories = futures[2] as List<Category>;
      _billsSubscriptions = futures[3] as List<BillSubscription>;
      _loanInstallments = futures[4] as List<LoanInstallment>;
      _userProfile = futures[5] as UserProfile?;
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
    _selectedThemeId = prefs.getString('theme') ?? 'modern_blue';
    _isDarkMode = prefs.getBool('darkMode') ?? false;
  }

  String _getEffectiveThemeId() {
    if (!_isDarkMode) return _selectedThemeId;
    
    // Map light themes to their dark counterparts
    switch (_selectedThemeId) {
      case 'modern_blue':
        return 'modern_blue_dark';
      case 'forest_green':
        return 'forest_green_dark';
      case 'sunset_orange':
        return 'sunset_orange_dark';
      case 'royal_purple':
        return 'royal_purple_dark';
      case 'rose_gold':
        return 'rose_gold_dark';
      case 'midnight_dark':
        return 'midnight_dark'; // Already dark
      default:
        return _selectedThemeId.contains('_dark') ? _selectedThemeId : 'midnight_dark';
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      await DatabaseHelper().insertAccount(account);
      
      // Generate installments for loan accounts
      if (account.type == AccountType.loan) {
        final addedAccount = (await DatabaseHelper().getAccounts())
            .firstWhere((a) => a.name == account.name);
        await DatabaseHelper().generateLoanInstallments(addedAccount);
      }
      
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

  void updateTheme(String themeId) {
    _selectedThemeId = themeId;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updateDarkMode(bool isDark) {
    _isDarkMode = isDark;
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

  // Loan Installment methods
  List<LoanInstallment> getLoanInstallments(int loanAccountId) {
    return _loanInstallments
        .where((installment) => installment.loanAccountId == loanAccountId)
        .toList()
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
  }

  List<LoanInstallment> getUpcomingInstallments([int days = 30]) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    
    return _loanInstallments
        .where((installment) => 
            installment.status == InstallmentStatus.pending &&
            installment.dueDate.isAfter(now) &&
            installment.dueDate.isBefore(futureDate))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<LoanInstallment> getOverdueInstallments() {
    final now = DateTime.now();
    
    return _loanInstallments
        .where((installment) => 
            installment.status == InstallmentStatus.pending &&
            installment.dueDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> payInstallment(LoanInstallment installment, int fromAccountId, {String? notes}) async {
    try {
      final now = DateTime.now();
      
      // Update installment as paid
      final updatedInstallment = installment.copyWith(
        status: InstallmentStatus.paid,
        paidDate: now,
        paidFromAccountId: fromAccountId,
        notes: notes,
        updatedAt: now,
      );
      
      await DatabaseHelper().updateLoanInstallment(updatedInstallment);
      
      // Create a transaction record
      final transaction = Transaction(
        type: TransactionType.expense,
        amount: installment.amount,
        description: 'Loan Installment #${installment.installmentNumber}',
        accountId: fromAccountId,
        date: now,
        notes: 'Payment for loan installment${notes != null ? '. $notes' : ''}',
        createdAt: now,
        updatedAt: now,
      );
      
      await DatabaseHelper().insertTransaction(transaction);
      
      // Update account balance
      final fromAccount = _accounts.firstWhere((a) => a.id == fromAccountId);
      final updatedFromAccount = fromAccount.copyWith(
        balance: fromAccount.balance - installment.amount,
        updatedAt: now,
      );
      await DatabaseHelper().updateAccount(updatedFromAccount);
      
      await loadAllData();
    } catch (e) {
      debugPrint('Error paying installment: $e');
      rethrow;
    }
  }

  Future<void> generateLoanInstallments(int loanAccountId) async {
    try {
      final loanAccount = _accounts.firstWhere((a) => a.id == loanAccountId);
      await DatabaseHelper().generateLoanInstallments(loanAccount);
      await loadAllData();
    } catch (e) {
      debugPrint('Error generating loan installments: $e');
      rethrow;
    }
  }

  Future<void> updateLoanInstallment(LoanInstallment installment) async {
    try {
      await DatabaseHelper().updateLoanInstallment(installment);
      await loadAllData();
    } catch (e) {
      debugPrint('Error updating loan installment: $e');
      rethrow;
    }
  }

  // Category Management Methods
  List<Category> getCategoriesByType(CategoryType type) {
    return _categories.where((c) => c.type == type).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addCategory(Category category) async {
    try {
      await DatabaseHelper().insertCategory(category);
      await loadAllData();
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await DatabaseHelper().updateCategory(category);
      await loadAllData();
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await DatabaseHelper().deleteCategory(categoryId);
      await loadAllData();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  // User Profile Management Methods
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await DatabaseHelper().updateUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await DatabaseHelper().insertUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> loadUserProfile() async {
    try {
      _userProfile = await DatabaseHelper().getUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Don't rethrow - profile is optional
    }
  }
}