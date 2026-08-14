%{
  title: "Configurer un fournisseur de modèles",
  summary: "Ajoutez un modèle de compte et référencez-le de manière sécurisée depuis les dépôts.",
  category: "how-to",
  order: 3
}
---
La configuration des projets et les exécutions de traduction utilisent les modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrez **Paramètres** et sélectionnez **Modèles**.
2. Sélectionnez **Nouveau modèle**.
3. Saisissez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèles et saisissez une partie du nom d’un fournisseur ou d’un modèle pour filtrer la liste.
5. Sélectionnez un modèle et saisissez sa clé fournisseur.
6. Enregistrez le modèle.

L’identifiant reste stable même si vous modifiez ultérieurement le modèle du fournisseur qui lui est associé. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Référencer le modèle depuis un dépôt

Définissez `model` dans les métadonnées liminaires `GLOSSIA.md` concernées :

```yaml
---
model: translation-default
---
```

Le dépôt stocke uniquement l’identifiant. La clé fournisseur reste dans les paramètres du compte.

## Choisir le modèle utilisé par défaut

Lorsque `GLOSSIA.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le modèle par défaut et sélectionnez **Définir par défaut**.

Pour garantir un comportement prévisible avec plusieurs modèles, référencez explicitement un identifiant dans `GLOSSIA.md`.

Vous pouvez placer un identifiant `model` différent dans un fichier `GLOSSIA.md` imbriqué pour une zone de contenu, ou dans `GLOSSIA/<locale>.md` pour une langue cible. Glossia utilise le paramètre applicable le plus proche pour chaque document et chaque langue. Glossia ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n’existe pas dans le compte, la traduction s’arrête avec une erreur. Aucun autre modèle n’est utilisé en remplacement.

## Modifier ou renouveler une clé fournisseur

Ouvrez **Paramètres**, sélectionnez **Modèles**, puis ouvrez l’identifiant du modèle. Saisissez une nouvelle clé fournisseur et enregistrez. Si vous laissez le champ de la clé vide, la clé actuelle est conservée.

Les dépôts qui référencent cet identifiant ne nécessitent aucune modification.