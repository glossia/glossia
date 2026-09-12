%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  order: 1
}
---
Premiers brouillons de [modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont corrects d'un point de vue structurel mais peuvent manquer de nuances, de ton ou de tournures spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrer une version fonctionnelle, la réviser et l'améliorer itérativement.

## La boucle d'affinement

1. **Brouillon**: Glossia génère une première passe valide structurellement basée sur vos fichiers source et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale les problèmes via des pull-requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections terminologiques et les retours sur révision s'incorporent à l'exécution suivante.
4. **Convergence**: Chaque cycle réduit la distance à la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi ça fonctionne

L'idée clé est que le contexte s'accumule. Chaque commentaire de révision qui conduit à une mise à jour `L10N.md` ou une entrée de terminologie corrigée améliore toutes les exécutions futures, pas seulement le fichier ayant déclenché la révision.

Ceci suit le même principe que Kaizen en fabrication et l'approximation successive en ingénierie : commencez avec une base suffisante et améliorez-la systématiquement avec un jugement humain dans la boucle.

## Implications pratiques

- N'attendez pas la perfection à la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps pour rédiger des fichiers de contexte clairs. Ils sont l'amélioration la plus efficace que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.