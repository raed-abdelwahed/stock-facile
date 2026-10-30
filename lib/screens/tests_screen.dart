import 'package:flutter/material.dart';

import '../database/database_helper.dart';

/// Banc d'essai : un bouton par méthode à tester (parties 03 et 04).
/// Les résultats s'affichent dans la console (Debug Console de VS Code).
class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StockFacile – Tests'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Q3.3 – Ouvrir la base et compter les catégories
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper().database;
              final resultat =
                  await db.rawQuery('SELECT COUNT(*) AS nb FROM categories');
              debugPrint('Nombre de catégories : ${resultat.first['nb']}');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Base ouverte : ${resultat.first['nb']} catégories'),
                ),
              );
            },
            child: const Text('Ouvrir la base'),
          ),
        ],
      ),
    );
  }
}
