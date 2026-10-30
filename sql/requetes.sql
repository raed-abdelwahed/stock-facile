-- =============================================================
-- Requêtes SQL du TP StockFacile (testées dans DB Browser)
-- Base de test : sql/brouillon.db
-- =============================================================

-- -------------------------------------------------------------
-- Partie 01 – Création des tables (Q1.2)
-- -------------------------------------------------------------
CREATE TABLE categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nom         TEXT    NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE produits (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  nom          TEXT    NOT NULL,
  prix         REAL    NOT NULL CHECK (prix >= 0),
  quantite     INTEGER NOT NULL DEFAULT 0 CHECK (quantite >= 0),
  disponible   INTEGER NOT NULL DEFAULT 1,   -- 1 = vrai, 0 = faux
  date_ajout   TEXT    NOT NULL,             -- date au format ISO 8601
  categorie_id INTEGER NOT NULL,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE RESTRICT
);

-- -------------------------------------------------------------
-- Partie 01 – Données de départ (Q1.4)
-- -------------------------------------------------------------
INSERT INTO categories (nom, description) VALUES
  ('Alimentation', 'Produits secs et conserves'),
  ('Boissons',     'Eaux, jus et sodas'),
  ('Hygiène',      'Savons et produits d''entretien'),
  ('Papeterie',    'Cahiers, stylos et fournitures');

INSERT INTO produits (nom, prix, quantite, disponible, date_ajout, categorie_id) VALUES
  ('Huile d''olive 1 L',   18.500,  24, 1, '2026-10-01T09:00:00', 1),
  ('Couscous moyen 1 kg',   2.300,  40, 1, '2026-10-01T09:05:00', 1),
  ('Eau minérale 1,5 L',    0.850, 120, 1, '2026-10-02T10:00:00', 2),
  ('Jus d''orange 1 L',     3.200,   0, 0, '2026-10-02T10:10:00', 2),
  ('Savon de Marseille',    2.900,  15, 1, '2026-10-03T11:00:00', 3),
  ('Cahier 96 pages',       1.600,  60, 1, '2026-10-04T08:30:00', 4);

-- -------------------------------------------------------------
-- Partie 01 – Requêtes de lecture (Q1.5)
-- -------------------------------------------------------------

-- Q1.5.1 – Tous les produits (résultat : 6 lignes)
SELECT * FROM produits;

-- Q1.5.2 – Produits en rupture de stock (résultat : Jus d'orange 1 L)
SELECT * FROM produits
WHERE quantite = 0;

-- Q1.5.3 – Produits du plus cher au moins cher (Huile d'olive en premier)
SELECT * FROM produits
ORDER BY prix DESC;

-- Q1.5.4 – Nom de chaque produit avec le nom de sa catégorie (INNER JOIN)
SELECT p.nom AS produit, c.nom AS categorie
FROM produits p
INNER JOIN categories c ON c.id = p.categorie_id;

-- Q1.5.5 – Nombre de produits par catégorie (COUNT + GROUP BY)
-- Alimentation 2, Boissons 2, Hygiène 1, Papeterie 1
SELECT c.nom AS categorie, COUNT(p.id) AS nb_produits
FROM categories c
LEFT JOIN produits p ON p.categorie_id = c.id
GROUP BY c.id, c.nom;

-- Q1.5.6 – Valeur totale du stock (résultat : 777.5 DT)
SELECT SUM(prix * quantite) AS valeur_totale
FROM produits;

-- -------------------------------------------------------------
-- Partie 01 – Tests des contraintes (Q1.6)
-- À exécuter une par une, puis « Annuler les modifications »
-- -------------------------------------------------------------

-- a) prix négatif  -> CHECK constraint failed: prix >= 0
INSERT INTO produits (nom, prix, quantite, date_ajout, categorie_id)
VALUES ('Test prix', -5, 1, '2026-10-05T08:00:00', 1);

-- b) catégorie qui n'existe pas  -> FOREIGN KEY constraint failed
INSERT INTO produits (nom, prix, quantite, date_ajout, categorie_id)
VALUES ('Test catégorie', 1, 1, '2026-10-05T08:00:00', 99);

-- c) supprimer une catégorie qui contient des produits  -> FOREIGN KEY constraint failed
DELETE FROM categories WHERE id = 1;

-- -------------------------------------------------------------
-- Partie 04 – Insertion (Create)
-- Exécuter, vérifier, puis « Annuler les modifications »
-- -------------------------------------------------------------

-- Q4.1 – Insérer la catégorie « Électroménager »
INSERT INTO categories (nom, description)
VALUES ('Électroménager', 'Petits appareils');

-- Q4.6 – Insérer le produit « Stylo bleu » (Papeterie = catégorie 4)
INSERT INTO produits (nom, prix, quantite, disponible, date_ajout, categorie_id)
VALUES ('Stylo bleu', 0.500, 100, 1, '2026-10-30T10:00:00', 4);

-- -------------------------------------------------------------
-- Partie 05 – Lecture (Read)
-- -------------------------------------------------------------

-- Q5.1 – Tous les produits triés par nom
SELECT * FROM produits
ORDER BY nom ASC;

-- Q5.1 – Le produit dont l'id vaut 3
SELECT * FROM produits
WHERE id = 3;

-- -------------------------------------------------------------
-- Partie 06 – Modification (Update)
-- -------------------------------------------------------------

-- Q6.9 – Modifier le prix du produit 1 seulement
UPDATE produits SET prix = 19.000 WHERE id = 1;

-- Q6.9 – ⚠️ SANS WHERE : TOUS les produits passent à 1 DT !
-- (à exécuter puis « Annuler les modifications »)
UPDATE produits SET prix = 1;

-- Q6.15 – Ajuster la quantité sans passer sous 0 (calcul fait par SQLite)
UPDATE produits SET quantite = quantite + -1
WHERE id = 4 AND quantite + -1 >= 0;   -- 0 ligne modifiée : le jus est à 0

-- Q6.17 – Rendre un produit indisponible
UPDATE produits SET disponible = 0 WHERE id = 4;
