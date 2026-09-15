%{
  title: "SDK Analytique",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité sous-jacent à l'analyse web de Glossia.",
  category: "référence",
  order: 1
}
---
## Endpoint des événements

`POST /api/analytics/events`

Accepte un événement JSON de `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges malformées, de sorte que le SDK ne révèle jamais quels projets collectent des statistiques.

Le projet est résolu par le domaine du site déclaré par le fragment. `d` est déterminant ; en son absence, le serveur se replie sur l'hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la demande

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site identifiant le projet (e.g. `example.com`). Requis. |
| `n`   | string | Nom de l'événement. Par défaut `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Référéur (`document.referrer`)                              |
| `l`   | chaîne | Langues du navigateur (`navigator.languages.join(",")`).         |
| `tz`  | chaîne | fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | chaîne | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) parce que le point de terminaison n'accepte aucun identifiant.

## Champs dérivés du serveur

Ces champs sont calculés à l'ingestion et stockés côté serveur. L'IP brute et les User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash journalier de l'IP + UA + projet. Non corrélable entre les jours.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide si GeoIP n'est pas configuré.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de page      | Composant de chemin.                                                     |
| `referrer_source` | Référent      | Hôte du référent, initiale `www.`/`m.` épuré.                        |
| `browser_language`| Langues     | Locale normalisée la plus préférée (p.ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | Première cible supportée correspondant à une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur préfère une langue que le projet ne prend pas en charge. |

## Modèle de confidentialité

- **Aucun stockage côté client.** Le SDK ne définit aucun cookie et ne stocke qu'un identifiant de session par onglet dans `sessionStorage`, que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Canvas, WebGL, polices et empreintes audio ne sont pas collectées. Le hash serveur renouvelé quotidiennement fournit des identifiants uniques sans elles.
- **Aucun identifiant brut persisté.** L'IP et le User-Agent sont lus une fois, hashés avec un secret serveur et un sel quotidien, puis supprimés.
- **Isolation par projet.** Le même navigateur sur deux projets génère des identifiants de visiteur non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.