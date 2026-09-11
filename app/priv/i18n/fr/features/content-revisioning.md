%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant en place. Glossia analyse vos fichiers source pour la clarté, la précision et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes à être revues.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent votre prose pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut remplacer l'original ou écrire sur un chemin séparé. Vous contrôlez toujours la destination de sortie.",
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

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte distant (vos réglages de voix, terminologie et style au niveau du compte). Une fois l'ensemble complet assemblé, il réécrit le contenu pour la clarté, l'exactitude et le ton, puis il fournit la version révisée prête à l'examen.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend de votre compte à votre dépôt. Les réglages au niveau du compte, comme la voix et la terminologie, fournissent une référence globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des ajustements locaux. L'agent résout ce graphe à chaque exécution, afin que vos instructions restent cohérentes d'un fichier à l'autre sans avoir à vous répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est retravaillé.

## Affinement progressif

Chaque cycle de révision améliore le résultat. Les corrections sont réinjectées dans les fichiers de contexte, de sorte que les erreurs répétées disparaissent et que le résultat converge vers la norme de votre équipe au fil du temps.