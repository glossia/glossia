
Si Glossia est déjà configuré et que vous souhaitez ajouter une autre langue cible, suivez les étapes suivantes.

## 1. Mettre à jour GLOSSIA.md

Ouvrez votre `GLOSSIA.md` et ajoutez le nouveau code langue à l'array `targets` :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Ajouter un contexte spécifique à la langue (optionnel)

Si la nouvelle langue nécessite des instructions spécifiques, comme le niveau de politesse ou des considérations sur l'ensemble de caractères, créez un fichier de surcharge de contexte :

```
GLOSSIA/
  ja.md
```

Écrivez toute directive spécifique à la langue dans ce fichier. Glossia le merge avec le contexte de base pour les traductions en japonais.

## 3. Publier la modification de configuration

Commitez et poussez la configuration mise à jour. Si le dépôt est connecté à Glossia, le serveur détecte la nouvelle langue cible et lance une session de traduction.

Les traductions existantes pour d'autres langues restent inchangées lorsque leurs entrées et leur contexte effectif n'ont pas évolué.

## 4. Examiner la demande de tirage généré de traduction

Suivez la session de traduction dans Glossia, puis examinez les fichiers linguistiques générés dans la pull request ouverte par le serveur.