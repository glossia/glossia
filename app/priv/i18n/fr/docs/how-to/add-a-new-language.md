%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "how-to",
  order: 1
}
---
Si vous avez déjà configuré Glossia et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue à `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (facultatif)

Si la nouvelle langue nécessite des instructions spéciales, telles que le niveau de formalité ou les considérations concernant l'ensemble de caractères, créez un fichier de surcharge de contexte :

    L10N/
      ja.md

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia la fusionne avec le contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Engager et pousser la configuration actualisée. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées
et contexte effectif n'ont pas changé.

## 4\. Examiner la pull request de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée
fichiers dans le pull request ouvert par le serveur.