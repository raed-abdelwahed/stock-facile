import 'package:flutter/material.dart';

import '../database/categorie_dao.dart';
import '../database/produit_dao.dart';
import '../models/categorie.dart';
import '../models/produit.dart';
import 'produit_form_screen.dart';

/// Boîte de confirmation « Supprimer ce produit ? » (Q7.3, réutilisée en Q7.4).
/// Renvoie true si l'utilisateur confirme.
Future<bool> confirmerSuppression(BuildContext context, String nom) async {
  final reponse = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer ce produit ?'),
      content: Text('« $nom » sera supprimé définitivement.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return reponse ?? false;
}

/// Détail d'un produit (Q5.11, Q6.14, Q6.16, Q6.17, Q7.3).
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
  final ProduitDao _dao = ProduitDao();
  late Future<_Details> _futurDetails;

  /// Devient true dès qu'on change quelque chose : la liste se rechargera.
  bool _modifie = false;

  @override
  void initState() {
    super.initState();
    _futurDetails = _charger();
  }

  Future<_Details> _charger() async {
    final produit = await _dao.lireProduitParId(widget.produitId);
    if (produit == null) return const _Details(null, null);
    final categorie =
        await CategorieDao().lireCategorieParId(produit.categorieId);
    return _Details(produit, categorie);
  }

  void _recharger() {
    setState(() => _futurDetails = _charger());
  }

  /// Date au format jj/mm/aaaa.
  String _formaterDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    return '$jour/$mois/${d.year}';
  }

  // Q6.14 – ouvrir le formulaire en mode modification
  Future<void> _modifier(Produit produit) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProduitFormScreen(produit: produit)),
    );
    if (ok == true) {
      _modifie = true;
      _recharger();
    }
  }

  // Q6.16 / Q6.17 – boutons − et +
  Future<void> _ajuster(Produit produit, int delta) async {
    final lignes = await _dao.ajusterQuantite(produit.id!, delta);
    debugPrint('ajusterQuantite(${produit.id}, $delta) a retourné $lignes');

    if (lignes == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité ne peut pas être négative')),
      );
      return;
    }

    // Q6.17 – stock épuisé : le produit devient indisponible
    if (produit.quantite + delta == 0) {
      await _dao.changerDisponibilite(produit.id!, false);
    }

    _modifie = true;
    _recharger();
  }

  // Q7.3 – supprimer après confirmation, puis revenir à la liste
  Future<void> _supprimer(Produit produit) async {
    final ok = await confirmerSuppression(context, produit.nom);
    if (!ok) return;
    await _dao.supprimerProduit(produit.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // En quittant l'écran, on renvoie _modifie à la liste (Q6.14).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _modifie);
      },
      child: Scaffold(
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(produit.nom,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            ),
                            IconButton(
                              tooltip: 'Modifier',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _modifier(produit),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _supprimer(produit),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _Ligne(Icons.payments, 'Prix',
                            '${produit.prix.toStringAsFixed(3)} DT'),
                        _Ligne(Icons.inventory, 'Quantité',
                            '${produit.quantite}'),
                        _Ligne(
                          produit.disponible
                              ? Icons.check_circle
                              : Icons.cancel,
                          'Disponibilité',
                          produit.disponible ? 'Disponible' : 'Indisponible',
                        ),
                        _Ligne(Icons.category, 'Catégorie',
                            categorie?.nom ?? 'Inconnue'),
                        _Ligne(Icons.event, "Date d'ajout",
                            _formaterDate(produit.dateAjout)),
                        const SizedBox(height: 16),

                        // Q6.16 – boutons − / +
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Retirer 1',
                              icon: const Icon(Icons.remove),
                              onPressed: () => _ajuster(produit, -1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text('${produit.quantite}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Ajouter 1',
                              icon: const Icon(Icons.add),
                              onPressed: () => _ajuster(produit, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
