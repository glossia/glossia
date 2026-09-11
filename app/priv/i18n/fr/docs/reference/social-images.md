%{
  title: "Images sociales",
  summary:
    "Aperçus quotidiens du tableau de bord, rendu côté navigateur, stockage et limites de trafic.",
  category: "Référence",
  order: 30
}
---
Les pages du tableau de bord annoncent une image de 1200 × 630 par [Open Graph](https://ogp.me/)
et les métadonnées d'images de grande taille de Twitter. Les projets publics incluent leur nom, leur section,
et le logo téléchargé. Les comptes publics reçoivent un aperçu spécifique à la section. Privés
comptes et paramètres personnels utilisent une marque générique Glossia.

## Identité de l'image et durée de vie

Le digest de l'image inclut le contenu affiché, la révision du logo du projet, le modèle,
styles, polices, actif de marque, lockfile des dépendances, et journée actuelle dans
[Temps universel coordonné](https://www.timeanddate.com/time/aboututc.html).
Modifier l'un de ces attributs crée une nouvelle adresse. Trier les attributs et signer
à minuit maintient l'adresse complète stable tout au long de la journée.

La charge utile signée ne peut être modifiée par un visiteur. Elle est valide pendant deux jours,
mais seule la charge utile du jour en cours peut générer une image manquante. d'hier
les images stockées restent lisibles. Les paramètres de requête ne deviennent jamais des clés de stockage d'objets.

Les images réussies sont persistées sous `og/images/<digest>.jpg` dans la configuration
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible bucket.
Seule une réponse explicite d'objet manquant déclenche la génération. Défaillances de stockage.
renvoie une erreur temporaire non mise en cache, sans lancer Chrome. Le téléversement doit
réussir avant qu'une image nouvellement rendue ne soit servie.

## Rendu et limites

Le rendu utilise Carta avec BrowseChrome, la même pile que le rendu d'image de Tuist.
Le pool supervisé contient deux navigateurs. Chaque rendu dispose d'un délai de 15 secondes ;
chaque instance d'application autorise au plus douze nouveaux rendus par minute.
Les requêtes d'images stockées ne consomment pas cette allocation.

Cachex combine les requêtes concurrentes pour la même image et conserve jusqu'à 100
images pendant cinq minutes. Un verrouillage PostgreSQL non bloquant de type conseil empêche
différentes réplicas d'application de rendre la même image simultanément.
Les autres réplicas reçoivent une erreur temporaire et peuvent réessayer une fois que l'objet existe.

Le modèle associe un badge de section Noora à l'arrière-plan chaleureux de Glossia, serif
En-tête, accent de dégradé et pied de page sobre. Source Serif 4 et Inter sont
intégrés localement de sorte que les prévisualisations ne dépendent pas d'un service de police. Les polices et les rasters
les logos sont intégrés. La politique de sécurité de contenu du document bloque les scripts et
ressources externes. Les logos sont chargés uniquement depuis le stockage des avatars de l'application
préfixe et sont limités à cinq millions d'octets, correspondant aux téléversements du projet.

## Comportement de réponse

| Résultat | Statut | Comportement du cache |
|---|---|---|
| Image stockée ou nouvellement persistée | 200 | Public, un jour, immuable |
| Signature invalide, expirée ou altérée | 404 | Aucun stockage |
| Image d'hier manquante dans le stockage | 404 | Aucun stockage |
| Navigateur occupé, échec de rendu, ou stockage indisponible | 503 | Aucun stockage ; réessayer après 60 secondes |
| Limite des requêtes d'origine dépassée | 429 | Aucun stockage ; intervalle de réessai dans la réponse |

L'origine autorise trente requêtes par minute par adresse client, y compris
des requêtes invalides.

## Cloudflare

La `social-images-rate-limit.yaml` ressource dans le dépôt d'infrastructure
correspond `GET` et `HEAD` les requêtes sous `/og/`, y compris les crawlers vérifiés. Elle
autorise vingt requêtes par dix secondes par adresse client et Cloudflare
localité. Le dépassement de la limite bloque les requêtes pendant dix secondes. Le général
les règles du défi de page publique excluent ce chemin donc les crawlers d'images n'ont jamais besoin de
résoudre un défi de navigateur.

de Cloudflare [comportement de cache par défaut](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
met en cache `.jpg` les réponses et respecte les en-têtes de cache d'origine. Conservez la requête signée
chaîne dans la clé de cache par défaut. N'appliquez pas une durée de cache surimposée qui
met en cache les réponses d'erreur ou ignore `no-store`. La signature déterministe évite
une entrée de cache par requête de page.

Déployez la ressource d'infrastructure aux côtés de l'application. Assurez-vous que l'origine
est accessible uniquement par l'ingress de confiance, puisque les adresses clientes acheminées
sont réputées fiables par le limiteur de requêtes existant. Le pool de navigateurs et le budget de rendu
limitent également les ratés distribués et les requêtes d'origine directe.

## Configuration locale

Définir `GLOSSIA_OG_IMAGES=true` pour activer le pool de navigateurs en développement. Installez
Google Chrome ou Chromium, générez des actifs avec `mix assets.build`, et configure
les variables d'environnement de stockage objet existantes :

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Exécuter `mix ecto.setup` et `mix phx.server`. Avec le stockage configuré, les graines offrent
le public `dev/glossia` projet un logo. Examiner le `og:image` métadonnées sur un
page du tableau de bord pour obtenir son adresse d'image signée.