/// Une ligne de la table `categories`.
class Categorie {
  final int? id; // null tant que la catégorie n'est pas en base
  final String nom;
  final String? description;

  const Categorie({this.id, required this.nom, this.description});

  // Ligne de la base (Map) → objet Dart
  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      description: map['description'] as String?,
    );
  }

  // Objet Dart → ligne de la base (Map)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'description': description,
    };
  }

  @override
  String toString() => 'Categorie(id: $id, nom: $nom)';
}
