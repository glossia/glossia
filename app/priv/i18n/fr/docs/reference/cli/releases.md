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

- Renommer le binaire dans les archives de publication depuis un nom spécifique à la plateforme à `glossia`,
- Supprimer l'attribut xattr de quarantaine macOS des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de libération local et d'un workflow de journal des modifications maintenu manuellement.

## 0.2.0

*2026-02-14*

#### Correction de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez les fournisseurs uniquement lorsque les variables d'environnement sont présentes.
- Utiliser le port 4000 par défaut pour la production et conserver 4050 pour le développement. Le proxy de production attend l'application sur le port 4000. Le `runtime.exs` défaut était 4050, ce qui a provoqué l'échec des vérifications de santé lors du déploiement.

#### Fonctionnalités

- Ajout de l'application Phoenix avec authentification OAuth, améliorations de la documentation et de l'interface utilisateur.
- Utilisation du logo arrondi comme favicon.
- Migration du CLI vers Bun et mise à jour des builds CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Empêcher le débordement horizontal des extraits de code sur mobile.
- Ajouter une marge droite correcte aux extraits de code sur mobile.
- Améliorer la mise en page responsive sur mobile pour éviter le débordement horizontal.
- Appliquer le formatage biome.
- Ajouter des en-têtes de groupe au modèle de notes de version.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps de l'article avec la mise en page hero et améliorer le contenu de l'article de blog.
- Centrer le contenu de l'article de blog horizontalement.
- Corriger la panique lors de la troncature des résultats d'outils UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter une section d'outils de première partie et de site web.
- Afficher les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web responsive avec un menu mobile et une disposition à plusieurs points de rupture.
- Réimplémenter CLI dans Bun/TypeScript.
- Ajouter un flux de travail CI et des tests.
- Ajouter une vérification de format avec Biome.
- Ajouter une section Amélioration progressive à l'accueil.
- Ajouter une section blog avec la prise en charge SEO et le premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de message plus riche.
- Ajouter une image carrée Open Graph et des balises meta Twitter Card.
- Rendre l'agent de coordination autonome avec l'usage d'outils.
- Réécriture `glossia init` avec le Protocole Agent Client (ACP).
- Ajout du support Gemini, validation automatique, suivi des jetons et améliorations de la fiabilité.

#### Remaniements

- Découper CI en tâches distinctes : formatage, vérification de types, tests et construction.
- Réécriture du CLI depuis TypeScript/Bun vers Rust.