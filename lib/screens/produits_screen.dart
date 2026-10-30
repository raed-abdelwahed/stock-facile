import 'package:flutter/material.dart';

import '../database/produit_dao.dart';
import '../models/produit.dart';
import '../widgets/produit_tile.dart';
import 'produit_detail_screen.dart';
import 'produit_form_screen.dart';

/// Liste des produits lue dans la base (Q5.6 à Q5.8, Q5.12).
class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  final ProduitDao _dao = ProduitDao();
  late Future<List<Produit>> _futurProduits;

  @override
  void initState() {
    super.initState();
    // La requête est lancée UNE fois ici, et non dans build() (Q5.7).
    _futurProduits = _dao.lireProduits();
  }

  /// Relance la lecture et reconstruit l'écran.
  void _rafraichir() {
    setState(() {
      _futurProduits = _dao.lireProduits();
    });
  }

  /// Ouvre le détail ; si le produit a changé (retour = true), on recharge.
  Future<void> _ouvrirDetail(Produit produit) async {
    final modifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProduitDetailScreen(produitId: produit.id!),
      ),
    );
    if (modifie == true) _rafraichir();
  }

  /// Q6.7 – Ouvre le formulaire d'ajout ; au retour, recharge la liste.
  Future<void> _ajouterProduit() async {
    final ajoute = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProduitFormScreen()),
    );
    if (ajoute == true) {
      _rafraichir();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouveau produit',
        onPressed: _ajouterProduit,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Produits'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichir,
          ),
        ],
      ),
      body: FutureBuilder<List<Produit>>(
        future: _futurProduits,
        builder: (context, snapshot) {
          // 1. Chargement en cours
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur : ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final produits = snapshot.data ?? [];

          // 3. Liste vide (RefreshIndicator a besoin d'une liste scrollable)
          if (produits.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _rafraichir(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Aucun produit')),
                ],
              ),
            );
          }

          // 4. Données reçues
          return RefreshIndicator(
            onRefresh: () async => _rafraichir(),
            child: ListView.builder(
              itemCount: produits.length,
              itemBuilder: (context, index) {
                final produit = produits[index];
                return ProduitTile(
                  produit: produit,
                  onTap: () => _ouvrirDetail(produit),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
