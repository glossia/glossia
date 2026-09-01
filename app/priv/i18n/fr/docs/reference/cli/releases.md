%{
  title: "Sorties",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "cli",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Corrections de bugs

- Renommer le binaire à l'intérieur des archives de release du nom spécifique à la plate-forme à simplement `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'emballage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajouter le script de release local et le workflow de journal de changement géré manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurer les fournisseurs uniquement lorsque les variables d'environnement sont présentes.
- Par défaut port 4000 pour la production et conservez 4050 pour le développement. Le proxy de production s'attend à ce que l'application soit sur le port 4000. The `runtime.exs` la valeur par défaut était 4050, ce qui a provoqué l'échec des vérifications de santé lors du déploiement.

#### Fonctionnalités

- Ajouter l'application Phoenix avec connexion OAuth, améliorations des docs et améliorations de l'interface.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Empêcher le débordement horizontal des extraits de code sur mobile.
- Ajouter la bonne marge droite aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des titres de groupe au modèle de notices de release.
- Mettre à jour le workflow de traduction de Bun vers Rust.
- Aligner le corps du post avec la mise en layout hero et améliorer le contenu du post de blog.
- Centrer le contenu du post de blog horizontalement.
- Correction de la panique lors de la troncation des résultats d'outil multioctets UTF-8.

#### Fonctionnalités

- Ajouter les outils du premier parti et la section site web.
- Afficher les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher les activités de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsive avec un menu mobile et une mise en page à plusieurs points d'arrêt.
- Réimplémenter le CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter l'inspection de formatage avec Biome.
- Ajouter une section Raffinement progressif à la page d'accueil.
- Ajouter une section blog avec support SEO et premier post de blog.
- Unifier la sortie du CLI avec un format de verbe aligné à droite.
- Ajouter la colorisation de la sortie du CLI avec un formatage de message plus riche.
- Ajouter une image carrée OG et les balises meta de carte twitter.
- Rendre l'agent coordinateur agentic avec l'utilisation d'outils.
- Réécrire `glossia init` avec le Protocole Client Agent (ACP).
- Ajouter le support Gemini, la validation automatique, le suivi des jetons et des améliorations de fiabilité.

#### Restructurations

- Diviser la CI en des jobs de formatage, de vérification de type, de test et de build distincts.
- Réécrire le CLI de TypeScript/Bun en Rust.