%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "guide",
  section: "translation",
  order: 1
}
---

Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1. Mettez à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le nouveau code de langue au tableau `targets` :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Ajoutez un contexte spécifique à la langue (facultatif)

Si la nouvelle langue nécessite des instructions spéciales, telles que le niveau de formalité ou les considérations liées au jeu de caractères, créez un fichier de surcharge de contexte :

```
L10N/
  ja.md
```

Écrivez tout guidage spécifique à la langue dans ce fichier. Glossia le combine avec le contexte de base pour les traductions japonaises.

## 3. Publiez le changement de configuration

Validez et poussez la configuration mise à jour. Si le dépôt est connecté à Glossia, le serveur détecte la nouvelle langue cible et lance une session de traduction.

Les traductions existantes pour d'autres langues demeurent inchangées tant que leurs entrées et le contexte effectif n'ont pas changé.

## 4. Examinez la demande de pull de traduction

Suivez la session de traduction dans Glossia, puis examinez les fichiers linguistiques générés dans la demande de pull ouverte par le serveur.
