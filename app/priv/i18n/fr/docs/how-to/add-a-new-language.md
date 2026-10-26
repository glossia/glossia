%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "tutoriel",
  section: "translation",
  order: 1
}
---

Si vous avez déjà Glossia configuré et souhaitez ajouter une autre langue cible, suivez ces étapes.

## 1. Mettre à jour L10N.md

Ouvrez votre `L10N.md` et ajoutez le code de la nouvelle langue dans le tableau `targets` :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spéciales, comme un niveau de formalité ou des considérations d'encodage de caractères, créez un fichier de surcharge de contexte :

```
L10N/
  ja.md
```

Écrivez tout guide spécifique à la langue dans ce fichier. Glossia le combine avec le contexte de base pour les traductions en japonais.

## 3. Publier le changement de configuration

Commitez et envoyez la configuration mise à jour. Si le référentiel est connecté à Glossia, le serveur détecte la nouvelle langue cible et démarre une session de traduction.

Les traductions existantes pour les autres langues restent inchangées lorsque leurs entrées et leur contexte effectif n'ont pas changé.

## 4. Examiner la demande de fusion de traduction

Suivez la session de traduction sur Glossia, puis examinez les fichiers de langue générés dans la demande de fusion ouverte par le serveur.
