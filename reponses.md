# Réponses – TP StockFacile

> **Environnement de test.** Visual Studio « Développement Desktop en C++ » n'étant pas installé sur mon PC (`flutter doctor` : *Unable to find suitable Visual Studio toolchain*), l'application est testée dans **Chrome** avec le package `sqflite_common_ffi_web` (ajouté dans `main.dart` avec `if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;`). Le code du TP pour Windows / Android est conservé tel quel.
> Conséquences : la base s'appelle bien `stock_facile.db`, mais elle est stockée **dans le navigateur** (IndexedDB, chemin affiché : `/stock_facile.db`) et non dans un fichier ; elle ne peut donc pas être ouverte dans DB Browser. Les vérifications « DB Browser » des parties 03 et 04 sont faites dans les outils de Chrome (F12 → Application → IndexedDB) et dans la console. Les requêtes SQL, elles, ont été testées dans DB Browser sur `sql/brouillon.db`.

## Partie 00

### Q0.5 – Pourquoi ne pas envoyer les fichiers `.db` sur GitHub ?
Les fichiers `.db` contiennent des **données** (de test ou personnelles) et sont des fichiers **binaires** : Git ne peut pas afficher leurs différences, ils changent à chaque exécution de l'application et provoqueraient des conflits. Ils peuvent aussi contenir des informations privées.
Le fichier `schema.sql`, lui, est du **texte** qui décrit seulement la **structure** de la base : il est lisible, comparable d'une version à l'autre, et il suffit pour recréer la base n'importe où.

### Question de réflexion – retrouver une version qui marchait
Comme on fait un commit à la fin de chaque partie, `git log --oneline` liste toutes les versions. Si l'application ne marche plus après la partie 07, on peut revenir voir (`git checkout <id>`) ou comparer (`git diff <id>`) la version de la partie 06, qui fonctionnait, pour trouver ce qui a cassé.

## Partie 01 – Concevoir la base dans DB Browser

### Q1.3 – Structure des tables
- **`disponible` et `date_ajout`** : SQLite n'a ni type `BOOLEAN` ni type `DATETIME`.
  - `disponible` est stocké en `INTEGER` : **1 = vrai**, **0 = faux**.
  - `date_ajout` est stockée en `TEXT` au format **ISO 8601** (`2026-10-01T09:00:00`). Ce format se trie correctement dans l'ordre alphabétique, donc aussi dans l'ordre chronologique.
- **`AUTOINCREMENT`** : SQLite attribue automatiquement l'`id` (1, 2, 3…) à chaque nouvelle ligne, et ne réutilise jamais un `id` déjà donné, même après une suppression.
- **`UNIQUE` sur `nom`** : interdit d'avoir deux catégories avec le même nom (par exemple deux fois « Boissons »).
- **`CHECK (prix >= 0)`** : refuse toute ligne dont le prix est négatif.
- **`ON DELETE RESTRICT`** : il est impossible de supprimer une catégorie tant qu'au moins un produit y est rattaché par `categorie_id`. La suppression est refusée avec une erreur.

