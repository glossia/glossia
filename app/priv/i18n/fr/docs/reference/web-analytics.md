%{
  title: "SDK Analytique",
  summary:
    "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité sous-jacent à l'analyse web de Glossia.",
  category: "référence",
  order: 1
}
---
## Point de terminaison d'événements

`POST /api/analytics/events`

Accepte un événement JSON provenant du `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les données malformées, de sorte que le SDK ne révèle jamais quels projets collectent des données analytiques.

Le projet est résolu par le domaine du site déclaré par le fragment. `d` est autoritaire ; en son absence, le serveur recourt à l'hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la demande

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Domaine du site identifiant le projet (par ex.") `example.com`). Obligatoire. |
| `n`   | chaîne | Nom de l'événement. Par défaut. `pageview`.|
| `u`   | chaîne | URL de la page (`location.href`)                                  |
| `r`   | chaîne | Référer (`document.referrer`)                              |
| `l`   | string | Langues du navigateur (`navigator.languages.join(",")`).         |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | Identifiant de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) car l'endpoint n'accepte aucune authentification.

## Champs dérivés du serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et l'User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Haché quotidiennement de l'IP + UA + projet. Non identifiable d'un jour à l'autre.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide si GeoIP n'est pas configuré.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`Le document reconstitué a précédemment échoué la validation : la récupération de nœud de texte Markdown a produit une traduction vide `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`Le document réassemblé a échoué la validation précédemment : la récupération de texte littéral Markdown doit retourner un tableau de chaînes JSON de même longueur. `firefox`, `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`Le document réassemblé a précédemment échoué la validation : la récupération de texte littéral Markdown doit retourner un tableau de chaînes JSON de longueur correspondante. `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant de chemin.                                                     |
| `referrer_source` | Référent      | Hôte du référent, slash de début `www.`/`m.` supprimé.                        |
| `browser_language`| Langues     | Locale préférée normalisée (ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | Première langue cible supportée correspondant à une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur préfère une langue que le projet ne gère pas. |

## Modèle de confidentialité

- **Aucun stockage côté client.** Le SDK n'émet aucun cookie et ne conserve qu'un identifiant de session par onglet dans `sessionStorage`, dont le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Les empreintes Canvas, WebGL, de police et audio ne sont pas collectées. Le hachage serveur roté quotidiennement fournit des identifiants uniques sans elles.
- **Aucun identifiant brut n'est persisté.** L'IP et le User-Agent sont lus une fois, hachés avec un secret serveur et un sel quotidien, puis éliminés.
- **Portée par projet.** Le même navigateur sur deux projets génère des identifiants de visiteur non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.