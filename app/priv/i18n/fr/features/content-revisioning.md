%{
  title: "Révision de contenu",
  summary:
    "Améliorez votre contenu existant en place. Glossia révise les fichiers sources pour la clarté, la précision et le ton en fonction du contexte que vous fournissez, puis produit des versions révisées prêtes à la revue.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Ton et clarté",
      description:
        "Les agents relisent votre texte pour la lisibilité, le jargon et la cohérence avec votre voix de marque.",
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
        "Les réviseurs corrigent la sortie, mettent à jour le contexte et chaque cycle réduit l'écart entre le brouillon et le final.",
      icon: "refresh-cw"
    }
  ]
}
---

## Comment fonctionne la révision

L'agent lit vos fichiers sources et le graphe de contexte, en fusionnant les consignes locales (fichiers `L10N.md` à la racine ou dans des sous‑répertoires) avec le contexte distant (vos paramètres de compte : voix, glossaire et style). Une fois l'ensemble complet réuni, il réécrit le contenu pour sa clarté, sa précision et son ton, puis génère la version révisée prête pour révision.

## Graphe de contexte

Le contexte dans Glossia est un graphe qui s'étend sur votre compte et votre dépôt. Les paramètres de compte, tels que la voix et le glossaire, fournissent une base globale, tandis que les fichiers `L10N.md` placés à côté de votre contenu ajoutent des paramètres locaux. L'agent résout ce graphe à chaque exécution, vos instructions restant cohérentes entre les fichiers sans que vous ayez à vous répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent ce qui a déjà été traité, de sorte que seul le contenu modifié ou nouveau est revisité.

## Affinement progressif

Chaque cycle de révision améliore la sortie. Les corrections sont réinjectées dans les fichiers de contexte, de sorte que les erreurs répétées disparaissent et le résultat converge vers les normes de votre équipe au fil du temps.
