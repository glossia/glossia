%{
  title: "Affinement progressif",
  summary: "Pourquoi la qualité du contenu converge au fil du temps, et non en une seule passe.",
  category: "explication",
  order: 1
}
---
Premiers brouillons à partir de [modèles de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) sont corrects structurellement mais peuvent manquer de nuances, de ton, ou de formulations spécifiques au domaine. C'est par conception. Glossia traite la génération de contenu de la même manière que les équipes logicielles traitent le code : déployez une version fonctionnelle, passez en revue et améliorez-la itérativement.

## La boucle d'affinement

1. **Brouillon**: Glossia génère un premier passage valide structurellement basé sur vos fichiers sources et le contexte dans `L10N.md`.
2. **Relecture**Votre équipe signale les problèmes via des pull requests et des diffs, le même flux de travail que vous utilisez déjà pour le code.
3. **Affiner**: Les fichiers de contexte mis à jour, les corrections terminologiques et les retours de revue alimentent la prochaine exécution.
4. **Converger**: Chaque cycle réduit l'écart par rapport à la qualité de production. Le système apprend la voix de votre produit grâce au contexte que vous fournissez.

## Pourquoi cela fonctionne

: Le principe clé est que le contexte s'accumule. Chaque commentaire de revue qui conduit à une mise à jour `L10N.md` ou une entrée de terminologie corrigée améliore toutes les exécutions futures, pas seulement le fichier à l'origine de la revue.

Cela suit le même principe que Kaizen en fabrication et l'approximation successive en ingénierie : commencez avec un socle suffisant et améliorez-le systématiquement avec le jugement humain en boucle.

## Implications pratiques

- Ne comptez pas sur la perfection lors du premier passage. Prévoyez un ou deux cycles de révision.
- Investissez du temps dans la rédaction de fichiers de contexte clairs. Ils constituent l'amélioration la plus efficace que vous puissiez apporter.
- Utilisez la session de traduction du serveur pour suivre quels fichiers ont été traduits,
  ignorés, ou échoués.