import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/tests_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows / Linux : SQLite passe par FFI (Q2.2).
  // Sur Android / iOS, sqflite fonctionne directement : rien à faire.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const StockFacileApp());
}

class StockFacileApp extends StatelessWidget {
  const StockFacileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFacile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      // Q3.4 – Le banc d'essai devient la page d'accueil (jusqu'à la partie 11).
      home: const TestsScreen(),
    );
  }
}
