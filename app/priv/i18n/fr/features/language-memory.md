%{
  title: "Mémoire linguistique",
  summary: "Une couche de contexte versionnée qui capture la voix, la terminologie et le style de votre organisation. La mémoire linguistique guide chaque workflow d'agent et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Versionnée et auditable", description: "Chaque modification de votre voix ou de votre terminologie crée une nouvelle version immuable. Vous pouvez consulter l'historique, comparer les itérations et revenir à une version antérieure en cas de dérive.", icon: "git-branch"},
    %{title: "Au-delà de la localisation", description: "La mémoire linguistique ne se limite pas à la localisation. Utilisez-la pour générer des contenus marketing, rédiger de la documentation, examiner des demandes de tirage ou créer des publications pour les réseaux sociaux, le tout dans la voix de votre organisation.", icon: "megaphone"},
    %{title: "Ouverte et extensible", description: "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Intégrez-la à vos propres pipelines CI, outils de contenu ou agents personnalisés afin de maintenir une cohérence dans tous vos écrits.", icon: "puzzle"}
  ]
}
---
## Qu’est-ce que la mémoire linguistique ?

La mémoire linguistique est l’ensemble du contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle repose sur deux éléments fondamentaux que vous créez et affinez au fil du temps :

**La voix** définit la manière dont le contenu doit s’exprimer. Le ton, le niveau de formalité, le public cible et les directives libres sont tous définis ici. Vous pouvez définir une voix de base pour votre compte, puis remplacer certains champs pour des paramètres régionaux spécifiques. Ainsi, vos contenus en japonais peuvent être plus formels tandis que ceux en anglais restent conversationnels.

**La terminologie** définit le sens des termes et la manière dont ils doivent être localisés. Chaque entrée comprend une définition et des traductions propres à chaque paramètre régional. Lorsqu’un agent rencontre « workspace » dans votre contenu source, la terminologie lui indique s’il doit le localiser, le translittérer ou le conserver tel quel, ainsi que le mot exact à utiliser dans chaque langue cible.

Ensemble, la voix et la terminologie forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins vos résultats nécessitent de révision.

## Gestion immuable des versions

La mémoire linguistique fonctionne uniquement par ajout. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version au lieu d’écraser l’ancienne. Chaque version indique son auteur, sa date de création et, éventuellement, une note expliquant les changements apportés.

Vous disposez ainsi en permanence d’une piste d’audit complète. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué au cours d’un trimestre. Si une modification récente a introduit des incohérences, revenez à une version précédente et poursuivez votre travail.

La gestion des versions sécurise également la collaboration. Plusieurs membres de l’équipe peuvent proposer des modifications de la voix sans craindre de conflits, car chaque changement constitue un événement distinct et traçable.

## Résolution adaptée aux paramètres régionaux

Lorsqu’un agent exécute un flux de travail pour un paramètre régional spécifique, Glossia résout la mémoire linguistique correspondant à ce contexte. Le système part des paramètres de votre voix de base, puis applique les éventuels remplacements propres au paramètre régional. Il procède de la même manière pour la terminologie : seules les entrées qui disposent d’un terme localisé pour le paramètre régional cible sont incluses.

Cette étape de résolution garantit que les agents travaillent toujours avec le contexte le plus pertinent. Vous n’avez pas besoin de gérer une configuration distincte pour chaque langue. Définissez vos valeurs par défaut une seule fois, remplacez-les lorsque cela est nécessaire et laissez le système de résolution gérer le reste.

## Utilisez-la partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Comme ce contexte est accessible par l’[API REST](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous pouvez l’intégrer à des flux de travail qui dépassent le cadre de la localisation :

**Contenu marketing et réseaux sociaux** -- Intégrez la voix de votre organisation à un agent de contenu chargé de rédiger des publications pour les réseaux sociaux, des campagnes par e-mail ou des textes de pages de destination. La terminologie garantit la cohérence des termes de la marque, tandis que les paramètres de voix assurent que le ton correspond à votre marque.

**Documentation** -- Intégrez la mémoire linguistique à un processus de documentation afin que les contenus techniques respectent les mêmes règles de style que le reste de vos contenus. Les entrées de terminologie évitent les divergences entre la documentation, les articles d’aide et les textes intégrés au produit.

**Revue de code** -- Créez un agent qui vérifie les textes des demandes de fusion, notamment les messages d’erreur, les libellés de l’interface utilisateur et les textes d’intégration, au regard de votre voix et de votre terminologie. Signalez les incohérences avant leur mise en production.

**Agents personnalisés** -- Tout client compatible avec MCP peut lire et modifier la mémoire linguistique. Demandez à votre assistant de programmation de « mettre à jour la terminologie avec le nouveau nom du produit » ou de « définir un ton professionnel pour la voix du paramètre régional allemand ». Il traduira votre intention en appel d’API approprié.

## Affinement progressif

La mémoire linguistique s’améliore à l’usage. Chaque fois qu’un réviseur corrige le résultat d’un agent, cette correction alimente la version suivante de votre voix ou de votre terminologie. Au fil du temps, l’écart entre la première version et le résultat final se réduit, et l’étape de révision devient plus rapide.

C’est la boucle de rétroaction au cœur de Glossia : générer, réviser, affiner le contexte, puis générer à nouveau. Les agents ne se contentent pas de suivre des instructions. Ils travaillent avec un contexte qui s’améliore à chaque cycle.