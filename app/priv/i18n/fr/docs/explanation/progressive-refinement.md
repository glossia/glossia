%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en un seul passage.",
  category: "explication",
  order: 1
}
---
Premiers brouillons à partir [grands modèles linguistiques](https://en.wikipedia.org/wiki/Large_language_model) sont structurellement corrects mais peuvent manquer de nuances, de ton ou de formulation spécifique au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : déployez une version fonctionnelle, révisez-la et améliorez-la de manière itérative.

## La boucle de raffinement

1. **Brouillon**: Glossia génère un premier jet valide sur le plan structurel basé sur vos fichiers source et le contexte dans `L10N.md`.
2. **Relecture**: Votre équipe signale les problèmes via des pull requests et des diff, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections de terminologie et les retours de revue alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit l'écart avec la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournit.

## Pourquoi cela fonctionne

: Le point clé est que le contexte s'accumule. Chaque commentaire de revue qui conduit à une mise à jour `L10N.md` ou une entrée de terminologie corrigée améliore toutes les exécutions futures, pas seulement le fichier ayant déclenché la revue.

Cela suit le même principe que le Kaizen en fabrication et l'approximation successive en ingénierie : commencez avec une base de départ suffisante et améliorez-la systématiquement avec le jugement humain en boucle.

## Conséquences pratiques

- Ne comptez pas sur la perfection lors de la première exécution. Prévoyez un ou deux cycles de révision.
- Investissez du temps pour rédiger des fichiers de contexte clairs. Ils constituent l'amélioration la plus efficace que vous puissiez apporter.
- Utilisez la session de traduction serveur pour suivre quels fichiers ont été traduits,
  sautés, ou échoués.