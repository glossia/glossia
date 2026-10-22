%{
  title: "Configurer un fournisseur de modèle",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "Tutoriel",
  section: "translation",
  order: 3
}
---

La configuration du projet et les exécutions de traduction utilisent des modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrez **Paramètres** et sélectionnez **Modèles**.
2. Sélectionnez **Nouveau modèle**.
3. Entrez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrez le modèle.

L'identifiant reste stable même lorsque vous modifiez ultérieurement le modèle du fournisseur qu'il pointe. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Référer le modèle depuis un dépôt

Définissez `model` dans le frontmatter pertinent `L10N.md` :

```yaml
---
model: translation-default
---
```

Le dépôt ne conserve uniquement l'identifiant. La clé du fournisseur reste dans les paramètres du compte.

## Choisir quel modèle est utilisé par défaut

Lorsque `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir le modèle par défaut et sélectionnez **Paramétrer par défaut**.

Pour un comportement prévisible avec plusieurs modèles, référez un identifiant explicitement dans `L10N.md`.

Vous pouvez placer un identifiant `model` différent dans un `L10N.md` imbriqué pour une zone de contenu, ou dans `L10N/<locale>.md` pour une cible locale spécifique. Glossia utilise le paramètre applicable le plus proche pour chaque document et locale. Cela ne divise pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne retourne pas vers un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrez **Paramètres**, sélectionnez **Modèles** et ouvrez l'identifiant du modèle. Entrez une nouvelle clé de fournisseur et enregistrez. Laisser le champ de clé vide conserve la clé actuelle.

Les dépôts qui référencent l'identifiant n'ont pas besoin de changer.

## Ajouter Jev pour les décisions de qualité de traduction

1. Ouvrez **Paramètres → Modèles → Nouveau modèle** et sélectionnez **Décision** en tant que catégorie.
2. Utilisez un identifiant tel que `translation-quality`. Conservez `typesafe/jev-latest`, ou entrez une version TypeSafe Jev fixée.
3. Entrez votre clé de fournisseur TypeSafe. Laissez l'adresse de base vide pour utiliser le point de terminaison TypeSafe natif ; une adresse personnalisée doit inclure son préfixe de version, tel que `https://api.typesafe.ai/v1`.
4. Définissez le score de qualité minimum de 1 à 10, puis enregistrez. Le premier modèle de décision devient le modèle de décision par défaut et active l'évaluation automatiquement.
5. Lancez la traduction. Les dimensions de qualité échouées demandent une correction dans le budget `retries` configuré dans votre dépôt.

Les modèles génératifs et de décision ont des valeurs par défaut distinctes. Gardez les identifiants de vos modèles de traduction inchangés. Les modèles de décision ne peuvent pas être sélectionnés par des identifiants de traduction de dépôt ou des règles de routage de locale. Supprimez tous les modèles de décision pour désactiver l'évaluation.
