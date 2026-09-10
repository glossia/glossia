%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers sources pour la clarté, l'exactitude et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes pour la révision.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents vérifient votre texte pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut remplacer l'original ou être écrit vers un chemin séparé. Vous avez toujours le contrôle de la destination de sortie.",
      icon: "shield-check"
    },
    %{
      title: "Boucle de rétroaction",
      description:
        "Les réviseurs corrigent la sortie, mettent à jour le contexte, et chaque cycle réduit l'écart entre le brouillon et le final.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (les fichiers `L10N.md` à la racine ou dans des sous-répertoires) avec le contexte distant (vos paramètres de voix, de terminologie et de style au niveau du compte). Une fois l'ensemble complet assemblé, il réécrit le contenu pour ses objectifs de clarté, d'exactitude et de ton, puis produit la version révisée prête à l'examen.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend de votre compte à votre dépôt. Les paramètres au niveau du compte, comme la voix et la terminologie, fournissent une base de référence globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des ajustements locaux. L'agent résout ce graphe à chaque exécution, de sorte que vos instructions restent cohérentes entre les fichiers sans que vous ayez à répéter vos consignes. Les examens sont incrémentaux grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est réexaminé.

## Raffinement progressif

Chaque cycle d'examen améliore la sortie. Les corrections alimentent les fichiers de contexte, de sorte que les erreurs répétées disparaissent et que la sortie converge vers les normes de votre équipe au fil du temps.