%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers source pour la clarté, l'exactitude et le ton grâce au contexte que vous fournissez, puis génère des versions révisées prêtes pour examen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent votre rédaction pour la lisibilité, le jargon et la cohérence avec votre ton de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non-destructif",
      description:
        "Le contenu révisé peut écraser l'original ou écrire vers un chemin séparé. Vous contrôlez toujours la destination de sortie.",
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

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (les fichiers `L10N.md` à la racine ou dans les sous-dossiers) avec le contexte distant (vos paramètres de ton, de terminologie et de style au niveau du compte). Une fois l'ensemble complet assemblé, il réécrit le contenu pour la clarté, la précision et le ton, puis produit la version révisée prête pour examen.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend sur votre compte et votre dépôt. Les paramètres au niveau du compte, comme le ton et la terminologie, fournissent une ligne de base globale, tandis que les fichiers `L10N.md` placés en marge de votre contenu ajoutent des ajustements locaux. L'agent résout ce graphe à chaque exécution, de sorte que vos instructions restent cohérentes entre les fichiers sans que vous ayez à les répéter. Les revues sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est réexaminé.

## Raffinement progressif

Chaque cycle de revue améliore le résultat. Les corrections s'intègrent dans les fichiers de contexte, de sorte que les erreurs répétées disparaissent et le résultat converge vers le standard de votre équipe au fil du temps.