%{
  title: "Kit de développement logiciel d’analyse",
  summary: "Les champs collectés, le point de terminaison des événements et le modèle de confidentialité des analyses web de Glossia.",
  category: "reference",
  order: 1
}
---
## Point de terminaison des événements

`POST /api/analytics/events`

Accepte un événement JSON provenant du kit de développement logiciel `@glossia/web`. Renvoie toujours `202 Accepted`, y compris pour les domaines inconnus ou les charges utiles mal formées, afin que le kit ne révèle jamais quels projets collectent des données analytiques.

Le projet est déterminé à partir du domaine du site déclaré par l’extrait de code. `d` fait autorité. S’il est absent, le serveur utilise l’hôte de `u` (l’URL de la page), puis les valeurs `Origin`/`Referer` de la requête.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | chaîne | Domaine du site qui identifie le projet (par exemple `example.com`). Obligatoire. |
| `n`   | chaîne | Nom de l’événement. Valeur par défaut : `pageview`.                          |
| `u`   | chaîne | URL de la page (`location.href`).                                  |
| `r`   | chaîne | Référent (`document.referrer`).                              |
| `l`   | chaîne | Langues du navigateur (`navigator.languages.join(",")`).         |
| `tz`  | chaîne | Fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | nombre | Largeur de l’écran en pixels CSS.                                  |
| `sid` | chaîne | Identifiant de session propre à l’onglet (sessionStorage, effacé à la fermeture).       |

Le partage des ressources entre origines est ouvert (`Access-Control-Allow-Origin: *`), car le point de terminaison n’accepte aucun identifiant d’authentification.

## Champs dérivés par le serveur

Ces champs sont calculés lors de l’ingestion et stockés côté serveur. L’adresse IP brute et l’agent utilisateur ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Empreinte de l’adresse IP, de l’agent utilisateur et du projet, renouvelée quotidiennement. Aucun rapprochement possible entre les jours.  |
| `country_code`    | GeoIP         | Code ISO 3166-1 alpha-2. Vide lorsque GeoIP n’est pas configuré.        |
| `device`          | Agent utilisateur    | `desktop`, `mobile`, `tablet`, `bot` ou `unknown`.                 |
| `browser`         | Agent utilisateur    | `chrome`, `safari`, `firefox`, `edge`, `opera` ou `unknown`.       |
| `os`              | Agent utilisateur    | `windows`, `macos`, `ios`, `android`, `linux` ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Référent      | Hôte référent, sans le préfixe `www.`/`m.`.                        |
| `browser_language`| Langues     | Paramètre régional normalisé privilégié (par exemple `pt-BR`).                    |
| `served_locale`   | Calculé      | Première langue cible prise en charge correspondant à une langue privilégiée, sinon vide.   |
| `has_locale_gap`  | Calculé      | `1` lorsque le visiteur préfère une langue que le projet ne prend pas en charge. |

## Modèle de confidentialité

- **Aucun stockage côté client.** Le kit de développement ne définit aucun cookie et stocke uniquement un identifiant de session propre à l’onglet dans `sessionStorage`, que le navigateur efface à sa fermeture.
- **Aucune prise d’empreinte.** Les empreintes du canevas, de WebGL, des polices et du contenu audio ne sont pas collectées. L’empreinte du serveur renouvelée quotidiennement permet de comptabiliser les visiteurs uniques sans les utiliser.
- **Aucun identifiant brut conservé.** L’adresse de protocole Internet et l’agent utilisateur sont lus une seule fois, hachés avec un secret du serveur et un sel quotidien, puis supprimés.
- **Cloisonnement par projet.** Un même navigateur utilisé sur deux projets génère des identifiants visiteur sans lien entre eux. Les visiteurs ne peuvent donc pas être suivis entre différents clients de Glossia.