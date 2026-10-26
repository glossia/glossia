# Glossia : un OS linguistique pour les équipes

Glossia intègre la guidance de ton, la terminologie, la traduction, l'historique des révisions et l'analyse de la localisation dans un seul système. Il aide les développeurs, les linguistes et les équipes produit à communiquer de manière cohérente dans différentes langues, sans avoir à déplacer leur intégrité hors de Git.

## Le problème

Publier dans une autre langue ne se limite pas à remplacer des mots. Les équipes doivent préserver le sens, utiliser le bon vocabulaire, adapter le ton au public cible, et maintenir les traductions à jour à mesure que le produit évolue. Le contexte dispersé sur plusieurs feuilles de calcul, inviteurs d'IA et outils de traduction conduit à une écriture incohérente et à un travail manuel répété.

Un LLM peut rédiger une traduction, mais un brouillon seul ne fournit pas l'historique des versions, la validation, les mises à jour sélectives, ou un cycle de retour d'information pour le prochain changement.

## Le rôle de Glossia

- **La mémoire linguistique :** des guides de langage et des entrées de glossaire partagés aident les personnes et les agents à utiliser un langage cohérent.
- **Localisation du dépôt :** connecter un dépôt, décrire les fichiers source et les cibles de langues dans la configuration, et examiner les modifications dans des pull requests.
- **Raffinement progressif :** les hachages de contenu aident à éviter de traduire le contenu inchangé. La validation et la récupération rendent les défaillances visibles et actionnables.
- **Révision du contenu :** préserver l'historique des décisions linguistiques et des modifications au lieu de traiter chaque génération comme un message isolé.
- **Analyse de la localisation :** une analyse web respectueuse de la confidentialité aide les équipes à comprendre leur public et où la localisation mérite un investissement.
- **Intégration d'agent :** un serveur MCP authentifié OAuth et des interfaces REST rendent le contexte linguistique disponible aux flux de travail existants.

Glossia ne remplace pas le jugement éditorial. Il fournit le contexte, l'automatisation et le flux de travail de révision qui permettent aux équipes d'appliquer ce jugement répété.

## Explorer

- [Commencer](/docs/tutorials/getting-started.md) : connecter un dépôt et exécuter votre premier flux de travail de localisation.
- [Pourquoi Glossia](/docs/explanation/why-glossia.md) : les problèmes que le système d'exploitation linguistique est conçu pour résoudre.
- [Fonctionnalités](/features.md) : capacités du produit et cas d'usage.
- [Documentation](/docs.md) : tutoriels, guides pratiques, références et explications.
- [Blog](/blog.md) : écrit sur la localisation et les systèmes linguistiques.
- [Registre des changements](/changelog.md) : modifications du produit.
- [Code source](https://github.com/glossia/glossia) : inspecter l'implémentation et contribuer.

## Comparaisons

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Pour les crawlers et agents

Les pages publiées sont disponibles en Markdown en y ajoutant `.md` à leur URL, ou en demandant `Accept: text/markdown` à l'URL HTML. L'URL Markdown de la page d'accueil est `/index.md`.

Utilisez [/llms.txt](/llms.txt) pour la découverte, [/llms-full.txt](/llms-full.txt) pour une exportation consolidée de la documentation, et [/sitemap.xml](/sitemap.xml) pour les URL HTML canoniques. Les tableaux de bord de compte sont des surfaces d'application, pas de documentation ; ne les grappez pas pour apprendre sur Glossia.
