import 'package:flutter/material.dart';

import '../database/categorie_dao.dart';
import '../database/produit_dao.dart';
import '../models/categorie.dart';
import '../models/produit.dart';

/// Formulaire unique : ajout (produit == null) ou modification (Q6.1 à Q6.14).
class ProduitFormScreen extends StatefulWidget {
  final Produit? produit;

  const ProduitFormScreen({super.key, this.produit});

  @override
  State<ProduitFormScreen> createState() => _ProduitFormScreenState();
}

class _ProduitFormScreenState extends State<ProduitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Q6.2 – un contrôleur par champ texte
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController();

  List<Categorie> _categories = [];
  bool _chargement = true;
  int? _categorieId;
  bool _disponible = true;
  bool _enregistrement = false;

  bool get _modeModification => widget.produit != null;

  @override
  void initState() {
    super.initState();

    // Q6.14 – mode modification : on pré-remplit les champs
    final p = widget.produit;
    if (p != null) {
      _nomCtrl.text = p.nom;
      _prixCtrl.text = p.prix.toStringAsFixed(3);
      _quantiteCtrl.text = '${p.quantite}';
      _categorieId = p.categorieId;
      _disponible = p.disponible;
    }

    // Q6.4 – les catégories viennent de la base
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final categories = await CategorieDao().lireCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _chargement = false;
    });
  }

  // Q6.2 – on libère les contrôleurs quand l'écran est détruit
  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    _quantiteCtrl.dispose();
    super.dispose();
  }

  /// Accepte « 2,5 » comme « 2.5 ».
  double? _lirePrix(String texte) =>
      double.tryParse(texte.trim().replaceAll(',', '.'));

  // Q6.6 – Enregistrer
  Future<void> _enregistrer() async {
    // 1. Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enregistrement = true);

    final nom = _nomCtrl.text.trim();
    final prix = _lirePrix(_prixCtrl.text)!;
    final quantite = int.parse(_quantiteCtrl.text.trim());

    try {
      if (_modeModification) {
        // Q6.14 – on garde l'id et la date d'ajout d'origine
        final modifie = widget.produit!.copyWith(
          nom: nom,
          prix: prix,
          quantite: quantite,
          disponible: _disponible,
          categorieId: _categorieId,
        );
        await ProduitDao().modifierProduit(modifie);
      } else {
        // 2. Construire le produit  3. L'insérer
        final nouveau = Produit(
          nom: nom,
          prix: prix,
          quantite: quantite,
          disponible: _disponible,
          dateAjout: DateTime.now(),
          categorieId: _categorieId!,
        );
        await ProduitDao().insererProduit(nouveau);
      }

      // 4. L'écran existe-t-il encore ?
      if (!mounted) return;
      // 5. Fermer en renvoyant true
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enregistrement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Q6.1
        title: Text(_modeModification ? 'Modifier le produit' : 'Nouveau produit'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Nom : obligatoire, au moins 2 caractères
                  TextFormField(
                    controller: _nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final texte = v?.trim() ?? '';
                      if (texte.isEmpty) return 'Le nom est obligatoire';
                      if (texte.length < 2) return 'Au moins 2 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Prix : nombre positif, virgule acceptée
                  TextFormField(
                    controller: _prixCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix (DT)',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final prix = _lirePrix(v ?? '');
                      if (prix == null) return 'Entrez un nombre (ex : 2,500)';
                      if (prix < 0) return 'Le prix doit être positif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantité : entier positif ou nul
                  TextFormField(
                    controller: _quantiteCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      prefixIcon: Icon(Icons.inventory),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final q = int.tryParse(v?.trim() ?? '');
                      if (q == null) return 'Entrez un nombre entier';
                      if (q < 0) return 'La quantité ne peut pas être négative';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Q6.4 – Catégorie choisie dans la base
                  DropdownButtonFormField<int>(
                    initialValue: _categorieId,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.nom),
                            ))
                        .toList(),
                    onChanged: (id) => setState(() => _categorieId = id),
                    validator: (id) =>
                        id == null ? 'Choisissez une catégorie' : null,
                  ),
                  const SizedBox(height: 8),

                  // Q6.5
                  SwitchListTile(
                    title: const Text('Disponible à la vente'),
                    value: _disponible,
                    onChanged: (v) => setState(() => _disponible = v),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _enregistrement ? null : _enregistrer,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
    );
  }
}
