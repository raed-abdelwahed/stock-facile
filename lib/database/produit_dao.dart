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
}
