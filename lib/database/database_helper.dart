// =============================================================================
// database_helper.dart
// -----------------------------------------------------------------------------
// Point d'accès UNIQUE à la base SQLite locale de l'application "StockFacile".
//
// Rôle de cette classe :
//   - ouvrir (ou créer) le fichier stock_facile.db sur l'appareil ;
//   - créer les tables au tout premier lancement ;
//   - fournir la même connexion à tout le reste de l'application ;
//   - permettre de fermer proprement la base.
//
// Utilisation typique ailleurs dans le code :
//   final db = await DatabaseHelper().database;
//   final produits = await db.query('produits');
// =============================================================================

// debugPrint : comme print(), mais n'inonde pas la console.
import 'package:flutter/foundation.dart';

// join() : construit un chemin de fichier correct quel que soit le système.
import 'package:path/path.dart';

// sqflite : le plugin Flutter qui donne accès à SQLite.
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Nom du fichier de la base sur l'appareil.
  static const String nomBase = 'stock_facile.db';

  // Version du SCHÉMA (structure des tables), pas de l'application.
  // À incrémenter (2, 3...) chaque fois qu'on modifie les tables (partie 10).
  static const int versionBase = 1;

  // ---------------------------------------------------------------------------
  // 1. SINGLETON : une seule instance de DatabaseHelper dans toute l'appli
  // ---------------------------------------------------------------------------
  // Constructeur privé : inaccessible hors de ce fichier.
  DatabaseHelper._interne();

  // L'unique instance, créée une seule fois.
  static final DatabaseHelper _instance = DatabaseHelper._interne();

  // Constructeur "factory" : il ne crée PAS de nouvel objet,
  // il renvoie toujours la même instance.
  factory DatabaseHelper() => _instance;

  // La connexion SQLite. null tant que la base n'est pas ouverte.
  static Database? _db;

  // ---------------------------------------------------------------------------
  // 2. OUVERTURE PARESSEUSE (lazy) : on n'ouvre la base qu'au premier besoin
  // ---------------------------------------------------------------------------
  Future<Database> get database async {
    // "??=" : si _db est null, on ouvre la base ; sinon on garde la connexion.
    _db ??= await _ouvrirBase();
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // 3. OUVERTURE DU FICHIER (et création s'il n'existe pas encore)
  // ---------------------------------------------------------------------------
  Future<Database> _ouvrirBase() async {
    // Dossier standard prévu par le système pour les bases de données.
    final dossier = await getDatabasesPath();
    final chemin = join(dossier, nomBase);

    // Affiche le chemin en console : utile pour retrouver le fichier.
    debugPrint('Base SQLite : $chemin');

    return openDatabase(
      chemin,
      version: versionBase,

      // onConfigure s'exécute à CHAQUE ouverture, avant tout le reste.
      // SQLite désactive les clés étrangères par défaut : on les active ici.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // onCreate n'est appelé QUE si le fichier .db n'existait pas.
      onCreate: _creerTables,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CRÉATION DES TABLES — exécutée UNE SEULE FOIS, au tout premier lancement
  // ---------------------------------------------------------------------------
  Future<void> _creerTables(Database db, int version) async {
    debugPrint('onCreate : création des tables (version $version)');

    await db.execute('''
      CREATE TABLE categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nom         TEXT    NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produits (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nom          TEXT    NOT NULL,
        prix         REAL    NOT NULL CHECK (prix >= 0),
        quantite     INTEGER NOT NULL DEFAULT 0 CHECK (quantite >= 0),
        disponible   INTEGER NOT NULL DEFAULT 1,
        date_ajout   TEXT    NOT NULL,
        categorie_id INTEGER NOT NULL,
        FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    // ---- Données initiales --------------------------------------------------
    const depart = [
      {'nom': 'Alimentation', 'description': 'Produits secs et conserves'},
      {'nom': 'Boissons', 'description': 'Eaux, jus et sodas'},
      {'nom': 'Hygiène', 'description': "Savons et produits d'entretien"},
      {'nom': 'Papeterie', 'description': 'Cahiers, stylos et fournitures'},
    ];

    for (final c in depart) {
      await db.insert('categories', c);
    }
  }

  // ---------------------------------------------------------------------------
  // 5. FERMETURE DE LA BASE
  // ---------------------------------------------------------------------------
  Future<void> fermer() async {
    await _db?.close();
    _db = null;
  }
}
