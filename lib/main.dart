import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'constants/app_theme.dart';
import 'screens/main_navigation.dart';
import 'providers/app_state_provider.dart';

// Conditional import for database initialization
import 'database_init_stub.dart'
    if (dart.library.io) 'database_init_desktop.dart'
    if (dart.library.html) 'database_init_stub.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize desktop database only for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      initDesktopDatabase();
    } catch (e) {
      debugPrint('Desktop database initialization failed: $e');
    }
  }
  
  runApp(const MonManApp());
}

class MonManApp extends StatelessWidget {
  const MonManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = AppStateProvider();
        // Load data safely with error handling
        _safeLoadData(provider);
        return provider;
      },
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'MonMan - Personal Finance Manager',
            theme: appState.themeData,
            debugShowCheckedModeBanner: false,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }

  void _safeLoadData(AppStateProvider provider) async {
    try {
      await provider.loadAllData();
    } catch (e) {
      debugPrint('Failed to load initial data: $e');
      // App will continue with empty data - user can try to refresh later
    }
  }
}