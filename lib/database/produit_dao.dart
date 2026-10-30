import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/produit.dart';
import 'database_helper.dart';

/// DAO (Data Access Object) : toutes les requêtes de la table `produits`.
class ProduitDao {
  static const String table = 'produits';

  // ---------------------------------------------------------------------------
  // CREATE – Q4.7
  // ---------------------------------------------------------------------------
  /// Insère un produit et renvoie l'id généré par SQLite.
  Future<int> insererProduit(Produit produit) async {
    final Database db = await DatabaseHelper().database;
    final int id = await db.insert(table, produit.toMap());
    return id;
  }

  // ---------------------------------------------------------------------------
  // READ – Q5.2
  // ---------------------------------------------------------------------------
  /// Tous les produits, triés par nom.
  Future<List<Produit>> lireProduits() async {
    // Q5.7 : ce message permet de compter combien de fois la requête s'exécute.
    debugPrint('lireProduits() : requête SELECT exécutée');
    final db = await DatabaseHelper().database;
    final lignes = await db.query(table, orderBy: 'nom ASC');
    return lignes.map((ligne) => Produit.fromMap(ligne)).toList();
  }

  /// Un seul produit par son id, ou null s'il n'existe pas.
  Future<Produit?> lireProduitParId(int id) async {
    final db = await DatabaseHelper().database;
    final lignes = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return lignes.isEmpty ? null : Produit.fromMap(lignes.first);
  }
}
