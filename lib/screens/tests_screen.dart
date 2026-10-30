import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/categorie_dao.dart';
import '../database/database_helper.dart';
import '../database/produit_dao.dart';
import '../models/categorie.dart';
import '../models/produit.dart';

/// Banc d'essai : un bouton par méthode à tester (parties 03 et 04).
/// Les résultats s'affichent dans la console (terminal / Debug Console).
class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  // Petit raccourci pour afficher un message en bas de l'écran.
  void _message(BuildContext context, String texte, {bool erreur = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? Colors.red : null,
      ),
    );
  }

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
          // ------------------------------------------------------------------
          // Partie 03
          // ------------------------------------------------------------------
          const _Titre('Partie 03 – Base'),

          // Q3.3 – Ouvrir la base et compter les catégories
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper().database;
              final resultat =
                  await db.rawQuery('SELECT COUNT(*) AS nb FROM categories');
              debugPrint('Nombre de catégories : ${resultat.first['nb']}');
              if (!context.mounted) return;
              _message(context,
                  'Base ouverte : ${resultat.first['nb']} catégories');
            },
            child: const Text('Ouvrir la base'),
          ),

          // ------------------------------------------------------------------
          // Partie 04 – Create
          // ------------------------------------------------------------------
          const _Titre('Partie 04 – Insertion'),

          // Q4.3 / Q4.4 – Ajouter une catégorie (2e clic = doublon)
          ElevatedButton(
            onPressed: () async {
              const nouvelle = Categorie(
                nom: 'Électroménager',
                description: 'Petits appareils',
              );
              try {
                final id = await CategorieDao().insererCategorie(nouvelle);
                debugPrint("Catégorie insérée avec l'id $id");
                if (!context.mounted) return;
                _message(context, "Catégorie ajoutée (id $id)");
              } on DatabaseException catch (e) {
                if (e.isUniqueConstraintError()) {
                  debugPrint('Erreur UNIQUE : $e');
                  if (!context.mounted) return;
                  _message(context, 'Cette catégorie existe déjà',
                      erreur: true);
                } else {
                  debugPrint('Erreur SQLite : $e');
                }
              }
            },
            child: const Text('Test : ajouter une catégorie'),
          ),

          // Q4.8 – Ajouter un produit (stylo, catégorie 4 = Papeterie)
          ElevatedButton(
            onPressed: () async {
              final stylo = Produit(
                nom: 'Stylo bleu',
                prix: 0.500,
                quantite: 100,
                disponible: true,
                dateAjout: DateTime.now(),
                categorieId: 4,
              );
              try {
                final id = await ProduitDao().insererProduit(stylo);
                debugPrint("Produit inséré avec l'id $id : $stylo");
                if (!context.mounted) return;
                _message(context, 'Produit ajouté (id $id)');
              } on DatabaseException catch (e) {
                debugPrint('Erreur SQLite : $e');
              }
            },
            child: const Text('Test : ajouter un produit'),
          ),

          // Q4.10 – Catégorie inexistante (clé étrangère)
          ElevatedButton(
            onPressed: () async {
              final orphelin = Produit(
                nom: 'Produit orphelin',
                prix: 1,
                quantite: 1,
                dateAjout: DateTime.now(),
                categorieId: 99,
              );
              try {
                final id = await ProduitDao().insererProduit(orphelin);
                debugPrint("ATTENTION : produit orphelin inséré (id $id)");
                if (!context.mounted) return;
                _message(context, 'Produit orphelin inséré (id $id) !',
                    erreur: true);
              } on DatabaseException catch (e) {
                debugPrint('Erreur clé étrangère : $e');
                if (!context.mounted) return;
                _message(context, "Refusé : la catégorie 99 n'existe pas",
                    erreur: true);
              }
            },
            child: const Text('Test : produit avec catégorie 99'),
          ),

          // Q4.11 – Prix négatif (contrainte CHECK)
          ElevatedButton(
            onPressed: () async {
              final mauvais = Produit(
                nom: 'Prix négatif',
                prix: -2,
                quantite: 1,
                dateAjout: DateTime.now(),
                categorieId: 1,
              );
              try {
                await ProduitDao().insererProduit(mauvais);
              } on DatabaseException catch (e) {
                debugPrint('Erreur CHECK : $e');
                if (!context.mounted) return;
                _message(context, 'Refusé : le prix ne peut pas être négatif',
                    erreur: true);
              }
            },
            child: const Text('Test : produit avec prix -2'),
          ),
        ],
      ),
    );
  }
}

/// Petit titre de section dans la liste de boutons.
class _Titre extends StatelessWidget {
  final String texte;
  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        texte,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
