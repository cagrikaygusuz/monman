import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'bills_screen.dart';
import 'accounts_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const StatisticsScreen(),
    const BillsScreen(),
    const AccountsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final isTurkish = selectedLanguage == 'Turkish';
        
        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey[600],
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.house, size: 20),
                label: isTurkish ? 'Özet' : 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.arrowRightArrowLeft, size: 20),
                label: isTurkish ? 'İşlemler' : 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.chartLine, size: 20),
                label: isTurkish ? 'İstatistikler' : 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.fileInvoiceDollar, size: 20),
                label: isTurkish ? 'Faturalar' : 'Bills & Subs',
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.wallet, size: 20),
                label: isTurkish ? 'Hesaplar' : 'Accounts',
              ),
              BottomNavigationBarItem(
                icon: const FaIcon(FontAwesomeIcons.gear, size: 20),
                label: isTurkish ? 'Ayarlar' : 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}