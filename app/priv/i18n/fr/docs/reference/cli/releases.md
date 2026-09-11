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

- Renommer le binaire à l'intérieur des archives de release à partir du nom spécifique à la plateforme vers `glossia`.
- Retirer l'attribut de quarantaine macOS xattr des binaires avant l'empaquetage.

## 0.14.0

*2026-02-14*

#### Fonctionnalités

- Ajout d'un script de déploiement local et d'un flux de journalisation de versions manuellement maintenu.

## 0.2.0

*2026-02-14*

#### Correctifs

- Rendre la configuration du fournisseur OAuth optionnelle en production. L'application doit démarrer même sans les identifiants OAuth GitHub/GitLab définis. Configurez uniquement les fournisseurs lorsque les variables d'environnement sont présentes.
- Par défaut, utilisez le port 4000 pour la production et conservez 4050 pour le développement. Le proxy de production attend que l'application soit sur le port 4000. Le `runtime.exs` valeur par défaut était 4050, ce qui a fait échouer les contrôles de santé lors du déploiement.

#### Fonctionnalités

- Ajout de l'application Phoenix avec connexion OAuth, améliorations de la documentation et de l'interface utilisateur.
- Utilisation du logo arrondi comme favicon.
- Migration du CLI vers Bun et mise à jour des builds exécutables CI.

## 0.1.0

*2026-02-12*

#### Corrections de bugs

- Prévention du débordement horizontal des extraits de code sur mobile.
- Ajouter une marge de droite appropriée aux extraits de code sur mobile.
- Améliorer la mise en page mobile adaptative pour prévenir le débordement horizontal.
- Appliquer le formatage de Biome.
- Ajouter des titres de groupe au modèle des notes de version.
- Mettre à jour le flux de travail de traduction de Bun à Rust.
- Aligner le corps de l'article avec la mise en page Hero et améliorer le contenu du message de blog.
- Centrer horizontalement le contenu du message de blog.
- Corriger la panique lors du tronçonnage des résultats d'outil multi-octets UTF-8.

#### Fonctionnalités

- Ajouter les outils de première partie et la section du site web.
- Présenter les étapes de vérification des outils.
- Simplifier la sortie de progression.
- Teinter les lignes de progression.
- Afficher l'activité de traduction et de validation.
- Formater les lignes d'outils.
- Rendre le site web adaptable avec un menu mobile et une mise en page multi-points de rupture.
- Réimplémenter CLI dans Bun/TypeScript.
- Ajouter le flux CI et les tests.
- Ajouter la vérification du format avec Biome.
- Ajouter la section d'affinement progressif à l'accueil.
- Ajouter une section de blog avec le support SEO et le premier article de blog.
- Unifier la sortie CLI avec un format de verbe aligné à droite.
- Coloriser la sortie CLI avec un formatage de message plus riche.
- Ajouter une image Open Graph carrée et les balises de carte Twitter.
- Rendre l'agent de coordination agentique avec l'utilisation d'outils.
- Réécrire `glossia init` avec le protocole Agent Client (ACP).
- Ajouter la prise en charge de Gemini, la validation automatique, le suivi de jetons et des améliorations de fiabilité.

#### Refaçages

- Diviser CI en jobs séparés pour le formatage, la vérification des types, les tests et la construction.
- Réécrire le CLI à partir de TypeScript/Bun en Rust.