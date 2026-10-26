%{
  title: "Apaiser les pull requests de traduction",
  summary:
    "Ce que nous avons appris en lâchant Glossia sur un dépôt très actif, et comment les pull requests de traduction ont évolué en conséquence."
}
---

Vous en apprenez beaucoup la première fois que votre outil rencontre un véritable dépôt. Pour nous, cela a été Tuist. Leur équipe fusionne vers `main` de nombreuses fois par jour, et Glossia a fait exactement ce pour quoi nous l'avions construit : il a traduit chaque modification et a poussé chaque fichier dès qu'il était prêt. Le résultat était une nouvelle pull request pour presque chaque fusion, chacune comportant environ 150 commits, et une file CI pleine de contrôles à qui personne n'avait demandé. Certaines de leurs pages de documentation sont également revenues avec des composants et des alertes échappés dans du texte brut. Pas l'expérience silencieuse et en arrière-plan dont nous continuons de parler.

Cela a piqué, car nous avons toujours dit que le meilleur système de traduction est celui dont on n'a pas besoin de réfléchir. Une pull request qui inonde votre CI ou corrompt votre documentation est l'opposé de cela. Nous sommes donc retournés et avons repensé à la façon dont les traductions atteignent votre dépôt.

Glossia maintient désormais une unique pull request par projet et la fait évoluer au fur et à mesure que votre contenu change. Elle lit les fichiers de verrouillage déjà présents sur cette branche, de sorte qu'elle ne traduit que ce qui est nouveau, et pousse par lots au lieu de fichier par fichier. Sur un dépôt comme celui de Tuist, il s'agit d'une demi-douzaine de pushes là où cela était cent cinquante.

Nous avons également arrêté de toucher aux parties de votre documentation qui ne nous concernent pas. Glossia reconstruisait autrefois chaque page qu'elle traduisait, et tout ce qu'elle ne comprenait pas pleinement, comme un composant Phoenix ou une alerte GitHub, pouvait ressortir échappé. Maintenant, elle remplace uniquement les phrases qu'elle a traduites et laisse tout le reste exactement tel que vous l'avez écrit. Il y a eu un agréable effet secondaire inattendu : car le modèle voit désormais des phrases entières et le reste de la page, les traductions se lisent mieux. En japonais, un lien n'a plus besoin de s'insérer de travers là où il se trouvait dans la phrase anglaise.

Enfin, la pull request vous indique désormais ce qui s'est passé. Quelles langues et quels fichiers ont été traduits, depuis quels commits, comment ils ont été notés, quels termes de glossaire les ont façonnés, et ce qui, le cas échéant, nécessite votre attention. Nous l'envisageons comme la note qu'un collègue attentif vous laisserait avant de demander une révision.

Merci à l'équipe Tuist pour sa patience pendant que nous avons résolu cela. Si Glossia finit par vous gêner comme cela, nous aimerions en entendre parler.
