%{
  title: "Configurez un fournisseur de modèles",
  summary: "Ajoutez un modèle de compte et référenciez-le en toute sécurité depuis les dépôts.",
  category: "tutoriel",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent les modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionner **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, par exemple `translation-default`.
4. Ouvrez le sélecteur de modèle et saisissez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrez le modèle.

L'identifiant reste stable, même si vous modifiez plus tard le modèle du fournisseur sous-jacent. Le premier modèle ajouté à un compte devient le modèle par défaut.

## Référencer le modèle depuis un dépôt

Définir `model` dans le pertinent `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt ne stocke que l'handle. La clé du fournisseur reste dans les paramètres du compte.

## Choisissez quel modèle est utilisé par défaut

Quand `L10N.md` omet `model`\`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir par défaut et sélectionnez **Définir par défaut**.

Pour un comportement cohérent entre plusieurs modèles, référez explicitement un handle dans `L10N.md`.

Vous pouvez placer une différente `model` poignée dans un imbriqué `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule localisation cible. Glossia utilise le paramètre le plus approprié pour chaque document et chaque localisation. Il ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne se replie pas sur un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionnez **Modèles**, et ouvrez l'identifiant du modèle. Entrez une nouvelle clé de fournisseur et sauvegardez. Laisser le champ de clé vide conserve la clé actuelle.

Les dépôts qui font référence au handle ne nécessitent pas de modification.