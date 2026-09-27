%{
  title: "Configurer un fournisseur de modèle",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "Tutoriel",
  section: "Traduction",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent des modèles configurés pour le compte actuel de Glossia. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionner **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, par exemple `translation-default`.
4. Ouvrez le sélecteur de modèle et saisissez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et saisissez sa clé de fournisseur.
6. Enregistrer le modèle.

L'identifiant reste stable, même si vous modifiez ultérieurement le modèle du fournisseur associé. Le premier modèle ajouté à un compte devient le modèle par défaut.

## Référez le modèle depuis un dépôt

Définir `model` dans la pertinente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt n'enregistre que le handle. La clé du fournisseur reste dans les paramètres de compte.

## Choisir quel modèle est utilisé par défaut

Lorsque `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le modèle par défaut et sélectionnez **Rendre par défaut**.

Pour un comportement prévisible à travers plusieurs modèles, référez un handle explicitement dans `L10N.md`.

Vous pouvez placer un handle différent `model` handle dans une section imbriquée `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule localisation cible. Glossia utilise le paramètre le plus approprié pour chaque document et localisation. Elle ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne bascule pas vers un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionner **Modèles**, et ouvrez la configuration du modèle. Entrez une nouvelle clé de fournisseur et sauvegardez. Laisser le champ clé vide conserve la clé actuelle.

Les référentiels qui font référence au handle n'ont pas besoin d'être modifiés.