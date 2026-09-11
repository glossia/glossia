%{
  title: "Configurer un fournisseur de modèle",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "Guide",
  order: 3
}
---
La mise en place du projet et les exécutions de traduction utilisent des modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionnez **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèles et tapez une partie du nom d'un fournisseur ou d'un modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrez le modèle.

L'identifiant est stable, même lorsque vous changez par la suite le modèle fournisseur sous-jacent. Le premier modèle ajouté à un compte devient le modèle par défaut.

## Référencer le modèle depuis un dépôt

Définir `model` dans le pertinent `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt ne contient que le handle. La clé du fournisseur reste dans les paramètres du compte.

## Choisissez quel modèle est utilisé par défaut

Quand `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir par défaut et sélectionnez **Définir par défaut**.

Pour un comportement prévisible sur plusieurs modèles, référez-vous explicitement à un gestionnaire dans `L10N.md`.

Vous pouvez placer une `model` gestionnaire dans un champ imbriqué `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule langue cible. Glossia utilise le paramètre le plus approprié pour chaque document et langue. Il ne divise pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'interrompt avec une erreur. Elle ne se rabat pas sur un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionner **Modèles**, et ouvrez l'identifiant du modèle. Saisissez une nouvelle clé de fournisseur et enregistrez. Laisser le champ clé vide conserve la clé actuelle.

Les dépôts qui font référence au handle ne nécessitent pas de modification.