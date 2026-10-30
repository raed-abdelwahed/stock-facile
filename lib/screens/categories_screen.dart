import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/categorie_dao.dart';
import '../models/categorie.dart';

/// Liste des catégories : ajout et suppression (Q7.7, Q7.8).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategorieDao _dao = CategorieDao();
  late Future<List<Categorie>> _futurCategories;

  @override
  void initState() {
    super.initState();
    _futurCategories = _dao.lireCategories();
  }

  void _rafraichir() {
    setState(() => _futurCategories = _dao.lireCategories());
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? Colors.red : null,
      ),
    );
  }

  // Q7.7 – ajouter une catégorie depuis un AlertDialog
  Future<void> _ajouter() async {
    final controleur = TextEditingController();
    final nom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controleur.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controleur.dispose();

    final texte = nom?.trim() ?? '';
    if (texte.isEmpty) return;

    try {
      await _dao.insererCategorie(Categorie(nom: texte));
      if (!mounted) return;
      _rafraichir();
      _message('Catégorie « $texte » ajoutée');
    } on DatabaseException catch (e) {
      if (!mounted) return;
      // Même gestion du doublon qu'en Q4.4
      if (e.isUniqueConstraintError()) {
        _message('Cette catégorie existe déjà', erreur: true);
      } else {
        _message('Erreur : $e', erreur: true);
      }
    }
  }

  // Q7.8 – supprimer : refusé par la clé étrangère si la catégorie a des produits
  Future<void> _supprimer(Categorie categorie) async {
    try {
      await _dao.supprimerCategorie(categorie.id!);
      if (!mounted) return;
      _rafraichir();
      _message('Catégorie « ${categorie.nom} » supprimée');
    } on DatabaseException catch (e) {
      debugPrint('Erreur suppression catégorie : $e');
      if (!mounted) return;
      _message('Impossible : cette catégorie contient des produits',
          erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouvelle catégorie',
        onPressed: _ajouter,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Categorie>>(
        future: _futurCategories,
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
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune catégorie'));
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = categories[index];
              return ListTile(
                leading: const Icon(Icons.category, color: Colors.teal),
                title: Text(c.nom),
                subtitle: c.description == null ? null : Text(c.description!),
                trailing: IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _supprimer(c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
