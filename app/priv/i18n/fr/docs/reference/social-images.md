%{
  title: "Images sociales",
  summary:
    "Aperçus de liens du tableau de bord, marque de projet, mises à jour d'images et disponibilité.",
  category: "référence",
  section: "analytics",
  order: 30
}
---

Glossia génère des images sociales pour les liens de tableau de bord sur son service hébergé.

## Aperçus de liens

Les pages de tableau de bord annoncent une image de 1200 × 630 via [Open Graph](https://ogp.me/) et les métadonnées d'images grand format de Twitter. Partager un lien dans un service qui lit ces métadonnées peut afficher l'aperçu. Le service de partage décide quand le récupérer ou le rafraîchir.

Les projets publics incluent leur nom, leur section et le logo téléchargé. Les comptes publics reçoivent un aperçu spécifique à la section. Les comptes privés et les paramètres personnels utilisent une marque générique de Glossia.

## Marque du projet

Téléversez ou remplacez le logo du projet dans Glossia pour changer la marque utilisée dans son aperçu public. Les logos sont limités à cinq millions d'octets, correspondant aux téléversements de projet.

Les informations sur les projets privés ne sont pas incluses dans un aperçu d'image sociale public. Un aperçu n'accorde pas l'accès à la page de tableau de bord liée.

## Mises à jour des images

Les adresses d'image changent lorsque le contenu affiché, le logo du projet, la version d'image quotidienne ou la mise en œuvre de rendu Glossia changent. Une image valide peut être mise en cache pendant un jour. Les services de partage peuvent conserver leur propre aperçu en cache, si remplacer un logo ne garantit pas une mise à jour immédiate partout.

Glossia gère la génération d'images, le stockage, les polices et la mise en cache.

## Disponibilité

| Résultat | Réponse |
|---|---|
| Image disponible | 200 |
| Adresse d'image invalide ou expirée | 404 |
| Image temporairement indisponible | 503, avec un délai de réessai de 60 secondes |
| Limite de requête dépassée | 429, avec un délai de réessai dans la réponse |

Si un aperçu est manquant, ouvrez la page de tableau de bord et partagez son lien actuel. En cas d'échec temporaire, réessayez après le délai indiqué. Si le problème persiste, contactez le support Glossia.