### Q1.4 – Pourquoi `'Huile d''olive'` avec deux apostrophes ?
En SQL, une chaîne de texte est entourée d'apostrophes `'...'`. Une seule apostrophe au milieu (`'Huile d'olive'`) fermerait la chaîne trop tôt et provoquerait une erreur de syntaxe. On **double l'apostrophe** (`''`) pour dire à SQLite qu'il s'agit d'un caractère du texte et non de la fin de la chaîne.

### Q1.5 – Requêtes
Toutes les requêtes sont dans `sql/requetes.sql`. Résultats obtenus :
1. Tous les produits : 6 lignes.
2. Rupture de stock : 1 produit, « Jus d'orange 1 L ».
3. Du plus cher au moins cher : Huile d'olive (18,500 DT) en premier, Eau minérale (0,850 DT) en dernier.
4. Jointure : chaque produit avec sa catégorie (Huile d'olive → Alimentation, Eau minérale → Boissons…).
5. Nombre par catégorie : Alimentation 2, Boissons 2, Hygiène 1, Papeterie 1.
6. Valeur totale du stock : **777,500 DT**.

### Q1.6 – Tests des contraintes
| Requête | Message d'erreur | Contrainte en cause |
|---|---|---|
| a) prix négatif (-5) | `CHECK constraint failed: prix >= 0` | `CHECK (prix >= 0)` |
| b) catégorie 99 inexistante | `FOREIGN KEY constraint failed` | clé étrangère `categorie_id` |
| c) supprimer la catégorie 1 (qui contient des produits) | `FOREIGN KEY constraint failed` | `ON DELETE RESTRICT` |

Les requêtes b) et c) ne sont bloquées que parce que les clés étrangères sont activées (`PRAGMA foreign_keys = ON`). DB Browser l'active par défaut ; dans Flutter, il faudra l'activer nous-mêmes (partie 03).

### Q1.7 – Contenu de `schema.sql`
Le fichier contient uniquement la **structure** de la base : les deux instructions `CREATE TABLE` (`categories` et `produits`) avec leurs colonnes, clés et contraintes, entourées de `BEGIN TRANSACTION;` et `COMMIT;`. Il ne contient **aucune donnée** (pas d'`INSERT`). C'est un fichier texte léger, lisible, qu'on peut envoyer sur GitHub et qui permet de recréer la base vide n'importe où.

### Q1.8 – Pourquoi fermer la base dans DB Browser ?
Quand DB Browser a la base ouverte, il peut garder un **verrou** sur le fichier ou des modifications pas encore écrites. Si un autre programme (notre application) écrit en même temps dans le même fichier, on risque une erreur « database is locked », des données perdues ou un fichier corrompu. Fermer la base garantit qu'un seul programme utilise le fichier à la fois.

## Partie 02 – Packages et classes modèles

### Q2.1 – Rôle de chaque package
| Package | Rôle |
|---|---|
| `sqflite` | Plugin qui permet d'ouvrir une base SQLite et d'exécuter des requêtes (`insert`, `query`, `update`, `delete`, `rawQuery`…) depuis Dart. |
| `path` | Construit des chemins de fichiers corrects quel que soit le système (`join(dossier, 'stock_facile.db')`), sans se soucier des `/` ou `\`. |
| `sqflite_common_ffi` | Version de sqflite pour le **desktop** (Windows / Linux) : elle utilise la bibliothèque SQLite native via FFI, car le plugin `sqflite` classique ne fonctionne que sur Android, iOS et macOS. |

### Q2.3 – Classe `Categorie`
- **Pourquoi `id` est-il `int?` ?** Tant qu'une catégorie n'est pas enregistrée, elle n'a pas encore d'identifiant : c'est SQLite qui le génère (`AUTOINCREMENT`) au moment de l'`INSERT`. Un objet créé dans l'application (`Categorie(nom: 'Électroménager')`) a donc un `id` à `null`.
- **Pourquoi `toMap()` n'ajoute-t-il `id` que s'il n'est pas `null` ?** Si on envoyait `'id': null` dans un `INSERT`, on demanderait explicitement un `id` vide. En n'ajoutant pas la clé, on laisse SQLite choisir lui-même le prochain `id`. Quand l'objet vient de la base (il a un `id`), la clé est présente : c'est utile pour un `UPDATE`.

### Q2.4 – Méthode `toMap()` de `Produit`
Les conversions faites :
- `bool disponible` → `1` ou `0` (`disponible ? 1 : 0`) ;
- `DateTime dateAjout` → texte ISO 8601 (`toIso8601String()`) ;
- `double prix` → envoyé tel quel (colonne `REAL`) ;
- `categorieId` → clé `'categorie_id'` : les clés de la `Map` doivent être **exactement** les noms des colonnes, sinon on obtient `table produits has no column named categorieId`.

### Questions de réflexion (Partie 02)
- **Pourquoi un constructeur `factory` pour `fromMap` ?** Un constructeur `factory` peut exécuter du code avant de créer l'objet (lire la `Map`, convertir les types : `1/0` → `bool`, texte → `DateTime`) puis retourner l'objet construit avec le constructeur normal. Il donne aussi un nom clair à cette façon de construire l'objet (`Produit.fromMap(ligne)`).
- **Pourquoi `(map['prix'] as num).toDouble()` et pas `map['prix'] as double` ?** SQLite peut renvoyer un nombre entier quand la valeur n'a pas de décimales : un prix de `5` revient en `int`, pas en `double`. `map['prix'] as double` provoquerait alors l'erreur `type 'int' is not a subtype of type 'double'`. `num` accepte les deux (`int` et `double`), et `.toDouble()` convertit dans tous les cas.

## Partie 03 – Ouvrir et créer la base depuis Flutter

### Q3.2 – Questions sur `DatabaseHelper`
- **(1) Que se passe-t-il si on écrit deux fois `DatabaseHelper()` ?** Un seul objet est créé. Le constructeur `factory DatabaseHelper() => _instance;` ne construit rien : il renvoie toujours l'unique instance `_instance`, créée une seule fois avec le constructeur privé `_interne()`. Donc `DatabaseHelper() == DatabaseHelper()` est vrai partout. C'est le patron **singleton**, rendu possible par le mot-clé `factory` (un constructeur `factory` peut renvoyer un objet existant au lieu d'en créer un nouveau).
- **(2) Que fait l'opérateur `??=` ?** `_db ??= await _ouvrirBase();` affecte une valeur à `_db` **seulement si `_db` est `null`**. Au premier appel, la base est ouverte et la connexion est gardée ; aux appels suivants, `_db` n'est plus `null`, donc on réutilise la même connexion sans rouvrir le fichier.
- **(3) Pourquoi `PRAGMA foreign_keys = ON` est-il dans `onConfigure` et non dans `onCreate` ?** Le réglage `foreign_keys` n'est pas enregistré dans le fichier : il est perdu à chaque fermeture et doit être activé **à chaque ouverture**. `onConfigure` s'exécute à chaque ouverture, alors que `onCreate` ne s'exécute qu'une seule fois (à la création du fichier). Dans `onCreate`, les clés étrangères seraient actives au premier lancement seulement, puis désactivées à tous les lancements suivants.
- **(4) Combien de fois `onCreate` est-il appelé ?** **Une seule fois** dans toute la vie de l'application : au tout premier lancement, quand le fichier `stock_facile.db` n'existe pas encore. Il sera rappelé seulement si on supprime le fichier (désinstallation ou réinitialisation de la base).

### Q3.4 – Console au premier clic sur « Ouvrir la base »
- Chemin de la base : affiché par `debugPrint('Base SQLite : …')`. Dans Chrome : `/stock_facile.db` (stockée dans IndexedDB du navigateur). Sous Windows (sqflite_common_ffi), le fichier serait créé dans `…\stock_facile\.dart_tool\sqflite_common_ffi\databases\stock_facile.db`.
- Messages : `onCreate : création des tables (version 1)` puis `Nombre de catégories : 4`.

### Q3.5 – Après redémarrage, le message `onCreate` s'affiche-t-il encore ?
Non. Au deuxième lancement, le fichier `stock_facile.db` existe déjà avec la version 1 enregistrée : sqflite ouvre simplement la base, sans rappeler `onCreate`. On voit seulement le chemin de la base et `Nombre de catégories : 4`.

### Q3.7 – Vérification dans DB Browser
- Onglet **Structure** : les tables `categories` et `produits` existent avec les mêmes colonnes que dans `brouillon.db`.
- Onglet **Parcourir les données** : `categories` contient les 4 catégories de départ, `produits` est vide.
- Onglet **Éditer les pragmas** : *User Version* = **1**. Cette valeur correspond à la ligne `static const int versionBase = 1;` de `database_helper.dart`, transmise à `openDatabase(version: versionBase)` : sqflite l'enregistre dans le fichier pour savoir s'il doit appeler `onCreate`, `onUpgrade` ou rien.

## Partie 04 – Opération 1 : insérer des données (Create)

### Q4.2 – Explication des trois lignes de `insererCategorie`
1. `final Database db = await DatabaseHelper().database;` : récupère la connexion **unique** à la base (singleton). La base est ouverte au premier appel puis réutilisée.
2. `final int id = await db.insert(table, categorie.toMap());` : `toMap()` transforme l'objet en `Map` `{colonne: valeur}` ; `insert` construit la requête `INSERT INTO categories (nom, description) VALUES (?, ?)` avec des paramètres, l'exécute et renvoie l'`id` généré.
3. `return id;` : renvoie cet `id` à l'appelant (le bouton de test, plus tard l'écran).

### Q4.3 – `id` obtenu au premier clic
On obtient **`id = 5`**. La table contient déjà les 4 catégories de départ (id 1 à 4) insérées par `onCreate` ; `AUTOINCREMENT` donne donc le numéro suivant.

### Q4.4 – Deuxième clic sur le même bouton
Message d'erreur :
`DatabaseException(UNIQUE constraint failed: categories.nom (code 2067 SQLITE_CONSTRAINT_UNIQUE))`
La contrainte en cause est **`UNIQUE` sur la colonne `nom`** (partie 01) : il ne peut pas y avoir deux catégories « Électroménager ». L'erreur est interceptée avec `on DatabaseException catch (e)` et `e.isUniqueConstraintError()`, et un `SnackBar` « Cette catégorie existe déjà » s'affiche.

### Q4.9 – Stockage de `disponible` et `date_ajout`
- `disponible` est stocké en **`1`** (entier) et non `true` ;
- `date_ajout` est stockée en **texte ISO 8601**, par exemple `2026-10-30T15:42:10.123456`.
C'est conforme à `toMap()` : `disponible ? 1 : 0` et `dateAjout.toIso8601String()`.

### Q4.10 – Produit avec `categorieId: 99`
- Avec les clés étrangères activées : `DatabaseException(FOREIGN KEY constraint failed (code 787 SQLITE_CONSTRAINT_FOREIGNKEY))`. L'insertion est refusée.
- En commentant `PRAGMA foreign_keys = ON` : l'insertion **réussit**, un produit « orphelin » est créé alors que la catégorie 99 n'existe pas. SQLite ne vérifie pas les clés étrangères par défaut.
- Un *hot reload* ne suffit pas : `onConfigure` ne s'exécute qu'à l'**ouverture** de la base, et la connexion déjà ouverte est gardée en mémoire par le singleton (`_db`). Il faut redémarrer complètement l'application pour que la base soit rouverte avec le nouveau réglage.

### Q4.11 – Produit avec un prix de `-2`
L'insertion est bloquée par la contrainte **`CHECK (prix >= 0)`** : `CHECK constraint failed: prix >= 0`.
Il faut quand même vérifier le prix dans le formulaire Flutter (partie 06) parce que :
- l'utilisateur reçoit un message clair tout de suite, sous le champ, au lieu d'une erreur technique SQLite ;
- on évite un aller-retour inutile vers la base ;
- la contrainte de la base reste une **dernière sécurité**, si une erreur passe à travers l'interface.

### Question de réflexion – `conflictAlgorithm`
- `ConflictAlgorithm.ignore` : si l'insertion viole une contrainte (`UNIQUE`, clé primaire…), la ligne est **simplement ignorée**, sans erreur ; `insert` renvoie alors 0 (aucune ligne insérée).
- `ConflictAlgorithm.replace` : en cas de conflit, SQLite **supprime l'ancienne ligne** puis insère la nouvelle à sa place.
- `replace` est dangereux sur une table référencée par une clé étrangère : remplacer une catégorie revient à la **supprimer** puis à la recréer. Avec `ON DELETE RESTRICT`, la suppression est refusée si des produits y sont rattachés (erreur) ; avec `ON DELETE CASCADE`, tous les produits de la catégorie seraient **supprimés** ; et la nouvelle ligne peut recevoir un nouvel `id`, ce qui casse les liens avec les produits.

## Partie 05 – Opération 2 : lire et afficher les données (Read)

### Q5.3 – Résultat brut de `db.query('produits')`
- **a)** Le type exact est `List<Map<String, Object?>>` (une liste de `Map`, une `Map` par ligne). Une ligne ressemble à :
  `{id: 1, nom: Stylo bleu, prix: 0.5, quantite: 100, disponible: 1, date_ajout: 2026-10-30T16:20:11.123, categorie_id: 4}`
  On voit les valeurs **brutes** de SQLite : `disponible` vaut `1` (pas `true`) et la date est du texte.
- **b)** `lignes.first['nom'] = 'Test';` provoque l'erreur `Unsupported operation: read-only` (*Cannot modify an unmodifiable map*). Les `Map` renvoyées par `sqflite` sont **en lecture seule** : on ne peut pas les modifier directement. Pour changer une valeur, on crée un objet Dart (`Produit.fromMap`), on fait une copie modifiée, puis on fait un `UPDATE` dans la base.
- **c)** Avec `ProduitDao().lireProduits()`, chaque ligne est convertie en objet `Produit` : `disponible` devient un vrai `bool` et `dateAjout` un `DateTime`.

### Q5.4 – `lireProduitParId(1)` et `lireProduitParId(999)`
- `lireProduitParId(1)` renvoie le produit d'id 1 (le stylo).
- `lireProduitParId(999)` renvoie **`null`** : aucune ligne n'a cet id.
Le type de retour est `Produit?` (nullable) car la requête peut ne trouver **aucune** ligne. Avec `Produit`, on serait obligé d'inventer un produit ou de lever une exception ; `Produit?` oblige l'appelant à gérer le cas « introuvable ».

### Q5.7 – `future: _dao.lireProduits()` directement dans le `FutureBuilder`
La méthode `build()` est rappelée très souvent (rotation de l'écran, ouverture du clavier, `setState`, redimensionnement de la fenêtre…). Si l'appel est écrit dans `build()`, **une nouvelle requête SQL est lancée à chaque reconstruction** : le `debugPrint` de `lireProduits()` s'affiche plusieurs fois, l'écran repasse par l'état « chargement » et la base est interrogée pour rien. En lançant la requête **une seule fois dans `initState`** et en gardant le `Future` dans une variable (`_futurProduits`), on ne relit la base que quand on le décide (`_rafraichir()`).

### Q5.9 – Modifier un prix dans DB Browser puis recharger
Dans notre cas (application testée dans **Chrome**), cette manipulation n'est **pas possible** : la base est stockée dans le navigateur (IndexedDB), pas dans un fichier que DB Browser peut ouvrir. C'est la même situation qu'avec un émulateur Android : DB Browser ne travaille que sur une **copie** du fichier, donc une modification faite dans DB Browser ne change pas la base utilisée par l'application.
En desktop (Windows), DB Browser ouvre directement le vrai fichier : après « Écrire les modifications » et un tirage de la liste vers le bas (`RefreshIndicator`), le nouveau prix apparaîtrait.

### Q5.11 – Pourquoi passer l'`id` au détail et relire la base ?
- Les données affichées sont toujours **à jour** : si le produit a été modifié entre-temps (quantité, prix…), l'écran de détail lit la dernière version dans la base, et non un objet ancien gardé en mémoire.
- On passe une valeur simple (un entier) au lieu d'un objet entier.
- C'est indispensable en partie 06 : après une modification depuis le détail, il suffit de relire la base par l'`id` pour réafficher le produit à jour.
