/// Une ligne de la table `produits`.
class Produit {
  final int? id; // null tant que le produit n'est pas en base
  final String nom;
  final double prix;
  final int quantite;
  final bool disponible;
  final DateTime dateAjout;
  final int categorieId;

  const Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.quantite = 0,
    this.disponible = true,
    required this.dateAjout,
    required this.categorieId,
  });

  // Ligne de la base (Map) → objet Dart
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      prix: (map['prix'] as num).toDouble(),
      quantite: map['quantite'] as int,
      disponible: map['disponible'] == 1,
      dateAjout: DateTime.parse(map['date_ajout'] as String),
      categorieId: map['categorie_id'] as int,
    );
  }

  // Objet Dart → ligne de la base (Map)  (Q2.4)
  // Les clés sont EXACTEMENT les noms des colonnes de la table produits.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // l'id est généré par SQLite à l'insertion
      'nom': nom,
      'prix': prix,
      'quantite': quantite,
      'disponible': disponible ? 1 : 0, // bool → INTEGER (1 / 0)
      'date_ajout': dateAjout.toIso8601String(), // DateTime → TEXT ISO 8601
      'categorie_id': categorieId, // camelCase → snake_case
    };
  }

  @override
  String toString() =>
      'Produit(id: $id, nom: $nom, prix: ${prix.toStringAsFixed(3)} DT, '
      'quantite: $quantite, disponible: $disponible, '
      'dateAjout: ${dateAjout.toIso8601String()}, categorieId: $categorieId)';
}
