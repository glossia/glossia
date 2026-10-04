%{
  title: "Versions",
  summary: "Historique des versions CLI.",
  category: "Référence",
  subcategory: "CLI",
  order: 2
}
---
## 0.14.1

*2026-02-14*

#### Corrections de bugs

- Renommer le binaire dans les archives de déploiement d'un nom spécifique à la plateforme en un simple `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de publication local et d'un flux de travail de journal des modifications manuellement maintenu.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Correction de la gestion de la configuration du fournisseur de connexion hébergé.
- Correction des contrôles de santé des services hébergés.

#### Fonctionnalités

- Ajouter une application Phoenix avec connexion OAuth, des améliorations de la documentation et de l'interface utilisateur.
- Utiliser le logo arrondi en tant que favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables de CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Empêcher le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des titres de groupe au modèle de notes de version.
- Mettre à jour le flux de traduction de Bun vers Rust.
- Aligner le corps du post avec la mise en page hero et améliorer le contenu des articles de blog.
- Centrer le contenu des articles de blog horizontalement.
- Corriger la panique lors de la troncature des résultats d'outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter la section outils de première partie et site web.
- Présenter les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsif avec un menu mobile et une mise en page multi-breakpoints.
- Réimplémenter le CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter une section Amélioration progressive sur la page d'accueil.
- Ajouter une section blog avec support SEO et premier article.
- Uniformiser la sortie CLI avec un format de verbe aligné à droite.
- Ajouter de la couleur à la sortie CLI avec un format de messages plus riche.
- Ajouter une image OG carrée et les balises meta Twitter Card.
- Rendre l'agent de coordination agentic avec l'utilisation d'outils.
- Réécriture `glossia init` avec le protocole Agent Client (ACP).
- Ajout de la prise en charge de Gemini, de l'auto-validation, du suivi des jetons et des améliorations de fiabilité.

#### Refactorisations

- Séparer la CI en tâches distinctes de format, typecheck, test et build.
- Réécriture de la CLI de TypeScript/Bun vers Rust.