%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents IA et les assistants de codage à Glossia via le protocole MCP. Gérez les voix, la terminologie, les organisations et plus en langage naturel à partir de tout client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface en langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents IA appellent les outils MCP pour gérer les voix, la terminologie et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Intégrez n'importe quel agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et tout client compatible MCP. Intégrez le serveur Glossia dans votre flux de travail agentique existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque requête MCP est authentifiée avec des jetons OAuth 2.1 d'accès et autorisée selon des scopes à granularité fine. Le même modèle de sécurité que celui de l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que MCP ?

Le [Protocole de contexte des modèles](https://modelcontextprotocol.io) est un standard ouvert pour connecter les assistants IA aux outils et sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au noyau linguistique de la plateforme : configuration de la voix, gestion de la terminologie, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes via la conversation.

**Configuration de la voix** -- Affichez et mettez à jour les paramètres de voix qui contrôlent la manière dont Glossia génère et réédite le contenu. Ajustez le ton, la formalité, le public cible et les personnalisations par locale sans quitter votre éditeur.

**Gestion de la terminologie** -- Maintenez la cohérence terminologique dans tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées de terminologie pour que les agents utilisent toujours les termes appropriés.

**Projets** -- Liste et inspectez les projets à travers les organisations.

## Comment cela fonctionne

Pointez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez-vous avec un jeton OAuth bearer. Le [guide de configuration MCP](/docs/reference/mcp/overview) parcourt le flux de connexion complet, y compris l'enregistrement dynamique de client et PKCE. Le serveur utilise le même système d'authentification et d'autorisation que [API REST](/features/rest-api), donc n'importe quel jeton qui fonctionne pour l'API fonctionnera pour MCP.

À partir de là, votre assistant IA peut invoker l'un des 16 outils. Demandez-lui de "créer une organisation nommée Acme" ou de "mettre à jour mon ton de voix en professionnel" et l'agent traduit votre intention en l'appel d'outil approprié.

## Conçu pour les flux de travail d'agents

MCP ne se limite pas à une couche de commodité. C'est la fondation permettant de composer Glossia dans des pipelines d'agents plus vastes. Un assistant de codage peut lire votre codebase, détecter le contenu non localisé, mettre à jour la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une localisation spécifique et lancer une exécution de localisation, le tout dans une seule conversation.

Le protocole étant standardisé, vous n'êtes pas verrouillé par un seul client. Alternez entre Claude, Cursor, ou votre propre agent personnalisé sans modifier une seule ligne de configuration.