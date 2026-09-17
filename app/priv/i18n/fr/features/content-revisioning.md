%{
  title: "Révision du contenu",
  summary:
    "Améliorez directement votre contenu existant. Glossia analyse les fichiers sources pour la clarté, l'exactitude et le ton en utilisant le contexte que vous fournissez, puis produit des versions révisées prêtes à l'examen.",
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
        "Le contenu révisé peut écraser l'original ou s'écrire vers un chemin distinct. Vous contrôlez toujours la destination de sortie.",
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

L'agent lit vos fichiers sources et le graphe de contexte, fusionnant les instructions locales (fichiers `L10N.md` à la racine ou dans les sous-dossiers) avec le contexte distant (vos paramètres de voix, de terminologie et de style au niveau du compte). Une fois l'ensemble reconstitué, il réécrit le contenu pour la clarté, la justesse et le ton, puis produit la version révisée prête pour l'examen.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui englobe votre compte et votre dépôt. Les paramètres de compte, comme la voix et la terminologie, fournissent une base globale, tandis que les fichiers `L10N.md` placés auprès de votre contenu ajoutent des surcharges locales. L'agent résout ce graphe à chaque exécution, de sorte que vos instructions restent cohérentes d'un fichier à l'autre sans vous répéter. Les examens sont incrémentaux grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est à nouveau examiné.

## Affinement progressif

Chaque cycle d'examen améliore le résultat. Les corrections sont réinjectées dans les fichiers de contexte, de sorte que les erreurs récurrentes disparaissent et que le résultat converge vers la norme de votre équipe avec le temps.