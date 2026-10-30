# Réponses – TP StockFacile

## Partie 00

### Q0.5 – Pourquoi ne pas envoyer les fichiers `.db` sur GitHub ?
Les fichiers `.db` contiennent des **données** (de test ou personnelles) et sont des fichiers **binaires** : Git ne peut pas afficher leurs différences, ils changent à chaque exécution de l'application et provoqueraient des conflits. Ils peuvent aussi contenir des informations privées.
Le fichier `schema.sql`, lui, est du **texte** qui décrit seulement la **structure** de la base : il est lisible, comparable d'une version à l'autre, et il suffit pour recréer la base n'importe où.

### Question de réflexion – retrouver une version qui marchait
Comme on fait un commit à la fin de chaque partie, `git log --oneline` liste toutes les versions. Si l'application ne marche plus après la partie 07, on peut revenir voir (`git checkout <id>`) ou comparer (`git diff <id>`) la version de la partie 06, qui fonctionnait, pour trouver ce qui a cassé.
