import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/financial_summary_card.dart';
import '../widgets/accounts_summary_card.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/add_account_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  
  String _getGreeting(String language) {
    final hour = DateTime.now().hour;
    final isTurkish = language == 'Turkish';
    
    if (hour < 12) {
      return isTurkish ? 'Günaydın!' : 'Good Morning!';
    } else if (hour < 17) {
      return isTurkish ? 'İyi Öğleden Sonralar!' : 'Good Afternoon!';
    } else {
      return isTurkish ? 'İyi Akşamlar!' : 'Good Evening!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(isTurkish ? 'Özet' : 'Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
      body: RefreshIndicator(
        onRefresh: () async {
          await appState.loadAllData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appState.selectedTheme.primaryColor,
                    appState.selectedTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(selectedLanguage),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isTurkish 
                        ? 'Finansal genel bakışınıza hoş geldiniz'
                        : 'Welcome to your financial overview',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const FinancialSummaryCard(),
            const SizedBox(height: AppSpacing.md),
            const AccountsSummaryCard(),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isTurkish ? 'Hızlı İşlemler' : 'Quick Actions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            isTurkish ? 'İşlem Ekle' : 'Add Transaction',
                            Icons.add_circle_outline,
                            appState.selectedTheme.primaryColor,
                            () {
                              _showAddTransactionDialog(context, appState);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            isTurkish ? 'Hesap Ekle' : 'Add Account',
                            Icons.account_balance_wallet_outlined,
                            appState.selectedTheme.secondaryColor,
                            () {
                              _showAddAccountDialog(context, appState);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        accounts: appState.accounts,
        categories: appState.categories,
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}