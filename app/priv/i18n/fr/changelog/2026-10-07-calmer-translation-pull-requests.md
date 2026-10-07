%{
  title: "Apaiser les pull requests de traduction",
  summary:
    "Ce que nous avons appris en laissant Glossia libre sur un dépôt très actif, et comment les pull requests de traduction ont changé en conséquence."
}
---
Vous en apprenez beaucoup lors de la première rencontre de votre outil avec un dépôt réel. Pour nous, ce fut Tuist. Leurs équipes fusionnent sur `main` plusieurs fois par jour, et Glossia a fait exactement ce pour quoi nous l'avions conçu : il a traduit chaque modification et a poussé chaque fichier dès qu'il était prêt. Le résultat était une nouvelle pull request pour presque chaque fusion, chacune contenant environ 150 commits, et une file d'attente CI bourrée de vérifications que personne n'avait demandées. Certaines pages de leur documentation sont revenues avec des composants et des alertes échappés en texte brut. Ce n'était pas l'expérience silencieuse et discrète dont nous parlons constamment.

Cela a fait mal, car nous disons toujours que le meilleur système de traduction est celui dont on n'a pas à se soucier. Une pull request qui inonde votre CI ou gâche votre documentation est l'opposé de cela. Nous sommes donc revenus et avons repensé la manière dont les traductions atteignent votre dépôt.

Glossia maintient désormais une unique pull request par projet et l'enrichit lorsque votre contenu change. Il lit les fichiers lock déjà présents sur cette branche, ne traduit donc que ce qui est nouveau, et pousse en lots plutôt que fichier par fichier. Sur un dépôt comme celui de Tuist, cela correspond à quelques pushes alors qu'il y en avait autrefois cent cinquante.

Nous avons aussi cessé de toucher aux parties de vos documents qui ne nous regardent pas. Glossia reconstruisait autrefois chaque page traduite, et tout ce qu'il ne comprenait pas entièrement, comme un composant Phoenix ou une alerte GitHub, pouvait sortir échappé de l'autre côté. Maintenant, il ne remplace que les phrases traduites et laisse le reste exactement tel que vous l'avez écrit. Il y a eu un effet secondaire agréable que nous n'attendions pas : le modèle voit désormais des phrases entières et le reste de la page, les traductions se lisent mieux. En japonais, un lien ne doit plus être mal placé à la place qu'il occupait dans la phrase anglaise.

Enfin, la pull request vous dit maintenant ce qui s'est passé. Quelles langues et quels fichiers ont été traduits, depuis quels commits, comment ils ont été notés, quels termes de glossaire les ont influencés, et ce qui, le cas échéant, requiert votre attention. Nous y pensons comme à la note qu'un collègue vigilant laisserait avant de vous demander une relecture.

Merci à l'équipe Tuist pour leur patience pendant que nous avons résolu cela. Si Glossia bloque votre travail de cette manière, nous aimerions en entendre parler.