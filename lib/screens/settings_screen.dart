import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('darkMode', _darkModeEnabled);
  }

  void _showLanguageDialog() {
    final appState = context.read<AppStateProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'English',
                groupValue: appState.selectedLanguage,
                onChanged: (value) {
                  appState.updateLanguage(value!);
                  _saveLanguageToPrefs(value);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Türkçe'),
              leading: Radio<String>(
                value: 'Turkish',
                groupValue: appState.selectedLanguage,
                onChanged: (value) {
                  appState.updateLanguage(value!);
                  _saveLanguageToPrefs(value);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLanguageToPrefs(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  void _showCurrencyDialog() {
    final currencies = ['USD', 'EUR', 'TRY', 'GBP', 'JPY'];
    final appState = context.read<AppStateProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return ListTile(
              title: Text(currency),
              leading: Radio<String>(
                value: currency,
                groupValue: appState.selectedCurrency,
                onChanged: (value) {
                  appState.updateCurrency(value!);
                  _saveCurrencyToPrefs(value);
                  Navigator.of(context).pop();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _saveCurrencyToPrefs(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final selectedCurrency = appState.selectedCurrency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(selectedLanguage == 'Turkish' ? 'Ayarlar' : 'Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLanguage == 'Turkish' ? 'Kullanıcı' : 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          selectedLanguage == 'Turkish' 
                              ? 'Kişisel Finans Yöneticisi' 
                              : 'Personal Finance Manager',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Language & Currency Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Dil ve Para Birimi' : 'Language & Currency'),
          
          _buildSettingItem(
            icon: Icons.language,
            title: selectedLanguage == 'Turkish' ? 'Dil' : 'Language',
            subtitle: selectedLanguage == 'Turkish' ? 'Türkçe' : 'English',
            onTap: _showLanguageDialog,
          ),
          
          _buildSettingItem(
            icon: Icons.attach_money,
            title: selectedLanguage == 'Turkish' ? 'Para Birimi' : 'Currency',
            subtitle: selectedCurrency,
            onTap: _showCurrencyDialog,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Preferences Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Tercihler' : 'Preferences'),
          
          _buildSwitchItem(
            icon: Icons.notifications,
            title: selectedLanguage == 'Turkish' ? 'Bildirimler' : 'Notifications',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Fatura ve abonelik hatırlatmaları' 
                : 'Bill and subscription reminders',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          
          _buildSwitchItem(
            icon: Icons.dark_mode,
            title: selectedLanguage == 'Turkish' ? 'Karanlık Tema' : 'Dark Mode',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Koyu renkli arayüz kullan' 
                : 'Use dark color theme',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedLanguage == 'Turkish' 
                        ? 'Karanlık tema desteği yakında gelecek!' 
                        : 'Dark theme support coming soon!'
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Data & Privacy Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Veri ve Gizlilik' : 'Data & Privacy'),
          
          _buildSettingItem(
            icon: Icons.backup,
            title: selectedLanguage == 'Turkish' ? 'Veri Yedekleme' : 'Data Backup',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Verilerinizi yedekleyin' 
                : 'Backup your data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedLanguage == 'Turkish' 
                        ? 'Veri yedekleme yakında gelecek!' 
                        : 'Data backup coming soon!'
                  ),
                ),
              );
            },
          ),
          
          _buildSettingItem(
            icon: Icons.download,
            title: selectedLanguage == 'Turkish' ? 'Verileri Dışa Aktar' : 'Export Data',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'CSV formatında dışa aktar' 
                : 'Export to CSV format',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedLanguage == 'Turkish' 
                        ? 'Veri dışa aktarma yakında gelecek!' 
                        : 'Data export coming soon!'
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // About Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Hakkında' : 'About'),
          
          _buildSettingItem(
            icon: Icons.info,
            title: selectedLanguage == 'Turkish' ? 'Uygulama Hakkında' : 'About App',
            subtitle: 'MonMan v1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MonMan',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
                children: [
                  Text(
                    selectedLanguage == 'Turkish'
                        ? 'Kişisel finans yönetimi için güçlü ve kullanıcı dostu uygulama.'
                        : 'Powerful and user-friendly personal finance management app.',
                  ),
                ],
              );
            },
          ),
          
          _buildSettingItem(
            icon: Icons.help,
            title: selectedLanguage == 'Turkish' ? 'Yardım ve Destek' : 'Help & Support',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'SSS ve iletişim' 
                : 'FAQ and contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedLanguage == 'Turkish' 
                        ? 'Yardım sayfası yakında gelecek!' 
                        : 'Help page coming soon!'
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}