%{
  title: "Contenu public et interfaces du crawler",
  summary:
    "HTML, Markdown, découverte, mise en cache et limites du crawler pour le site web public.",
  category: "référence",
  section: "platform",
  order: 10
}
---

Glossia expose le contenu web publié séparément des interfaces d'application des comptes et des projets.

## Représentations

| Interface | Comportement |
|---|---|
| Une URL HTML publiée | La représentation navigateur, avec des métadonnées canoniques et un en-tête de réponse Markdown alternatif `Link`. |
| `Accept: text/markdown` à cette URL | Une représentation Markdown si le type de média explicite a une qualité positive et n'est pas moins préféré que `text/html`. |
| L'URL de la page avec `.md` ajouté | Une représentation Markdown explicite, indépendante de la préférence de langue du navigateur. |
| `/index.md` | L'aperçu Markdown de la page d'accueil. |
| `/docs.md`, `/blog.md`, `/features.md` | Indices Markdown du contenu publié. |
| `/changelog.md` | Les entrées de changelog publiées dans un seul document Markdown. |
| `/terms.md`, `/privacy.md`, `/cookies.md` | Les derniers documents juridiques publiés. Les URLs juridiques datées supportent également `.md`. |

`*/*` seul n'implique pas le Markdown. Les réponses HTML et les réponses Markdown partagent `Vary: Accept` pour que les caches ne mélangent pas les représentations.

La documentation, les articles de blog, les fonctionnalités et les contenus juridiques utilisent individuellement le Markdown rédigé plutôt qu'une conversion du HTML rendu. Les pages d'index sont générées à partir de l'inventaire publié ; la page d'accueil possède une vue Markdown curatée. La référence REST interactive oriente les lecteurs vers la spécification OpenAPI plutôt que d'intégrer un widget API dédié au navigateur.

## Localisations

L'anglais ne possède pas de préfixe. Les URLs de marketing traduites utilisent des préfixes littéraux : `/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` et `/zh-hans`. Par exemple, `/es/docs/tutorials/getting-started.md` diffuse la version espagnole lorsqu'elle est publiée.

L'URL choisit la langue du contenu Markdown. `Accept-Language` ne redirige pas une requête Markdown. Une traduction de contenu manquante recourt à sa source anglaise. L'aperçu de la page d'accueil est actuellement rédigé en anglais.

## Découverte

- `/robots.txt` par défaut interdit le crawl et autorise l'inventaire HTML et Markdown publié fini, les flux localisés, les assets de rendu sous `/assets/`, `/fonts/` et `/images/`, le favicon et les aperçus marketing publics sous `/og/marketing/`. Les images d'aperçu de compte sous `/og/app/` restent interdites. Il s'agit d'une orientation pour les crawlers coopératifs, et non d'un mécanisme d'autorisation.
- `/sitemap.xml` liste le contenu HTML public canonique avec des alternates de localisation. Les fragments de changelog ne sont pas des URLs séparées.
- `/llms.txt` présente Glossia et met en lien la documentation publique, les guides de fonctionnalités et les écrits récents, y compris des liens Markdown explicites.
- `/llms-full.txt` exporte l'aperçu de la page d'accueil et l'inventaire de documentation complet dans un seul document texte contenant du Markdown.

L'authentification, les tableaux de bord de compte, les API et les autres réponses d'application sont marqués `noindex, nofollow`. Le contenu publié valide est marqué `index, follow` ; les erreurs restent non indexables. Les fichiers texte de découverte (`/robots.txt`, `/llms.txt` et `/llms-full.txt`) utilisent `noindex, follow` : les lecteurs peuvent les récupérer et suivre leurs liens, mais les moteurs de recherche doivent indexer les pages canoniques plutôt qu'un inventaire de documentation dupliqué.

## Mise en cache et utilisation des ressources

Les réponses Markdown et de découverte de texte incluent :

| En-tête | Valeur ou signification |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8` ou `text/plain; charset=utf-8` pour le texte de découverte. |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | Un digest SHA-256 entouré de guillemets de la représentation. |
| `X-Markdown-Tokens` | Une estimation approximative des caractères divisés par quatre, arrondie à l'entier supérieur ; pas un comptage de tokenizer spécifique au modèle. |

`If-None-Match` permet de correspondre des validateurs forts ou faibles, plusieurs validateurs et `*`. Une correspondance retourne `304` sans corps. `HEAD` retourne les en-têtes de représentation sans corps.

L'inventaire Markdown publié est intégré à la version de déploiement. Les requêtes ne font pas de traduction de contenu, ne lisent pas les fichiers sources, ne chargent pas un compte authentifié, ni ne rendent un LiveView. L'usurpation d'identité User-Agent n'est pas nécessaire pour accéder à ces représentations publiques.

## Limites opérationnelles

La négociation Markdown ne fournit pas d'accès aux tableaux de bord de compte ou de projet. Les limites existantes de débit de navigation de compte et les vérifications Turnstile restent des protections séparées.

Les limites de débit en production edge s'appliquent aux deux `GET` et `HEAD`. Les crawlers vérifiés sont toujours limités en débit. Les requêtes excessives reçoivent une réponse de limite de débit plutôt qu'un défi navigateur ; les lecteurs doivent ralentir et réessayer plus tard. Le cache partagé et les requêtes conditionnelles ne dispensent pas les clients des limites de débit.

Les modifications de politique de crawler dans le référentiel ne prennent effet qu'après le déploiement de l'application et la configuration de l'infrastructure pertinente.
