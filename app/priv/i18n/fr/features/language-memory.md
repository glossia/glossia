%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, la terminologie et le style de votre organisation. La mémoire linguistique guide chaque workflow d'agent et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et auditable",
      description:
        "Toute modification de votre voix ou de votre terminologie crée une nouvelle version immuable. Vous pouvez consulter l'historique, comparer les itérations et revenir en arrière si quelque chose dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer des contenus marketing, rédiger de la documentation, examiner les pull requests ou créer des posts sociaux, le tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Alimentez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous écrivez.",
      icon: "puzzle"
    }
  ]
}
---
## Quelle est la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle est composée de deux primitives centrales que vous créez et affinez au fil du temps :

**Voix** définit comment le contenu devrait s'entendre. Le ton, la formalité, le public cible et les directives libres résident ici. Vous pouvez définir une voix de base pour votre compte et surcharger des champs spécifiques pour chaque localisation, de sorte que votre contenu japonais puisse être plus formel tandis que votre anglais reste conversationnel.

**Terminologie** définit la signification des termes et comment ils doivent être traduits. Chaque entrée contient une définition et des traductions par localisation. Lorsqu'un agent rencontre "workspace" dans votre contenu source, la terminologie lui indique s'il doit le localiser, le translittérer ou le laisser tel quel, et exactement quel mot utiliser dans chaque langue cible.

Ensemble, la voix et la terminologie forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre sortie nécessite de relecture.

## Versionnement immuable

La mémoire linguistique est append-only. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version au lieu de remplacer l'ancienne. Chaque version enregistre par qui elle a été créée, quand, et une note de modification optionnelle expliquant les évolutions.

Cela signifie que vous disposez toujours d'une trace d'audit complète. Vous pouvez comparer la version 3 contre la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

La versionnisation rend également la collaboration plus sûre. Plusieurs membres d'équipe peuvent proposer des modifications de voix sans s'inquiéter des conflits, car chaque changement est un événement discret et traçable.

## Résolution locale-adaptée

Lorsqu'un agent exécute un workflow pour une locale spécifique, Glossia résout la mémoire linguistique pour ce contexte. Cela commence par vos paramètres de voix de base et applique ensuite les surcharges spécifiques à la locale. Il en va de même pour la terminologie : seules les entrées ayant un terme localisé pour la locale cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations distinctes par langue. Définissez vos paramètres par défaut une fois, surchargez là où cela compte, et laissez le système de résolution gérer le reste.

## Utilisez-la partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible via le [API REST](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous pouvez l'intégrer à des workflows au-delà de la localisation :

**Marketing et contenu social** -- Intégrez la voix de votre organisation dans un agent de contenu qui rédige des publications sur les réseaux sociaux, des campagnes par e-mail ou des textes pour page d'atterrissage. La Terminologie maintient la cohérence des termes de marque et les paramètres de voix assurent que le ton correspond à votre marque.

**Documentation** -- Aliménez la mémoire linguistique dans un pipeline de documentation afin que l'écriture technique respecte les mêmes règles de style que le reste de votre contenu. Les entrées de Terminologie empêchent la dérive entre la documentation, les articles d'aide et le contenu intégré au produit.

**Revue de code** -- Construisez un agent qui examine le contenu des pull requests (messages d'erreur, libellés d'interface, textes d'onboarding) par rapport à votre voix et terminologie. Signalez les incohérences avant leur publication.

**Agents personnalisés** -- Tout client compatible MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour la terminologie avec le nouveau nom de produit" ou de "régler le ton de la voix sur professionnel pour la localisation allemande" et il traduira votre intention dans le bon appel API.

## Affinement progressif

La mémoire linguistique s'améliore avec l'utilisation. Chaque fois qu'un réviseur corrige la sortie d'un agent, cette correction s'intègre dans la prochaine version de votre voix ou de votre terminologie. Au fil du temps, l'écart entre le premier jet et la sortie finale se réduit, et l'étape de révision devient plus rapide.

C'est la boucle de rétroaction au cœur de Glossia : générer, vérifier, affiner le contexte, générer à nouveau. Les agents ne se contentent pas de suivre les instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.