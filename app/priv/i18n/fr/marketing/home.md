# Glossia : un système d'exploitation linguistique pour les équipes

Glossia intègre la voix, la terminologie, la traduction, l'historique des révisions et les analytiques de localisation dans un seul système. Il aide les développeurs, les linguistes et les équipes produit à communiquer de manière cohérente dans plusieurs langues sans déplacer leur contenu hors de Git.

## Le problème

Le lancement dans une autre langue n'est pas seulement le remplacement de mots. Les équipes doivent préserver le sens, utiliser les bons termes, adapter le ton au public et maintenir les traductions à jour en fonction des modifications du produit. Un contexte dispersé à travers des tableurs, des prompts et des outils de traduction conduit à une écriture incohérente et à des tâches manuelles répétitives.

Un LLM peut rédiger un brouillon de traduction, mais une ébauche seule ne fournit pas d'historique des versions, de validation, de mises à jour sélectives ou de boucle de rétroaction pour le changement suivant.

## Le rôle de Glossia

- **Mémoire linguistique:** les guides de voix partagés et les entrées de glossaire aident les personnes et les agents à utiliser un vocabulaire cohérent.
- **Localisation du dépôt:** connecter un dépôt, décrire les fichiers sources et les localisations cibles dans la configuration, et examiner les modifications via des pull requests.
- **Affinement progressif:** les hachages de contenu aident à éviter la traduction de contenu inchangé. La validation et la récupération rendent les échecs visibles et actionnables.
- **Révision du contenu:** préserver l'historique des décisions linguistiques et des modifications au lieu de traiter chaque génération comme un prompt isolé.
- **Analytiques de localisation:** les analytics web respectueux de la vie privée aident les équipes à comprendre leur public et où investir en localisation.
- **Intégration d'agent:** un serveur MCP authentifié par OAuth et des interfaces REST rendent le contexte linguistique disponible pour les flux de travail existants.

Glossia ne remplace pas le jugement éditorial. Il fournit le contexte, l'automatisation et le flux de travail de révision qui permettent aux équipes d'appliquer ce jugement de manière répétée.

## Explorer

- [Comment commencer](/docs/tutorials/getting-started.md) : connecter un dépôt et exécuter votre premier flux de travail de localisation.
- [Pourquoi Glossia](/docs/explanation/why-glossia.md) : les problèmes que le système d'exploitation linguistique est conçu pour résoudre.
- [Fonctionnalités](/features.md) : capacités du produit et cas d'usage.
- [Documentation](/docs.md) : tutoriels, guides pas à pas, références et explications.
- [Blog](/blog.md) : écriture sur la localisation et les systèmes linguistiques.
- [Journal des modifications](/changelog.md) : changements de produit.
- [Code source](https://github.com/glossia/glossia) : inspecter la mise en œuvre et contribuer.

## Comparaisons

- [Glossia VS Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia VS Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia VS Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia VS Weblate](/docs/explanation/glossia-vs-weblate.md)

## Pour les robots et les agents

Les pages publiées sont disponibles en Markdown en ajoutant `.md` à leur URL, ou en demandant `Accept: text/markdown` à l'URL HTML. L'URL Markdown de la page d'accueil est `/index.md`. Le contenu traduit utilise les mêmes préfixes de localisation que l'HTML et revient à l'anglais lorsqu'aucune traduction n'est publiée.

Utilisez [/llms.txt](/llms.txt) pour la découverte, [/llms-full.txt](/llms-full.txt) pour une exportation de documentation consolidée, et [/sitemap.xml](/sitemap.xml) pour les URL HTML canoniques. Les tableaux de bord de compte sont des surfaces d'application, pas de la documentation ; ne les explorez pas pour en savoir plus sur Glossia.
