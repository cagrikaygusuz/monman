import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'constants/app_theme.dart';
import 'screens/main_navigation.dart';
import 'providers/app_state_provider.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MonManApp());
}

class MonManApp extends StatelessWidget {
  const MonManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider()..loadAllData(),
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
}