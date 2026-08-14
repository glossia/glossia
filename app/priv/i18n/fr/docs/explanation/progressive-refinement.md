%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en une seule passe.",
  category: "explanation",
  order: 1
}
---
Les premiers jets produits par les [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects, mais peuvent manquer de nuances, ne pas respecter le ton ou employer des formulations inadaptées au domaine. C’est intentionnel. Glossia traite la génération de contenu comme les équipes de développement traitent le code : livrer une version fonctionnelle, la réviser et l’améliorer de manière itérative.

## La boucle d’amélioration

1. **Générer** : Glossia génère une première version structurellement valide à partir de vos fichiers sources et du contexte défini dans `GLOSSIA.md`.
2. **Réviser** : votre équipe signale les problèmes au moyen de demandes d’intégration et de diffs, selon le même processus que celui déjà utilisé pour le code.
3. **Améliorer** : les fichiers de contexte mis à jour, les corrections de terminologie et les commentaires de révision alimentent l’exécution suivante.
4. **Converger** : chaque cycle réduit l’écart avec la qualité requise pour la production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cette approche fonctionne

Le principe essentiel est que le contexte s’enrichit progressivement. Chaque commentaire de révision qui entraîne la mise à jour d’un `GLOSSIA.md` ou la correction d’une entrée de terminologie améliore toutes les exécutions futures, et pas seulement le fichier à l’origine de la révision.

Cette approche suit le même principe que le Kaizen dans l’industrie manufacturière et l’approximation successive en ingénierie : partir d’une base suffisamment fiable et l’améliorer systématiquement en intégrant le jugement humain au processus.

## Conséquences pratiques

- N’attendez pas un résultat parfait dès la première exécution. Prévoyez un ou deux cycles de révision.
- Consacrez du temps à la rédaction de fichiers de contexte clairs. Il s’agit du levier d’amélioration le plus efficace.
- Utilisez la session de traduction du serveur pour identifier les fichiers traduits, ignorés ou en échec.