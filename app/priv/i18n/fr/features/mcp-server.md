%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents IA et assistants de programmation à Glossia via le Model Context Protocol. Gérez les voix, terminologies, organisations et plus encore en langage naturel via n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Langage naturel",
      description:
        "Interagissez avec l'analyse linguistique de Glossia via du texte simple. Les agents IA appellent les outils MCP pour gérer les voix, terminologies et organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Se brancher à n'importe quel agent",
      description:
        "Compatible avec Claude, Cursor, Windsurf et n'importe quel client compatible MCP. Ajoutez le serveur Glossia à votre flux de travail agent existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque requête MCP est authentifiée avec des jetons OAuth 2.1 et autorisée selon des périmètres fins. le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que MCP ?

Le [Model Context Protocol](https://modelcontextprotocol.io) est un standard ouvert pour connecter les assistants IA à des outils et sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de codage, vous exposez un serveur MCP unique et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au cœur linguistique de la plateforme : configuration de la voix, gestion de la terminologie, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources que vous utilisez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les détails des paramètres et d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes par conversation.

**Configuration de la voix** -- Consultez et mettez à jour les paramètres de la voix qui contrôlent comment Glossia génère et révise le contenu. Ajustez le ton, la formalité, le public cible et les adaptations par locale sans quitter votre éditeur.

**Gestion de la terminologie** -- Maintenez la cohérence terminologique sur tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées de terminologie afin que les agents utilisent toujours les bons termes.

**Projets** -- Lister et inspecter les projets à travers les organisations.

## Comment cela fonctionne

Pointez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton Bearer OAuth. Le [guide de configuration MCP](/docs/reference/mcp/overview) parcourt le flux de connexion complet, incluant l'enregistrement dynamique du client et PKCE. Le [REST API](/features/rest-api), donc n'importe quel jeton qui fonctionne avec l'API fonctionne également pour MCP.

À partir de là, votre assistant IA peut utiliser l'une des 16 outils. Demandez-lui de « créer une organisation nommée Acme » ou de « mettre à jour la tonalité de ma voix vers un ton professionnel » et l'agent traduit votre intention dans l'appel d'outil approprié.

## Conçu pour les flux de travail d'agents

MCP n'est pas seulement une couche de commodité. C'est le socle pour intégrer Glossia dans de plus grands pipelines d'agents. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une localisation spécifique, et déclencher une exécution de localisation, le tout dans une seule conversation.

Étant donné que le protocole est standardisé, vous n'êtes pas verrouillé dans un client unique. Passez entre Claude, Cursor ou votre propre agent personnalisé sans modifier une seule ligne de configuration.