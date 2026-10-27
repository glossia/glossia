%{
  title: "Apaiser les pull requests de traduction",
  summary:
    "Ce que nous avons appris en laissant Glossia libre sur un dépôt très chargé, et comment les pull requests de traduction ont évolué en conséquence."
}
---

Vous apprenez beaucoup à la première fois que votre outil rencontre un véritable dépôt. Pour nous, c'était Tuist. Leur équipe fusionne vers `main` de nombreuses fois par jour, et Glossia a fait exactement ce pour quoi nous l'avions conçu : il traduisait chaque modification et poussait chaque fichier dès qu'il était prêt. Le résultat était une nouvelle demande de fusion pour presque chaque fusion, chacune comportant environ 150 commits, et une file d'attente CI remplie de vérifications que personne n'avait demandées. Certaines de leurs pages de documentation rentraient également avec des composants et des alertes échappés dans du texte en clair. Ce n'était pas l'expérience silencieuse, en arrière-plan, de laquelle nous parlons continuellement.

Ça a fait mal, car nous avons toujours affirmé que le meilleur système de traduction est celui auquel vous n'avez pas à réfléchir. Une demande de fusion qui inonde votre CI ou gâche votre documentation est l'opposé de cela. Donc nous sommes retournés en arrière et avons repensé à la façon dont les traductions atteignent votre dépôt.

Glossia maintient désormais une seule demande de fusion par projet et la fait évoluer lorsque votre contenu change. Il lit les fichiers de verrouillage déjà présents sur cette branche, de sorte qu'il ne traduit que les nouveautés, et il pousse par lots au lieu de fichier par fichier. Dans un dépôt comme celui de Tuist, cela représente quelques pousses là où il y en avait auparavant cent cinquante.

Nous avons également arrêté de modifier les parties de vos documents qui ne nous concernent pas. Glossia reconstruisait autrefois chaque page qu'il traduisait, et tout ce qu'il ne comprenait pas entièrement, comme un composant Phoenix ou une alerte GitHub, pouvait sortir de l'autre côté échappé. Maintenant, il ne remplace que les phrases qu'il a traduites et laisse tout le reste exactement tel que vous l'avez écrit. Il y a eu une agréable conséquence secondaire que nous n'attendions pas : car le modèle voit désormais des phrases complètes et le reste de la page, les traductions se lisent mieux. En japonais, un lien n'a plus à se trouver inconfortablement là où il se trouvait dans la phrase anglaise.

Enfin, la demande de fusion vous indique désormais ce qui s'est passé. Quelles langues et quels fichiers ont été traduits, depuis quels commits, comment ils ont été notés, quels termes du glossaire les ont façonnés, et ce, si nécessaire, qui demande votre attention. Nous y voyons la note qu'un collègue prudent vous laisserait avant de demander une relecture.

Merci à l'équipe Tuist pour sa patience pendant que nous avons trouvé la solution. Si Glossia vous gêne jamais de cette manière, nous aimerions en entendre parler.
