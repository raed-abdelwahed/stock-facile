import 'package:sqflite/sqflite.dart';

import '../models/categorie.dart';
import 'database_helper.dart';

/// DAO (Data Access Object) : toutes les requêtes de la table `categories`.
/// Les écrans n'écrivent jamais de SQL : ils appellent ces méthodes.
class CategorieDao {
  static const String table = 'categories';

  // ---------------------------------------------------------------------------
  // CREATE – Q4.2
  // ---------------------------------------------------------------------------
  Future<int> insererCategorie(Categorie categorie) async {
    // 1) On récupère la connexion unique à la base (singleton DatabaseHelper).
    //    La base est ouverte au premier appel, puis réutilisée.
    final Database db = await DatabaseHelper().database;

    // 2) On insère la ligne : toMap() transforme l'objet en Map
    //    {colonne: valeur}. sqflite construit lui-même la requête
    //    INSERT INTO categories (nom, description) VALUES (?, ?)
    //    avec des paramètres « ? » (pas d'injection SQL possible).
    //    insert() renvoie l'id généré par AUTOINCREMENT.
    final int id = await db.insert(table, categorie.toMap());

    // 3) On renvoie cet id à l'appelant (écran ou test).
    return id;
  }

  // ---------------------------------------------------------------------------
  // READ – Q5.2
  // ---------------------------------------------------------------------------
  /// Toutes les catégories, triées par nom.
  Future<List<Categorie>> lireCategories() async {
    final db = await DatabaseHelper().database;
    final lignes = await db.query(table, orderBy: 'nom ASC');
    return lignes.map((ligne) => Categorie.fromMap(ligne)).toList();
  }

  // READ – Q5.10
  /// Une seule catégorie par son id, ou null si elle n'existe pas.
  Future<Categorie?> lireCategorieParId(int id) async {
    final db = await DatabaseHelper().database;
    final lignes = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return lignes.isEmpty ? null : Categorie.fromMap(lignes.first);
  }
}
