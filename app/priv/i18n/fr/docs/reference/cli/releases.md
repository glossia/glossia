%{
  title: "Versions",
  summary: "Historique des versions de la CLI.",
  category: "reference",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Correctifs
- Renommer le binaire dans les archives de version, en remplaçant le nom propre à la plateforme par `glossia`.
- Supprimer l’attribut étendu de quarantaine macOS des binaires avant leur empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités
- Ajouter un script de publication locale et un processus de gestion manuelle du journal des modifications.

## 0.2.0

*2026-02-14*

#### Correctifs
- Rendre la configuration des fournisseurs OAuth facultative en production. L’application doit démarrer même si les identifiants OAuth GitHub/GitLab ne sont pas définis. Configurer les fournisseurs uniquement lorsque les variables d’environnement sont présentes.
- Utiliser le port 4000 par défaut en production et conserver le port 4050 en développement. Le mandataire de production attend l’application sur le port 4000. La valeur par défaut de `runtime.exs` était 4050, ce qui provoquait l’échec des contrôles d’intégrité pendant le déploiement.

#### Fonctionnalités
- Ajouter une application Phoenix avec connexion OAuth, améliorations de la documentation et de l’interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer l’interface en ligne de commande vers Bun et mettre à jour la génération des exécutables d’intégration continue.

## 0.1.0

*2026-02-12*

#### Correctifs
- Empêcher le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page adaptative sur mobile afin d’éviter le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des titres de groupe au modèle des notes de version.
- Migrer le processus de traduction de Bun vers Rust.
- Aligner le corps des articles sur la mise en page de la bannière principale et améliorer leur contenu.
- Centrer horizontalement le contenu des articles de blog.
- Corriger l’arrêt brutal lors de la troncature de résultats d’outils UTF-8 contenant des caractères multioctets.

#### Fonctionnalités
- Ajouter des outils propriétaires et une section dédiée sur le site web.
- Afficher les étapes de vérification des outils.
- Simplifier l’affichage de la progression.
- Teinter les lignes de progression.
- Afficher les activités de traduction et de validation.
- Mettre en forme les lignes relatives aux outils.
- Rendre le site web adaptatif avec un menu mobile et une mise en page reposant sur plusieurs points de rupture.
- Réimplémenter l’interface en ligne de commande avec Bun/TypeScript.
- Ajouter un processus d’intégration continue et des tests.
- Ajouter la vérification du formatage avec Biome.
- Ajouter une section sur l’affinement progressif à la page d’accueil.
- Ajouter une section de blog avec prise en charge de l’optimisation pour les moteurs de recherche et un premier article.
- Uniformiser la sortie de l’interface en ligne de commande avec des verbes alignés à droite.
- Colorer la sortie de l’interface en ligne de commande avec une mise en forme plus riche des messages.
- Ajouter une image Open Graph carrée et des balises méta de carte Twitter.
- Rendre l’agent coordinateur autonome grâce à l’utilisation d’outils.
- Réécrire `glossia init` avec Agent Client Protocol (ACP).
- Ajouter la prise en charge de Gemini, la validation automatique, le suivi des jetons et des améliorations de fiabilité.

#### Remaniements
- Diviser l’intégration continue en tâches distinctes de formatage, de vérification des types, de test et de compilation.
- Réécrire l’interface en ligne de commande de TypeScript/Bun vers Rust.