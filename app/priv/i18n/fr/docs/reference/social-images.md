%{
  title: "Images sociales",
  summary:
    "Aperçus quotidiens du tableau de bord, rendu dans le navigateur, stockage et limites de trafic.",
  category: "référence",
  order: 30
}
---
Les pages du tableau de bord annoncent une image de 1200 × 630 via [Open Graph](https://ogp.me/)
et les métadonnées d'images de grande taille pour Twitter. Les projets publics incluent leur nom, section,
et le logo chargé. Les comptes publics reçoivent un aperçu spécifique à la section. Privés
comptes et paramètres personnels utilisent l'identité de marque générique de Glossia.

## Identité et durée de vie de l'image

Le digest de l'image comprend le contenu affiché, la révision du logo du projet, le modèle,
styles, polices, actif de marque, fichier de verrouillage de dépendances, et le jour actuel dans
[Temps universel coordonné](https://www.timeanddate.com/time/aboututc.html).
Modifier l'un de ceux-ci crée une nouvelle adresse. Trier les attributs et signer
à minuit maintient l'adresse complète stable tout au long de la journée.

La charge utile signée ne peut être modifiée par un visiteur. Elle est valide pendant deux jours,
mais seule la charge utile du jour actuel peut générer une image manquante. D'hier
les images stockées restent lisibles. Les paramètres de requête ne deviennent jamais des clés de stockage objet.

Les images générées avec succès sont persistées sous `og/images/<digest>.jpg` dans le configuré
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-bucket compatible.
Seule une réponse explicite d'objet manquant déclenche la génération. Échecs de stockage
renvoyez un échec temporaire non cacheable, sans démarrer Chrome. Le téléversement doit
réussir avant qu'une image nouvellement générée ne soit servie.

## Rendu et limites

Le rendu utilise Carta avec BrowseChrome, la même stack que le générateur d'image de Tuist.
Le pool supervisé contient deux navigateurs. Chaque rendu a un délai de 15 secondes ;
chaque instance d'application autorise au maximum douze nouveaux rendus par minute.
Les requêtes d'images stockées ne consomment pas cette allocation.

Cachex combine les requêtes concurrentes pour la même image et conserve jusqu'à 100
images pendant cinq minutes. Un verrouillage de conseil PostgreSQL non bloquant empêche
différentes répliques d'application de rendre la même image simultanément.
Les autres répliques reçoivent un échec temporaire et peuvent réessayer une fois que l'objet existe.

Le modèle associe un badge de la section Noora à l'arrière-plan chaleureux de Glossia, serif
un titre, un accent dégradé et un pied de page sobre. Source Serif 4 et Inter sont
incluses localement pour que les aperçus ne dépendent pas d'un service de police. Les polices et les rasters
logos sont intégrés. La politique de sécurité de contenu du document bloque les scripts et
ressources externes. Les logos sont chargés uniquement depuis le stockage des avatars de l'application
préfixe et sont limités à cinq millions d'octets, correspondant aux téléversements de projet.

## Comportement de réponse

| Résultat | Statut | Comportement du cache |
|---|---|---|
| Image stockée ou nouvellement persistée | 200 | Public, un jour, immuable |
| Signature invalide, expirée ou altérée | 404 | Aucun stockage |
| Image d'hier absente du stockage | 404 | Aucun stockage |
| Navigateur occupé, échec de rendu ou stockage indisponible | 503 | Aucun stockage ; réessayer après 60 secondes |
| Limite des requêtes d'origine dépassée | 429 | Aucun stockage ; intervalle de réessai dans la réponse |

L'origine autorise trente requêtes par minute par adresse client, y compris
les requêtes invalides.

## Cloudflare

La `social-images-rate-limit.yaml` ressource du dépôt d'infrastructure
correspond `GET` et `HEAD` les requêtes sous `/og/`, incluant les crawlers vérifiés. Il
permet vingt requêtes par dix secondes par adresse client et Cloudflare
localisation. Le dépassement de la limite bloque les requêtes pendant dix secondes. Le général
les règles de défi de page publique excluent ce chemin, de sorte que les crawlers d'images n'ont jamais besoin de
résoudre un défi navigateur.

de Cloudflare [comportement par défaut du cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
cache `.jpg` les réponses et respecte les en-têtes de cache d'origine. Conservez la requête signée
chaîne dans la clé de cache par défaut. N'appliquez pas une durée de cache override qui
cache les réponses d'erreur ou ignore `no-store`. La signature déterministe évite
une entrée de cache par requête de page.

Déployez la ressource d'infrastructure aux côtés de l'application. Assurez-vous que l'origine
n'est accessible que via l'ingress de confiance, car les adresses clientes acheminées
sont considérées comme fiables par le limiteur de requêtes existant. Le pool de navigateurs et le budget de rendu
limitent également les ratés distribués et les requêtes d'origine directe.

## Configuration locale

Définir `GLOSSIA_OG_IMAGES=true` pour activer le pool de navigateurs en développement. Installez
Google Chrome ou Chromium, et construisez les actifs avec `mix assets.build`, et configurez
les variables d'environnement de stockage objet existantes :

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Lancer `mix ecto.setup` et `mix phx.server`. Avec le stockage configuré, les modèles donnent
le public `dev/glossia` projetter un logo. Inspecter le `og:image` métadonnées sur un
page du tableau de bord pour obtenir son adresse d'image signée.