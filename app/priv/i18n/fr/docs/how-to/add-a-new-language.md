%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "Guide",
  section: "translation",
  order: 1
}
---

Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code langue au tableau `targets` :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spéciales, telles que le niveau de formalité ou des considérations d'ensemble de caractères, créez un fichier de surcharge de contexte :

```
L10N/
  ja.md
```

Écrivez toute recommandation linguistique spécifique dans ce fichier. Glossia le fusionne avec le contexte de base pour les traductions en japonais.

## 3. Publier le changement de configuration

Commitez et poussez la configuration mise à jour. Si le dépôt est connecté à Glossia, le serveur détecte la nouvelle langue cible et démarre une session de traduction.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées et leur contexte effectif n'ont pas changé.

## 4. Reviser la pull request de traduction

Suivez la session de traduction dans Glossia, puis révisez les fichiers de langue générés dans la pull request ouverte par le serveur.
