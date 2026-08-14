%{
  title: "Serveur MCP",
  summary: "Connectez les agents d’IA et les assistants de programmation à Glossia via le Model Context Protocol. Gérez les voix, la terminologie, les organisations et bien plus encore en langage naturel depuis tout client compatible avec MCP.",
  order: 3,
  icon: "cpu",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Interface en langage naturel", description: "Interagissez avec le moteur linguistique de Glossia en texte libre. Les agents d’IA appellent les outils MCP pour gérer les voix, la terminologie et les organisations sans écrire de code.", icon: "message-square-text"},
    %{title: "Compatible avec tous les agents", description: "Fonctionne avec Claude, Cursor, Windsurf et tout client compatible avec MCP. Intégrez le serveur Glossia à votre flux de travail agentique existant et commencez immédiatement à l’utiliser.", icon: "puzzle"},
    %{title: "Sécurisé par défaut", description: "Chaque requête MCP est authentifiée avec des jetons porteurs OAuth 2.1 et autorisée selon des portées précises. Elle bénéficie du même modèle de sécurité que l’API REST.", icon: "shield-check"}
  ]
}
---
## Qu’est-ce que MCP ?

Le [Model Context Protocol](https://modelcontextprotocol.io) est une norme ouverte permettant de connecter des assistants d’intelligence artificielle à des outils et à des sources de données externes. Au lieu de créer des intégrations personnalisées pour chaque assistant de programmation, vous exposez un serveur MCP unique que tout client compatible peut utiliser.

Le serveur MCP de Glossia donne aux agents un accès direct au cœur linguistique de la plateforme : configuration de la voix, gestion de la terminologie, administration des organisations et liste des projets.

## Outils disponibles

Le serveur MCP expose 16 outils organisés selon les ressources que vous utilisez quotidiennement. Consultez la [référence complète des outils](/docs/reference/mcp/tools) pour connaître les paramètres et les modalités d’utilisation.

**Comptes et organisations** -- Répertoriez vos comptes, créez et gérez des organisations, invitez des membres et contrôlez les accès. Les agents peuvent mettre en place des structures d’équipe complètes par le biais d’une conversation.

**Configuration de la voix** -- Consultez et mettez à jour les paramètres de voix qui contrôlent la manière dont Glossia génère et révise le contenu. Ajustez le ton, le niveau de formalité, le public cible et les paramètres propres à chaque langue sans quitter votre éditeur.

**Gestion de la terminologie** -- Assurez la cohérence de la terminologie dans l’ensemble de votre contenu. Ajoutez, mettez à jour et versionnez les entrées de terminologie afin que les agents utilisent toujours les termes appropriés.

**Projets** -- Répertoriez et examinez les projets de toutes les organisations.

## Fonctionnement

Configurez votre client MCP pour qu’il se connecte à `https://your-glossia-instance/mcp`, puis authentifiez-vous avec un jeton porteur OAuth. Le [guide de configuration de MCP](/docs/reference/mcp/overview) présente l’intégralité du processus de connexion, notamment l’enregistrement dynamique du client et PKCE. Le serveur utilise le même système d’authentification et d’autorisation que l’[API REST](/features/rest-api). Tout jeton compatible avec l’API fonctionne donc également avec MCP.

Votre assistant d’intelligence artificielle peut ensuite appeler n’importe lequel des 16 outils. Demandez-lui de « créer une organisation appelée Acme » ou de « définir le ton de ma voix comme professionnel ». L’agent traduit alors votre intention en appel d’outil approprié.

## Conçu pour les flux de travail fondés sur des agents

MCP n’est pas seulement une couche pratique. Il constitue la base permettant d’intégrer Glossia à de plus grands pipelines fondés sur des agents. Au cours d’une même conversation, un assistant de programmation peut analyser votre base de code, détecter le contenu non localisé, enrichir la terminologie avec de nouveaux termes, ajuster les paramètres de voix pour une langue spécifique et déclencher une exécution de localisation.

Le protocole étant normalisé, vous ne dépendez d’aucun client particulier. Passez de Claude à Cursor ou à votre propre agent personnalisé sans modifier une seule ligne de configuration.