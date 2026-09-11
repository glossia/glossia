%{
  title: "Configurer un fournisseur de modèle",
  summary:
    "Ajoutez un modèle de compte et référencez-le en toute sécurité depuis les référentiels.",
  category: "tutoriel",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent les modèles configurés pour le compte actuel de Glossia. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionner **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un handle unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèles et saisissez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et saisissez sa clé de fournisseur.
6. Enregistrer le modèle.

Le handle est stable même lorsque vous modifiez plus tard le modèle du fournisseur sous-jacent. Le premier modèle ajouté à un compte devient celui par défaut.

## Référencer le modèle depuis un dépôt

Définir `model` dans le pertinent `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt ne stocke que le handle. La clé du fournisseur reste dans les paramètres du compte.

## Choisir quel modèle est utilisé par défaut

Quand `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le modèle par défaut et sélectionnez **Rendre par défaut**.

Pour un comportement prévisible à travers plusieurs modèles, référez explicitement un handle dans `L10N.md`.

Vous pouvez placer un autre `model` handle dans une imbriquée `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule langue cible. Glossia utilise le paramètre le plus pertinent pour chaque document et langue. Il ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne bascule pas vers un autre modèle.

## Changer ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionnez **Modèles**, et ouvrez l'identifiant du modèle. Entrez une nouvelle clé de fournisseur et enregistrez. En laissant le champ de clé vide, la clé actuelle est conservée.

Les dépôts faisant référence au handle ne nécessitent pas de modification.