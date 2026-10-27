%{
  title: "Analytics SDK",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité sous-jacent aux analyses web de Glossia.",
  category: "Référence",
  section: "analytics",
  order: 1
}
---

## Point de terminaison d'événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hébergé dérive `/v1/collect` de son origine propre ; les intégrations de packages doivent définir `endpoint` explicitement.

Accepte un événement JSON depuis le `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges de données malformées, afin que le SDK ne révèle jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site déclaré par le fragment. `d` est l'autorité ; lorsqu'il est absent, le serveur recourt à l'hôte de `u` (l'URL de la page) puis à la requête `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | chaîne | Domaine du site qui identifie le projet (par exemple `example.com`). Envoyé par la bibliothèque de navigateur ; la résolution de secours est décrite ci-dessus. |
| `n`   | chaîne | Nom de l'événement. Par défaut `pageview`.                          |
| `u`   | chaîne | URL de la page (`location.href`).                                  |
| `r`   | chaîne | Référent (`document.referrer`).                              |
| `l`   | chaîne | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | chaîne | Langue réelle de la page (`document.documentElement.lang`). Vide si non déclarée. |
| `al`  | chaîne | Langues de traduction séparées par des virgules depuis `link[rel="alternate"][hreflang]`, excluant `x-default`. |
| `cl`  | chaîne | Langue choisie explicitement, ou vide lorsque aucune sélection n'a été observée. Le SDK canonicalise les balises BCP 47 et limite l'entrée à 64 caractères. |
| `tz`  | chaîne | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | nombre | Largeur de l'écran en pixels CSS.                                  |
| `sid` | chaîne | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouverte (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune authentification.

## Sélection de langue explicite

`selectLanguage(language)` est disponible comme exportation nommée, sur l'exportation par défaut du SDK, et sur le global `glossia` du script hébergé. Appelez-le après l'initialisation depuis un gestionnaire d'action utilisateur, avant la navigation. Les balises de langue invalides et les appels avant l'initialisation sont ignorés.

La méthode émet un événement `language_selection` immédiatement. Son `sl` décrit toujours la page actuelle, et non la destination. Les événements suivants incluent le choix dans `cl` jusqu'à ce qu'un autre choix explicite le remplace. Sans sélection observée, `cl` est vide. Le choix est stocké sous la forme `__glossia_selected_language` dans le `sessionStorage` d'origine identique, par onglet ; lorsque le stockage échoue, il est conservé uniquement en mémoire jusqu'au déchargement.

Pour les liens, `data-glossia-language="zh-Hans"` permet le suivi délégué des clics primaires de confiance, non modifiés, y compris l'activation au clavier. Les clics scriptés, les clics déjà annulés, les téléchargements, les liens cross-origin, et les liens ciblant un autre onglet ou cadre sont ignorés. L'auditeur s'exécute dans la phase de capture avant la navigation des routeurs, n'interrompt pas la navigation, et gère également les liens insérés dynamiquement. Utilisez soit l'annotation, soit l'API pour une action, mais non les deux.

Il s'agit d'un signal d'intention signalé par le client, mais pas de preuve que la navigation a réussi. Les changements d'URL, les redirections et les changements de langue HTML ne sont pas interprétés comme des choix. La sélection ne remplace pas `l` ou `sl`. Une sélection valide ne prime sur les préférences du navigateur que lors du calcul de `has_locale_gap` : la langue choisie doit correspondre à une cible de projet, une traduction annoncée (`al`), ou la langue réelle de la page (`sl`). Le choix lui-même n'est pas une preuve de disponibilité. Le correspondage utilise des correspondances exactes ou de base normalisées, tout comme pour les préférences du navigateur.

Par exemple, un visiteur privilégiant le japonais qui choisit explicitement une traduction anglaise disponible n'a pas de lacune. Un visiteur privilégiant l'anglais qui choisit un japonais indisponible a toujours une lacune, même sur une page anglaise. Un événement de sélection émis avant la navigation conserve la `sl` de la page actuelle ; la langue de destination peut être reconnue via les cibles de projet ou `al` sans supposer la navigation réussie.

Les choix manquants, malformés ou démesurés recourent aux préférences du navigateur. Si aucun choix ni préférences de navigateur ne sont connus, il n'y a pas de lacune. Les totaux du tableau de bord et les badges lisent le indicateur stocké par événement. Les indicateurs historiques, y compris ceux collectés avant que les choix n'affectent le calcul de la lacune, ne sont pas recalculés : les traductions annoncées historiques et les préférences complètes du navigateur ne sont pas stockées.

## Champs dérivés du serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. IP brute et User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage en rotation quotidienne d'IP + UA + projet. N'importe pas de lien entre les jours.  |
| `country_code`    | Cloudflare / GeoIP | Code ISO 3166-1 alpha-2 issu d'un en-tête `CF-IPCountry` de confiance, ou de l'adaptateur de géolocalisation IP configuré. Vide si ni l'un ni l'autre ne résout un pays. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Référent      | Hôte du référent, `www.`/`m.` initial supprimé.                        |
| `browser_language`| Langues     | Locale normalisée préférée (par exemple, `pt-BR`).                    |
| `served_locale`   | Langue de la page | Normalisé `sl` , ou vide si n'a pas été collecté. Les lignes avec une langue de la page vide sont omises du récapitulatif des préférences de navigateur. |
| `selected_locale` | Choix explicite | Normalisé `cl` , ou vide pour des entrées manquantes, malformées ou trop grandes. Stocké séparément des préférences du navigateur et de la langue de la page. |
| `has_locale_gap`  | Calculé      | `1` lorsqu'un choix explicite valide n'a pas de correspondance parmi les cibles de projet, les traductions annoncées (`al`), ou la langue de la page (`sl`). Sans choix valide, `1` uniquement lorsque les préférences du navigateur ne sont pas vides et qu'aucune ne correspond. |

### Résolution de l'IP client

Pour les requêtes provenant d'un pair d'ingress privé, Glossia utilise l'en-tête `X-Real-IP` écrasé de nginx, pas l'entrée du premier contrôlée par l'appelant dans `X-Forwarded-For`. Les connexions publiques directes utilisent l'adresse du socket. Sur Hetzner, à la fois le load balancer et nginx doivent activer le protocole PROXY afin que nginx reçoive l'adresse du visiteur plutôt que l'adresse du load balancer. D'autres reverse proxies doivent également écraser `X-Real-IP` en utilisant une source authentifiée, pas un en-tête `X-Forwarded-For` entrant sans restriction. La politique de forwarded-header du graphique générique ne garantit pas cela à elle seule. Les pairs privés sont une infrastructure de confiance, restreignez donc l'accès direct aux pods.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` permet à `CF-Connecting-IP` de remplacer l'adresse canonique pour les requêtes provenant d'un pair d'ingress privé. Il est **désactivé par défaut**, indépendamment de la confiance de l'en-tête pays. Activez-le uniquement après que l'edge ait authentifié Cloudflare ou éliminé les en-têtes forgés sur les requêtes contournant Cloudflare. Les déploiements DNS uniquement doivent le laisser désactivé. Cette adresse sert également de clé pour les limites d'IP et le hachage quotidien du visiteur.

### Résolution du pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active la voie rapide `CF-IPCountry`. Il est **désactivé par défaut**. Activez-le uniquement après que l'origine ait authentifié Cloudflare, rejeté les requêtes qui contournent Cloudflare, ou supprimé les copies non fiables de l'en-tête à l'ingress. Le paramètre IP Geolocation de Cloudflare doit également être activé pour la zone. `CF-Connecting-IP`, `CF-Ray` et `use-forwarded-headers` de nginx n'authentifiquent pas une requête seuls.

Lorsque la confiance d'en-tête est activée, un code pays ISO valide unique est utilisé immédiatement, sans recherche IP ou accès au cache. La valeur actuelle de l'edge prime toujours sur toute recherche en cache. Les codes manquants, dupliqués, malformés ou inconnus, y compris les valeurs `XX` (inconnu) et `T1` (Tor) de Cloudflare, retombent sur l'adaptateur de géolocalisation configuré.

Sans une base de données MaxMind configurée, les recherches de repli utilisent `api.ipapi.is`, puis `api.country.is` lorsque la requête principale échoue ou ne renvoie aucun pays reconnu. Chaque requête a un délai de connexion et de réponse d'une seconde avec les réessais désactivés. Les résultats réussis de l'un des deux fournisseurs sont mis en cache par Cachex pendant 24 heures, avec une limite de taille planifiée de 100 000 entrées et une récupération automatique d'expiration. `Cachex.fetch/3` regroupe les erreurs simultanées pour la même IP en un seul résolveur. Les échecs ne sont pas mis en cache. Les adresses privées et réservées ne sont pas envoyées à l'un ou l'autre fournisseur.

### Langue manquante de la page

Le récapitulatif des préférences de navigateur omet les événements sans `sl`. Cela inclut les événements collectés par des versions plus anciennes de traceurs et des pages sans attribut HTML `lang`. Ces événements contribuent toujours au trafic global. La langue de la page n'est pas déduite des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées collectées à l'époque ; les nouvelles versions de traceurs ne les backfillent pas.

## Modèle de confidentialité

- **Aucun identifiant de session croisée permanent.** Le SDK ne définit pas de cookies et ne stocke qu'un identifiant de session par onglet et une langue explicitement sélectionnée dans `sessionStorage`, que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Canvas, WebGL, police et empreintes audio ne sont pas collectés. Le hachage du serveur en rotation quotidienne fournit des uniques sans ces derniers.
- **Aucun identifiant brut persisté.** L'IP et le User-Agent sont lus une seule fois, hachés avec un secret serveur et un sel quotidien, puis jetés.
- **Isolation par projet.** Le même navigateur sur deux projets génère des identifiants de visiteurs non associés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.
