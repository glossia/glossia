%{
  title: "Contenu public et interfaces de crawler",
  summary:
    "HTML, Markdown, découverte, mise en cache et limites du crawler pour le site web public.",
  category: "référence",
  section: "platform",
  order: 10
}
---

Glossia expose du contenu web publié séparément des surfaces d'application de compte et de projet.

## Représentations

| Interface | Comportement |
|---|---|
| Une URL HTML publiée | La représentation navigateur, avec des métadonnées canoniques et un en-tête de réponse Markdown alternatif `Link`. |
| `Accept: text/markdown` à cette URL | Une représentation Markdown lorsque le type de média explicite a une qualité positive et n'est pas moins préféré que `text/html`. |
| L'URL de la page avec `.md` ajouté à la fin | Une représentation Markdown explicite, indépendante de la préférence de langue du navigateur. |
| `/index.md` | L'aperçu Markdown de la page d'accueil. |
| `/docs.md`, `/blog.md`, `/features.md` | Des index Markdown du contenu publié. |
| `/changelog.md` | Des articles de changelog publiés dans un seul document Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Les derniers documents juridiques publiés. Les URL juridiques datées prennent également en charge `.md`. |

`*/*` seul ne s'engage pas pour le Markdown. Les réponses HTML et les réponses Markdown partagent `Vary: Accept` afin que les caches ne mélangent pas les représentations.

Chaque documentation, contenu de blog, fonctionnalité et juridique utilise le Markdown rédigé plutôt qu'une conversion du HTML rendu. Les pages index sont générées à partir de l'inventaire publié ; la page d'accueil dispose d'un aperçu Markdown soigné. La référence REST interactive oriente les lecteurs vers la spécification OpenAPI plutôt que d'intégrer un widget d'API dédié au navigateur.

## Localisations

L'anglais n'a pas de préfixe. Les URL marketing traduites utilisent des préfixes littéraux : `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` et `/zh-hans`. Par exemple, `/es/docs/tutorials/getting-started.md` fournit la version espagnole lorsqu'elle est publiée.

L'URL choisit la langue du contenu Markdown. `Accept-Language` ne redirige pas une demande Markdown. Une traduction de contenu manquante retombe sur sa source anglaise. L'aperçu de la page d'accueil est actuellement rédigé en anglais.

## Découverte

- `/robots.txt` interdit par défaut le crawling et inclut l'inventaire HTML et Markdown publié fini, les flux localisés, les assets de rendu sous `/assets/`, `/fonts/` et `/images/`, le favicon, ainsi que les aperçus marketing publics sous `/og/marketing/`. Les images d'aperçu de compte sous `/og/app/` restent interdites. C'est des directives pour les crawlers coopératifs, et non un mécanisme d'autorisation.
- `/sitemap.xml` liste le contenu public canonique avec des alternats de localisation, y compris des URL Markdown pour les pages exclusivement Markdown. Les fragments de changelog ne sont pas des URL séparées.
- `/llms.txt` présente Glossia et relie à la documentation publique, les guides de fonctionnalités et les écrits récents, y compris des liens Markdown explicites.
- `/llms-full.txt` exporte l'aperçu de la page d'accueil, la documentation et le contenu de comparaison Markdown uniquement dans un document texte contenant du Markdown.

Le contenu de comparaison est publié exclusivement en Markdown. Il reste hors de la documentation HTML, de la navigation, de la recherche et des index de documentation, mais les agents peuvent le découvrir via `/llms.txt` et le sitemap. Son URL canonique se termine par `.md` ; l'URL HTML antérieure répond également à `Accept: text/markdown`, mais n'affiche plus une page navigateur.

L'authentification, les tableaux de bord de compte, les API et autres réponses d'application sont marquées `noindex, nofollow`. Le contenu publié réussi est marqué `index, follow` ; les erreurs restent non indexables. Les fichiers texte de découverte (`/robots.txt`, `/llms.txt` et `/llms-full.txt`) utilisent `noindex, follow` : les lecteurs peuvent les récupérer et suivre leurs liens, mais les moteurs de recherche devraient indexer les pages canoniques plutôt qu'un téléchargement de documentation dupliqué.

## Mise en cache et utilisation des ressources

Les réponses de découverte Markdown et texte incluent :

| En-tête | Valeur ou signification |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, ou `text/plain; charset=utf-8` pour le texte de découverte. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un digest SHA-256 guillemeté de la représentation. |
| `X-Markdown-Tokens` | Une estimation grossière du nombre de caractères divisé par quatre, arrondi par excès ; pas un comptage de tokenizer spécifique au modèle. |

`If-None-Match` prend en charge l'appariement des validateurs forts ou faibles, plusieurs validateurs et `*`. Un appariement retourne `304` sans corps. `HEAD` retourne les en-têtes de représentation sans corps.

L'inventaire Markdown publié est compilé dans le déploiement. Les requêtes ne réalisent pas la traduction de contenu, ne lisent pas les fichiers sources, ne chargent pas un compte authentifié, ni n'affichent un LiveView. L'impersonation d'agent utilisateur n'est pas requise pour accéder à ces représentations publiques.

## Limites opérationnelles

La négociation Markdown n'accorde pas accès aux tableaux de bord de compte ou de projet. Les limites de débit de navigation existantes et les vérifications Turnstile restent des protections séparées.

Les limites de débit de l'edge de production s'appliquent aux `GET` et `HEAD`. Les crawlers vérifiés sont toujours limités en débit. Les requêtes excessives reçoivent une réponse de limite de débit plutôt qu'un défi navigateur ; les lecteurs devraient ralentir et réessayer plus tard. Le caching partagé et les requêtes conditionnelles n'exemptent pas les clients des limites de débit.

Les modifications de la politique de crawler dans le référentiel ne prennent effet que lorsque l'application et la configuration d'infrastructure pertinente sont déployées.
