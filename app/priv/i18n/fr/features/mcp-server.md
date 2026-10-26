%{
  title: "Serveur MCP",
  summary:
    "Connectez des agents IA et assistants de codage à Glossia via le protocole de contexte du modèle (MCP). Gérez les voix, le glossaire, les organisations, et plus encore en utilisant un langage naturel depuis tout client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte simple. Les agents IA appellent des outils MCP pour gérer les voix, le glossaire et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à n'importe quel agent",
      description:
        "Compatible avec Claude, Cursor, Windsurf et tout client compatible MCP. Intégrez le serveur Glossia à votre flux de travail agentic existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque demande MCP est authentifiée avec des jetons OAuth 2.1 et autorisée sur des scopes granulaires. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---

## Qu'est-ce que le MCP ?

Le [Protocole de contexte du modèle](https://modelcontextprotocol.io) est une norme ouverte pour connecter les assistants d'IA à des outils et sources de données externes. Au lieu de construire des intégrations personnalisées pour chaque assistant de codage, vous exposez un serveur MCP unique et n'importe quel client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au noyau linguistique de la plateforme : configuration de la voix, gestion du glossaire, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe entières par conversation.

**Configuration de la voix** -- Lisez et mettez à jour les paramètres de voix qui contrôlent la façon dont Glossia génère et révise le contenu. Ajustez le ton, la formalité, le public cible et les surcharges locales sans quitter votre éditeur.

**Gestion du glossaire** -- Maintenez la cohérence du glossaire sur tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées du glossaire pour que les agents utilisent toujours les bons termes.

**Projets** -- Listez et inspectez les projets à travers les organisations.

## Comment cela fonctionne

Orientez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton porteur OAuth. Le [guide de configuration MCP](/docs/reference/mcp/overview) décrit le flux de connexion complet, incluant l'enregistrement dynamique du client et le PKCE. Le serveur utilise le même système d'authentification et d'autorisation que la [REST API](/features/rest-api), de sorte que n'importe quel jeton fonctionnant pour l'API fonctionne pour MCP.

À partir de là, votre assistant d'IA peut appeler n'importe lequel des 16 outils. Demandez-lui de "créer une organisation nommée Acme" ou de "mettre à jour le ton de ma voix à professionnel" et l'agent traduit votre intention dans l'appel d'outil approprié.

## Conçu pour les workflows agés

MCP n'est pas qu'une couche de commodité. C'est la fondation pour composer Glossia dans des pipelines agés plus grands. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour le glossaire avec de nouveaux termes, ajuster les paramètres de voix pour une locale spécifique, et déclencher une exécution de localisation, le tout dans une seule conversation.

Étant donné que le protocole est standardisé, vous n'êtes pas verrouillé sur un client unique. Basculez entre Claude, Cursor ou votre propre agent personnalisé sans changer une ligne de configuration.
