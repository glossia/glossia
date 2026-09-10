%{
  title: "Images sociales",
  summary:
    "Aperçus quotidiens du tableau de bord, rendu navigateur, stockage et limites de trafic.",
  category: "référence",
  order: 30
}
---
Les pages du tableau de bord annoncent une image de 1200 × 630 via [Open Graph](https://ogp.me/)
et les métadonnées d'images grandes de Twitter. Les projets publics incluent leur nom, leur section,
et un logo chargé. Les comptes publics reçoivent un aperçu spécifique à la section. Privés
les comptes et les paramètres personnels utilisent un branding générique de Glossia.

## Identité de l'image et durée de vie

Le digest de l'image inclut le contenu affiché, la révision du logo du projet, le modèle,
les styles, les polices, l'actif de marque, le fichier de verrouillage des dépendances, et le jour actuel dans
[Temps universel coordonné](https://www.timeanddate.com/time/aboututc.html).
Modifier l'un de ces éléments crée une nouvelle adresse. Le tri des attributs et la signature
à minuit maintient l'adresse complète stable tout au long de la journée.

La charge utile signée ne peut être modifiée par un visiteur. Elle est valide pendant deux jours,
mais seule la charge utile du jour présent peut générer une image manquante. Hier
les images stockées restent lisibles. Les paramètres de requête ne deviennent jamais des clés de stockage d'objets.

Les images générées avec succès sont persistées sous `og/images/<digest>.jpg` dans la configuration
[Service Simple de Stockage Amazon](https://aws.amazon.com/s3/)-bucket compatible.
Seule une réponse explicite d'objet manquant déclenche la génération. Les échecs de stockage
retournent une erreur temporaire non mise en cache, sans lancer Chrome. Le téléversement doit
réussir avant qu'une image nouvellement rendue ne soit servie.

## Rendu et limites

Le rendu utilise Carta avec BrowseChrome, la même pile que le moteur de rendu d'images de Tuist.
Le pool supervisé contient deux navigateurs. Chaque rendu dispose d'un délai de 15 secondes ;
chaque instance d'application autorise au maximum douze nouveaux rendus par minute.
Les requêtes d'images stockées ne consomment pas cette allocation.

Cachex combine des requêtes concurrentes pour la même image et conserve jusqu'à 100
images pour cinq minutes. Un verrou conseil PostgreSQL non bloquant empêche
les différentes répliques d'application de rendre simultanément la même image.
Les autres réplications subissent une erreur temporaire et peuvent réessayer dès que l'objet existe.

Le modèle associe un badge de section Noora avec l'arrière-plan chaleureux de Glossia, serif
entête, accent dégradé et pied de page sobre. Source Serif 4 et Inter sont
incluses localement de sorte que les aperçus ne dépendent pas d'un service de polices. Polices et images raster
les logos sont intégrés. La politique de sécurité du contenu du document bloque les scripts et
des ressources externes. Les logos sont chargés uniquement depuis le stockage des avatars de l'application
préfixe et sont limités à cinq millions d'octets, correspondant aux téléversements de projet.

## Comportement de réponse

| Résultat | Statut | Comportement du cache |
|---|---|---|
| Image stockée ou nouvellement persistée | 200 | Publique, une journée, immuable |
| Signature invalide, expirée ou modifiée | 404 | Pas de stockage |
| Image d'hier manquante dans le stockage | 404 | Pas de stockage |
| Navigateur occupé, échec de rendu ou stockage indisponible | 503 | Pas de stockage ; réessayez après 60 secondes |
| Contingent de requêtes d'origine dépassé | 429 | Pas de stockage ; intervalle de réessai dans la réponse |

L'origine autorise trente requêtes par minute par adresse client, y compris
les requêtes invalides.

## Cloudflare

La `social-images-rate-limit.yaml` ressource dans le référentiel d'infrastructure
correspond `GET` et `HEAD` requêtes sous `/og/`, y compris les crawlers vérifiés. Elle
permet vingt requêtes par dix secondes par adresse client et Cloudflare
localisation. Le dépassement de la limite bloque les requêtes pendant dix secondes. Le général
les règles du défi de page publique excluent ce chemin, de sorte que les robots d'images n'aient jamais besoin de
résoudre un défi du navigateur.

de Cloudflare [comportement par défaut de mise en cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
met en cache `.jpg` des réponses et respecte les en-têtes de cache d'origine. Conservez la requête signée
chaîne dans la clé de cache par défaut. Ne définissez pas une durée de cache qui prend le dessus qui
cache les réponses d'erreur ou ignore `no-store`. La signature déterministe évite
une entrée de cache par requête de page.

Déployez la ressource d'infrastructure aux côtés de l'application. Assurez-vous que l'origine
est accessible uniquement via l'ingress de confiance, car les adresses clientes transférées
sont considérées de confiance par le limiteur de requêtes existant. Le pool de navigateurs et le budget de rendu
limitent également les manques distribués et les requêtes d'origine directe.

## Configuration locale

Définir `GLOSSIA_OG_IMAGES=true` pour activer le pool de navigateurs en développement. Installer
Google Chrome ou Chromium, compilé les actifs avec `mix assets.build`, et configurer
les variables d'environnement de stockage objet existantes :

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Exécuter `mix ecto.setup` et `mix phx.server`. Avec le stockage configuré, les graines donnent
le public `dev/glossia` projet un logo. Inspectez les `og:image` métadonnées sur un
page du tableau de bord pour récupérer l'adresse de l'image signée.