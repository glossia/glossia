%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité sous-jacent à l'analyse web Glossia.",
  category: "référence",
  order: 1
}
---
## Point de terminaison des événements

`POST /api/analytics/events`

Accepte un événement JSON en provenance du `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges utiles malformées, de sorte que le SDK n'expose jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site déclaré par le fragment. `d` est autoritaire ; en son absence, le serveur recourt par défaut à l'hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la demande

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site identifiant le projet (p. ex. `example.com`. Requises. |
| `n`   | string | Nom d'événement. Valeur par défaut `pageview`.                          |
| `u`   | string | URL de page (`location.href`).                                  |
| `r`   | string | En-tête (`document.referrer`).                              |
| `l`   | chaîne | Langues du navigateur („).`navigator.languages.join(",")`|
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | Identifiant de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`car le point de terminaison n'accepte aucune authentification.

## Champs dérivés du serveur

Ces éléments sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et l'User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash tournant quotidiennement de l'IP + UA + projet. Non corrélatif entre les jours.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide si GeoIP n'est pas configuré.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, or `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | Agent utilisateur    | `windows`, `macos`Le document reconstitué a précédemment échoué la validation : la récupération de texte Markdown doit retourner un tableau de chaînes JSON de longueur correspondante. `ios`Le document réassemblé a précédemment échoué la validation : la récupération de texte Markdown a retourné un JSON invalide `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant de chemin.                                                     |
| `referrer_source` | Référer      | Hôte du Référer, principal `www.`/`m.` épuré.                        |
| `browser_language`| Langues      | Locale normalisée préférée (p. ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | Première cible supportée correspondant à une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur préfère une langue que le projet ne prend pas en charge. |

## Modèle de confidentialité

- **Aucun stockage côté client.** L' SDK ne crée aucun cookie et stocke uniquement un ID de session par onglet dans `sessionStorage`, ce que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Les empreintes Canvas, WebGL, de police et audio ne sont pas collectées. Le hachage quotidien du serveur fournit des identifiants uniques sans les utiliser.
- **Aucun identifiant brut n'est conservé.** IP et User-Agent sont lus une fois, hachés avec un secret serveur et un sel quotidien, puis supprimés.
- **Portée par projet.** Le même navigateur sur deux projets génère des identifiants de visiteurs non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.