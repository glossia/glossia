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

- Renommer le binaire dans les archives de version d'un nom spécifique à la plateforme au simple `glossia`.
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de déploiement local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Utilisez le port 4000 par défaut en production et gardez 4050 pour le développement. Le `runtime.exs` défaut était 4050, ce qui a fait échouer les vérifications de santé lors du déploiement.

#### Fonctionnalités

- Ajouter une application Phoenix avec connexion OAuth, des améliorations de la documentation et de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds CI exécutables.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévenir le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive sur mobile pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des en-têtes de groupe au modèle de notes de versions.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps de l'article avec la mise en page hero et améliorer le contenu du post de blog.
- Centrer le contenu du post de blog horizontalement.
- Réparer la panique lors de la troncature des résultats UTF-8 multi-octets des outils.

#### Fonctionnalités

- Ajouter les outils de première partie et la section de site web.
- Mettre en avant les étapes de vérification des outils.
- Simplifier l'affichage de la progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web réactif avec un menu mobile et une mise en page multi-support.
- Réimplémenter CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter une vérification de format avec Biome.
- Ajouter la section d'affinement progressif à la page d'accueil.
- Ajouter une section blog avec support SEO et premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de messages plus riche.
- Ajouter l'image OG carrée et les balises meta Twitter Card.
- Rendre l'agent de coordonnateur agentic avec l'utilisation d'outils.
- Réécriture `glossia init` avec le protocole agent client (ACP).
- Ajouter la prise en charge de Gemini, la validation automatique, le suivi des tokens et les améliorations de fiabilité.

#### Refactoring

- Diviser CI en tâches distinctes de formatage, de vérification de type, de test et de build.
- Réécriture du CLI de TypeScript/Bun vers Rust.