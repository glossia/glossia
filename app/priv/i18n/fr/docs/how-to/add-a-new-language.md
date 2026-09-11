%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "Tutoriels",
  order: 1
}
---
Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettez à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue dans le `targets` array:

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (facultatif)

Si la nouvelle langue nécessite des instructions spécifiques, telles que le niveau de formalité ou des considérations sur l'ensemble de caractères, créez un fichier de surcharge de contexte :

    L10N/
      ja.md

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia le fusionne avec le contexte de base pour les traductions en japonais.

## 3\. Publier la modification de configuration

Effectuez un commit et poussez la configuration mise à jour. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour d'autres langues demeurent inchangées lorsque leurs entrées
et contexte effectif n'ont pas changé.

## 4\. Passer en revue le pull request de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée
fichiers de la demande de tirage ouverte par le serveur.