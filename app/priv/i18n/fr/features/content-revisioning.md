%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant sur place. Glossia examine les fichiers sources pour la clarté, la précision et le ton en utilisant le contexte que vous fournissez, puis génère des versions révisées prêtes à être revues.",
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
        "Le contenu révisé peut écraser l'original ou s'écrire sur un chemin séparé. Vous contrôlez toujours la destination de sortie.",
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

L'agent lit vos fichiers source et le graphe de contexte, fusionnant les instructions locales (`L10N.md` fichiers à la racine ou dans les sous-dossiers) avec le contexte distant (vos paramètres au niveau du compte : voix, glossaire et style). Une fois l'ensemble pris en compte, il réécrit le contenu pour la clarté, la précision et le ton, puis sort la version révisée prête à l'examen.

## Grappe de contexte

Le contexte dans Glossia est un graphe qui s'étend sur votre compte et votre dépôt. Les paramètres au niveau du compte, comme la voix et le glossaire, fournissent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des paramètres locaux. L'agent résout ce graphe à chaque exécution, si vos instructions restent cohérentes entre les fichiers sans que vous ayez à les répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau soit réexaminé.

## Affinement progressif

Chaque cycle de révision améliore la sortie. Les corrections alimentent les fichiers de contexte, si les erreurs répétées disparaissent et la sortie converge vers la norme de votre équipe au fil du temps.
