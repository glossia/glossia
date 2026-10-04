%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "how-to",
  section: "translation",
  order: 1
}
---
Si vous avez déjà configuré Glossia et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le code de la nouvelle langue au `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spéciales, comme le niveau de formalité ou la gestion de l'ensemble de caractères, créez un fichier de remplacement de contexte :

    L10N/
      ja.md

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia le fusionne avec le contexte de base pour les traductions en japonais.

## 3\. Publier la modification de configuration

Commit et push la configuration mise à jour. Si le référentiel est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées
ainsi que le contexte effectif n'ont pas changé.

## 4\. Reviser la pull request de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée
fichiers dans la pull request ouverte par le serveur.