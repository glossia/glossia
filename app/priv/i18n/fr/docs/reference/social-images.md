%{
  title: "Images sociales",
  summary:
    "Aperçus de liens du tableau de bord, image de marque du projet, mises à jour d'images et disponibilité.",
  category: "référence",
  section: "analytics",
  order: 30
}
---

Glossia génère des images sociales pour les liens de tableau de bord sur son service hébergé.

## Aperçus de lien

Les pages de tableau de bord présentent une image 1200 × 630 via [Open Graph](https://ogp.me/) et les métadonnées d'images grandes de Twitter. Partager un lien dans un service qui lit ces métadonnées peut afficher l'aperçu. Le service de partage décide quand récupérer ou mettre à jour cette image.

Les projets publics incluent leur nom, section et logo téléchargé. Les comptes publics reçoivent un aperçu spécifique à la section. Les comptes privés et les paramètres personnels utilisent une marque générique de Glossia.

## Marque du projet

Téléchargez ou remplacez le logo du projet dans Glossia pour modifier la marque utilisée dans son aperçu public. Les logos sont limités à cinq millions d'octets, correspondant aux fichiers uploadés du projet.

Les informations de projet privé ne sont pas incluses dans un aperçu social public. Un aperçu n'accorde pas accès à la page de tableau de bord liée.

## Mise à jour des images

Les adresses d'image changent lorsque le contenu affiché, le logo du projet, la version quotidienne de l'image ou la mise en œuvre du rendu de Glossia changent. Une image générée peut être mise en cache pour un jour. Les services de partage peuvent garder leur propre aperçu en cache, donc remplacer un logo ne garantit pas une mise à jour immédiate partout.

Glossia gère la génération d'image, le stockage, les polices et la mise en cache.

## Disponibilité

| Résultat | Réponse |
|---|---|
| Image disponible | 200 |
| Adresse d'image invalide ou expirée | 404 |
| Image temporairement indisponible | 503, avec un délai de reprise de 60 secondes |
| Limite de requête dépassée | 429, avec un délai de reprise dans la réponse |

Si un aperçu est manquant, ouvrez la page de tableau de bord et partagez son lien actuel. En cas d'erreur temporaire, réessayez après le délai indiqué. Si le problème persiste, contactez le support Glossia.
