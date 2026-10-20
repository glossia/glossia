%{
  title: "SDK analytique",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité derrière l'analyse web de Glossia.",
  category: "Référence",
  section: "analytics",
  order: 1
}
---

## Endpoint d'événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hébergé tire `/v1/collect` de son propre origine ; les intégrations de paquet doivent configurer `endpoint` explicitement.

Accepte un événement JSON provenant du SDK `@glossia/web`. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges malformées, de sorte que le SDK ne révèle jamais quels projets collectent des données.

Le projet est résolu par le domaine du site déclaré dans le fragment. `d` est prioritaire ; s'il est absent, le serveur se rabat sur le hôte de `u` (l'URL de la page), puis sur les en-têtes `Origin`/`Referer` de la requête.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | Chaîne | Domaine du site qui identifie le projet (p. ex. `example.com`). Envoyé par la bibliothèque du navigateur ; la résolution de secours est décrite ci-dessus. |
| `n`   | Chaîne | Nom de l'événement. Par défaut, `pageview`.                          |
| `u`   | Chaîne | URL de la page (`location.href`).                                  |
| `r`   | Chaîne | En-tête Referrer (`document.referrer`).                              |
| `l`   | Chaîne | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | Chaîne | Langue de la page réelle (`document.documentElement.lang`). Vide si non déclarée. |
| `al`  | Chaîne | Langues de traduction séparées par des virgules provenant de `link[rel="alternate"][hreflang]`, excluant `x-default`. |
| `tz`  | Chaîne | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | Nombre | Largeur d'écran en pixels CSS.                                  |
| `sid` | Chaîne | Identifiant de session par onglet (sessionStorage, effacé à la fermeture).       |

Le CORS est ouvert (`Access-Control-Allow-Origin: *`) car le point de terminaison n'accepte aucune authentification.

## Champs dérivés du serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et le User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage rotatif quotidien de l'IP + UA + projet. Non identifiable entre les jours.  |
| `country_code`    | Cloudflare / GeoIP | Code ISO 3166-1 alpha-2 depuis l'en-tête `CF-IPCountry` de confiance, ou l'adaptateur de géolocalisation IP configuré. Vide lorsqu'aucun des deux ne résout un pays. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | En-tête Referrer      | Hôte de l'en-tête Referrer, `www.`/`m.` en tête supprimés.                        |
| `browser_language`| Langues     | Préférence locale normalisée la plus recherchée (p. ex. `pt-BR`).                    |
| `served_locale`   | Langue de la page | Normalisé `sl`, ou vide (affiché comme Non signalé) si elle n'a pas été collectée. |
| `has_locale_gap`  | Calculé      | `1` lorsque aucune des langues préférées du visiteur ne correspond aux objectifs du projet, aux traductions annoncées (`al`) ou à la langue de la page (`sl`). Les préférences manquantes ne comptent pas comme un écart. |

### Résolution du pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active le chemin rapide `CF-IPCountry`. Il est **désactivé par défaut**. Activez-le uniquement après que l'origine authentifie Cloudflare, rejette les requêtes contournant Cloudflare, ou que l'ingress supprime des copies non authentifiées de l'en-tête. Le paramètre de géolocalisation IP de Cloudflare doit également être activé pour la zone. `CF-Connecting-IP`, `CF-Ray` et `use-forwarded-headers` de nginx n'authentifient pas une requête à eux seuls.

Lorsque la confiance des en-têtes est activée, un code pays ISO valide unique est utilisé immédiatement, sans requête IP ou accès à la mémoire cache. La valeur de bordure actuelle a toujours la priorité sur toute recherche en cache. Les codes manquants, dupliqués, malformés ou inconnus, y compris les codes `XX` (inconnu) et `T1` (Tor) de Cloudflare, retombent sur l'adaptateur de géolocalisation configuré.

Sans base de données MaxMind configurée, les recherches de secours utilisent `api.ipapi.is` puis `api.country.is` si la requête principale échoue ou retourne aucun pays reconnu. Chaque requête dispose d'un délai de connexion et de réponse d'une seconde avec les réessais désactivés. Les résultats réussis depuis l'un ou l'autre fournisseur sont mis en mémoire par Cachex pendant 24 heures, avec une limite de taille planifiée de 100 000 entrées et une libération automatique de l'expiration. `Cachex.fetch/3` regroupe les manquements concurrents pour la même IP en un seul résolveur. Les échecs ne sont pas mis en mémoire. Les adresses privées et réservées ne sont envoyées à aucun des deux fournisseurs.

### Langue de page manquante

Le tableau de bord affiche **Non signalé** lorsqu'un événement n'a aucun `sl`. Cela inclut les événements collectés par des versions plus anciennes du tracker et les pages sans attribut HTML `lang`. La langue de la page n'est pas déduite des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées collectées à l'époque ; les nouvelles versions du tracker ne les comblent pas.

## Modèle de vie privée

- **Aucun identifiant de session persistant.** Le SDK n'établit pas de cookies et ne stocke qu'un identifiant de session par onglet dans `sessionStorage`, que le navigateur efface à la fermeture.
- **Aucune empreinte digitale.** Les empreintes numériques du canvas, WebGL, de la police et de l'audio ne sont pas collectées. Le hachage du serveur rotatif quotidien fournit des uniques sans elles.
- **Aucun identifiant brut persisté.** L'IP et le User-Agent sont lus une seule fois, hachés avec un secret de serveur et un sel quotidien, puis jetés.
- **Délimitation par projet.** Le même navigateur utilisé sur deux projets génère des identifiants de visiteur non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.
