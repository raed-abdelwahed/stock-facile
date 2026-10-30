import 'package:flutter/material.dart';

import '../database/categorie_dao.dart';
import '../database/produit_dao.dart';
import '../models/categorie.dart';
import '../models/produit.dart';

/// Détail d'un produit (Q5.11).
/// L'écran reçoit seulement l'id et relit le produit dans la base.
class ProduitDetailScreen extends StatefulWidget {
  final int produitId;

  const ProduitDetailScreen({super.key, required this.produitId});

  @override
  State<ProduitDetailScreen> createState() => _ProduitDetailScreenState();
}

/// Le produit et sa catégorie, chargés ensemble.
class _Details {
  final Produit? produit;
  final Categorie? categorie;
  const _Details(this.produit, this.categorie);
}

class _ProduitDetailScreenState extends State<ProduitDetailScreen> {
  late Future<_Details> _futurDetails;

  @override
  void initState() {
    super.initState();
    _futurDetails = _charger();
  }

  Future<_Details> _charger() async {
    final produit = await ProduitDao().lireProduitParId(widget.produitId);
    if (produit == null) return const _Details(null, null);
    final categorie =
        await CategorieDao().lireCategorieParId(produit.categorieId);
    return _Details(produit, categorie);
  }

  /// Date au format jj/mm/aaaa.
  String _formaterDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    return '$jour/$mois/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du produit'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_Details>(
        future: _futurDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final produit = snapshot.data?.produit;
          if (produit == null) {
            return const Center(child: Text('Produit introuvable'));
          }
          final categorie = snapshot.data?.categorie;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produit.nom,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Divider(height: 24),
                      _Ligne(Icons.payments, 'Prix',
                          '${produit.prix.toStringAsFixed(3)} DT'),
                      _Ligne(Icons.inventory, 'Quantité',
                          '${produit.quantite}'),
                      _Ligne(
                        produit.disponible ? Icons.check_circle : Icons.cancel,
                        'Disponibilité',
                        produit.disponible ? 'Disponible' : 'Indisponible',
                      ),
                      _Ligne(Icons.category, 'Catégorie',
                          categorie?.nom ?? 'Inconnue'),
                      _Ligne(Icons.event, "Date d'ajout",
                          _formaterDate(produit.dateAjout)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Une ligne « icône – libellé – valeur » de la carte.
class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _Ligne(this.icone, this.libelle, this.valeur);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, color: Colors.teal),
          const SizedBox(width: 12),
          Text('$libelle : ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(valeur)),
        ],
      ),
    );
  }
}
