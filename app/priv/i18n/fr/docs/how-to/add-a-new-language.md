%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "Guides",
  order: 1
}
---
Si vous avez déjà configuré Glossia et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour L10N.md

Ouvrir votre `L10N.md` et ajouter le code de la nouvelle langue au `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spéciales, comme le niveau de formalité ou les considérations de jeu de caractères, créez un fichier de surcharge du contexte :

    L10N/
      ja.md

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia le fusionne avec le contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Engager et pousser la configuration mise à jour. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et lance une session de
traduction.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées
et contexte effectif n'ont pas changé.

## 4\. Reviser la Pull Request de traduction

Suivez la session de traduction dans Glossia, puis révisez la langue générée.
les fichiers de la demande de fusion ouverte par le serveur.