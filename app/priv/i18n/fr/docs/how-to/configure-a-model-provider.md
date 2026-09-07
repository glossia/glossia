%{
  title: "Configurer un fournisseur de modèle",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "tutoriel",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent les modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrez **Paramètres** et sélectionnez **Modèles**.
2. Sélectionnez **Nouveau modèle**.
3. Saisissez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Sauvegardez le modèle.

L'identifiant reste stable même lorsque vous modifiez plus tard le modèle fournisseur sous-jacent. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Référencer le modèle depuis un dépôt

Définissez `model` dans le frontmatter du `GLOSSIA.md` pertinent :

```yaml
---
model: translation-default
---
```

Le dépôt ne stocke que l'identifiant. La clé de fournisseur reste dans les paramètres du compte.

## Choisir quel modèle est utilisé par défaut

Lorsque `GLOSSIA.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui devrait devenir par défaut et sélectionnez **Définir comme par défaut**.

Pour un comportement prévisible entre plusieurs modèles, référez un identifiant explicitement dans `GLOSSIA.md`.

Vous pouvez placer un identifiant `model` différent dans un `GLOSSIA.md` imbriqué pour une zone de contenu donnée, ou dans `GLOSSIA/<locale>.md` pour une locale cible donnée. Glossia utilise le paramétrage le plus pertinent pour chaque document et locale. Il ne répartit pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Il ne bascule pas sur un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrez **Paramètres**, sélectionnez **Modèles**, puis ouvrez l'identifiant du modèle. Saisissez une nouvelle clé de fournisseur et sauvegardez. Laisser le champ de clé vide conserve la clé actuelle.

Les dépôts qui référencent l'identifiant ne nécessitent aucune modification.