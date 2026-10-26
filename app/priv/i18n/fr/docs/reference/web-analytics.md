%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité sous-jacent aux analyses web Glossia.",
  category: "référence",
  section: "analytics",
  order: 1
}
---

## Endpoint d'événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hébergé dérive `/v1/collect` de son propre origine ; les intégrations de paquets doivent définir `endpoint` explicitement.

Accepte un événement JSON venant du SDK `@glossia/web`. Répond toujours `202 Accepted`, y compris pour des domaines inconnus ou des charges malformées, de sorte que le SDK ne révèle jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site que le fragment déclare. `d` est l'autorité ; lorsqu'il est absent, le serveur recourt au hôte de `u` (l'URL de la page), puis à l'en-tête `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site qui identifie le projet (par exemple `example.com`). Envoyé par la bibliothèque de navigateur ; le mécanisme de repli est décrit ci-dessus. |
| `n`   | string | Nom de l'événement. Par défaut `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Référent (`document.referrer`).                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | string | Langue réelle de la page (`document.documentElement.lang`). Vide si non déclarée. |
| `al`  | string | Langues de traduction séparées par des virgules issues de `link[rel="alternate"][hreflang]`, excluant `x-default`. |
| `cl`  | string | Langue choisie explicitement, ou vide si aucune sélection n'a été observée. Le SDK normalise les balises BCP 47 et limite l'entrée à 64 caractères. |
| `tz`  | string | Fuse horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car le point de terminaison n'accepte aucune authentification.

## Sélection explicite de la langue

Le nom `selectLanguage(language)` est disponible en export nommé, dans l'export SDK par défaut, et dans la variable `glossia` globale du script hébergé. Appelez-le après l'initialisation depuis un gestionnaire d'action utilisateur, avant la navigation. Les balises de langue invalides et les appels avant l'initialisation sont ignorés.

La méthode envoie immédiatement un événement `language_selection`. Son `sl` décrit toujours la page actuelle, pas la destination. Les événements suivants incluent le choix dans `cl` jusqu'à ce qu'un autre choix explicite le remplace. Sans sélection observée, `cl` est vide. Le choix est stocké sous la clé `__glossia_selected_language` dans le stockage d'origine même, par onglet `sessionStorage` ; en cas d'échec de stockage, il est conservé uniquement en mémoire jusqu'à la décharge.

Pour les liens, `data-glossia-language="zh-Hans"` active le suivi délégué des clics primaires sûrs et non modifiés, y compris l'activation du clavier. Les clics scriptés, les clics déjà annulés, les téléchargements, les liens cross-origin, et les liens ciblant un autre onglet ou un cadre sont ignorés. L'écouteur s'exécute dans la phase capture avant la navigation des routeurs, ne bloque pas la navigation, et gère aussi les liens insérés dynamiquement. Utilisez soit l'annotation, soit l'API pour une action, pas les deux.

Il s'agit d'un signal d'intention rapporté par le client, pas d'une preuve que la navigation a réussi. Les changements d'URL, les redirections et les changements de langue HTML ne sont pas interprétés comme des choix. La sélection ne recouvre pas `l` ou `sl`, ni ne modifie actuellement `has_locale_gap` ou les insignes du tableau de bord.

## Champs dérivés par le serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et l'User-Agent ne sont jamais conservés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage rotatif quotidien de l'IP + UA + projet. Non rattachable à travers les jours.  |
| `country_code`    | Cloudflare / GeoIP | Code ISO 3166-1 alpha-2 issu d'un en-tête `CF-IPCountry` de confiance, ou de l'adaptateur de géolocalisation IP configuré. Vide si aucun ne résout un pays. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte minuscule.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Referrer      | Hôte Referrer, `www.`/`m.` initial supprimé.                        |
| `browser_language`| Langues     | Langue locale normalisée la plus préférée (par exemple `pt-BR`).                    |
| `served_locale`   | Langue de la page | `sl` normalisé, ou vide s'il n'a pas été recueilli. Les lignes avec une langue de la page vide sont omises de la ventilation par langue du navigateur. |
| `selected_locale` | Choix explicite | `cl` normalisé, ou vide pour des entrées manquantes, malformées ou de taille excessive. Stocké séparément des préférences du navigateur et de la langue de la page. |
| `has_locale_gap`  | Calculé      | `1` lorsque aucune des langues préférées du visiteur ne correspond aux cibles du projet, aux traductions annoncées (`al`) ou à la langue de la page (`sl`). Les préférences manquantes ne constituent pas un manquement. |

### Résolution de l'IP client

Pour les requêtes provenant d'un pair d'ingress privé, Glossia utilise l'en-tête `X-Real-IP` écrasé de nginx, non la première entrée contrôlée par l'appelant dans `X-Forwarded-For`. Les connexions publiques directes utilisent l'adresse du socket. Chez Hetzner, le chargeur de charge et nginx doivent tous deux activer le protocole PROXY afin que nginx reçoive l'adresse du visiteur au lieu de celle du chargeur de charge. D'autres proxies inverses doivent également écraser `X-Real-IP` avec une source authentifiée, non un en-tête inbound `X-Forwarded-For` illimité. La seule politique d'en-tête forwarded du graphique générique ne garantit pas cela. Les pairs privés sont une infrastructure de confiance, donc limiter l'accès direct au pod.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permet à `CF-Connecting-IP` de surcharger l'adresse canonique pour les requêtes provenant d'un pair d'ingress privé. Il est **désactivé par défaut**, indépendamment de la confiance de l'en-tête de pays. Activez-le uniquement après que l'edge authentifie Cloudflare ou élimine les en-têtes forgés sur les requêtes contournant Cloudflare. Les déploiements DNS uniquement doivent le laisser désactivé. Cette adresse sert également de clé pour les limites de taux IP et l'hachage des visiteurs quotidiens.

### Résolution des pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active la voie rapide `CF-IPCountry`. Il est **désactivé par défaut**. Activez-le uniquement après que l'origine authentifie Cloudflare, rejette les requêtes contournant Cloudflare, ou après que l'ingress élimine les copies non fiables de l'en-tête. Le paramètre de géolocalisation IP de Cloudflare doit également être activé pour la zone. `CF-Connecting-IP`, `CF-Ray` et l'exécution `use-forwarded-headers` de nginx n'authentifient pas une requête à eux seuls.

Lorsque la confiance de l'en-tête est activée, un code pays ISO valide unique est utilisé immédiatement, sans requête d'IP ou accès cache. La valeur actuelle du bord prend toujours le dessus sur toute recherche en cache. Codes manquants, dupliqués, malformés ou inconnus, y compris les valeurs Cloudflare `XX` (inconnu) et `T1` (Tor), retombent sur l'adaptateur de géolocalisation configuré.

Sans base de données MaxMind configurée, les requêtes de repli utilisent `api.ipapi.is`, puis `api.country.is` si la requête principale échoue ou ne renvoie pas de pays reconnu. Chaque requête a un délai de connexion et réponse d'une seconde avec réessai désactivé. Les résultats réussis de l'un ou l'autre fournisseur sont mis en cache par Cachex pendant 24 heures, avec une limite de taille planifiée de 100 000 entrées et une récupération automatique à l'expiration. `Cachex.fetch/3` condense les manques concurrents pour la même IP en un seul résolveur. Les échecs ne sont pas mis en cache. Les adresses privées et réservées ne sont pas envoyées à l'un ou l'autre fournisseur.

### Langue de la page manquante

La ventilation par langue du navigateur omet les événements sans `sl`. Cela inclut les événements recueillis par des versions de trackers plus anciennes et les pages sans attribut HTML `lang`. Ces événements contribuent toujours au trafic global. La langue de la page n'est pas déduite des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées recueillies à l'époque ; les nouvelles versions de trackers ne les reconstituent pas.

## Modèle de confidentialité

- **Aucun identifiant de session croisée persistant.** L'SDK ne définit pas de cookies et stocke uniquement un ID de session par onglet et une langue explicitement sélectionnée dans `sessionStorage`, que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Les empreintes Canvas, WebGL, polices et audio ne sont pas recueillies. Le hachage serveur rotatif quotidien fournit des uniques sans elles.
- **Aucun identifiant brut persistant.** L'IP et l'User-Agent sont lus une fois, hachés avec un secret serveur et un sel quotidien, puis éliminés.
- **Portée par projet.** Le même navigateur sur deux projets génère des identifiants de visiteurs sans lien, donc les visiteurs ne peuvent être suivis à travers les clients Glossia.
