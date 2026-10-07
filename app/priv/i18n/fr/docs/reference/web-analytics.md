%{
  title: "SDK d'analyse",
  summary:
    "Les champs collectés, l'endpoint des événements et le modèle de confidentialité derrière les analyses web de Glossia.",
  category: "référence",
  section: "analytics",
  order: 1
}
---
## Endpoint des événements

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` reste disponible pour la compatibilité. Le script hôte dérive `/v1/collect` de son origine ; les intégrations de paquets doivent définir `endpoint` explicitement.

Accepte un événement JSON de `@glossia/web` SDK. Répond toujours `202 Accepted`, y compris pour les domaines inconnus ou les données malformées, de sorte que le SDK ne révèle jamais quels projets collectent des analyses.

Le projet est résolu par le domaine du site déclaré par le snippet. `d` est autoritaire ; en son absence, le serveur se rabat sur l'hôte de `u` (l'URL de la page) puis la demande `Origin`/`Referer`.

### Corps de la requête

| Champ | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Nom de domaine qui identifie le projet (par ex. `example.com`). Envoyé par la bibliothèque du navigateur ; la résolution de repli est décrite ci-dessus. |
| `n`   | string | Nom de l'événement. Par défaut `pageview`.                          |
| `u`   | chaîne | URL de la page (`location.href`).                                  |
| `r`   | chaîne | Référent (`document.referrer`) .                              |
| `l`   | chaîne | Langues du navigateur (`navigator.languages.join(",")`).         |
| `sl`  | string | Langue de la page actuelle (`document.documentElement.lang`). Vide si non déclaré. |
| `al`  | string | Langues de traduction séparées par des virgules à partir de `link[rel="alternate"][hreflang]`, excluant `x-default`". |
| `tz`  | string | fuseau horaire IANA (`Intl.DateTimeFormat().resolvedOptions().timeZone`) |
| `sw`  | number | Largeur d'écran en pixels CSS.                                  |
| `sid` | string | ID de session par onglet (sessionStorage, effacé à la fermeture).       |

CORS est ouverte (`Access-Control-Allow-Origin: *`parce que l'endpoint n'accepte aucune authentification.

## Champs dérivés du serveur

Ces données sont calculées à l'ingestion et stockées côté serveur. L'IP brute et l'User-Agent ne sont jamais stockés.

| Champ             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Hachage quotidien de IP + UA + projet. Non corrélable entre les jours.  |
| `country_code`    | Cloudflare / GeoIP | code ISO 3166-1 alpha-2 d'une de confiance `CF-IPCountry` en-tête, ou l'adaptateur de géolocalisation IP configuré. Vide lorsque aucun ne résout un pays. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, ou `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`Le document reconstitué a précédemment échoué la validation : la récupération du texte littéral Markdown a retourné un JSON invalide `opera`, ou `unknown`.       |
| `os`              | Agent d'utilisateur    | `windows`Le document réassemblé a précédemment échoué la validation : la récupération de chaînes littérales Markdown doit retourner un tableau de chaînes JSON de longueur correspondante. `macos`Le document reconstitué a précédemment échoué la validation : la récupération du texte littéral Markdown doit retourner un tableau JSON de chaînes de même longueur. `ios`, `android`, `linux`, ou `unknown`.        |
| `hostname`        | URL de la page      | Hôte en minuscules.                                                    |
| `pathname`        | URL de la page      | Composant du chemin.                                                     |
| `referrer_source` | Réf. URL      | Hôte du réf. URL, caractère de tête `www.`/`m.` supprimé.                        |
| `browser_language`| Langues     | Locale normalisée la plus préférée (par ex. `pt-BR`).                    |
| `served_locale`   | Langue de la page | Normalisée `sl`, ou vide (affiché comme Non rapporté) si elle n'a pas été collectée. |
| `has_locale_gap`  | Calculé      | `1` quand aucune des langues préférées du visiteur ne correspond aux objectifs du projet, aux traductions annoncées (`al`), ou la langue de la page (`sl`). Les préférences manquantes ne comptent pas comme un écart. |

### Résolution du pays

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` active le `CF-IPCountry` chemin rapide. Il est **désactivé par défaut**. Activez-le uniquement après que l'origine ait authentifié Cloudflare, rejeté les requêtes qui contournent Cloudflare, ou que l'ingress supprime les copies non fiables de l'en-tête. La configuration de géolocalisation IP de Cloudflare doit également être activée pour la zone. `CF-Connecting-IP`, `CF-Ray`, et nginx `use-forwarded-headers` n'authentifient pas une requête par elles-mêmes.

Lorsque la confiance des en-têtes est activée, un seul code pays ISO valide est utilisé immédiatement, sans recherche IP ni accès au cache. La valeur actuelle de bord est toujours prioritaire sur toute recherche en cache. Les codes manquants, doublons, malformés ou inconnus, incluant ceux de Cloudflare `XX` (inconnu) et `T1` (Tor) des valeurs, retour à l'adaptateur de géolocalisation configuré.

Sans une base de données MaxMind configurée, les recherches de secours utilisent `api.ipapi.is`, puis `api.country.is` quand la demande principale échoue ou ne retourne aucun pays reconnu. Chaque demande dispose d'un délai de connexion et de réponse d'une seconde, les réessais étant désactivés. Les résultats réussis des deux fournisseurs sont mis en cache par Cachex pendant 24 heures, avec une limite de taille planifiée à 100 000 entrées et un nettoyage automatique à expiration. `Cachex.fetch/3` regroupe les ratés concourants de la même IP en un seul résolveur. Les échecs ne sont pas mis en cache. Les adresses privées et réservées ne sont pas envoyées à l'un ou à l'autre fournisseur.

### Langue de page manquante

Le tableau de bord affiche **Non signalé** quand un événement n'a pas `sl`. Cela inclut les événements collectés par les anciennes versions du traceur et les pages sans attribut HTML `lang` attribut. La langue de la page n'est pas déduite des préférences du navigateur ou de l'URL. Les événements historiques conservent les métadonnées collectées à l'époque ; les nouvelles versions du traceur ne les reconstituent pas.

## Modèle de confidentialité

- **Aucun identifiant persistant entre les sessions.** L'SDK ne définit pas de cookies et ne stocke qu'un identifiant de session par onglet dans `sessionStorage`, ce que le navigateur efface à la fermeture.
- **Aucune empreinte numérique.** Les empreintes Canvas, WebGL, de police et audio ne sont pas collectées. Le hachage du serveur en rotation quotidienne fournit des identifiants uniques sans elles.
- **Aucun identifiant brut persisté.** L'IP et le User-Agent sont lus une seule fois, hachés avec un secret serveur et un sel quotidien, puis supprimés.
- **Portée par projet.** Un même navigateur sur deux projets génère des identifiants de visiteurs non liés, de sorte que les visiteurs ne peuvent pas être suivis entre les clients Glossia.