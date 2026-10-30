import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/tests_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web (Chrome) : SQLite tourne dans le navigateur (WebAssembly).
    // La base est stockée dans le navigateur (IndexedDB), pas dans un fichier.
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Windows / Linux : SQLite passe par FFI (Q2.2).
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android / iOS : sqflite fonctionne directement, rien à faire.

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
