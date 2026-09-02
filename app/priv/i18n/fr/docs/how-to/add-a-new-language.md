%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "how-to",
  order: 1
}
---
Si vous avez déjà configuré Glossia et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour GLOSSIA.md

Ouvrez votre `GLOSSIA.md` et ajoutez le nouveau code de langue à la `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (facultatif)

Si la nouvelle langue nécessite des instructions particulières, telles que le niveau de formalité ou les considérations du jeu de caractères, créez un fichier de surcharge de contexte :

    GLOSSIA/
      ja.md

Écrivez toute orientation spécifique à la langue dans ce fichier. Glossia l'intègre au contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Validez et envoyez la configuration mise à jour. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une traduction
session.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées
et leurs contextes effectifs n'ont pas changé.

## 4\. Examiner la demande de fusion de traduction

Suivez la session de traduction dans Glossia, puis examinez le langage généré
fichiers dans la demande de fusion ouverte par le serveur.