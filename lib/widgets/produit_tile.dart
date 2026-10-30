import 'package:flutter/material.dart';

import '../models/produit.dart';

/// Une ligne de la liste des produits (Q5.5).
class ProduitTile extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onTap;

  const ProduitTile({super.key, required this.produit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enRupture = produit.quantite == 0;

    return ListTile(
      onTap: onTap,
      // Quantité dans un cercle : rouge si 0, vert sinon.
      leading: CircleAvatar(
        backgroundColor: enRupture ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        child: Text('${produit.quantite}'),
      ),
      title: Text(produit.nom),
      // Prix avec 3 décimales (dinar tunisien).
      subtitle: Text('${produit.prix.toStringAsFixed(3)} DT'),
      // Disponible ou non.
      trailing: Icon(
        produit.disponible ? Icons.check_circle : Icons.cancel,
        color: produit.disponible ? Colors.green : Colors.red,
      ),
    );
  }
}
