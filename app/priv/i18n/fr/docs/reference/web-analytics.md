%{
  title: "SDK Analytique",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité derrière l'analyse web Glossia.",
  category: "référence",
  section: "analytics",
  order: 1
}
---

## Point de terminaison des événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hébergé dérive `/v1/collect` de sa propre origine ; les intégrations de packages doivent définir `endpoint` explicitement.

Accepte un événement JSON depuis le SDK `@glossia/web`. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges de données malformées, afin que leSDK ne révèle jamais quels projets collectent des analytics.

Le projet est résolu par le domaine du site déclaré par le script. `d` est prééminent ; lorsqu'il est absent, le serveur bascule sur l'hôte de `u` (l'URL de la page) puis sur les en-têtes de requête `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site identifiant le projet (par ex. `example.com`). Envoyé par la bibliothèque du navigateur ; la résolution de basculement est décrite ci-dessus. |
| `n`   | string | Nom de l'événement. Valeur par défaut : `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Réferrer (`document.referrer`).                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | string | Langue réelle de la page (`document.documentElement.lang`). Vide si non déclarée. |
| `al`  | string | Langues de traduction séparées par des virgules provenant de `link[rel="alternate"][hreflang]`, excluant `x-default`. |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur de l'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car le point de terminaison n'accepte aucune authentification.

## Champs dérivés du serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et le User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage tournant quotidiennement de IP + UA + projet. Non traçable entre les jours.  |
| `country_code`    | Cloudflare / GeoIP | Code ISO 3166-1 alpha-2 provenant d'un en-tête `CF-IPCountry` de confiance, ou de l'adaptateur de géolocalisation IP configuré. Vide si aucun ne résout un pays. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Réferrer      | Hôte du réferrer, préfixe `www.`/`m.` supprimé.                        |
| `browser_language`| Langues     | Localisation locale la plus préférée normalisée (par ex. `pt-BR`).                    |
| `served_locale`   | Langue de la page | Normalisé `sl`, ou vide (affiché comme Non signalé) si elle n'a pas été collectée. |
| `has_locale_gap`  | Calculé      | `1` lorsqu'aucune des langues préférées de l'utilisateur ne correspond aux objectifs du projet, aux traductions annoncées (`al`) ou à la langue de la page (`sl`). Les préférences manquantes ne comptent pas comme un écart. |

### Résolution de l'adresse IP

Pour les requêtes provenant d'un pair d'ingrès privé, Glossia utilise l'en-tête `X-Real-IP` écrasé de nginx, au lieu de la première entrée contrôlée par l'appelant dans `X-Forwarded-For`. Les connexions publiques directes utilisent l'adresse de socket. Chez Hetzner, le chargeur de charge et nginx doivent tous deux activer le protocole PROXY afin que nginx reçoive l'adresse du visiteur au lieu de celle du chargeur. Les autres proxys inverses doivent également écraser `X-Real-IP` en utilisant une source authentifiée, au lieu d'un en-tête `X-Forwarded-For` entrant non restreint. La seule politique d'en-tête transféré du diagramme générique ne garantit pas cela. Les pairs privés sont une infrastructure de confiance, donc restreindre l'accès direct aux pods.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permet à `CF-Connecting-IP` de remplacer l'adresse canonique pour les requêtes provenant d'un pair d'ingrès privé. Il est **désactivé par défaut**, indépendamment de la confiance dans l'en-tête pays. Activez-le uniquement après que l'extrémité authentifie Cloudflare ou supprime les en-têtes falsifiés sur les requêtes contournant Cloudflare. Les déploiements DNS uniquement doivent le laisser désactivé. Cette adresse détermine également les limites de débit IP et la hachage des visiteurs quotidiens.

### Résolution du pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active le chemin rapide de `CF-IPCountry`. Il est **désactivé par défaut**. Activez-le uniquement après que l'origine authentifie Cloudflare, rejette les requêtes contournant Cloudflare, ou que l'ingrès supprime des copies non fiables de l'en-tête. Le paramètre de géolocalisation IP Cloudflare doit également être activé pour la zone. `CF-Connecting-IP`, `CF-Ray` et nginx `use-forwarded-headers` ne peuvent pas authentifier une requête par eux-mêmes.

Lorsque la confiance dans les en-têtes est activée, un code pays ISO valide unique est utilisé immédiatement, sans recherche d'IP ou accès au cache. La valeur actuelle de l'extrémité prime toujours sur toute recherche mise en cache. Les codes manquants, en double, malformés ou inconnus, y compris les valeurs `XX` (inconnu) et `T1` (Tor) de Cloudflare, sont remplacés par l'adaptateur de géolocalisation configuré.

Sans une base de données MaxMind configurée, les recherches de repli utilisent `api.ipapi.is` puis `api.country.is` en cas d'échec de la requête principale ou de retour de pays non reconnu. Chaque requête a un temps de connexion et de réponse d'une seconde avec des redémarrages désactivés. Les résultats réussis d'un fournisseur sont mis en cache par Cachex pendant 24 heures, avec une limite de taille planifiée de 100 000 entrées et une expiration automatique et récupération. `Cachex.fetch/3` regroupe les défaillances concurrentes pour la même IP en un seul résolveur. Les échecs ne sont pas mis en cache. Les adresses privées et réservés ne sont pas envoyées à aucun fournisseur.

### Langue de la page manquante

Le tableau de bord affiche **Non signalé** lorsqu'un événement n'a pas de `sl`. Cela inclut les événements collectés par les versions plus anciennes du traceur et les pages sans attribut HTML `lang`. La langue de la page n'est pas déduite des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées collectées à l'époque ; les nouvelles versions du traceur ne les comblent pas rétrospectivement.

## Modèle de confidentialité

- **Aucun identifiant transversal aux sessions persistant.** Le SDK ne définit pas de cookies et stocke uniquement un ID de session par onglet dans `sessionStorage`, que le navigateur supprime à la fermeture.
- **Aucune empreinte numérique.** Les empreintes de Canvas, WebGL, polices et audio ne sont pas collectées. Le hachage serveur tournant quotidiennement fournit des uniques sans elles.
- **Aucun identifiant brut persistant.** IP et User-Agent sont lus une fois, hachés avec un secret serveur et un sel quotidien, puis rejetés.
- **Périmètre par projet.** Le même navigateur sur deux projets génère des identifiants de visiteur non apparentés, donc les visiteurs ne peuvent pas être suivis entre clients Glossia.
