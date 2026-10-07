%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et la mise en forme. Les agents Glossia gèrent le gros du travail afin que votre équipe puisse se concentrer sur la relecture.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Structure-adapté",
      description:
        "Les blocs de code, le frontmatter et la mise en forme sont préservés intacts lors de la localisation. Aucun nettoyage manuel requis.",
      icon: "Code"
    },
    %{
      title: "N'importe quelle paire de langues",
      description:
        "Localisez avec n'importe quelle combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne de votre configuration.",
      icon: "Monde"
    },
    %{
      title: "Mises à jour incrémentales",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage suivent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "Éclair"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui suivent ce qui a déjà été traité. Il combine ensuite votre contexte local (les fichiers `L10N.md` à la racine ou dans des sous-répertoires) avec le contexte global (ton, glossaire et paramètres de compte) pour construire une vue complète de la façon dont votre contenu devrait se lire dans chaque langue cible. Avec ce contexte assemblé, un workflow agentic localise le contenu modifié tout en préservant la structure, les blocs de code et le formatage. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de demande de fusion prête à la revue.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. Le glossaire, les notes de style et les instructions spécifiques au domaine alimentent le prompt pour que l'agent produise une sortie qui correspond au ton de votre produit.

## Révision avec confiance

Les sorties arrivent sous forme de demandes de fusion ou de fichiers brouillon, prêts pour la revue de votre équipe. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte et la prochaine exécution intègre automatiquement ces corrections.