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

- Renommer le binaire dans les archives de version d'un nom spécifique à la plate-forme vers `glossia`.
- Supprimer l'attribut de quarantaine macOS des binaires avant le conditionnement.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de sortie local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application devrait démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Utilisez le port 4000 par défaut pour la production et conservez 4050 pour le développement. Le proxy de production attend l'application sur le port 4000. Le `runtime.exs` la valeur par défaut était 4050, ce qui a fait échouer les contrôles de santé lors du déploiement.

#### Fonctionnalités

- Ajouter une application Phoenix avec authentification OAuth, des améliorations de la documentation et de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Correctifs

- Prévenir le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge de droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des titres de groupe au modèle de notes de version.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps de l'article avec la mise en page Hero et améliorer le contenu de l'article de blog.
- Centrer horizontalement le contenu de l'article de blog.
- Corriger la panique lors de la troncation des résultats d'outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter des outils de première partie et la section du site web.
- Mettre en évidence les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Mettre en forme les lignes d'outils.
- Rendre le site web réactif avec un menu mobile et une mise en page à plusieurs points de rupture.
- Réimplémenter le CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter la section Affinement progressif à l'accueil.
- Ajouter une section blog avec support SEO et premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage des messages plus riche.
- Ajouter une image carrée OG et des balises meta Twitter Card.
- Rendre l'agent coordinateur agenciel avec l'utilisation d'outils.
- Réécriture `glossia init` avec le protocole Agent Client Protocol (ACP).
- Ajouter la prise en charge de Gemini, la validation automatique, le suivi des tokens et des améliorations de la fiabilité.

#### Refactoring

- Diviser CI en jobs distincts pour le format, le typecheck, le test et le build.
- Réécrire la CLI de TypeScript/Bun vers Rust.