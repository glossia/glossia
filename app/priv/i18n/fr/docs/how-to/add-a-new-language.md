%{
  title: "Ajouter une nouvelle langue",
  summary: "Comment ajouter une langue cible à une configuration Glossia existante.",
  category: "how-to",
  order: 1
}
---
Si Glossia est déjà configuré et que vous souhaitez ajouter une autre langue cible, procédez comme suit.

## 1. Mettre à jour GLOSSIA.md

Ouvrez votre fichier `GLOSSIA.md` et ajoutez le code de la nouvelle langue au tableau `targets` :

```yaml
targets:
  - es
  - fr
  - de
  - ja
```

## 2. Ajouter un contexte propre à la langue (facultatif)

Si la nouvelle langue nécessite des instructions particulières, telles qu'un niveau de formalité ou des considérations relatives au jeu de caractères, créez un fichier de remplacement du contexte :

```
GLOSSIA/
  ja.md
```

Ajoutez dans ce fichier toutes les consignes propres à la langue. Glossia les fusionne avec le contexte de base pour les traductions en japonais.

## 3. Publier la modification de configuration

Validez et poussez la configuration mise à jour. Si le dépôt est connecté à
Glossia, le serveur détecte la nouvelle langue cible et démarre une session de
traduction.

Les traductions existantes dans les autres langues restent inchangées si leurs entrées
et leur contexte effectif n'ont pas changé.

## 4. Examiner la demande de tirage de traduction

Suivez la session de traduction dans Glossia, puis examinez les fichiers de langue
générés dans la demande de tirage ouverte par le serveur.