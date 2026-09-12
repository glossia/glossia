%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia gèrent le gros du travail afin que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Prise en compte de la structure",
      description:
        "Les blocs de code, le frontmatter et le formatage demeurent intacts après la localisation. Aucun nettoyage manuel n'est requis.",
      icon: "Code"
    },
    %{
      title: "N'importe quelle paire de langues",
      description:
        "Localisez entre n'importe quelle combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne de votre configuration.",
      icon: "Monde"
    },
    %{
      title: "Mises à jour incrémentales",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage suivent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "Eclair"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui suivent les éléments déjà traités. Il fusionne ensuite votre contexte local (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte global (voix, terminologie et paramètres liés au compte) pour construire une vision complète de la manière dont votre contenu doit être rendu dans chaque langue cible. Une fois ce contexte assemblé, un flux de travail basé sur des agents localise le contenu modifié tout en préservant la structure, les blocs de code et le formatage. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de pull request prête à être examinée.

## Qualité basée sur le contexte

Chaque localisation bénéficie du contexte que vous apportez. La terminologie, les notes de style et les instructions spécifiques au domaine sont intégrées dans la requête pour que l'agent produise une sortie correspondant à la voix de votre produit.

## Revue en toute confiance

Les résultats sont déposés sous forme de pull request ou de fichiers brouillon, prêts à être examinés par votre équipe. Les réviseurs signalent des problèmes, mettent à jour les fichiers de contexte et la prochaine exécution intègre automatiquement ces corrections.