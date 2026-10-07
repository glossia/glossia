%{
  title: "Gérer les autorisations des membres",
  summary:
    "Accorder des autorisations individuelles ou sélectionner des zones de produit entières pour les membres de l'organisation.",
  category: "Tutoriel",
  section: "platform",
  order: 9
}
---
Les administrateurs d'organisation peuvent choisir les domaines de produit auxquels chaque membre peut accéder. Commencez par un accès en lecture de base et accordez des autorisations supplémentaires au besoin.

## Modifier l'accès d'un membre

1. Ouvrez votre organisation et allez à **Organisation → Membres**.
2. Trouvez un membre qui n'est pas administrateur et sélectionnez **Autorisations**.
3. Sélectionnez les autorisations individuelles dans une zone, par exemple **Projet → Écriture**. Sélectionnez **Tout sélectionner** pour activer toutes les autorisations disponibles dans cette zone. Re-sélectionner efface la zone ; une zone partiellement sélectionnée affiche une case à cocher indéterminée.
4. Sélectionner **Enregistrer les autorisations** en haut à droite de la page, au-dessus du titre. Une confirmation apparaît une fois les autorisations enregistrées. Les modifications de la case à cocher prennent effet uniquement après l'enregistrement.
5. Sélectionner **Membres**, avec la flèche de gauche au-dessus du titre, pour retourner à la liste des membres.

Les autorisations sont regroupées dans des rangées compactes dans une carte. Sur les écrans étroits, les autorisations de chaque zone s'affichent sous son libellé. La navigation et l'enregistrement restent au-dessus du titre de la page.

## Commencer les nouveaux membres avec un accès de base

Nouveaux membres non administrateurs, y compris les personnes rejoignant par [connexion organisationnelle](/docs/how-to/organization-sign-in) ou en acceptant une invitation, reçoivent un accès en lecture sur le compte, l'organisation, les projets, la voix, le glossaire, les discussions et les tickets. Ils ne reçoivent pas par défaut les autorisations d'écriture, de suppression ou d'administrateur.

Membres existants conservent leurs permissions précédentes basées sur le rôle jusqu'à ce qu'un administrateur sauvegarde des permissions explicites pour eux. La sauvegarde remplace cet accès par les permissions sélectionnées. Le décochage de toutes les cases à cocher et la sauvegarde suppriment les permissions déléguées du membre ; cela ne retire pas leur statut de membre.

## Gardez les responsabilités de l'administrateur distinctes

Les administrateurs utilisent le rôle administrateur et leurs permissions ne peuvent pas être modifiées via cette interface. Les invitations et la gestion des membres, les identifiants d'accès, la modification des modèles de langage et la suppression de l'organisation restent des responsabilités de l'administrateur. Elles ne peuvent pas être déléguées en sélectionnant les permissions des membres.

La suppression d'un membre est une action distincte dans la liste des membres. La suppression bloque également l'inscription automatique via la connexion organisationnelle jusqu'à ce qu'un administrateur ajoute ou invite explicitement la personne à nouveau.