%{
  title: "serveur MCP",
  summary:
    "Connectez les agents IA et les assistants de codage à Glossia via le protocole MCP. Gérez les voix, le glossaire, les organisations et plus encore en utilisant un langage naturel à partir de tout client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface en langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents IA appellent les outils MCP pour gérer les voix, le glossaire et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à tout agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et tout client compatible MCP. Intégrez le serveur Glossia à votre flux de travail d'agents existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque demande MCP est authentifiée avec des jetons OAuth 2.1 Bearer et autorisée selon des portées granulaires. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---

## Qu'est-ce que MCP ?

Le [Protocole de contexte des modèles](https://modelcontextprotocol.io) est un standard ouvert pour connecter les assistants IA aux outils et sources de données externes. Au lieu de construire des intégrations personnalisées pour chaque assistant de codage, vous exposez un serveur MCP unique et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au noyau linguistique de la plateforme : la configuration vocale, la gestion du glossaire, l'administration des organisations et la liste de projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes par conversation.

**Configuration de la voix** -- Lisez et mettez à jour les paramètres vocaux qui contrôlent la manière dont Glossia génère et révis le contenu. Ajustez le ton, la formalité, le public cible et les paramètres par locale sans quitter votre éditeur.

**Gestion du glossaire** -- Maintenez la cohérence du glossaire sur tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées du glossaire afin que les agents utilisent toujours les bons termes.

**Projets** -- Listez et inspectez les projets à travers les organisations.

## Comment cela fonctionne

Pointez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton de connexion OAuth. Le [guide de configuration MCP](/docs/reference/mcp/overview) décrit le flux de connexion complet, y compris l'inscription dynamique du client et PKCE. Le serveur utilise le même système d'authentification et d'autorisation que l'[API REST](/features/rest-api), de sorte que n'importe quel jeton qui fonctionne pour l'API fonctionne aussi pour MCP.

À partir de là, votre assistant IA peut appeler l'un des 16 outils. Demandez-lui de \"créer une organisation nommée Acme\" ou de \"mettre le ton de ma voix à professionnel\" et l'agent traduit votre intention en l'appel d'outil approprié.

## Conçu pour les flux de travail d'agents

MCP n'est pas seulement une couche de commodité. C'est le fondement pour intégrer Glossia dans des pipelines d'agents plus vastes. Un assistant de codage peut lire votre code source, détecter le contenu non localisé, mettre à jour le glossaire avec de nouveaux termes, ajuster les paramètres vocaux pour une locale spécifique et déclencher une exécution de localisation, le tout dans une seule conversation.

Puisque le protocole est normalisé, vous n'êtes pas verrouillé dans un seul client. Basculez entre Claude, Cursor ou votre propre agent personnalisé sans modifier une ligne de configuration.
