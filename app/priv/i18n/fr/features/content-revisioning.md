%{
  title: "Révision du contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers sources pour la clarté, la précision et le ton en utilisant le contexte que vous fournissez, puis génère des versions révisées prêtes pour relecture.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents examinent votre texte pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
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
        "Les réviseurs corrigent la sortie, mettent à jour le contexte, et chaque cycle réduit l'écart entre le brouillon et la version finale.",
      icon: "refresh-cw"
    }
  ]
}
---
## Comment fonctionne la révision

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (`GLOSSIA.md` à la racine ou dans des sous-dossiers) avec le contexte distant (vos paramètres de voix, de terminologie et de style au niveau du compte). Une fois le panorama complet assemblé, il réécrit le contenu pour la clarté, la précision et le ton, puis génère la version révisée prête à être revue.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend sur votre compte et votre dépôt. Les paramètres de compte, comme la voix et la terminologie, définissent une base globale, tandis que les fichiers `GLOSSIA.md` placés à proximité de votre contenu ajoutent des ajustements locaux. L'agent résout ce graphe à chaque exécution, afin que vos instructions restent cohérentes entre les fichiers sans avoir à les répéter. Les relectures sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seules les modifications ou le nouveau contenu sont re-traités.

## Affinement progressif

Chaque cycle de relecture améliore le résultat. Les corrections sont réinjectées dans les fichiers de contexte, de sorte que les erreurs répétes disparaissent et le résultat converge vers le standard de votre équipe au fil du temps.