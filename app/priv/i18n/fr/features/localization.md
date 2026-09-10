%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et la mise en forme. Les agents Glossia gèrent l'essentiel du travail pour que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible à la structure",
      description:
        "Les blocs de code, le frontmatter et la mise en forme restent intacts après la localisation. Aucun nettoyage manuel requis.",
      icon: "code"
    },
    %{
      title: "Toute paire de langues",
      description:
        "Localisez entre n'importe quelle combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne dans votre configuration.",
      icon: "globe"
    },
    %{
      title: "Mises à jour incrémentielles",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage enregistrent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "zap"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui enregistrent ce qui a déjà été traité. Il combine ensuite votre contexte local (les fichiers `L10N.md` à la racine ou dans les sous-dossiers) avec le contexte global (voix, terminologie et paramètres de niveau compte) pour dresser une vue complète de la manière dont votre contenu devrait sonner dans chaque langue cible. Une fois ce contexte assemblé, un workflow agentique localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de demande de fusion prête à l'examen.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. La terminologie, les notes de style et les instructions spécifiques au domaine sont toutes intégrées à la configuration de l'invite pour que l'agent produise une sortie qui correspond à la voix de votre produit.

## Révision avec confiance

Les résultats prennent la forme de demandes de fusion ou de fichiers brouillon, prêts à être examinés par votre équipe. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte, et l'exécution suivante intègre automatiquement ces corrections.