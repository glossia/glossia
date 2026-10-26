%{
  title: "Raffinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  section: "translation",
  order: 1
}
---

Les premiers brouillons générés par [les grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont structurés correctement, mais peuvent manquer de nuance, de ton ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes informatiques traitent le code : diffusez une version fonctionnelle, révisez-la et améliorez-la itérativement.

## La boucle de raffinement

1. **Brouillon**: Glossia génère une première version valide structurellement basée sur vos fichiers source et le contexte dans `L10N.md`.
2. **Revue**: Votre équipe signale les problèmes via des Pull Requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Raffinement**: Les fichiers de contexte mis à jour, les corrections du glossaire et les retours de revue alimentent la prochaine exécution.
4. **Convergence**: Chaque cycle réduit la distance à la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

L'idée clé est que le contexte s'accumule. Chaque commentaire de revue qui conduit à un `L10N.md` mis à jour ou à une entrée de glossaire corrigée améliore tous les futurs exécutions, et non seulement le fichier qui a déclenché la revue.

Cela suit le même principe que le Kaizen dans l'industrie manufacturière et l'approximation successive en ingénierie : commencez par une base suffisante et améliorez-la systématiquement avec le jugement humain dans la boucle.

## Conséquences pratiques

- N'attendez pas la perfection au premier essai. Prévoyez un ou deux cycles de révision.
- Investissez du temps à rédiger des fichiers de contexte clairs. C'est l'amélioration à plus haut rendement que vous puissiez réaliser.
- Utilisez la session de traduction dans Glossia pour suivre quels fichiers ont été traduits, ignorés ou ont échoué.
