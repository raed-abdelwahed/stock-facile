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
