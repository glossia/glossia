%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité derrière l'analyse web de Glossia.",
  category: "référence",
  order: 1
}
---
## Point de terminaison d'événements

`POST /api/analytics/events`

Accepte un événement JSON à partir du`@glossia/web` SDK. Always responds `202 Accepted`, including for unknown domains or malformed payloads, so the SDK never leaks which projects collect analytics.

Le projet est résolu par le domaine du site que l'extrait déclare.`d` est prépondérant ; lorsqu'il est absent, le serveur se rabat sur l'hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la requête

| Libellé | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
|`d`   | chaîne de caractères | Site du réseau qui identifie le projet (par ex. `example.com`). Requis. |
| `n`   | string | Nom de l'événement. Valeur par défaut `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Origine (`document.referrer`).                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur de l'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

Les CORS sont ouverts (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune authentification.

## Champs dérivés du serveur

Ils sont calculés à l'ingestion et stockés côté serveur. L'IP brute et l'Utilisateur-Utilisateur ne sont jamais stockés.

| Champs                                                          | Source    | Description                                                         |
|-----------------|-----------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC      | Hachage quotidien pivoté de IP + UA + projet. Non joignable entre jours.  |
| `country_code`    | GeoIP     | Code ISO 3166-1 alpha-2. Vide si GeoIP n'est pas configuré.        |
| `device`          | Utilisateur-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | Utilisateur-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | Utilisateur-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte minuscules.                                                    |
| `pathname`        | URL de la page      | Composant de chemin.                                                     |
| `referrer_source` | Origine      | Hôte de l'Origine, `www.`/`m.` retirés.                        |
| `browser_language`| Langues     | Langue locale normalisée préférée (par ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | Première cible cible compatible une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur privilégie une langue que le projet ne diffuse pas. |

## Modèle de confidentialité

- **Aucun stockage côté client.** Le SDK ne définit pas de cookies et stocke uniquement un ID de session par onglet dans `sessionStorage`, qu'il efface le navigateur lors de la fermeture.
- **Aucune empreinte numérique.** Empreintes de Canvas, WebGL, polices et audio ne sont pas collectées. Le hash serveur tourné quotidiennement fournit des uniques sans elles.
- **Aucune identifiant brut persisté.** IP et Utilisateur-Agent sont lus une fois, hachés avec un secret serveur et un sel journalier, puis éliminés.
- **Portage par projet.** Le même navigateur sur deux projets donne des ID de visiteur non liés, donc les visiteurs ne peuvent pas être tracés parmi les clients de Glossia.