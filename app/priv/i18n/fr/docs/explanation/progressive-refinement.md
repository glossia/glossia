%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps et non en un seul passage.",
  category: "explication",
  section: "traduction",
  order: 1
}
---
Premiers brouillons de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects mais peuvent manquer de nuances, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : livrez une version fonctionnelle, révisez-la et améliorez-la de manière itérative.

## La boucle d'affinement

1. **Brouillon**: Glossia génère une première passe structuralement valide basée sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale les problèmes via des pull requests et des diffs, le même processus que celui que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections du glossaire et les retours de révision alimentent l'exécution suivante.
4. **Convergence**: Chaque cycle réduit l'écart avec la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

L'idée clé est que le contexte s'accumule. Chaque commentaire de révision qui conduit à une mise à jour `L10N.md` ou une correction du glossaire améliore toutes les exécutions futures, pas seulement le fichier qui a déclenché la révision.

Ceci s'articule autour du même principe que Kaizen dans la production et l'approximation successive en ingénierie : commencer par une base suffisante et l'améliorer systématiquement avec le jugement humain en boucle.

## Conséquences pratiques

- N'attendez pas la perfection au premier essai. Prévoyez une ou deux itérations de révision.
- Investissez du temps à rédiger des fichiers de contexte clairs. Ils constituent l'amélioration la plus rentable que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignoré, ou raté.