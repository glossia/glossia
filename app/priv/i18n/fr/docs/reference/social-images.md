%{
  title: "Images sociales",
  summary:
    "Aperçus de liens du tableau de bord, branding de projet, mises à jour d'images et disponibilité.",
  category: "Référence",
  section: "analytics",
  order: 30
}
---

Glossia génère des images sociales pour les liens du tableau de bord sur son service hébergé.

## Aperçus de liens

Les pages du tableau de bord annoncent une image de 1200 × 630 via [Open Graph](https://ogp.me/) et les métadonnées Twitter d'image de grande taille. Partager un lien dans un service qui lit ces métadonnées peut afficher l'aperçu. Le service de partage décide quand le récupérer ou le rafraîchir.

Les projets publics incluent leur nom, leur section et le logo téléchargé. Les comptes publics reçoivent un aperçu spécifique à la section. Les comptes privés et les paramètres personnels utilisent une marque Glossia générique.

## Branding du projet

Téléchargez ou remplacez le logo du projet dans Glossia pour modifier le branding utilisé dans son aperçu public. Les logos sont limités à cinq millions d'octets, correspondant aux téléchargements de projet.

Les informations sur le projet privé ne sont pas incluses dans un aperçu public d'image sociale. Un aperçu n'accorde pas l'accès à la page du tableau de bord liée.

## Mises à jour d'images

Les adresses d'image changent lorsque le contenu affiché, le logo du projet, la version quotidienne de l'image ou l'implémentation de rendu Glossia change. Une image réussie peut être mise en cache pendant un jour. Les services de partage peuvent conserver leur propre aperçu mis en cache, donc remplacer un logo ne garantit pas une mise à jour immédiate partout.

Glossia gère la génération d'images, le stockage, les polices et la mise en cache.

## Disponibilité

| Résultat | Réponse |
|---|---|
| Image disponible | 200 |
| Adresse d'image invalide ou expirée | 404 |
| Image temporairement indisponible | 503, avec un délai de réessai de 60 secondes |
| Limite de requêtes dépassée | 429, avec un délai de réessai dans la réponse |

Si un aperçu manque, ouvrez la page du tableau de bord et partagez son lien actuel. En cas d'échec temporaire, réessayez après le délai indiqué. Si le problème persiste, contactez le support Glossia.
