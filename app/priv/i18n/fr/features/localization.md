%{
  title: "Localisation",
  summary:
    "Localisez votre contenu dans n'importe quelle langue tout en préservant la structure, les blocs de code et le formatage. Les agents Glossia assument la majeure partie du travail pour que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "Langues",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Sensible à la structure",
      description:
        "Les blocs de code, le frontmatter et le formatage subsistent intacts après la localisation. Aucun nettoyage manuel requis.",
      icon: "Code"
    },
    %{
      title: "Tout couple de langues",
      description:
        "Localisez pour toute combinaison de langues. Ajoutez de nouvelles cibles en modifiant une seule ligne dans votre config.",
      icon: "Planète"
    },
    %{
      title: "Mises à jour incrémentales",
      description:
        "Seul le contenu modifié est relocalisé. Les fichiers de verrouillage suivent ce qui a déjà été traité, épargnant le temps et les coûts.",
      icon: "Flash"
    }
  ]
}
---
## Comment fonctionne la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui enregistrent ce qui a déjà été traité. Il fusionne ensuite votre contexte local (`L10N.md` à la racine ou dans des sous-répertoires) avec le contexte global (voix, terminologie et paramètres du compte) pour créer une vue complète de la manière dont votre contenu doit sonner dans chaque langue cible. Une fois ce contexte constitué, un flux de travail orienté agents localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. Une fois l'exécution terminée, les résultats sont renvoyés vers votre dépôt sous la forme d'un pull request prêt à être examiné.

## Qualité pilotée par le contexte

Chaque localisation bénéficie du contexte que vous fournissez. La terminologie, les notes de style et les instructions spécifiques au domaine s'ajoutent toutes au prompt afin que l'agent génère une sortie correspondant à la voix de votre produit.

## Revue en toute confiance

Les résultats se présentent sous la forme de pull requests ou de fichiers brouillon, prêts pour que votre équipe les examine. Les réviseurs signalent les problèmes, mettent à jour les fichiers de contexte, et la prochaine exécution intègre ces corrections automatiquement.