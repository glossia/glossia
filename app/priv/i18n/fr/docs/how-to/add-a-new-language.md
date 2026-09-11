%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "Tutoriel",
  order: 1
}
---
Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettez à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue dans le `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajoutez un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spéciales, telles que le niveau de formalité ou les contraintes liées à l'ensemble de caractères, créez un fichier de surcharge de contexte :

    L10N/
      ja.md

Écrivez toute consigne spécifique à la langue dans ce fichier. Glossia le fusionne avec le contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Valider et pousser la configuration mise à jour. Si le référentiel est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées
et que leur contexte effectif n'a pas changé.

## 4\. Révisez la demande de tirage de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée.
fichiers dans la pull request ouverte par le serveur.