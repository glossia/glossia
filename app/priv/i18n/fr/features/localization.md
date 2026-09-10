%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia gèrent le gros du travail pour que votre équipe puisse se concentrer sur la relecture.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible à la structure",
      description:
        "Les blocs de code, le frontmatter et le formatage sont préservés intacts après la localisation. Aucun nettoyage manuel requis.",
      icon: "Code"
    },
    %{
      title: "N'importe quelle paire de langues",
      description:
        "Localisez toute combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne dans votre configuration.",
      icon: "Monde"
    },
    %{
      title: "Mises à jour incrémentaires",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage permettent de suivre ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "Supprimer"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt aux côtés des lockfiles qui suivent ce qui a déjà été traité. Il fusionne ensuite votre contexte local (\``L10N.md` fichiers au niveau de l'enracinement ou dans des sous-répertoires) avec le contexte global (ton, terminologie et paramètres au niveau du compte) afin de construire une image claire de la manière dont votre contenu doit se présenter dans chaque langue cible. Avec ce contexte assemblé, un flux de travail agentique localise le contenu modifié tout en conservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont envoyés de retour à votre dépôt sous la forme d'une pull request prête pour examen.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. Les notes de terminologie, les annotations de style et les instructions spécifiques au domaine alimentent toutes le prompt de sorte que l'agent produise une sortie qui correspond au ton de votre produit.

## Examen en toute confiance

Les résultats deviennent des pull requests ou des fichiers de brouillon, prêts pour que votre équipe examine. Les examinateurs signalent les problèmes, mettent à jour les fichiers de contexte et le prochain exécution incorpore automatiquement ces corrections.