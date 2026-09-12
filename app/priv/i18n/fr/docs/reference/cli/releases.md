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

- Renommer le binaire dans les archives de release du nom spécifique à la plateforme vers uniquement `glossia`.
- Éliminer l'attribut de quarantaine macOS xattr des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de sortie local et d'un flux de travail de journal des modifications à main tenante.

## 0.2.0

*2026-02-14*

#### Corrections de bugs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Utilisez le port 4000 par défaut pour la production et conservez le 4050 pour le développement. Le proxy de production attend que l'application soit sur le port 4000. Le `runtime.exs` la valeur par défaut était 4050, ce qui a provoqué un échec des contrôles de santé lors du déploiement.

#### Fonctionnalités

- Ajout d'une application Phoenix avec authentification OAuth, améliorations de la documentation et de l'interface utilisateur.
- Utiliser le logo arrondi comme favicon.
- Migrer le CLI vers Bun et mettre à jour les builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévenir le débordement horizontal des fragments de code sur mobile.
- Ajouter une marge droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page responsive mobile pour éviter le débordement horizontal.
- Appliquer le formatage Biome.
- Ajouter des titres de groupe au modèle de notes de version.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps du post avec la mise en page Hero et améliorer le contenu du post de blog.
- Centrer horizontalement le contenu du post de blog.
- Corriger la panique lors du tronçonnage des résultats de l'outil UTF-8 multi-octets.

#### Fonctionnalités

- Ajouter les outils first-party et la section du site web.
- Afficher les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Mettre en forme les lignes des outils.
- Rendre le site web réactif avec un menu mobile et une mise en page multi-breakpoint.
- Reimplémenter le CLI en Bun/TypeScript.
- Ajouter un workflow CI et des tests.
- Ajouter la vérification de format avec Biome.
- Ajouter la section Raffinement progressif à la page d'accueil.
- Ajouter une section blog avec support SEO et premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de messages plus riche.
- Ajouter une image OG carrée et les balises meta Twitter Card.
- Rendre l'agent de coordination autonome avec utilisation d'outils.
- Réécriture `glossia init` avec le protocole Client Agent (ACP).
- Ajout du support de Gemini, de la validation automatique, du suivi des jetons et des améliorations de fiabilité.

#### Réfaçonnements

- Division du CI en tâches format, typecheck, test, build séparées.
- Réécriture du CLI depuis TypeScript/Bun en Rust.