%{
  title: "Images sociales",
  summary:
    "Aperçus quotidiens du tableau de bord, rendu navigateur, stockage et limites du trafic.",
  category: "référence",
  order: 30
}
---
Les pages du tableau de bord annoncent une image de 1200 × 630 via [Open Graph](https://ogp.me/)
et les métadonnées Twitter d'images en grand format. Les projets publics incluent leur nom, section,
et le logo téléchargé. Les comptes publics reçoivent un aperçu spécifique à la section. Privés
comptes et paramètres personnels utilisent une marque Glossia générique.

## Identité et durée de vie des images

Le digest d'image comprend le contenu affiché, la révision du logo du projet, le modèle,
styles, polices, actif de marque, verrouillage des dépendances, et le jour actuel dans
[Temps universel coordonné](https://www.timeanddate.com/time/aboututc.html).
Modifier l'un de ces éléments crée une nouvelle adresse. Trier les attributs et signer
à minuit conserve l'adresse complète stable tout au long de la journée.

La charge utile signée ne peut pas être modifiée par un visiteur. Elle est valide pour deux jours,
mais uniquement la charge utile du jour actuel peut générer une image manquante. Hier
les images stockées restent lisibles. Les paramètres de requête ne deviennent jamais des clés de stockage objet.

Les images générées avec succès sont persistées sous `og/images/<digest>.jpg` dans le configuré
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)- bucket compatible.
Une réponse explicite missing-object déclenche la génération. Les échecs de stockage
retournent une erreur temporaire non mettable en cache, sans lancer Chrome. Un téléversement doit
réussir avant qu'une image nouvellement rendue ne soit servie.

## Rendu et limites

Le rendu utilise Carta avec BrowseChrome, la même pile que le générateur d'image de Tuist.
La piscine supervisée contient deux navigateurs. Chaque rendu a un délai de 15 secondes;
chaque instance d'application autorise au plus douze nouveaux rendus par minute.
Les requêtes d'images stockées ne consomment pas cette allocation.

Cachex regroupe les requêtes concurrentes pour la même image et conserve jusqu'à 100
images pendant cinq minutes. Un verrou conseil non bloquant de PostgreSQL empêche
les différentes répliques d'application de rendre la même image simultanément.
Les autres répliques reçoivent un échec temporaire et peuvent réessayer une fois que l'objet existe.

Le modèle associe un badge de section Noora à l'arrière-plan chaleureux de Glossia, en police serif
en-tête, accent de dégradé et pied de page sobre. Source Serif 4 et Inter sont
inclus localement de sorte que les aperçus ne dépendent pas d'un service de police. Polices et raster
les logos sont intégrés. La politique de sécurité du contenu du document bloque les scripts et
ressources externes. Les logos sont chargés uniquement depuis le stockage des avatars de l'application
préfixe et sont limités à cinq millions d'octets, correspondant aux téléversements de projet.

## Comportement de réponse

| Résultat | Statut | Comportement du cache |
|---|---|---|
| Image stockée ou nouvellement persistée | 200 | Publique, un jour, immuable |
| Signature invalide, expirée ou altérée | 404 | Sans stockage |
| Image d'hier manquante dans le stockage | 404 | Sans stockage |
| Navigateur occupé, échec de rendu ou stockage indisponible | 503 | Sans stockage ; réessayer après 60 secondes |
| Limite des requêtes à l'origine dépassée | 429 | Sans stockage ; intervalle de réessai dans la réponse |

L'origine autorise trente requêtes par minute par adresse client, y compris
des requêtes invalides.

## Cloudflare

La `social-images-rate-limit.yaml` ressource du dépôt d'infrastructure
correspond à `GET` et `HEAD` des requêtes sous `/og/`, y compris les crawlers vérifiés. Elle
permet vingt requêtes par dix secondes par adresse du client et Cloudflare
localité. Le dépassement de la limite bloque les requêtes pendant dix secondes. Le général
Les règles de défi des pages publiques excluent ce chemin, si bien que les crawlers d'images n'ont
jamais besoin de résoudre un défi du navigateur.

de Cloudflare [Comportement par défaut de mise en cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
cache les `.jpg` réponses et respecte les en-têtes de cache d'origine. Conservez la
requête signée dans la clé de cache par défaut. N'appliquez pas une durée de cache écrasante qui
cache les réponses d'erreur ou ignore `no-store`. La signature déterministe évite
une entrée de cache par requête de page.

Déployez la ressource d'infrastructure aux côtés de l'application. Assurez-vous que l'origine
est accessible uniquement via l'ingress de confiance, car les adresses client
sont considérées de confiance par le limiteur de requêtes existant. Le pool de navigateurs et le budget de rendu
limitent également les manques distribués et les requêtes d'origine directe.

## Configuration locale

Définir `GLOSSIA_OG_IMAGES=true` pour activer le pool de navigateurs en développement. Installez
Google Chrome ou Chromium, construisez des ressources avec `mix assets.build`, et configurer
les variables d'environnement de stockage d'objets existantes :

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Exécuter `mix ecto.setup` et `mix phx.server`. Avec le stockage configuré, les graines fournissent
le public `dev/glossia` projet un logo. Inspectez les `og:image` métadonnées sur un
page du tableau de bord pour obtenir son adresse d'image signée.