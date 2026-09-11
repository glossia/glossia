%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité sous-jacent à l'analyse web de Glossia.",
  category: "Référence",
  order: 1
}
---
## Point de terminaison des événements

`POST /api/analytics/events`

Accepte un événement JSON de `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges utiles malformées, afin que le SDK ne révèle jamais quels projets collectent des données d'analyse.

Le projet est résolu par le nom de domaine du site déclaré par le snippet. `d` est autoritaire ; en son absence, le serveur se rabat sur le hôte de `u` (l'URL de la page) puis la requête `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Nom de domaine du site qui identifie le projet (e.g.," `example.com`. Requis. |
| `n`   | string | Nom de l'événement. Valeur par défaut `pageview`.                          |
| `u`   | string | URL de la page (`location.href`).                                  |
| `r`   | string | Référent (`document.referrer`).                              |
| `l`   | string | Langues de navigateur (`navigator.languages.join(",")`).         |
| `tz`  | string | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Largeur de l'écran en pixels CSS.                                  |
| `sid` | Chaîne | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouvert (`Access-Control-Allow-Origin: *`) parce que l'endpoint n'accepte aucun identifiant.

## Champs dérivés par le serveur

Ces champs sont calculés lors de l'ingestion et stockés côté serveur. L'IP brute et le User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hash journalier basé sur l'IP + UA + projet. Non corrélable entre les jours.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide lorsque GeoIP n'est pas configuré.        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | Agent utilisateur    | `chrome`, `safari`, `firefox`Le document réassemblé a précédemment échoué la validation : la récupération de texte littéral Markdown doit retourner un tableau de chaînes JSON de longueur correspondante `edge`, `opera`, ou `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`Le document reconstitué a précédemment échoué la validation : la récupération de texte Markdown doit retourner un tableau de chaînes JSON de longueur correspondante. `linux`Le document réassemblé a précédemment échoué la validation : la récupération de texte littéral Markdown a retourné un JSON invalide `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Referrer      | Hôte du référent `www.`/`m.` éliminée.                        |
| `browser_language`| Langues     | Emplacement locale normalisé le plus préféré (par ex. `pt-BR`).                    |
| `served_locale`   | Calculé      | première cible supportée correspondante à une langue préférée, sinon vide.   |
| `has_locale_gap`  | Calculé       | `1` lorsque le visiteur privilégie une langue non prise en charge par le projet. |

## Modèle de confidentialité

- **Aucun stockage côté client.** L'SDK ne place aucun cookie et ne stocke qu'un identifiant de session par onglet dans `sessionStorage`, ce que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Les empreintes Canvas, WebGL, de police et audio ne sont pas collectées. Le hachage de serveur, roté quotidiennement, fournit des identifiants uniques sans elles.
- **Aucun identifiant brut n'est conservé.** L'IP et l'User-Agent sont lus une fois, hachés avec un secret de serveur et un sel quotidien, puis effacés.
- **Portée par projet.** Le même navigateur sur deux projets génère des identifiants de visiteur non apparentés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.