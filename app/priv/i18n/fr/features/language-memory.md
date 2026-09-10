%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, la terminologie et le style de votre organisation. La mémoire linguistique guide chaque flux de travail des agents et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionnée et auditable",
      description:
        "Chaque modification de la voix ou de la terminologie crée une nouvelle version immuable. Vous pouvez examiner l'historique, comparer les itérations et revenir en arrière si quelque chose dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique n'est pas seulement pour la localisation. Utilisez-la pour générer des textes marketing, rédiger de la documentation, examiner les pull requests, ou créer des publications sociales, le tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouverte et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Alimentez-la dans vos propres pipelines CI, outils de contenu ou agents sur mesure pour maintenir la cohérence partout où vous écrivez.",
      icon: "puzzle"
    }
  ]
}
---
## Qu'est-ce que la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui explique aux agents de Glossia comment votre organisation communique. Elle est constituée de deux primitives de base que vous créez et affinez au fil du temps :

**Voix** définit comment le contenu doit sonner. Le ton, la formalité, la cible et les directives libres y sont regroupées. Vous pouvez définir une voix de base pour votre compte, puis surclasser des champs spécifiques pour des locales individuelles, afin que votre contenu japonais puisse être plus formel tandis que votre contenu en anglais reste conversationnel.

**Terminologie** définit ce que signifient les termes et comment ils doivent être localisés. Chaque entrée contient une définition et des traductions par locale. Lorsqu'un agent rencontre "workspace" dans votre contenu source, la terminologie indique s'il doit traduire, translittérer ou le laisser inchangé, et quel mot utiliser exactement dans chaque langue cible.

Ensemble, la voix et la terminologie constituent une couche contextuelle que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre production a besoin de relecture.

## Versionnement immuable

La mémoire linguistique est uniquement en ajout. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version plutôt que d'écraser l'ancienne. Chaque version enregistre son créateur, la date et une note de changement optionnelle expliquant les évolutions.

Cela signifie que vous avez toujours un historique d'audit complet. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

Le versionnement sécurise également la collaboration. Plusieurs membres de l'équipe peuvent proposer des modifications de voix sans se soucier des conflits, car chaque changement est un événement distinct et traçable.

## Résolution sensible à la localisation

Lorsqu'un agent exécute un workflow pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Il commence par vos paramètres de voix de base puis applique toutes les surcharges spécifiques à la localisation. Le même principe s'applique à la terminologie : seules les entrées ayant un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations distinctes par langue. Définissez vos paramètres par défaut une fois, surchargez là où c'est nécessaire, et laissez le système de résolution gérer le reste.

## Utilisez-le partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible par le biais de la [API REST](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous pouvez l'intégrer dans des flux de travail au-delà de la localisation :

**Marketing et contenu social** -- Intégrez la voix de votre organisation dans un agent de contenu qui rédige des publications sur les réseaux sociaux, des campagnes d'e-mail, ou des textes pour les pages d'atterrissage. La terminologie maintient la cohérence des termes de la marque et les paramètres de voix garantissent que le ton correspond à votre marque.

**Documentation** -- Alimentez la mémoire linguistique dans un pipeline de documentation afin que l'écriture technique suive les mêmes règles de style que le reste de votre contenu. Les entrées de terminologie préviennent la dérive entre la documentation, les articles d'aide et le contenu du produit.

**Revue de code** -- Construisez un agent qui examine le contenu des pull requests (messages d'erreur, étiquettes d'interface, textes d'inscription) par rapport à votre voix et votre terminologie. Relevez les incohérences avant leur déploiement.

**Agents personnalisés** -- Tout client compatible avec MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour la terminologie avec le nouveau nom du produit" ou de "régler le ton de la voix sur professionnel pour la locale allemande" et il traduira votre intention dans le bon appel API.

## Affinement progressif

La mémoire linguistique s'améliore avec l'usage. À chaque fois qu'un réviseur corrige la sortie d'un agent, cette correction est intégrée dans la prochaine version de votre voix ou de votre terminologie. Au fil du temps, l'écart entre le premier jet et le résultat final s'amenuise, et l'étape de révision devient plus rapide.

C'est la boucle de rétroaction au cœur de Glossia : générer, réviser, affiner le contexte, générer à nouveau. Les agents ne se contentent pas de suivre des instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.