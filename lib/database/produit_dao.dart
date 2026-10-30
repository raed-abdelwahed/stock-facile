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

  // ---------------------------------------------------------------------------
  // UPDATE – Q6.11
  // ---------------------------------------------------------------------------
  /// Modifie toutes les colonnes du produit dont l'id est produit.id.
  /// Renvoie le nombre de lignes modifiées (1, ou 0 si l'id n'existe pas).
  Future<int> modifierProduit(Produit produit) async {
    final db = await DatabaseHelper().database;
    return db.update(
      table,
      produit.toMap(),
      where: 'id = ?', // sans WHERE, TOUS les produits seraient modifiés !
      whereArgs: [produit.id],
    );
  }

  // UPDATE partiel – Q6.15 : une seule colonne
  Future<int> changerDisponibilite(int id, bool disponible) async {
    final db = await DatabaseHelper().database;
    return db.update(
      table,
      {'disponible': disponible ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE partiel – Q6.15 : le calcul est fait par SQLite
  /// Ajoute delta (positif ou négatif) à la quantité, sans jamais passer
  /// sous 0. Renvoie 1 si la modification a eu lieu, 0 sinon.
  Future<int> ajusterQuantite(int id, int delta) async {
    final db = await DatabaseHelper().database;
    return db.rawUpdate(
      'UPDATE produits SET quantite = quantite + ? '
      'WHERE id = ? AND quantite + ? >= 0',
      [delta, id, delta],
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE – Q7.2
  // ---------------------------------------------------------------------------
  /// Supprime le produit d'id donné. Renvoie le nombre de lignes supprimées.
  Future<int> supprimerProduit(int id) async {
    final db = await DatabaseHelper().database;
    return db.delete(
      table,
      where: 'id = ?', // sans WHERE, TOUS les produits seraient supprimés !
      whereArgs: [id],
    );
  }
}
