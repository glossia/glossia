%{
  title: "Contenu public et interfaces crawler",
  summary: "HTML, Markdown, découverte, mise en cache et limites crawler pour le site public.",
  category: "référence",
  section: "platform",
  order: 10
}
---

Glossia expose le contenu web publié séparément des surfaces d'application de compte et de projet.

## Représentations

| Interface | Comportement |
|---|---|
| Une URL HTML publiée | La représentation navigateur, avec des métadonnées canoniques et un en-tête de réponse Markdown alternatif `Link`. |
| `Accept: text/markdown` à cette URL | Une représentation Markdown lorsque le type de média explicite a une qualité positive et n'est pas moins préféré que `text/html`. |
| L'URL de la page avec `.md` en annexe | Une représentation Markdown explicite, indépendante de la préférence de langue du navigateur. |
| `/index.md` | L'aperçu Markdown de la page d'accueil. |
| `/docs.md`, `/blog.md`, `/features.md` | Indices Markdown du contenu publié. |
| `/changelog.md` | Entries du journal des modifications publiées dans un seul document Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Les documents légaux publiés à jour. Les URL légales datées supportent également `.md`. |

`*/*` tout seul ne suffit pas pour obtenir le Markdown. Les réponses HTML et Markdown partagent `Vary: Accept` afin que les caches ne mélangent pas les représentations.

La documentation individuelle, les articles de blog, les fonctionnalités et le contenu juridique utilisent du Markdown rédigé plutôt qu'une conversion du HTML rendu. Les pages d'index sont générées à partir de l'inventaire publié ; la page d'accueil dispose d'un aperçu Markdown curaté. La référence REST interactive dirige les lecteurs vers la spécification OpenAPI plutôt que d'intégrer un widget API exclusif au navigateur.

## Langues

L'anglais n'a pas de préfixe. Les URL marketing traduites utilisent des préfixes littéraux : `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` et `/zh-hans`. Par exemple, `/es/docs/tutorials/getting-started.md` sert de version espagnole lorsqu'elle est publiée.

L'URL choisit la langue du contenu Markdown. `Accept-Language` ne redirige pas une demande Markdown. Une traduction de contenu manquante revient à sa source anglaise. L'aperçu de la page d'accueil est actuellement rédigé en anglais.

## Découverte

- `/robots.txt` par défaut interdit le crawl et autorise l'inventaire publié HTML et Markdown fini, les flux localisés, les ressources de rendu sous `/assets/`, `/fonts/` et `/images/`, l'icône de site et les aperçus marketing publics sous `/og/marketing/`. Les images d'aperçu de compte sous `/og/app/` restent interdites. C'est une orientation pour les crawlers coopératifs, pas un mécanisme d'autorisation.
- `/sitemap.xml` liste le contenu public canonique avec des alternats locaux, y compris les URL Markdown pour les pages Markdown uniquement. Les fragments du journal des modifications ne sont pas des URL séparées.
- `/llms.txt` présente Glossia et lie à la documentation publique, les guides de fonctionnalités et les écrits récents, y compris des liens Markdown explicites.
- `/llms-full.txt` exporte l'aperçu de la page d'accueil, la documentation et le contenu de comparaison Markdown uniquement dans un seul document de texte contenant Markdown.

Le contenu de comparaison est publié uniquement en Markdown. Il reste en dehors de la documentation HTML, de la navigation, de la recherche et des indices de documentation, mais les agents peuvent le découvrir via `/llms.txt` et le sitemap. Son URL canonique se termine par `.md` ; l'URL HTML précédente répond également à `Accept: text/markdown` mais ne rend plus une page navigateur.

L'authentification, tableaux de bord de compte, API et autres réponses d'application sont marqués `noindex, nofollow`. Le contenu publié réussi est marqué `index, follow` ; les erreurs restent non indexables. Les fichiers de texte de découverte (`/robots.txt`, `/llms.txt` et `/llms-full.txt`) utilisent `noindex, follow` : les lecteurs peuvent les récupérer et suivre leurs liens, mais les moteurs de recherche doivent indexer les pages canoniques plutôt qu'un déversement de documentation dupliqué.

## Mise en cache et utilisation des ressources

Les réponses de découverte Markdown et de texte incluent :

| En-tête | Valeur ou signification |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` ou `text/plain; charset=utf-8` pour le texte de découverte. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un digest SHA-256 en guillemets de la représentation. |
| `X-Markdown-Tokens` | Une estimation grossière des caractères divisés par quatre, arrondis à la hausse ; pas un compteur de tokenizeur spécifique au modèle. |

`If-None-Match` prend en charge la correspondance des validateurs forts ou faibles, plusieurs validateurs et `*`. Une correspondance retourne `304` sans un corps. `HEAD` retourne les en-têtes de représentation sans un corps.

L'inventaire Markdown publié est compilé dans la version de sortie. Les requêtes n'exécutent pas de traduction de contenu, ne lisent pas les fichiers sources, ne chargent pas un compte authentifié, ni ne rendent un LiveView. Aucune usurpation d'User-Agent n'est nécessaire pour accéder à ces représentations publiques.

## Limites opérationnelles

La négociation Markdown ne fournit pas l'accès aux tableaux de bord de compte ou projet. Les limites de débit existantes de navigation de compte et les vérifications Turnstile restent des protections distinctes.

Les limites de débit de bordure de production s'appliquent à la fois à `GET` et `HEAD`. Les crawlers vérifiés sont toujours limités en débit. Les requêtes excessives reçoivent une réponse de limite de débit plutôt qu'un défi navigateur ; les lecteurs doivent ralentir et réessayer plus tard. La mise en cache partagée et les requêtes conditionnelles n'exemptent pas les clients des limites de débit.

Les changements de politique de crawler dans le dépôt n'entrent en vigueur qu'après le déploiement de l'application et de la configuration de l'infrastructure pertinente.
