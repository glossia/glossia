%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "guide",
  order: 1
}
---
Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue dans le `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spécifiques, telles que le niveau de formalité ou des considérations concernant l'ensemble de caractères, créez un fichier de surcharge de contexte :

    L10N/
      ja.md

Écrivez toute consigne spécifique à la langue dans ce fichier. Glossia le combine avec le contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Valider et pousser la configuration mise à jour. Si le référentiel est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour les autres langues restent inchangées lorsque leurs entrées
et contexte effectif n'ont pas changé.

## 4\. Examiner la demande de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée
fichiers de la demande de fusion ouverts par le serveur.