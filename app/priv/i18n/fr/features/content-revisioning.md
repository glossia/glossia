%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers sources pour la clarté, la précision et le ton grâce au contexte que vous fournissez, puis produit des versions révisées prêtes à l'examen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent vos textes pour la lisibilité, le jargon et la cohérence avec la voix de votre marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut écraser l'original ou écrire dans un chemin séparé. Vous contrôlez toujours la destination de sortie.",
      icon: "shield-check"
    },
    %{
      title: "Boucle de rétroaction",
      description:
        "Les relecteurs corrigent le résultat, mettent à jour le contexte, et chaque cycle réduit l'écart entre le brouillon et la version finale.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers source et le graphe de contexte, fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte distant (votre voix, glossaire et paramètres de style au niveau du compte). Une fois l'ensemble complet assemblé, il réécrit le contenu pour la clarté, l'exactitude et le ton, puis génère la version révisée prête pour la relecture.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui relie votre compte et votre dépôt. Les paramètres au niveau du compte, comme la voix et le glossaire, fixent une base de référence globale, tandis que les fichiers `L10N.md` placés aux côtés de votre contenu ajoutent des surcharges locales. L'agent résout ce graphe à chaque exécution, garantissant que vos instructions restent cohérentes entre les fichiers sans avoir à répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est réexaminé.

## Affinement progressif

Chaque cycle de révision améliore le résultat. Les corrections s'intègrent dans les fichiers de contexte, ce qui fait disparaître les erreurs répétées et permet au résultat de converger vers le standard de votre équipe au fil du temps.