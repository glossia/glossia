%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents d'IA et assistants de codage à Glossia via le Model Context Protocol. Gérez les voix, la terminologie, les organisations et plus encore grâce à la langue naturelle depuis n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface en langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents IA invoquent des outils MCP pour gérer les voix, la terminologie et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez à n'importe quel agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et n'importe quel client compatible MCP. Intégrez le serveur Glossia à votre flux de travail agentic et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Toute requête MCP est authentifiée avec des jetons OAuth 2.1 Bearer et autorisée contre des scopes granulaires. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que MCP ?

Le [protocole de contexte des modèles](https://modelcontextprotocol.io) est une norme ouverte permettant de connecter les assistants IA à des outils et sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia offre aux agents un accès direct au cœur linguistique de la plateforme : configuration de la voix, gestion de la terminologie, administration de l'organisation et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez au quotidien. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Lister vos comptes, créer et gérer des organisations, inviter des membres, et contrôler l'accès. Les agents peuvent configurer des structures d'équipe complètes par conversation.

**Configuration de la voix** -- Consulter et mettre à jour les paramètres de voix qui contrôlent la façon dont Glossia génère et révise le contenu. Ajuster le ton, le niveau de formalité, le public cible et les surcharges locales sans quitter votre éditeur.

**Gestion de terminologie** -- Maintenir la cohérence terminologique dans tout votre contenu. Ajouter, mettre à jour et versionner les entrées de terminologie afin que les agents utilisent toujours les bons termes.

**Projets** -- Lister et inspecter les projets au sein des organisations.

## Comment ça marche

Configurez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton bearer OAuth. Le [guide de configuration MCP](/docs/reference/mcp/overview) décrit le flux de connexion complet, y compris l'enregistrement dynamique du client et PKCE. Le [REST API](/features/rest-api), donc tout jeton qui fonctionne pour l'API fonctionne également pour MCP.

À partir de là, votre assistant IA peut appeler l'un des 16 outils. Demandez-lui de \\"créer une organisation nommée Acme\\" ou de \\"mettre à jour mon ton de voix pour le rendre professionnel\\" et l'agent traduit votre intention dans le bon appel d'outil.

## Conçu pour les workflows d'agents

MCP n'est pas seulement une couche de commodité. C'est la fondation pour intégrer Glossia dans de plus grands pipelines d'agents. Un assistant de codage peut lire votre codebase, détecter le contenu non localisé, mettre à jour la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une locale spécifique, et déclencher une exécution de localisation, le tout dans une seule conversation.

Comme le protocole est standardisé, vous n'êtes pas cantonné à un client unique. Passez de Claude à Cursor, ou à votre propre agent personnalisé, sans modifier une ligne de configuration.