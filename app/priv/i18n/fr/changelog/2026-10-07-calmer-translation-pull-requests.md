%{
  title: "Apaiser les demandes de fusion de traduction",
  summary:
    "Ce que nous avons appris en laissant Glossia librement agir sur un dépôt très actif, et comment les demandes de fusion de traduction ont changé en conséquence."
}
---

Vous en apprendrez beaucoup la première fois que votre outil rencontre un vrai dépôt. Pour nous, c'était Tuist. Leur équipe fusionne vers `main` de nombreuses fois par jour, et Glossia a fait exactement ce pour quoi nous l'avions construit : il a traduit chaque changement et a poussé chaque fichier dès qu'il était prêt. Le résultat était une nouvelle demande d'intégration pour presque chaque fusion, chacune avec environ 150 commits et une file d'attente CI remplie de contrôles dont personne n'avait demandé. Certaines de leurs pages de documentation sont aussi revenues avec des composants et des alertes échappés en texte brut. Pas l'expérience silencieuse et en arrière-plan dont nous parlons constamment.

Cela a fait mal, car nous avons toujours dit que le meilleur système de traduction est celui dont vous n'avez pas à prendre soin. Une demande d'intégration qui inonde votre CI ou gâte vos documents est à l'opposé de cela. Nous sommes donc retournés et avons repensé à la façon dont les traductions atteignent votre dépôt.

Glossia conserve désormais une seule demande d'intégration par projet et l'enrichit au fur et à mesure que votre contenu change. Il lit les fichiers de verrouillage déjà présents sur cette branche, de sorte qu'il ne traduit que ce qui est nouveau, et pousse par lots au lieu de fichier par fichier. Sur un dépôt comme celui de Tuist, il s'agit de quelques poussées là où il y en avait autrefois cent cinquante.

Nous avons également arrêté de toucher aux parties de vos documents qui ne nous appartiennent pas. Glossia reconstruisait autrefois chaque page qu'elle traduisait, et tout ce qu'elle ne comprenait pas entièrement, comme un composant Phoenix ou une alerte GitHub, pouvait ressortir de l'autre côté échappé. Maintenant, elle ne remplace que les phrases qu'elle a traduites et laisse le reste exactement comme vous l'avez écrit. Il y a eu un agréable effet secondaire inattendu : parce que le modèle voit désormais des phrases entières et le reste de la page, les traductions se lisent mieux. En japonais, un lien n'a plus à se trouver où il était dans la phrase anglaise.

Enfin, la demande d'intégration vous indique désormais ce qui s'est passé. Quelles langues et fichiers ont été traduits, depuis quels commits, comment ils ont été notés, quels termes de glossaire les ont façonnés, et quoi, le cas échéant, nécessite votre attention. Nous y voyons la note qu'un collègue attentif vous laisserait avant de demander une revue.

Merci à l'équipe Tuist pour leur patience pendant que nous avons découvert cela. Si Glossia vous gêne jamais comme cela, nous aimons en entendre parler.
