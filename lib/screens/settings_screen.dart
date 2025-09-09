import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/category.dart';
import '../models/app_theme_template.dart';
import '../widgets/category_management_dialog.dart';
import '../widgets/user_profile_dialog.dart';

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

  void _showThemeDialog() {
    final appState = context.read<AppStateProvider>();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Tasarım Şablonu Seç' : 'Select Design Template'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: AppThemeTemplates.templates.length,
            itemBuilder: (context, index) {
              final template = AppThemeTemplates.templates[index];
              final isSelected = template.id == appState.selectedThemeId;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [template.primaryColor, template.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(isTurkish ? template.nameTr : template.nameEn),
                  subtitle: Text(template.description),
                  trailing: isSelected
                    ? Icon(Icons.check_circle, color: template.primaryColor)
                    : null,
                  onTap: () {
                    appState.updateTheme(template.id);
                    _saveThemeToPrefs(template.id);
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isTurkish ? 'Kapat' : 'Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveThemeToPrefs(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', themeId);
  }

  Future<void> _saveDarkModeToPrefs(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
  }

  void _showCategoryManagement(CategoryType categoryType) {
    final appState = context.read<AppStateProvider>();
    final categories = appState.getCategoriesByType(categoryType);
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    String getTypeTitle() {
      switch (categoryType) {
        case CategoryType.income:
          return isTurkish ? 'Gelir Kategorileri' : 'Income Categories';
        case CategoryType.expense:
          return isTurkish ? 'Gider Kategorileri' : 'Expense Categories';
        case CategoryType.billSubscription:
          return isTurkish ? 'Fatura Kategorileri' : 'Bills Categories';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTypeTitle()),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 300,
                child: categories.isEmpty
                  ? Center(
                      child: Text(
                        isTurkish 
                          ? 'Henüz kategori eklenmemiş' 
                          : 'No categories added yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(
                                int.parse(category.color.substring(1), radix: 16) + 0xFF000000
                              ),
                              radius: 12,
                            ),
                            title: Text(category.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => CategoryManagementDialog(
                                        category: category,
                                        categoryType: categoryType,
                                      ),
                                    );
                                    if (result == true) {
                                      _showCategoryManagement(categoryType);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(category),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isTurkish ? 'Kapat' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => CategoryManagementDialog(
                  categoryType: categoryType,
                ),
              );
              if (result == true) {
                _showCategoryManagement(categoryType);
              }
            },
            child: Text(isTurkish ? 'Yeni Ekle' : 'Add New'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(Category category) async {
    final appState = context.read<AppStateProvider>();
    final isTurkish = appState.selectedLanguage == 'Turkish';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Kategoriyi Sil' : 'Delete Category'),
        content: Text(
          isTurkish 
            ? '${category.name} kategorisini silmek istediğinizden emin misiniz?'
            : 'Are you sure you want to delete the ${category.name} category?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isTurkish ? 'Sil' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true && category.id != null) {
      try {
        await appState.deleteCategory(category.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTurkish 
                  ? 'Kategori başarıyla silindi' 
                  : 'Category deleted successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTurkish 
                  ? 'Kategori silinirken hata oluştu' 
                  : 'Error deleting category'
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showUserProfileDialog() async {
    final appState = context.read<AppStateProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserProfileDialog(
        userProfile: appState.userProfile,
      ),
    );
    
    if (result == true) {
      // Profile was updated, data is automatically synced through the provider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final selectedLanguage = appState.selectedLanguage;
        final selectedCurrency = appState.selectedCurrency;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            child: InkWell(
              onTap: () => _showUserProfileDialog(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: appState.selectedTheme.primaryColor,
                      child: appState.userProfile?.avatarPath != null
                          ? ClipOval(
                              child: Image.asset(
                                appState.userProfile!.avatarPath!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              appState.userProfile?.getInitials() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.userProfile?.name ?? 
                            (selectedLanguage == 'Turkish' ? 'Kullanıcı' : 'User'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            appState.userProfile?.email ?? 
                            (selectedLanguage == 'Turkish' 
                                ? 'Profili düzenlemek için dokunun' 
                                : 'Tap to edit profile'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      color: appState.selectedTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Language & Currency Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Dil ve Para Birimi' : 'Language & Currency', appState),

          _buildSettingItem(
            icon: Icons.language,
            title: selectedLanguage == 'Turkish' ? 'Dil' : 'Language',
            subtitle: selectedLanguage == 'Turkish' ? 'Türkçe' : 'English',
            onTap: _showLanguageDialog,
            appState: appState,
          ),
          
          _buildSettingItem(
            icon: Icons.attach_money,
            title: selectedLanguage == 'Turkish' ? 'Para Birimi' : 'Currency',
            subtitle: selectedCurrency,
            onTap: _showCurrencyDialog,
            appState: appState,
          ),
          
          _buildSettingItem(
            icon: Icons.palette,
            title: selectedLanguage == 'Turkish' ? 'Tasarım Şablonu' : 'Design Template',
            subtitle: selectedLanguage == 'Turkish' 
                ? appState.selectedTheme.nameTr 
                : appState.selectedTheme.nameEn,
            onTap: _showThemeDialog,
            appState: appState,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Category Management Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Kategori Yönetimi' : 'Category Management', appState),
          
          _buildSettingItem(
            icon: Icons.trending_up,
            title: selectedLanguage == 'Turkish' ? 'Gelir Kategorileri' : 'Income Categories',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Gelir kategorilerini yönet' 
                : 'Manage income categories',
            onTap: () => _showCategoryManagement(CategoryType.income),
            appState: appState,
          ),
          
          _buildSettingItem(
            icon: Icons.trending_down,
            title: selectedLanguage == 'Turkish' ? 'Gider Kategorileri' : 'Expense Categories',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Gider kategorilerini yönet' 
                : 'Manage expense categories',
            onTap: () => _showCategoryManagement(CategoryType.expense),
            appState: appState,
          ),
          
          _buildSettingItem(
            icon: Icons.receipt_long,
            title: selectedLanguage == 'Turkish' ? 'Fatura Kategorileri' : 'Bills Categories',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Fatura kategorilerini yönet' 
                : 'Manage bills categories',
            onTap: () => _showCategoryManagement(CategoryType.billSubscription),
            appState: appState,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Preferences Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Tercihler' : 'Preferences', appState),
          
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
            appState: appState,
          ),
          
          _buildSwitchItem(
            icon: Icons.dark_mode,
            title: selectedLanguage == 'Turkish' ? 'Karanlık Tema' : 'Dark Mode',
            subtitle: selectedLanguage == 'Turkish' 
                ? 'Koyu renkli arayüz kullan' 
                : 'Use dark color theme',
            value: appState.isDarkMode,
            onChanged: (value) {
              appState.updateDarkMode(value);
              _saveDarkModeToPrefs(value);
            },
            appState: appState,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Data & Privacy Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Veri ve Gizlilik' : 'Data & Privacy', appState),
          
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
            appState: appState,
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
            appState: appState,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // About Section
          _buildSectionHeader(selectedLanguage == 'Turkish' ? 'Hakkında' : 'About', appState),
          
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
                  color: appState.selectedTheme.primaryColor,
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
            appState: appState,
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
            appState: appState,
          ),
          
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSectionHeader(String title, AppStateProvider appState) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: appState.selectedTheme.primaryColor,
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
    required AppStateProvider appState,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: appState.selectedTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: appState.selectedTheme.primaryColor),
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
    required AppStateProvider appState,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: appState.selectedTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: appState.selectedTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: appState.selectedTheme.primaryColor,
        ),
      ),
    );
  }
}