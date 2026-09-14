%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant en place. Glossia examine les fichiers sources pour la clarté, l'exactitude et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes à être revues.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents relisent vos textes pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non destructif",
      description:
        "Le contenu révisé peut écraser l'original ou s'écrire dans un chemin séparé. Vous contrôlez toujours la destination de sortie.",
      icon: "shield-check"
    },
    %{
      title: "Boucle de rétroaction",
      description:
        "Les réviseurs corrigent le résultat, mettent à jour le contexte et chaque cycle réduit l'écart entre le brouillon et la version finale.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte distant (vos paramètres de voix, de terminologie et de style au niveau du compte). Une fois l'ensemble complet assemblé, il réécrit le contenu pour la clarté, la précision et le ton, puis fournit la version révisée prête pour la revue.

## Graphe de contexte

Dans Glossia, le contexte est un graphe qui englobe votre compte et votre dépôt. Les paramètres de compte comme la voix et la terminologie fournissent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des surcharges locales. L'agent résout ce graphe à chaque exécution, afin que vos instructions restent cohérentes à travers les fichiers sans devoir les répéter. Les revues sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est réexaminé.

## Affinement progressif

Chaque cycle de revue améliore la sortie. Les corrections sont réinjectées dans les fichiers de contexte, de sorte que les erreurs répétées disparaissent et la sortie converge vers la norme de votre équipe au fil du temps.