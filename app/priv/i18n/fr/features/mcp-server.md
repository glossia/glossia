%{
  title: "Serveur MCP",
  summary:
    "Connectez des agents IA et assistants de codage à Glossia via le Model Context Protocol. Gérez les voix, le glossaire, les organisations et plus encore en langage naturel depuis n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents IA appellent des outils MCP pour gérer les voix, le glossaire et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à n'importe quel agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et tout client compatible MCP. Intégrez le serveur Glossia dans votre flux de travail agentic existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque demande MCP est authentifiée avec des jetons Bearer OAuth 2.1 et autorisée contre des scopes granulaires. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---

## Qu'est-ce que MCP ?

Le [Protocole de contexte des modèles](https://modelcontextprotocol.io) est un standard ouvert pour connecter les assistants d'intelligence artificielle à des outils et des sources de données externes. Au lieu de concevoir des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia offre aux agents un accès direct au noyau linguistique de la plateforme : configuration de la voix, gestion du glossaire, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources que vous travaillez quotidiennement. Consultez [la référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez les membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe entières par conversation.

**Configuration de la voix** -- Lisez et mettez à jour les paramètres de voix qui contrôlent comment Glossia génère et révise le contenu. Ajustez le ton, le niveau de formalité, l'audience cible et les surcharges par locale sans quitter votre éditeur.

**Gestion du glossaire** -- Assurez la cohérence du glossaire sur tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées de glossaire afin que les agents utilisent toujours les bons termes.

**Projets** -- Listez et inspectez les projets à travers les organisations.

## Comment cela fonctionne

Orientez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton OAuth bearer. Le [guide de configuration MCP](/docs/reference/mcp/overview) décrit le flux de connexion complet, y compris l'enregistrement dynamique du client et le PKCE. Le serveur utilise le même système d'authentification et d'autorisation que le [API REST](/features/rest-api), donc tout jeton qui fonctionne pour l'API fonctionne pour MCP.

Dès lors, votre assistant IA peut appeler n'importe lequel des 16 outils. Demandez-lui de "créer une organisation nommée Acme" ou "mettre à jour le ton de ma voix vers professionnel" et l'agent traduit votre intention dans l'appel d'outil approprié.

## Conçu pour les workflows d'agents

MCP n'est pas seulement une couche de commodité. C'est la fondation pour composer Glossia dans des pipelines d'agents plus vastes. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour le glossaire avec de nouveaux termes, ajuster les paramètres de voix pour un locale spécifique et déclencher une exécution de localisation, tout cela dans une seule conversation.

Comme le protocole est normalisé, vous n'êtes pas verrouillé sur un client unique. Basculez entre Claude, Cursor ou votre propre agent personnalisé sans modifier une ligne de configuration.
