%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia gèrent les tâches lourdes afin que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Prise en compte structurelle",
      description:
        "Les blocs de code, le frontmatter et le formatage survivent à la localisation. Aucun nettoyage manuel requis.",
      icon: "code"
    },
    %{
      title: "N'importe quelle paire de langues",
      description:
        "Localisez entre n'importe quelle combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne dans votre config.",
      icon: "mondial"
    },
    %{
      title: "Mises à jour incrémentales",
      description:
        "Seul le contenu modifié est relocalisé. Les lockfiles suivent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "éclair"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui enregistrent ce qui a déjà été traité. Elle fusionne ensuite votre contexte local (les fichiers `GLOSSIA.md` à la racine ou dans des sous-répertoires) avec le contexte global (voix, terminologie et paramètres de compte) pour bâtir une vision complète de la façon dont votre contenu doit se présenter dans chaque langue cible. Avec ce contexte assemblé, un flux de travail agentique localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme d'une pull request prête à être révisée.

## Qualité guidée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. La terminologie, les notes de style et les instructions spécifiques au domaine alimentent le prompt afin que l'agent génère un contenu qui correspond à la voix de votre produit.

## Revue avec confiance

Les résultats se matérialisent sous forme de pull requests ou de fichiers brouillon, prêts pour l'examen par votre équipe. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte, et le prochain lancement intègre automatiquement ces corrections.