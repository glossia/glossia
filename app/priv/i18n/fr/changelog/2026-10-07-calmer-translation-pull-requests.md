%{
  title: "Apaisement des pull requests de traduction",
  summary:
    "Ce que nous avons appris de l'utilisation libre de Glossia sur un dépôt très actif, et comment les pull requests de traduction ont changé en conséquence."
}
---

Vous en apprendrez beaucoup la première fois que votre outil rencontre un vrai dépôt. Pour nous, c'était Tuist. L'équipe fusionne vers `main` de nombreuses fois par jour, et Glossia a fait exactement ce pour quoi nous l'avions conçu : il traduit chaque changement et pousse chaque fichier dès qu'il est prêt. Le résultat était une nouvelle Pull request pour presque chaque fusion, comportant à chaque fois autour de 150 commits, et une file d'attente CI remplie de vérifications que personne ne demandait. Certaines de leurs pages de documentation revenaient également avec des composants et des alertes restées en texte brut. Pas l'expérience silencieuse et en arrière-plan dont nous parlons souvent.

Cela a fait mal, car nous avons toujours affirmé que le meilleur système de traduction est celui dont vous n'avez pas à vous soucier. Une Pull request qui inonde votre CI ou corrompt votre documentation est la contrepartie. Alors nous sommes revenus repenser la façon dont les traductions parviennent à votre dépôt.

Glossia maintient maintenant une seule Pull request par projet et l'élargit lorsque votre contenu évolue. Il lit les fichiers de verrouillage déjà présents sur cette branche, ne traduit donc que le nouveau, et pousse par lots au lieu de fichier par fichier. Sur un dépôt comme celui de Tuist, cela ne nécessite plus qu'une poignée de pushes où il y en avait autrefois une centaine.

Nous avons également arrêté d'intervenir sur les parties de votre documentation qui ne sont pas les nôtres. Glossia reconstruisait auparavant chaque page traduite, et tout ce qu'il ne comprenait pas entièrement, comme un composant Phoenix ou une alerte GitHub, sortait inélégamment sous forme de texte brut. Maintenant, il ne remplace que les phrases traduites et laisse tout le reste tel que vous l'avez écrit. Il y avait un effet secondaire agréable que nous n'avions pas anticipé : car le modèle voit désormais des phrases entières et le reste de la page, les traductions sont plus fluides. En japonais, un lien n'a plus besoin d'apparaître bêtement là où il se trouvait dans la phrase anglaise.

Enfin, la Pull request vous indique ce qui s'est passé. Les langues et les fichiers traduits, depuis quelles commits, comme ils ont été notés, quels termes du glossaire les ont façonnés, et ce qui, le cas échéant, réclame votre attention. Nous la concevons comme la note qu'un collègue attentif laisserait avant de demander une relecture.

Merci à l'équipe de Tuist pour sa patience pendant que nous avons trouvé la solution. Si Glossia vous gêne jamais de cette manière, nous serions ravis d'en entendre parler.
