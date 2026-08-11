%{
  title: "Révision du contenu",
  summary: "Améliorez votre contenu existant directement. Glossia examine les fichiers sources afin d’en évaluer la clarté, l’exactitude et le ton à partir du contexte fourni, puis produit des versions révisées prêtes à être examinées.",
  order: 2,
  icon: "pencil",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Ton et clarté", description: "Les agents examinent vos textes afin d’en évaluer la lisibilité, le jargon et la cohérence avec la voix de votre marque.", icon: "message-circle"},
    %{title: "Non destructif", description: "Le contenu révisé peut remplacer l’original ou être enregistré dans un chemin distinct. Vous gardez toujours le contrôle de la destination de sortie.", icon: "shield-check"},
    %{title: "Boucle de rétroaction", description: "Les relecteurs corrigent le résultat, mettent à jour le contexte et, à chaque cycle, réduisent l’écart entre le brouillon et la version finale.", icon: "refresh-cw"}
  ]
}
---
## Fonctionnement du versionnement

L’agent lit vos fichiers sources et le graphe de contexte. Il fusionne les instructions locales (les fichiers `GLOSSIA.md` situés à la racine ou dans des sous-répertoires) avec le contexte distant (la voix, la terminologie et les paramètres de style définis au niveau de votre compte). Une fois le contexte complet établi, il réécrit le contenu afin d’en améliorer la clarté, la précision et le ton, puis génère une version révisée prête à être examinée.

## Graphe de contexte

Dans Glossia, le contexte est un graphe qui couvre votre compte et votre dépôt. Les paramètres définis au niveau du compte, comme la voix et la terminologie, fournissent une base globale, tandis que les fichiers `GLOSSIA.md` placés à côté de votre contenu ajoutent des règles locales prioritaires. L’agent résout ce graphe à chaque exécution afin que vos instructions restent cohérentes entre les fichiers sans que vous ayez à les répéter. Les révisions sont incrémentales grâce aux fichiers de verrouillage qui suivent les éléments déjà traités. Ainsi, seuls les contenus nouveaux ou modifiés sont réexaminés.

## Amélioration progressive

Chaque cycle de révision améliore le résultat. Les corrections sont réintégrées dans les fichiers de contexte, ce qui élimine les erreurs récurrentes et rapproche progressivement le résultat des normes de votre équipe.