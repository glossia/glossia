%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et la mise en forme. Les agents Glossia gèrent les travaux fastidieux afin que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible à la structure",
      description:
        "Les blocs de code, le frontmatter et la mise en forme sont préserver intacts. Aucun nettoyage manuel n'est requis.",
      icon: "Code"
    },
    %{
      title: "Tout couple de langues",
      description:
        "Localisez entre toute combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne de votre config.",
      icon: "Globe"
    },
    %{
      title: "Mises à jour incrémentielles",
      description:
        "Seul le contenu modifié est relancé pour la localisation. Les fichiers de verrouillage suivent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "Zap"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui enregistrent ce qui a déjà été traité. Elle fusionne ensuite votre contexte local (les fichiers `L10N.md` à la racine ou dans des sous-répertoires) avec le contexte global (ton, terminologie et paramètres au niveau du compte) pour dresser un tableau complet de la manière dont votre contenu devrait sonner dans chaque langue cible. Avec ce contexte assemblé, un workflow agent localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de demande de fusion prête pour revue.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. La terminologie, les notes de style et les instructions spécifiques au domaine transitent toutes dans le prompt afin que l'agent produise une sortie qui correspond au ton de votre produit.

## Revue avec confiance

Les sorties aboutissent sous forme de demandes de fusion ou de fichiers brouillons, prêtes pour examen par votre équipe. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte et l'exécution suivante intègre automatiquement ces corrections.