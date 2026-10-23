%{
  title: "Mémoire linguistique et mémoire de traduction",
  summary:
    "Comment la voix et la terminologie complètent les traductions révisées sans lier la livraison à une mémoire propriétaire.",
  category: "Explication",
  markdown_only: true,
  section: "translation",
  order: 4
}
---

La mémoire de traduction enregistre généralement des segments source-cible précédemment traduits. Un segment source correspondant ou similaire peut réutiliser un travail antérieur. Cela est précieux pour le contenu répété et pour préserver les traductions révisées.

La mémoire linguistique de Glossia répond à un autre besoin : les principes qui font que les nouveaux écrits correspondent à l'organisation, même si la phrase n'a jamais paru auparavant.

## Mémoriser la sortie versus mémoriser l'intention

Une traduction examinée répond : « Comment avons-nous traduit cela auparavant ? » Les directives de ton et le glossaire répondent à des questions telles que :

- Quels termes de produit doivent rester inchangés ?
- Quelle terminologie devons-nous utiliser de manière cohérente ?
- Quel ton convient à ce public ?
- Quelles décisions linguistiques un agent doit-il respecter lors de la rédaction de nouveaux contenus ?

Ces entrées peuvent aider à la localisation et à la création de contenu dans la langue source. Elles ne se limitent pas à la récupération d'un segment cible correspondant.

## Outils complémentaires

Les mémoires de traduction et les directives linguistiques résolvent des problèmes chevauchants mais distincts. Une équipe peut en bénéficier des deux. Glossia ne promet pas que le texte généré par un modèle puisse remplacer chaque segment examiné, ni que l'utilisation de prompts garantit une justesse linguistique.

Le choix architectural important n'est pas de faire d'une mémoire propriétaire l'autorité unique du langage de l'entreprise. Le contenu du dépôt, le contexte réutilisable, l'historique des versions et la révision contribuent tous à un processus que l'équipe peut comprendre et maintenir.

## Le contexte nécessite toujours une révision

Les directives peuvent être incomplètes ou contradictoires. Un terme peut avoir différentes significations dans différents produits. Les humains restent responsables de décider si le résultat est précis et approprié ; la validation peut détecter des défaillances structurelles mais ne peut pas prouver que chaque phrase est correcte.

Lisez [Pourquoi Glossia](./why-glossia) pour le modèle plus large et [Localisation continue](./continuous-localization) pour sa relation avec la livraison.
