%{
  title: "Apaisement des pull requests de traduction",
  summary:
    "Ce que nous avons appris de l'utilisation libre de Glossia sur un dépôt très actif, et comment les pull requests de traduction ont changé en conséquence."
}
---

Vous apprenez beaucoup la première fois que votre outil rencontre un véritable dépôt. Pour nous, c'était Tuist. Leur équipe fusionne vers `main` de nombreuses fois par jour, et Glossia a fait exactement ce pour quoi nous l'avons conçu : il a traduit chaque modification et a poussé chaque fichier dès qu'il était prêt. Le résultat était une nouvelle demande d'intégration pour presque chaque fusion, chacune avec environ 150 commits, et une file d'attente CI remplie de contrôles que personne n'avait demandés. Certaines pages de leurs documents présentaient également des composants et des alertes échappés en texte brut. Pas l'expérience calme et en arrière-plan dont nous parlons constamment.

Ça a fait mal, car nous avons toujours affirmé que le meilleur système de traduction est celui auquel on ne doit pas réfléchir. Une demande d'intégration qui inonde votre CI ou gâche votre documentation est l'opposé de cela. Alors nous sommes revenus replanifier la façon dont les traductions atteignent votre dépôt.

Glossia maintient désormais une seule demande d'intégration par projet et l'enrichit au fur et à mesure que votre contenu change. Il lit les fichiers de verrouillage déjà présents sur cette branche, de sorte qu'il ne traduit que le nouveau contenu, et il pousse par lots plutôt que fichier par fichier. Sur un dépôt comme celui de Tuist, cela représente une poignée de poussées alors qu'il y en avait autrefois cent cinquante.

Nous avons également arrêté de modifier les parties de vos documents qui ne nous appartiennent pas. Glossia reconstruisait autrefois chaque page qu'il traduisait, et tout ce qu'il ne comprenait pas entièrement, comme un composant Phoenix ou une alerte GitHub, pouvait sortir de l'autre côté échappé. Maintenant, il ne remplace que les phrases qu'il a traduites et laisse tout le reste exactement tel que vous l'avez écrit. Il y avait un agréable effet secondaire imprévu : car le modèle voit désormais des phrases entières et le reste de la page, les traductions se lisent mieux. En japonais, un lien n'a plus à s'insérer inconfortablement là où il était dans la phrase anglaise.

Enfin, la demande d'intégration vous informe désormais ce qui s'est passé. Quelles langues et fichiers ont été traduits, de quels commits, de quelle manière ils ont été notés, quels termes du glossaire les ont façonnés, et ce qui, le cas échéant, nécessite votre attention. Nous l'envisageons comme la note qu'un collègue attentif vous laisserait avant de demander une relecture.

Merci à l'équipe Tuist pour cette patience pendant que nous avons mis cela au point. Si Glossia entrave votre chemin un jour comme cela, nous aimerions en entendre parler.
