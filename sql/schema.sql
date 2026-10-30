BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nom         TEXT    NOT NULL UNIQUE,
  description TEXT
);
CREATE TABLE IF NOT EXISTS produits (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  nom          TEXT    NOT NULL,
  prix         REAL    NOT NULL CHECK (prix >= 0),
  quantite     INTEGER NOT NULL DEFAULT 0 CHECK (quantite >= 0),
  disponible   INTEGER NOT NULL DEFAULT 1,   -- 1 = vrai, 0 = faux
  date_ajout   TEXT    NOT NULL,             -- date au format ISO 8601
  categorie_id INTEGER NOT NULL,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE RESTRICT
);
COMMIT;
