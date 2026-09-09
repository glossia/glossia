%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité derrière l'analyse web de Glossia.",
  category: "référence",
  order: 1
}
---
## Endpoint d'événements

`POST /api/analytics/events`

Accepte un événement JSON depuis le `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les payloads malformés, afin que le SDK ne divulgue jamais quels projets collectent des données analytiques.

Le projet est résolu par le domaine du site déclaré par l'extrait de code. `d` est autoritaire ; en cas d'absence, le serveur revient au hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la demande

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | `example.com`| string | domaine du site qui identifie le projet (e.g.","). Obligatoire. |
| `n`   | string | Nom de l'événement. Par défaut à `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Référé (`document.referrer`).                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune authentification.

## Champs dérivés du serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et l'User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Haché quotidiennement rotatif de l'IP + UA + projet. Non identifiable entre les jours.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide lorsque GeoIP n'est pas configuré.        |
| `device`          | User-Agent    | `desktop`| `mobile`| `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`\[",", ou"\] `opera`Le document assemblé a précédemment échoué la validation : la récupération de texte-littéral Markdown a retourné du JSON invalide `unknown`|
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de page      | Composant de chemin                                                     |
| `referrer_source` | Réf.      | Hôte du site référent, initiale `www.`/`m.` épuré.                        |
| `browser_language`| Langues     | Locale normalisée préférée (p.ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | Première cible supportée correspondant à une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur préfère une langue non prise en charge par le projet. |

## Modèle de confidentialité

- **Aucun stockage côté client.** L'SDK ne définit pas de cookies et ne stocke qu'un identifiant de session par onglet dans `sessionStorage`, que le navigateur efface à la fermeture.
- **Aucune empreinte.** Canvas, WebGL, police et empreintes audio ne sont pas collectés. Le hachage du serveur roté quotidiennement fournit des identifiants uniques sans elles.
- **Aucun identifiant brut persisté.** L'IP et l'User-Agent sont lus une fois, hachés avec un secret serveur et un sel quotidien, puis supprimés.
- **Portée par projet.** Le même navigateur sur deux projets produit des identifiants de visiteurs non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.