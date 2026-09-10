%{
  title: "Serveur MCP",
  summary:
    "Connectez les agents d'IA et les assistants de codage à Glossia via le protocole de contexte de modèle (MCP). Gérez les voix, la terminologie, les organisations et plus avec un langage naturel depuis n'importe quel client compatible MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Interface de langage naturel",
      description:
        "Interagissez avec le moteur linguistique de Glossia via du texte brut. Les agents d'IA utilisent les outils MCP pour gérer les voix, la terminologie et les organisations sans écrire de code.",
      icon: "message-square-text"
    },
    %{
      title: "Connectez-vous à n'importe quel agent",
      description:
        "Fonctionne avec Claude, Cursor, Windsurf et n'importe quel client compatible MCP. Déposez le serveur Glossia dans votre workflow agéntique existant et commencez à l'utiliser immédiatement.",
      icon: "puzzle"
    },
    %{
      title: "Sécurisé par défaut",
      description:
        "Chaque requête MCP est authentifiée avec des jetons OAuth 2.1 porteurs et autorisée contre des périmètres fins. Le même modèle de sécurité que l'API REST.",
      icon: "shield-check"
    }
  ]
}
---
## Qu'est-ce que MCP ?

Le [Protocole de contexte des modèles](https://modelcontextprotocol.io) est une norme ouverte permettant de connecter les assistants IA à des outils et sources de données externes. Plutôt que de développer des intégrations personnalisées pour chaque assistant de codage, vous exposez un seul serveur MCP et tout client compatible peut l'utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au noyau linguistique de la plateforme : configuration vocale, gestion terminologique, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés autour des ressources avec lesquelles vous travaillez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour les paramètres et les détails d'utilisation.

**Comptes et organisations** -- Listez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez l'accès. Les agents peuvent configurer des structures d'équipe complètes par conversation.

**Configuration de la voix** -- Consultez et mettez à jour les paramètres de voix qui contrôlent la façon dont Glossia génère et révise le contenu. Ajustez le ton, la formalité, le public cible et les paramètres locaux sans quitter votre éditeur.

**Gestion de la terminologie** -- Maintenez la cohérence terminologique dans tout votre contenu. Ajoutez, mettez à jour et versionnez les entrées de terminologie pour que les agents utilisent toujours les bons termes.

**Projets** -- Lister et inspecter les projets dans les organisations.

## Comment cela fonctionne

Orientez votre client MCP vers `https://your-glossia-instance/mcp` et authentifiez avec un jeton bearer OAuth. Le [guide de configuration MCP](/docs/reference/mcp/overview) décrit le flux complet de connexion, y compris l'inscription dynamique du client et PKCE. Le serveur utilise le même système d'authentification et d'autorisation que le [REST API](/features/rest-api)", donc tout jeton qui fonctionne pour l'API fonctionne pour MCP."

À partir de là, votre assistant IA peut appeler l'un des 16 outils. Demandez-lui de "créer une organisation nommée Acme" ou de "mettre à jour ma tonalité de voix en professionnelle" et l'agent traduit votre intention vers l'appel d'outil approprié.

## Conçu pour les workflows agents

MCP n'est pas seulement une couche de commodité. C'est la fondation pour composer Glossia dans des pipelines agents plus vastes. Un assistant de codage peut lire votre base de code, détecter le contenu non localisé, mettre à jour la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une locale spécifique, et déclencher une exécution de localisation, tout cela dans une conversation unique.

Puisque le protocole est standardisé, vous n'êtes pas verrouillé à un client unique. Basculez entre Claude, Cursor ou votre propre agent personnalisé sans modifier une ligne de configuration.