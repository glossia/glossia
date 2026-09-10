%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine vos fichiers sources pour la clarté, l'exactitude et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes à l'examen.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents relisent votre rédaction pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
      icon: "message-circle"
    },
    %{
      title: "Non destructif",
      description:
        "Le contenu révisé peut écraser l'original ou être écrit sur un chemin séparé. Vous contrôlez toujours la destination de sortie.",
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

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte distant (vos paramètres de voix, de terminologie et de style au niveau du compte). Une fois l'image complète assemblée, il réécrit le contenu pour la clarté, l'exactitude et le ton, puis produit la version révisée prête à la révision.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui englobe votre compte et votre dépôt. Les paramètres au niveau du compte, comme la voix et la terminologie, offrent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des surcharges locales. L'agent résout ce graphe à chaque exécution, de sorte que vos instructions restent cohérentes entre les fichiers sans vous répéter. Les révisions sont incrémentielles grâce aux fichiers de verrouillage qui enregistrent ce qui a déjà été traité, afin que seules les modifications ou le nouveau contenu soient réexaminés.

## Affinement progressif

Chaque cycle de révision améliore la sortie. Les corrections réintègrent les fichiers de contexte, de sorte que les erreurs répétées disparaissent et que la sortie converge vers le standard de votre équipe au fil du temps.