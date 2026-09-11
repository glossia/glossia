%{
  title: "Dernières versions",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Corrections de bugs

- Renommer le binaire dans les archives de distribution d'un nom spécifique à la plate-forme à juste `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de libération local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendez la configuration du fournisseur OAuth facultative en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Utilisez le port 4000 par défaut pour la production et conservez 4050 pour le développement. Le proxy de production attend que l'application soit sur le port 4000. Le `runtime.exs` défaut était 4050, ce qui a fait échouer les contrôles de santé lors du déploiement.

#### Fonctionnalités

- Ajout d'une application Phoenix avec connexion OAuth, améliorations de la documentation et améliorations de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables de CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Empêcher le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour empêcher le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des en-têtes de groupe au modèle de notes de version.
- Mettre à jour le flux de travail de traduction de Bun vers Rust.
- Aligner le corps de l'article avec la mise en page Hero et améliorer le contenu du billet de blog.
- Centrer le contenu du billet de blog horizontalement.
- Corriger la panique lors de la troncature des résultats d'outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter une section d'outils de première partie et du site web.
- Mettre en évidence les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsive avec un menu mobile et une mise en page multi-breakpoint.
- Réimplémenter CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter la section Affinement progressif à la page d'accueil.
- Ajouter une section Blog avec support SEO et le premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec une mise en forme de messages plus riche.
- Ajouter des balises meta image carrée OG et carte Twitter.
- Rendre l'agent coordinateur agentic avec utilisation d'outils.
- Réécriture `glossia init` avec le Protocole Client Agent (ACP).
- Ajouter le support Gemini, la validation automatique, le suivi des jetons et des améliorations de fiabilité.

#### Refactoring

- Diviser CI en tâches distinctes de formatage, vérification des types, les tests et le build.
- Réécrire CLI de TypeScript/Bun vers Rust.