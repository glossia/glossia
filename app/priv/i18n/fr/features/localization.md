%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia gèrent les tâches lourdes pour que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Prise en compte de la structure",
      description:
        "Les blocs de code, le frontmatter et le formatage sont conservés intacts lors de la localisation. Aucun nettoyage manuel requis.",
      icon: "code"
    },
    %{
      title: "N'importe quelle paire de langues",
      description:
        "Localisez entre toute combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne de votre configuration.",
      icon: "Monde"
    },
    %{
      title: "Mises à jour incrémentielles",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage suivent ce qui a déjà été traité, économisant du temps et des coûts.",
      icon: "Zap"
    }
  ]
}
---

## Comment la localisation fonctionne

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui suivent ce qui a déjà été traité. Il fusionne ensuite votre contexte local (fichiers `L10N.md` à la racine ou dans les sous-répertoires) avec le contexte global (voix, glossaire et paramètres de compte) pour construire une image complète de la façon dont votre contenu doit sonner dans chaque langue cible. Une fois ce contexte assemblé, un workflow d'agent localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous forme de pull request prête pour révision.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. Le glossaire, les notes de style et les instructions spécifiques au domaine alimentent toutes le prompt pour que l'agent produise une sortie qui correspond à la voix de votre produit.

## Révision avec confiance

Les résultats prennent la forme de pull requests ou de fichiers brouillons, prêts pour votre équipe à les réviser. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte et l'exécution suivante intègre automatiquement ces corrections.
