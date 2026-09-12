%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "guide",
  order: 1
}
---
Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1\. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue à la `targets` tableau :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2\. Ajouter un contexte spécifique à la langue (facultatif)

Si la nouvelle langue nécessite des instructions particulières, comme le niveau de formalité ou des considérations d'encodage de caractères, créez un fichier de contexte de remplacement :

    L10N/
      ja.md

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia le combine avec le contexte de base pour les traductions en japonais.

## 3\. Publier le changement de configuration

Commitez et poussez la configuration mise à jour. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et démarre une
traduction séance.

Traductions existantes pour les autres langues restent inchangées quand leurs entrées
et contexte effectif n'ont pas changé.

## 4\. Examinez la pull request de traduction

Suivez la séance de traduction dans Glossia, puis révisez la langue générée.
les fichiers de la pull request ouverte par le serveur.