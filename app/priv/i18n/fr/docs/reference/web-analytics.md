%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité sous-jacent à l'analyse web de Glossia.",
  category: "Référence",
  section: "analytics",
  order: 1
}
---

## Endpoint d'événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hébergé déduit `/v1/collect` de son propre origine ; les intégrations de packages doivent définir `endpoint` explicitement.

Accepte un événement JSON du SDK `@glossia/web`. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les payloads malformés, afin que le SDK ne divulgue jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site déclaré. `d` est déterminant ; en son absence, le serveur recourt à l'hôte de `u` (l'URL de la page) puis à la requête `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site identifiant le projet (par ex. `example.com`). Envoyé par la bibliothèque du navigateur ; la résolution de repli est décrite ci-dessus. |
| `n`   | string | Nom de l'événement. Par défaut `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Réferrer (`document.referrer`).                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | string | Langue réelle de la page (`document.documentElement.lang`). Vide si non déclarée. |
| `al`  | string | Langues de traduction séparées par des virgules issues de `link[rel="alternate"][hreflang]`, excluant `x-default`. |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune identification.

## Champs dérivés par le serveur

Ces champs sont calculés à l'ingestion et stockés côté serveur. L'IP brute et l'agent utilisateur ne sont jamais conservés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage quotidiennement rotatif de l'IP + UA + projet. Non traçable entre les jours.  |
| `country_code`    | Cloudflare / GeoIP | Code ISO 3166-1 alpha-2 issu d'une entête `CF-IPCountry` de confiance, ou de l'adaptateur de géolocalisation IP configuré. Vide lorsque l'un et l'autre ne résolvent pas un pays. |
| `device`          | agent utilisateur    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | agent utilisateur    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | agent utilisateur    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant de chemin.                                                     |
| `referrer_source` | Réferrer      | Hôte du référent, `www.`/`m.` en tête effacés.                        |
| `browser_language`| Langues     | Locale normalisée la plus préférée (par ex. `pt-BR`).                    |
| `served_locale`   | Langue de la page | Normalisé `sl`, ou vide (affiché comme Non signalé) s'il n'a pas été collecté. |
| `has_locale_gap`  | Calculé      | `1` lorsque aucune des langues préférées du visiteur ne correspond aux cibles de projet, aux traductions annoncées (`al`), ou à la langue de la page (`sl`). Les préférences manquantes ne comptent pas pour un écart. |

### Résolution de l'IP client

Pour les requêtes provenant d'un pair d'ingress privé, Glossia utilise l'entête `X-Real-IP` écrasée d'nginx, pas la première entrée contrôlée par l'appelant dans `X-Forwarded-For`. Les connexions publiques directes utilisent l'adresse de socket. Sur Hetzner, le chargeur de charge et nginx doivent activer le protocole PROXY, afin que nginx reçoive l'adresse du visiteur plutôt que celle du chargeur de charge. D'autres proxy inverses doivent également écraser `X-Real-IP` en utilisant une source authentifiée, pas une entête `X-Forwarded-For` entrante non restreinte. La politique d'en-tête-avancé du graphique générique ne garantit pas cela par elle-même. Les pairs privés sont une infrastructure de confiance, restreignez donc l'accès direct aux pods.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permet à `CF-Connecting-IP` de surclasser l'adresse canonique pour les requêtes provenant d'un pair d'ingress privé. Il est **disabled by default**, indépendamment de la confiance de l'entête-pays. Activez-le uniquement après que le bord ait authentifié Cloudflare ou après suppression des entêtes falsifiées sur les requêtes contournant Cloudflare. Les déploiements DNS uniquement doivent le laisser désactivé. Cette adresse détermine également les limites de taux d'IP et le hachage du visiteur quotidien.

### Résolution du pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active la voie rapide `CF-IPCountry`. Il est **disabled by default**. Activez-le uniquement après que l'origine ait authentifié Cloudflare, rejeté les requêtes contournant Cloudflare, ou l'ingress ait supprimé les copies non fiables de l'entête. Le paramétrage de Géolocalisation IP de Cloudflare doit aussi être activé pour la zone. `CF-Connecting-IP`, `CF-Ray` et `use-forwarded-headers` d'nginx n'authentifient pas une requête seuls.

Lorsque la confiance d'entête est activée, un code pays ISO valide est utilisé immédiatement, sans recherche d'IP ou d'accès au cache. La valeur actuelle du bord a toujours la priorité sur toute recherche en cache. Les codes manquants, en double, malformés ou inconnus, incluant `XX` (inconnu) et `T1` (Tor) de Cloudflare, retombent sur l'adaptateur de géolocalisation configuré.

Sans base de données MaxMind configurée, les recherches de repli utilisent `api.ipapi.is`, puis `api.country.is` lorsque la requête principale échoue ou ne retourne aucun pays reconnu. Chaque requête dispose d'un délai de connexion et de réponse d'une seconde sans reprises. Les résultats réussis de l'un ou l'autre fournisseur sont mis en cache par Cachex pendant 24 heures, avec une limite de taille planifiée à 100 000 entrées et une réclamation d'expiration automatique. `Cachex.fetch/3` regroupe les pannes concurrentes pour une même IP en un seul résolveur. Les échecs ne sont pas mis en cache. Les adresses privées et réservées ne sont envoyées à aucun fournisseur.

### Langue de la page manquante

Le tableau montre **Not reported** lorsqu'un événement n'a pas de `sl`. Cela inclut les événements collectés par des versions de tracker plus anciennes et les pages sans attribut HTML `lang`. La langue de la page n'est pas inférée des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées collectées à l'époque ; les nouvelles versions de tracker ne les comblent pas.

## Modèle de confidentialité

- **Identifiant transversal de session persistant inexistant.** Le SDK ne définit aucun cookie et stocke seulement un ID de session par onglet dans `sessionStorage`, effacé par le navigateur à la fermeture.
- **Aucune empreinte.** Les empreintes Canvas, WebGL, police et audio ne sont pas collectées. Le hachage quotidien du serveur fournit l'unicité sans elles.
- **Aucun identifiant brut persistant.** L'IP et l'agent utilisateur sont lus une fois, hachés avec un secret de serveur et un sel quotidien, puis abandonnés.
- **Étournement projet par projet.** Un même navigateur sur deux projets génère des identifiants de visiteur sans rapport, donc les visiteurs ne peuvent pas être suivis entre les clients Glossia.
