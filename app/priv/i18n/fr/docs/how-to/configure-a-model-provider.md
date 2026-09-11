%{
  title: "Configurer un fournisseur de modèle",
  summary:
    "Ajouter un modèle de compte et le référencer en toute sécurité depuis les référentiels.",
  category: "guide",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent des modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionnez **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèles et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrez le modèle.

L'identifiant reste stable même lorsque vous changez plus tard le modèle du fournisseur sous-jacent. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Configurer le modèle depuis un dépôt

Définir `model` dans la section pertinente `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt ne conserve que le handle. La clé du fournisseur reste dans les paramètres du compte.

## Choisir quel modèle est utilisé par défaut

Quand `L10N.md` omet `model`", Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le par défaut et sélectionnez **Définir par défaut**.

Pour un comportement prévisible avec plusieurs modèles, référencez explicitement un handle dans `L10N.md`.

Vous pouvez placer un autre `model` handle dans une structure imbriquée `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule langue cible. Glossia utilise le paramètre applicable le plus proche pour chaque document et langue. Il ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne bascule pas vers un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionner **Modèles**, et ouvrez l'identifiant du modèle. Entrez une nouvelle clé de fournisseur et sauvegardez. Laisser le champ clé vide conserve la clé actuelle.

Les dépôts qui font référence à l'handle ne nécessitent pas de modification.