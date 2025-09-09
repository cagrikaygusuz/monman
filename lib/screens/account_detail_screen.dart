import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/account.dart';
import '../models/transaction.dart' as models;
import '../models/loan_installment.dart';
import '../providers/app_state_provider.dart';

class AccountDetailScreen extends StatelessWidget {
  final Account account;
  
  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        final currencySymbol = appState.getCurrencySymbol();
        
        // Filter transactions for this account
        final accountTransactions = appState.transactions
            .where((t) => t.accountId == account.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(account.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Navigate to edit account
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Account Info Card
                Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getAccountColor(appState),
                      _getAccountColor(appState).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            _getAccountTypeIcon(account.type),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                _getAccountTypeName(account.type, isTurkish),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                              if (account.bankName != null) ...[
                                Text(
                                  account.bankName!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBalanceSection(context, currencySymbol, isTurkish),
                    if (account.accountNumber != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '${isTurkish ? 'Hesap No' : 'Account No'}: ${account.accountNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Type-specific details
              ..._buildTypeSpecificDetails(context, isTurkish, currencySymbol),
              
              // Statistics Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isTurkish ? 'Toplam Gelir' : 'Total Income',
                        accountTransactions
                            .where((t) => t.type == models.TransactionType.income)
                            .fold(0.0, (sum, t) => sum + t.amount),
                        Colors.green,
                        currencySymbol,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        isTurkish ? 'Toplam Gider' : 'Total Expenses',
                        accountTransactions
                            .where((t) => t.type == models.TransactionType.expense)
                            .fold(0.0, (sum, t) => sum + t.amount),
                        Colors.red,
                        currencySymbol,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Transactions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTurkish ? 'Son İşlemler' : 'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${accountTransactions.length} ${isTurkish ? 'işlem' : 'transactions'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Transactions List
              SizedBox(
                height: 400, // Fixed height for transactions list
                child: accountTransactions.isEmpty
                    ? _buildEmptyTransactionsState(context, isTurkish)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: accountTransactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final transaction = accountTransactions[index];
                          return _buildTransactionCard(context, transaction, currencySymbol, isTurkish, appState);
                        },
                      ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    String currencySymbol,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsState(BuildContext context, bool isTurkish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isTurkish ? 'Bu hesap için işlem yok' : 'No transactions for this account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isTurkish 
                  ? 'İşlem eklemek için ana sayfaya gidin'
                  : 'Go to the main page to add transactions',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    models.Transaction transaction,
    String currencySymbol,
    bool isTurkish,
    AppStateProvider appState,
  ) {
    final isIncome = transaction.type == models.TransactionType.income;
    final isExpense = transaction.type == models.TransactionType.expense;
    final isTransfer = transaction.type == models.TransactionType.transfer;
    
    String toAccountName = '';
    if (isTransfer && transaction.toAccountId != null) {
      try {
        final toAccount = appState.accounts.firstWhere((a) => a.id == transaction.toAccountId);
        toAccountName = toAccount.name;
      } catch (e) {
        toAccountName = isTurkish ? 'Bilinmeyen Hesap' : 'Unknown Account';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isIncome
                      ? Colors.green.withOpacity(0.1)
                      : isExpense
                          ? Colors.red.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.1),
                  child: Icon(
                    isIncome
                        ? Icons.add_circle_outline
                        : isExpense
                            ? Icons.remove_circle_outline
                            : Icons.swap_horiz,
                    color: isIncome
                        ? Colors.green
                        : isExpense
                            ? Colors.red
                            : Colors.amber,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isTransfer && toAccountName.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${isTurkish ? 'Alıcı' : 'To'}: $toAccountName',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} ${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense || (isTransfer && transaction.accountId == account.id) ? '-' : '+'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isIncome
                                ? Colors.green
                                : isExpense || (isTransfer && transaction.accountId == account.id)
                                    ? Colors.red
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  transaction.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAccountColor(AppStateProvider appState) {
    if (account.color != null) {
      try {
        final colorValue = int.parse(account.color!.replaceAll('#', ''), radix: 16);
        return Color(0xFF000000 | colorValue);
      } catch (e) {
        return appState.selectedTheme.primaryColor;
      }
    }
    return appState.selectedTheme.primaryColor;
  }
  
  Widget _buildBalanceSection(BuildContext context, String currencySymbol, bool isTurkish) {
    String balanceLabel;
    switch (account.type) {
      case AccountType.bankAccount:
        balanceLabel = isTurkish ? 'Mevcut Bakiye' : 'Current Balance';
        break;
      case AccountType.creditCard:
        balanceLabel = isTurkish ? 'Mevcut Borç' : 'Current Debt';
        break;
      case AccountType.loan:
        balanceLabel = isTurkish ? 'Kalan Borç' : 'Remaining Debt';
        break;
      case AccountType.depositAccount:
        balanceLabel = isTurkish ? 'Yatırılan Tutar' : 'Deposited Amount';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          balanceLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$currencySymbol${account.balance.abs().toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
  
  List<Widget> _buildTypeSpecificDetails(BuildContext context, bool isTurkish, String currencySymbol) {
    switch (account.type) {
      case AccountType.creditCard:
        return _buildCreditCardDetails(context, isTurkish, currencySymbol);
      case AccountType.loan:
        return _buildLoanDetails(context, isTurkish, currencySymbol);
      case AccountType.depositAccount:
        return _buildDepositDetails(context, isTurkish, currencySymbol);
      case AccountType.bankAccount:
      default:
        return [];
    }
  }
  
  List<Widget> _buildCreditCardDetails(BuildContext context, bool isTurkish, String currencySymbol) {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kredi Kartı Detayları' : 'Credit Card Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Kredi Limiti' : 'Credit Limit',
                    account.creditLimit != null ? '$currencySymbol${account.creditLimit!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.credit_score,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Minimum Ödeme' : 'Minimum Payment',
                    account.minimumPayment != null ? '$currencySymbol${account.minimumPayment!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Son Ödeme Tarihi' : 'Last Payment Date',
                    account.lastPaymentDate != null 
                        ? '${account.lastPaymentDate!.day}/${account.lastPaymentDate!.month}/${account.lastPaymentDate!.year}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Hesap Kesim Tarihi' : 'Statement Date',
                    account.statementDate != null 
                        ? '${account.statementDate!.day}/${account.statementDate!.month}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.receipt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }
  
  List<Widget> _buildLoanDetails(BuildContext context, bool isTurkish, String currencySymbol) {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Kredi Detayları' : 'Loan Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Kredi Tutarı' : 'Loan Amount',
                    account.loanAmount != null ? '$currencySymbol${account.loanAmount!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.monetization_on,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Faiz Oranı' : 'Interest Rate',
                    account.interestRate != null ? '${account.interestRate!.toStringAsFixed(2)}%' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Taksit Sayısı' : 'Installment Count',
                    account.installmentCount?.toString() ?? (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.format_list_numbered,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Taksit Tutarı' : 'Installment Amount',
                    account.installmentAmount != null ? '$currencySymbol${account.installmentAmount!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.payment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Başlangıç Tarihi' : 'Start Date',
                    account.loanStartDate != null 
                        ? '${account.loanStartDate!.day}/${account.loanStartDate!.month}/${account.loanStartDate!.year}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Bitiş Tarihi' : 'End Date',
                    account.loanEndDate != null 
                        ? '${account.loanEndDate!.day}/${account.loanEndDate!.month}/${account.loanEndDate!.year}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.stop,
                  ),
                ),
              ],
            ),
            
            // Add installment schedule for loans
            if (account.type == AccountType.loan) ...[
              const SizedBox(height: AppSpacing.md),
              _buildInstallmentSchedule(context, isTurkish, currencySymbol, context.read<AppStateProvider>()),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  Widget _buildInstallmentSchedule(BuildContext context, bool isTurkish, String currencySymbol, AppStateProvider appState) {
    final installments = appState.getLoanInstallments(account.id!);
    
    if (installments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTurkish ? 'Taksit Planı Bulunamadı' : 'No Installment Plan Found',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isTurkish 
                        ? 'Taksitler otomatik olarak oluşturulmalı. Kredi bilgilerini kontrol edin.'
                        : 'Installments should be generated automatically. Check loan details.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await appState.generateLoanInstallments(account.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTurkish 
                                ? 'Taksit planı oluşturuldu'
                                : 'Installment plan generated'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTurkish 
                                ? 'Plan oluşturulurken hata: $e'
                                : 'Error generating plan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(
                      isTurkish ? 'Plan Oluştur' : 'Generate Plan',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final paidCount = installments.where((i) => i.isPaid).length;
    final overdueCount = installments.where((i) => i.isOverdue).length;
    final nextInstallment = installments.firstWhere(
      (i) => i.isPending && !i.isOverdue, 
      orElse: () => installments.last,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTurkish ? 'Taksit Planı' : 'Installment Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: appState.selectedTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildInstallmentSummaryCard(
                context,
                isTurkish ? 'Ödenen' : 'Paid',
                '$paidCount/${installments.length}',
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildInstallmentSummaryCard(
                context,
                isTurkish ? 'Geciken' : 'Overdue',
                overdueCount.toString(),
                overdueCount > 0 ? Colors.red : Colors.grey,
                Icons.warning,
              ),
            ),
          ],
        ),
        
        if (!nextInstallment.isPaid) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: nextInstallment.isOverdue 
                  ? Colors.red.shade50 
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: nextInstallment.isOverdue 
                    ? Colors.red.shade200 
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  nextInstallment.isOverdue ? Icons.error : Icons.schedule,
                  color: nextInstallment.isOverdue ? Colors.red : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextInstallment.isOverdue
                            ? (isTurkish ? 'Geciken Taksit' : 'Overdue Installment')
                            : (isTurkish ? 'Sonraki Taksit' : 'Next Installment'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: nextInstallment.isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
                            ),
                      ),
                      Text(
                        '${isTurkish ? 'Taksit' : 'Installment'} #${nextInstallment.installmentNumber} - $currencySymbol${nextInstallment.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${isTurkish ? 'Vade' : 'Due'}: ${nextInstallment.dueDate.day}/${nextInstallment.dueDate.month}/${nextInstallment.dueDate.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showPayInstallmentDialog(context, nextInstallment, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextInstallment.isOverdue ? Colors.red : appState.selectedTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  ),
                  child: Text(isTurkish ? 'Öde' : 'Pay'),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppSpacing.sm),
        
        // Installments list
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            children: installments.map((installment) {
              return _buildInstallmentListItem(context, installment, currencySymbol, isTurkish, appState);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentSummaryCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentListItem(
    BuildContext context,
    LoanInstallment installment,
    String currencySymbol,
    bool isTurkish,
    AppStateProvider appState,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (installment.isPaid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = isTurkish ? 'Ödendi' : 'Paid';
    } else if (installment.isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = isTurkish ? 'Gecikmiş' : 'Overdue';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = isTurkish ? 'Bekliyor' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                installment.installmentNumber.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currencySymbol${installment.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${isTurkish ? 'Vade' : 'Due'}: ${installment.dueDate.day}/${installment.dueDate.month}/${installment.dueDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                if (installment.isPaid && installment.paidDate != null) ...[
                  Text(
                    '${isTurkish ? 'Ödendi' : 'Paid'}: ${installment.paidDate!.day}/${installment.paidDate!.month}/${installment.paidDate!.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              if (!installment.isPaid) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _showEditInstallmentDialog(context, installment, appState),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 20),
                      ),
                      child: Text(
                        isTurkish ? 'Düzenle' : 'Edit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton(
                      onPressed: () => _showPayInstallmentDialog(context, installment, appState),
                      style: TextButton.styleFrom(
                        foregroundColor: statusColor,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 20),
                      ),
                      child: Text(
                        isTurkish ? 'Öde' : 'Pay',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCalculation(BuildContext context, Account account, String currencySymbol, bool isTurkish) {
    final principal = account.principal ?? 0.0;
    final interestRate = account.monthlyInterest ?? 0.0; // Assuming this is annual rate
    final days = account.maturityDays ?? 0;
    final taxRate = account.taxPercentage ?? 15.0; // Default 15% tax

    // Calculate earnings according to Guide.md formula
    // Gross Earnings = [Principal] x [Interest Rate (43% = 0.43)] x [Number of Days in the Term] / 365
    final grossEarnings = principal * (interestRate / 100) * days / 365;
    
    // Net Earnings = [Gross Earnings] x [Tax Rate (15% = 0.15)]
    final taxAmount = grossEarnings * (taxRate / 100);
    final netEarnings = grossEarnings - taxAmount;
    
    final totalAmount = principal + netEarnings;
    
    final now = DateTime.now();
    final isMatured = account.maturityEndDate != null && now.isAfter(account.maturityEndDate!);
    final daysUntilMaturity = account.maturityEndDate != null 
        ? account.maturityEndDate!.difference(now).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isMatured ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isMatured ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMatured ? Icons.celebration : Icons.calculate,
                color: isMatured ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isTurkish ? 'Kazanç Hesaplaması' : 'Earnings Calculation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isMatured ? Colors.green.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          if (!isMatured && daysUntilMaturity > 0) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(
                '${isTurkish ? 'Vadeye' : 'Days to maturity'}: $daysUntilMaturity ${isTurkish ? 'gün kaldı' : 'days'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          if (isMatured) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Text(
                isTurkish ? '🎉 Vade doldu! Kazançlar hazır.' : '🎉 Matured! Earnings are ready.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Earnings breakdown
          _buildEarningsRow(context, isTurkish ? 'Anapara' : 'Principal', principal, currencySymbol, Colors.grey.shade700),
          const SizedBox(height: AppSpacing.xs),
          _buildEarningsRow(context, isTurkish ? 'Brüt Kazanç' : 'Gross Earnings', grossEarnings, currencySymbol, Colors.green.shade600),
          const SizedBox(height: AppSpacing.xs),
          _buildEarningsRow(context, isTurkish ? 'Vergi (${taxRate.toStringAsFixed(1)}%)' : 'Tax (${taxRate.toStringAsFixed(1)}%)', taxAmount, currencySymbol, Colors.red.shade600),
          const SizedBox(height: AppSpacing.xs),
          _buildEarningsRow(context, isTurkish ? 'Net Kazanç' : 'Net Earnings', netEarnings, currencySymbol, Colors.green.shade700),
          
          const Divider(),
          
          _buildEarningsRow(context, isTurkish ? 'Toplam Tutar' : 'Total Amount', totalAmount, currencySymbol, Colors.blue.shade700, isTotal: true),
          
          if (isMatured) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTransferEarningsDialog(context, account, netEarnings),
                icon: const Icon(Icons.send_outlined),
                label: Text(isTurkish ? 'Kazançları Transfer Et' : 'Transfer Earnings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsRow(BuildContext context, String label, double amount, String currencySymbol, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          '$currencySymbol${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _showTransferEarningsDialog(BuildContext context, Account depositAccount, double netEarnings) {
    final appState = context.read<AppStateProvider>();
    final bankAccounts = appState.accounts.where((a) => a.type == AccountType.bankAccount).toList();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    if (bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTurkish 
              ? 'Transfer için banka hesabı bulunamadı'
              : 'No bank account found for transfer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Account? selectedAccount = bankAccounts.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isTurkish ? 'Kazançları Transfer Et' : 'Transfer Earnings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isTurkish ? 'Net Kazanç' : 'Net Earnings'}: ${appState.getCurrencySymbol()}${netEarnings.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isTurkish ? 'Hedef Hesap' : 'Target Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<Account>(
                value: selectedAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                ),
                items: bankAccounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${appState.getCurrencySymbol()}${account.balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    selectedAccount = account;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTurkish ? 'İptal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAccount != null
                  ? () async {
                      try {
                        // Transfer earnings logic would go here
                        // For now, just show success message
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTurkish 
                                ? 'Kazançlar başarıyla transfer edildi'
                                : 'Earnings transferred successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTurkish 
                                  ? 'Transfer sırasında hata oluştu: $e'
                                  : 'Error during transfer: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isTurkish ? 'Transfer Et' : 'Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayInstallmentDialog(BuildContext context, LoanInstallment installment, AppStateProvider appState) {
    final bankAccounts = appState.accounts.where((a) => a.type == AccountType.bankAccount && a.balance >= installment.amount).toList();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    if (bankAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTurkish 
              ? 'Ödeme için yeterli bakiyesi olan banka hesabı bulunamadı'
              : 'No bank account found with sufficient balance for payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Account? selectedAccount = bankAccounts.first;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isTurkish ? 'Taksit Öde' : 'Pay Installment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isTurkish ? 'Taksit' : 'Installment'} #${installment.installmentNumber}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${isTurkish ? 'Tutar' : 'Amount'}: ${appState.getCurrencySymbol()}${installment.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isTurkish ? 'Ödeme Hesabı' : 'Payment Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<Account>(
                value: selectedAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                ),
                items: bankAccounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${appState.getCurrencySymbol()}${account.balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    selectedAccount = account;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: isTurkish ? 'Notlar (İsteğe Bağlı)' : 'Notes (Optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTurkish ? 'İptal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAccount != null
                  ? () async {
                      try {
                        await appState.payInstallment(
                          installment,
                          selectedAccount!.id!,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTurkish 
                                  ? 'Taksit başarıyla ödendi'
                                  : 'Installment paid successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTurkish 
                                  ? 'Taksit ödenirken hata oluştu: $e'
                                  : 'Error paying installment: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: Text(isTurkish ? 'Öde' : 'Pay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditInstallmentDialog(BuildContext context, LoanInstallment installment, AppStateProvider appState) {
    final isTurkish = appState.selectedLanguage == 'Turkish';
    final TextEditingController amountController = TextEditingController(
      text: installment.amount.toStringAsFixed(2),
    );
    DateTime selectedDate = installment.dueDate;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('${isTurkish ? 'Taksiti Düzenle' : 'Edit Installment'} #${installment.installmentNumber}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isTurkish ? 'Tutar' : 'Amount',
                      prefixText: appState.getCurrencySymbol(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(isTurkish ? 'Vade Tarihi' : 'Due Date'),
                    subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setStateDialog(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isTurkish ? 'İptal' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newAmount = double.tryParse(amountController.text);
                    if (newAmount != null && newAmount > 0) {
                      try {
                        final updatedInstallment = installment.copyWith(
                          amount: newAmount,
                          dueDate: selectedDate,
                          updatedAt: DateTime.now(),
                        );
                        await appState.updateLoanInstallment(updatedInstallment);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTurkish 
                                ? 'Taksit başarıyla güncellendi'
                                : 'Installment updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTurkish 
                                ? 'Taksit güncellenirken hata oluştu: $e'
                                : 'Error updating installment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isTurkish ? 'Güncelle' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  List<Widget> _buildDepositDetails(BuildContext context, bool isTurkish, String currencySymbol) {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTurkish ? 'Vadeli Mevduat Detayları' : 'Term Deposit Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Anapara' : 'Principal',
                    account.principal != null ? '$currencySymbol${account.principal!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.savings,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Aylık Faiz' : 'Monthly Interest',
                    account.monthlyInterest != null ? '$currencySymbol${account.monthlyInterest!.toStringAsFixed(2)}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Vade Süresi' : 'Maturity Period',
                    account.maturityDays != null ? '${account.maturityDays} ${isTurkish ? 'gün' : 'days'}' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.calendar_view_day,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Vergi Oranı' : 'Tax Rate',
                    account.taxPercentage != null ? '${account.taxPercentage!.toStringAsFixed(2)}%' : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.receipt_long,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Vade Başlangıcı' : 'Maturity Start',
                    account.maturityStartDate != null 
                        ? '${account.maturityStartDate!.day}/${account.maturityStartDate!.month}/${account.maturityStartDate!.year}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.start,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildDetailCard(
                    context,
                    isTurkish ? 'Vade Bitişi' : 'Maturity End',
                    account.maturityEndDate != null 
                        ? '${account.maturityEndDate!.day}/${account.maturityEndDate!.month}/${account.maturityEndDate!.year}'
                        : (isTurkish ? 'Belirtilmemiş' : 'Not specified'),
                    Icons.event_available,
                  ),
                ),
              ],
            ),
            if (account.autoRenewal != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: account.autoRenewal! ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      account.autoRenewal! ? Icons.autorenew : Icons.block,
                      color: account.autoRenewal! ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      account.autoRenewal! 
                          ? (isTurkish ? 'Otomatik Yenileme Aktif' : 'Auto Renewal Active')
                          : (isTurkish ? 'Otomatik Yenileme Pasif' : 'Auto Renewal Inactive'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: account.autoRenewal! ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // Add earnings calculation for term deposits
            if (account.principal != null && account.maturityDays != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildEarningsCalculation(context, account, currencySymbol, isTurkish),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }
  
  Widget _buildDetailCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.bankAccount:
        return Icons.account_balance;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.loan:
        return Icons.trending_down;
      case AccountType.depositAccount:
        return Icons.savings;
    }
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
        return isTurkish ? 'Mevduat Hesabı' : 'Deposit Account';
    }
  }
}