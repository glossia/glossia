%{
  title: "Configurer un fournisseur de modèle",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "Tutoriel",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent les modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionner **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèle et saisissez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrez le modèle.

L'identifiant est stable même si vous modifiez plus tard le modèle fournisseur sous-jacent. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Faire référence au modèle depuis un dépôt

Définir `model` dans le pertinent `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt ne stocke que le handle. La clé du fournisseur reste dans les paramètres de compte.

## Choisissez quel modèle est utilisé par défaut

Lorsque `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le par défaut et sélectionnez **Rendre par défaut**.

Pour un comportement prédictible à travers plusieurs modèles, référez explicitement un handle dans `L10N.md`.

Vous pouvez placer un handle différent `model` handle dans un imbriqué `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule locale cible. Glossia utilise le paramètre applicable le plus pertinent pour chaque document et locale. Il ne répartit pas automatiquement le travail parmi les modèles configurés.

Si un handle explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne recourt pas à un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionner **Modèles**, et ouvrez le handle du modèle. Entrez une nouvelle clé de fournisseur et enregistrez. Laisser le champ de clé vide conserve la clé actuelle.

Les dépôts qui font référence au handle n'ont pas besoin de changer.