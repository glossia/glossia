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
        "Tout changement apporté à votre voix ou à votre terminologie crée une nouvelle version immuable. Vous pouvez examiner l'historique, comparer les itérations et revenir en arrière si une dérive survient.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer le contenu marketing, rédiger de la documentation, réviser des pull requests, ou créer des publications sociales, le tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Intégrez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous écrivez.",
      icon: "puzzle"
    }
  ]
}
---
## Qu'est-ce que la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle est constituée de deux primitives fondamentales que vous créez et affinez au fil du temps :

**Voix** définit la manière dont le contenu doit sonner. Le ton, la formalité, le public cible et les directives libres y figurent tous. Vous pouvez définir une voix de base pour votre compte, puis surcharger des champs spécifiques pour chaque localisation, de sorte que vos textes japonais puissent être plus formels, tandis que vos textes anglais restent conversationnels.

**Terminologie** définit ce que signifient les termes et comment ils doivent être adaptés. Chaque entrée comporte une définition et des traductions par localisation. Lorsqu'un agent rencontre "workspace" dans votre contenu source, la terminologie indique s'il faut le traduire, le translittérer ou le laisser tel quel, et exactement quel mot utiliser dans chaque langue cible.

Ensemble, la voix et la terminologie forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre résultat nécessite de révision.

## Versionnement immuable

La mémoire linguistique est append-only. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version plutôt que de remplacer l'ancienne. Chaque version enregistre qui l'a créée, quand, et une note de modification optionnelle expliquant les évolutions.

Cela signifie que vous disposez toujours d'une trace d'audit complète. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un récent changement a introduit des incohérences, revenez à une version précédente et continuez.

Le versionnement sécurise également la collaboration. Plusieurs membres de l'équipe peuvent proposer des modifications de voix sans craindre les conflits, car chaque changement est un événement distinct et traçable.

## Résolution sensible à la localisation

Lorsqu'un agent exécute un flux de travail pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Elle commence par vos paramètres de voix de base et applique ensuite toute surcharge locale spécifique au-dessus. Le même traitement s'applique à la terminologie : seules les entrées disposant d'un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations distinctes par langue. Définissez vos valeurs par défaut une seule fois, surchargez-les là où cela compte, et laissez le système de résolution gérer le reste.

## Utilisez-le partout

La mémoire linguistique est conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible via le [REST API](/features/rest-api) et le [MCP server](/features/mcp-server), vous pouvez l'intégrer dans des flux de travail au-delà de la localisation :

**Marketing et contenu social** -- Intégrez la voix de votre organisation dans un agent de contenu qui rédige des publications sur les réseaux sociaux, des campagnes e-mail ou du texte de page d'atterrissage. Terminologie maintient les termes de marque cohérents et les paramètres de la voix assurent que le ton correspond à votre marque.

**Documentation** -- Alimentez la mémoire linguistique dans une pipeline de documentation afin que la rédaction technique suive les mêmes règles de style que le reste de votre contenu. Les entrées de Terminologie empêchent la dérive au sein des docs, des articles d'aide et du contenu du produit.

**Revue de code** -- Construisez un agent qui examine le contenu des pull requests (messages d'erreur, étiquettes d'interface, textes de prise en main) par rapport à votre voix et terminologie. Signalez les incohérences avant publication.

**Agents personnalisés** -- Tout client compatible MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour la terminologie avec le nouveau nom de produit" ou de "définir le ton vocal au professionnel pour la locale allemande" et il traduira votre intention vers l'appel API approprié.

## Raffinement progressif

\-- La mémoire linguistique s'améliore avec l'usage. Chaque fois qu'un réviseur corrige la sortie d'un agent, cette correction se réinjecte dans la prochaine version de votre voix ou terminologie. Au fil du temps, l'écart entre le premier jet et le résultat final se réduit, et l'étape de revue devient plus rapide.

C'est la boucle de rétroaction au cœur de Glossia : générer, réviser, affiner le contexte, générer de nouveau. Les agents ne suivent pas seulement les instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.