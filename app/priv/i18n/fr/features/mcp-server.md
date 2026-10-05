%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents IA et les assistants de codage à Glossia via le Model Context Protocol. Gérez les voix, le glossaire, les organisations et plus encore en utilisant le langage naturel à partir de n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte simple. Les agents IA appellent les outils MCP pour gérer les voix, le glossaire et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à n'importe quel agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et tout client compatible MCP. Intégrez le serveur Glossia dans votre flux de travail existant basé sur des agents et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque requête MCP est authentifiée avec des jetons Bearer OAuth 2.1 et autorisée selon des scopes granulaires. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que l'MCP ?

Le [Model Context Protocol](https://modelcontextprotocol.io) est un standard ouvert pour connecter les assistants IA aux outils et sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au noyau linguistique de la plateforme : configuration vocale, gestion du glossaire, administration de l'organisation et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes par conversation.

**Configuration de la voix** -- Lisez et mettez à jour les paramètres de voix qui contrôlent comment Glossia génère et révise le contenu. Ajustez le ton, la formalité, le public cible et les paramètres locaux sans quitter votre éditeur.

**Gestion du glossaire** -- Maintenez la cohérence du glossaire dans tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées de glossaire pour que les agents utilisent toujours les bons termes.

**Projets** -- Lister et inspecter les projets dans les organisations.

## Comment ça marche

Pointez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton OAuth porteur. Le [guide de configuration MCP](/docs/reference/mcp/overview) Parcourt le flux de connexion complet, y compris l'inscription dynamique du client et PKCE. Le serveur utilise le même système d'authentification et d'autorisation que le [REST API](/features/rest-api), de sorte que tout jeton fonctionnant pour l'API fonctionne pour MCP.

Désormais, votre assistant IA peut utiliser n'importe laquelle des 16 outils. Demandez-lui "créer une organisation nommée Acme" ou "modifiez le ton de ma voix en professionnel" et l'agent traduit votre intention en l'appel d'outil approprié.

## Conçu pour les workflows d'agents

MCP n'est pas seulement une couche pratique. C'est la base pour composer Glossia dans des pipelines d'agents plus larges. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour le glossaire avec de nouveaux termes, ajuster les paramètres de voix pour une localisation spécifique et déclencher une exécution de localisation, tout cela dans une seule conversation.

Car le protocole est standardisé, vous n'êtes pas verrouillé sur un seul client. Passez de Claude, Cursor ou votre propre agent personnalisé sans modifier une seule ligne de configuration.