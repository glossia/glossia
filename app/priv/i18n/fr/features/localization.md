%{
  title: "Localisation",
  summary: "Localisez votre contenu dans n’importe quelle langue tout en préservant la structure, les blocs de code et la mise en forme. Les agents Glossia prennent en charge l’essentiel du travail afin que votre équipe puisse se concentrer sur la révision.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Respect de la structure", description: "Les blocs de code, le frontmatter et la mise en forme restent intacts après la localisation. Aucun nettoyage manuel n’est nécessaire.", icon: "code"},
    %{title: "Toutes les paires de langues", description: "Localisez votre contenu entre n’importe quelle combinaison de langues. Ajoutez de nouvelles langues cibles en modifiant une seule ligne dans votre configuration.", icon: "globe"},
    %{title: "Mises à jour incrémentales", description: "Seul le contenu modifié est à nouveau localisé. Les fichiers de verrouillage indiquent ce qui a déjà été traité, ce qui permet de réduire les délais et les coûts.", icon: "zap"}
  ]
}
---
## Fonctionnement de la localisation

Glossia lit le contenu de votre dépôt ainsi que les fichiers de verrouillage qui indiquent ce qui a déjà été traité. Glossia fusionne ensuite votre contexte local (les fichiers `GLOSSIA.md` situés à la racine ou dans des sous-répertoires) avec le contexte global (voix, terminologie et paramètres au niveau du compte) afin d’établir une vue complète du rendu attendu de votre contenu dans chaque langue cible. Une fois ce contexte assemblé, un flux de travail agentique localise le contenu modifié tout en préservant la structure, les blocs de code et la mise en forme. À la fin de l’exécution, les résultats sont renvoyés vers votre dépôt sous la forme d’une pull request prête à être examinée.

## Une qualité fondée sur le contexte

Chaque localisation bénéficie du contexte que vous fournissez. La terminologie, les consignes stylistiques et les instructions propres au domaine sont intégrées au prompt afin que l’agent produise un résultat conforme à la voix de votre produit.

## Examinez les résultats en toute confiance

Les résultats sont fournis sous forme de pull requests ou de fichiers brouillons, prêts à être examinés par votre équipe. Les personnes chargées de l’examen signalent les problèmes et mettent à jour les fichiers de contexte. L’exécution suivante intègre automatiquement ces corrections.