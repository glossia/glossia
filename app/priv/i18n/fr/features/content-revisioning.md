%{
  title: "Révision du contenu",
  summary:
    "Améliorez votre contenu existant en place. Glossia analyse les fichiers sources pour la clarté, la précision et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes pour relecture.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent votre texte pour la lisibilité, le jargon et la cohérence avec la voix de votre marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut remplacer l'original ou être écrit sur un chemin séparé. Vous contrôlez toujours la destination de sortie.",
      icon: "shield-check"
    },
    %{
      title: "Boucle de rétroaction",
      description:
        "Les réviseurs corrigent la sortie, mettent à jour le contexte, et chaque cycle réduit l'écart entre le brouillon et la version finale.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers sources et le graphe de contexte, en fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans des sous-répertoires) avec le contexte distant (vos paramètres de voix, terminologie et style au niveau du compte). Une fois l'ensemble assemblé, il réécrit le contenu pour la clarté, la précision et le ton, puis génère la version révisée prête à la révision.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend sur votre compte et votre dépôt. Les paramètres au niveau du compte, comme la voix et la terminologie, fournissent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des ajustements locaux. L'agent résout ce graphe à chaque exécution, afin que vos instructions restent cohérentes à travers les fichiers sans que vous ayez à les répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est révisé.

## Affinement progressif

Chaque cycle de révision améliore le résultat. Les corrections sont réintroduites dans les fichiers de contexte, de sorte que les erreurs répétées disparaissent et que le résultat converge vers le standard de votre équipe au fil du temps.