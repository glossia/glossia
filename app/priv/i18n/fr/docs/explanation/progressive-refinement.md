%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  section: "translation",
  order: 1
}
---
Premiers brouillons de [modèles de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) sont structurés correctement mais peuvent manquer de nuances, de ton ou de tournures spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : publier une version fonctionnelle, la réviser et l'améliorer de manière itérative.

## La boucle d'affinement

1. **Brouillon**: Glossia génère une première version structuralement valide basée sur vos fichiers source et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale les problèmes via des pull requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections du glossaire et les retours de revue alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit la distance vers la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournit.

## Pourquoi cela fonctionne

: Le principe clé est que le contexte s'accumule. Chaque commentaire de revue qui mène à une mise à jour `L10N.md` ou une correction d'entrée de glossaire améliore toutes les exécutions futures, et non seulement le fichier qui a déclenché la revue.

Cela suit le même principe que Kaizen dans la fabrication et l'approximation successive en ingénierie : partez d'une base déjà suffisante et améliorez-la systématiquement avec le jugement humain en boucle.

## Implications pratiques

- Ne comptez pas sur la perfection lors du premier lancement. Prévoyez un ou deux cycles de révision.
- Investissez du temps pour écrire des fichiers de contexte clairs. Ce sont les améliorations les plus rentables que vous puissiez apporter.
- Utilisez la session de traduction dans Glossia pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.