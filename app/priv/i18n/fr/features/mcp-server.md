%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents IA et les assistants de codage à Glossia via le Model Context Protocol. Gérez les voix, la terminologie, les organisations et bien plus encore en utilisant la langue naturelle depuis n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface en langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents IA utilisent les outils MCP pour gérer les voix, la terminologie et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à n'importe quel agent",
      description:
        "Compatible avec Claude, Cursor, Windsurf et tout client compatible MCP. Ajoutez le serveur Glossia à votre flux de travail agentique existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque requête MCP est authentifiée avec des jetons Bearer OAuth 2.1 et autorisée contre des portées à granularité fine. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que MCP ?

Le [Model Context Protocol](https://modelcontextprotocol.io) est une norme ouverte pour connecter les assistants IA à des outils et sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et n'importe quel client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au cœur linguistique de la plateforme : configuration de la voix, gestion de la terminologie, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes via la conversation.

**Configuration de la voix** -- Lisez et mettez à jour les paramètres de voix qui contrôlent comment Glossia génère et révis le contenu. Ajustez le ton, le niveau de formalité, le public cible et les surcharges par locale sans quitter votre éditeur.

**Gestion de la terminologie** -- Assurez la cohérence de la terminologie dans tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées terminologiques pour que les agents utilisent toujours les bons termes.

**Projets** -- Listez et inspectez les projets dans les organisations.

## Comment cela fonctionne

Orientez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton OAuth bearer. Le [guide de configuration MCP](/docs/reference/mcp/overview) détaille le flux de connexion complet, y compris l'enregistrement dynamique des clients et le PKCE. Le serveur utilise le même système d'authentification et d'autorisation que l'API [REST API](/features/rest-api), donc n'importe quel jeton qui fonctionne pour l'API fonctionne pour MCP.

À partir de là, votre assistant IA peut utiliser n'importe lequel des 16 outils. Demandez-lui de « créer une organisation nommée Acme » ou de « mettre à jour le ton de ma voix à professionnel » et l'agent traduit votre intention en appel d'outil approprié.

## Conçu pour les workflows agenciques

MCP n'est pas seulement une couche de commodité. C'est la fondation pour composer Glossia dans de plus grands pipelines agenciques. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une localisation spécifique et déclencher une exécution de localisation, le tout dans une seule conversation.

Comme le protocole est normalisé, vous n'êtes pas verrouillé sur un client unique. Basculez entre Claude, Cursor ou votre propre agent personnalisé sans changer une ligne de configuration.