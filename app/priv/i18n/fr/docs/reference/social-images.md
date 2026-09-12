%{
  title: "Images sociales",
  summary:
    "Aperçus du tableau de bord quotidien, rendu navigateur, stockage et limites de trafic.",
  category: "Référence",
  order: 30
}
---
Les pages du tableau de bord affichent une image de 1200 × 630 via [Open Graph](https://ogp.me/)
et les métadonnées Twitter à grande image. Les projets publics incluent leur nom, la section,
et le logo téléversé. Les comptes publics reçoivent un aperçu spécifique à la section. Privé
comptes et paramètres personnels utilisent une marque générique Glossia.

## Identité et durée de vie de l'image

Le digest de l'image inclut le contenu affiché, la révision du logo du projet, le modèle,
styles, polices, élément de marque, fichier de verrouillage des dépendances, et jour actuel dans
[Temps universel coordonné](https://www.timeanddate.com/time/aboututc.html).
Modifier l'un de ces éléments crée une nouvelle adresse. Le tri des attributs et la signature
à minuit maintient l'adresse complète stable tout au long de la journée.

La charge utile signée ne peut pas être modifiée par un visiteur. Elle est valide pendant deux jours,
mais seule la charge utile du jour peut générer une image manquante. D'hier
les images stockées restent lisibles. Les paramètres de requête ne deviennent jamais des clés de stockage d'objets.

Les images réussies sont persistées sous `og/images/<digest>.jpg` dans le configuré
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible bucket.
Seule une réponse explicite d'objet manquant déclenche la génération. Les erreurs de stockage
retournent une erreur temporaire non mise en cache, sans démarrer Chrome. Un upload doit
réussir avant qu'une image nouvellement rendue ne soit servie.

## Rendu et limites

Le rendu utilise Carta avec BrowseChrome, la même pile que le moteur de rendu d'image de Tuist.
Le pool supervisé contient deux navigateurs. Chaque rendu dispose d'un délai de 15 secondes ;
chaque instance d'application autorise au plus douze nouveaux rendus par minute.
Les requêtes d'images stockées ne consomment pas cette allocation.

Cachex combine les requêtes concurrentes pour la même image et conserve jusqu'à 100
images pendant cinq minutes. Un verrou advisory PostgreSQL non bloquant empêche
différentes répliques d'application de rendre la même image simultanément.
Les autres répliques reçoivent une erreur temporaire et peuvent réessayer une fois l'objet présent.

Le modèle associe un badge de section Noora au fond chaleureux de Glossia, serif
entête, accent de dégradé et pied de page sobre. Source Serif 4 et Inter sont
incluses localement pour que les prévisualisations ne dépendent pas d'un service de polices. Polices et raster
les logos sont intégrés. La politique de sécurité du contenu du document bloque les scripts et
ressources externes. Les logos sont chargés uniquement depuis le stockage des avatars de l'application
préfixe et sont limités à cinq millions d'octets, correspondant aux téléversements de projet.

## Comportement de réponse

| Résultat | Statut | Comportement du cache |
|---|---|---|
| Image stockée ou nouvellement persistée | 200 | Public, une journée, immuable |
| Signature invalide, expirée ou altérée | 404 | Pas de stockage |
| Image d'hier absente du stockage | 404 | Pas de stockage |
| Navigateur occupé, échec de rendu ou stockage indisponible | 503 | Pas de stockage ; réessai après 60 secondes |
| Limite des requêtes d'origine dépassée | 429 | Pas de stockage ; intervalle de réessai dans la réponse |

L'origine autorise trente requêtes par minute par adresse client, y compris
des requêtes invalides.

## Cloudflare

La `social-images-rate-limit.yaml` ressource du référentiel d'infrastructure
correspond `GET` et `HEAD` requêtes sous `/og/`, y compris les crawlers vérifiés. Elle
autorise vingt requêtes par dix secondes par adresse client et Cloudflare
localisation. Le dépassement de la limite bloque les requêtes pendant dix secondes. En général
les règles de défi pour les pages publiques excluent ce chemin de sorte que les robots d'image n'ont jamais besoin de
résoudre un défi navigateur.

de Cloudflare [comportement par défaut du cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
met en cache `.jpg` les réponses et respecte les en-têtes de cache d'origine. Conservez la requête signée
chaîne dans la clé de cache par défaut. Ne pas appliquer une durée de cache qui remplace
met en cache les réponses d'erreur ou ignore `no-store`. La signature déterministe évite
une entrée de cache par requête de page.

Déployez la ressource d'infrastructure aux côtés de l'application. Assurez-vous que l'origine
est accessible uniquement via l'ingress de confiance, car les adresses client transmises
sont réputés fiables par le limiteur de requêtes existant. Le pool de navigateurs et le budget de rendu
limitent également les ratés distribués et les requêtes d'origine directe.

## Configuration locale

Définir `GLOSSIA_OG_IMAGES=true` pour activer le pool de navigateurs en développement. Installer
Google Chrome ou Chromium, construire les actifs avec `mix assets.build`, et configurer
les variables d'environnement de stockage objet existantes :

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Exécuter `mix ecto.setup` , et `mix phx.server`. Une fois le stockage configuré, les graines donnent
le public `dev/glossia` projet un logo. Inspecter les `og:image` métadonnées sur un
page du tableau de bord pour obtenir l'adresse de son image signée.