%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia gèrent le gros du travail afin que votre équipe puisse se concentrer sur la relecture.",
  order: 1,
  icon: "langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible à la structure",
      description:
        "Les blocs de code, le frontmatter et le formatage survivent à la localisation intacts. Aucun nettoyage manuel requis.",
      icon: "code"
    },
    %{
      title: "Tout couple de langues",
      description:
        "Localisez entre toute combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne dans votre config.",
      icon: "Planète"
    },
    %{
      title: "Mises à jour incrémentales",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage suivent ce qui a déjà été traité, économisant du temps et de l'argent.",
      icon: "Éclair"
    }
  ]
}
---

## ## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui suivent ce qui a déjà été traité. Il fusionne ensuite votre contexte local (`L10N.md` fichiers à la racine ou dans les sous-répertoires) avec le contexte global (voix, glossaire et paramètres de compte) pour une vision complète de la façon dont votre contenu devrait sonner dans chaque langue cible. Avec ce contexte assemblé, un flux de travail agentic localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de pull request prête à l'examen.

## ## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournit. Le glossaire, les notes de style et les instructions spécifiques au domaine s'ajoutent toutes au prompt pour que l'agent produise un résultat conforme à la voix de votre produit.

## ## Examen en toute confiance

Les sorties se présentent sous la forme de pull requests ou de fichiers brouillons, prêts à l'examen par votre équipe. Les examinateurs signalent les problèmes, mettent à jour les fichiers de contexte, et l'exécution suivante incorpore automatiquement ces corrections.
