%{
  title: "Révision du contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers sources pour clarté, précision et ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes pour la relecture.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent votre texte pour sa lisibilité, le jargon et la cohérence avec votre ton de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut écraser l'original ou être écrit vers un chemin séparé. Vous contrôlez toujours la destination de sortie.",
      icon: "shield-check"
    },
    %{
      title: "Boucle de rétroaction",
      description:
        "Les réviseurs corrigent la sortie, mettent à jour le contexte et chaque cycle réduit l'écart entre le brouillon et la version finale.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers source et le graphe de contexte, en fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte distant (votre voix, votre terminologie et vos réglages de style au niveau du compte). Une fois le contexte complet assemblé, il réécrit le contenu pour sa clarté, son exactitude et son ton, puis génère la version révisée prête pour la revue.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui relie votre compte et votre référentiel. Les paramètres au niveau du compte, tels que la voix et la terminologie, constituent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des surcharges locales. L'agent résout ce graphe à chaque exécution, afin que vos instructions restent cohérentes entre les fichiers sans que vous ayez à vous répéter. Les revues sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est revisité.

## Affinement progressif

Chaque cycle de révision améliore le résultat. Les corrections alimentent les fichiers de contexte, de sorte que les erreurs récurrentes disparaissent et que le résultat converge vers la norme de votre équipe au fil du temps.