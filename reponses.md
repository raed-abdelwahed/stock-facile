# Réponses – TP StockFacile

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
