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

- Renommer le binaire dans les archives de release du nom spécifique à la plateforme en `glossia`.
- Supprimer l'attribut de quarantaine macOS xattr des binaires avant le packaging.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de versionnement local et d'un flux de travail de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Correctifs de bugs

- Rendre la configuration du fournisseur OAuth facultative en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Définir le port 4000 par défaut en production et garder 4050 en développement. Le proxy de production s'attend à ce que l'application soit sur le port 4000. Le `runtime.exs` la valeur par défaut était 4050, ce qui a fait échouer les vérifications de santé pendant le déploiement.

#### Fonctionnalités

- Ajouter une application Phoenix avec connexion OAuth, améliorations de la documentation et améliorations de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévenir le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des titres de groupe au modèle de notes de version.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps de l'article avec la mise en page héro et améliorer le contenu de l'article de blog.
- Centrer horizontalement le contenu de l'article de blog.
- Corriger la panique lors du tronçonnage des résultats des outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter les outils de première partie et la section de site web.
- Mettre en valeur les étapes de vérification des outils.
- Simplifier l'affichage de progression.
- Appliquer une couleur aux lignes de progression.
- Afficher les activités de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsive avec un menu mobile et une mise en page multi-écran.
- Réimplémenter la CLI dans Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter une section de raffinement progressif sur la page d'accueil.
- Ajouter une section Blog avec support SEO et le premier article.
- Unifier la sortie CLI avec le format des verbes alignés à droite.
- Coloriser la sortie CLI avec un formatage de messages plus riche.
- Ajouter une image OG carrée et les balises meta de carte Twitter.
- Rendre l'agent coordonnateur agentic avec utilisation d'outils.
- Réécriture `glossia init` via le protocole Agent Client (ACP).
- Ajout de la prise en charge de Gemini, de la validation automatique, du suivi des jetons et d'améliorations de fiabilité.

#### Refactoring

- Séparation du CI en tâches distinctes de formatage, de vérification de type, de tests et de build.
- Réécriture de la CLI depuis TypeScript/Bun vers Rust.