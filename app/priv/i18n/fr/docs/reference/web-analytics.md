%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité sous-jacent à l'analyse web de Glossia.",
  category: "référence",
  order: 1
}
---
## Endpoint d'événements

`POST /api/analytics/events`

Accepte un événement JSON du SDK `@glossia/web`. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges utiles malformées, afin que le SDK ne divulgue jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site que le snippet déclare. `d` est l'élément prépondérant ; en son absence, le serveur recourt à l'hôte de `u` (URL de la page) puis à l'entête `Origin`/`Referer` de la requête.

### Corps de la demande

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site qui identifie le projet (ex. `example.com`). Requis. |
| `n`   | string | Nom de l'événement. Par défaut `pageview`.                  |
| `u`   | string | URL de la page (`location.href`).                            |
| `r`   | string | Source de référence (`document.referrer`).                  |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).     |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur de l'écran en pixels CSS.                            |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture). |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune authtication.

## Champs dérivés du serveur

Ils sont calculés lors de l'ingestion et stockés côté serveur. La IP brute et l'User-Agent ne sont jamais stockés.

| Champs           | Source        | Description                                                         |
|------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`     | HMAC          | Hachage quotidiennement roté de l'IP + UA + projet. Non corrélatable entre les jours. |
| `country_code`   | GeoIP         | Code ISO 3166-1 alpha-2. Vide lorsque GeoIP n'est pas configuré.   |
| `device`         | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`        | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.        |
| `os`             | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.         |
| `hostname`       | URL de la page | Hôte en minuscules.                                                  |
| `pathname`       | URL de la page | Composant du chemin.                                                  |
| `referrer_source`| Source de référence | Hôte de la source de référence, les préfixes `www.`/`m.` étant supprimés.      |
| `browser_language`| Langues     | Locale normalisé selon la préférence (ex. `pt-BR`).                   |
| `served_locale`  | Calculé       | Premier objectif pris en charge correspondant à une langue préférée, sinon vide. |
| `has_locale_gap` | Calculé       | `1` lorsque le visiteur préfère une langue que le projet ne propose pas. |

## Modèle de confidentialité

- **Pas de stockage côté client.** Le SDK ne définit aucun cookie et ne stocke qu'un ID de session par onglet dans `sessionStorage`, ce que le navigateur efface à la fermeture.
- **Pas de fingerprinting.** L'empreinte du Canvas, du WebGL, de la police et de l'audio n'est pas collectée. Le hachage serveur quotidiennement roté permet d'obtenir des identifiants uniques sans ces traces.
- **Aucune identité brute persistée.** L'IP et l'User-Agent sont lus une fois, hachés avec un secret du serveur et un sel quotidien, puis éliminés.
- **Portée par projet.** Le même navigateur sur deux projets produit des identifiants de visiteur non apparentés, de sorte que les visiteurs ne puissent pas être suivis entre les clients Glossia.