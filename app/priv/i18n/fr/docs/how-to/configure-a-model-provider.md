%{
  title: "Configurer un fournisseur de modèles",
  summary: "Ajouter un modèle de compte et le référencer en toute sécurité depuis les dépôts.",
  category: "Tutoriel",
  section: "translation",
  order: 3
}
---

La configuration de projet et les exécutions de traduction utilisent des modèles configurés pour le compte Glossia actuel. Configurez au moins un modèle avant de créer un projet.

## Ajouter un modèle

1. Ouvrez **Paramètres** et sélectionnez **Modèles**.
2. Sélectionnez **Nouveau modèle**.
3. Entrez un identifiant unique, comme `translation-default`.
4. Ouvrez le sélecteur de modèles et tapez une partie du nom d'un fournisseur ou d'un modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé fournisseur.
6. Enregistrez le modèle.

L'identifiant reste stable même si vous modifiez plus tard le modèle fournisseur derrière. Le premier modèle ajouté à un compte en devient le modèle par défaut.

## Référencer le modèle depuis un dépôt

Définissez `model` dans le frontmatter `L10N.md` pertinent :

```yaml
---
model: translation-default
---
```

Le dépôt stocke uniquement l'identifiant. La clé fournisseur reste dans les paramètres du compte.

## Choisir quel modèle est utilisé par défaut

Lorsque `L10N.md` omet `model`, Glossia utilise le modèle par défaut du compte. Pour le changer, ouvrez le modèle qui doit devenir le par défaut et sélectionnez **Définir comme par défaut**.

Pour un comportement prévisible avec plusieurs modèles, référennez explicitement un identifiant dans `L10N.md`.

Vous pouvez placer un identifiant `model` différent dans un `L10N.md` imbriqué pour une zone de contenu, ou dans `L10N/<locale>.md` pour une locale cible. Glossia utilise le paramètre applicable le plus proche pour chaque document et locale. Il ne divise pas automatiquement le travail entre les modèles configurés.

Si un identifiant explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne revient pas à un autre modèle.

## Modifier ou faire pivoter une clé fournisseur

Ouvrez **Paramètres**, sélectionnez **Modèles** et ouvrez l'identifiant du modèle. Entrez une nouvelle clé fournisseur et enregistrez. Laisser le champ de la clé vide conserve la clé actuelle.

Les dépôts qui référencent l'identifiant n'ont pas besoin de changer.

## Ajouter Jev pour les décisions de qualité de traduction

1. Ouvrez **Paramètres → Modèles → Nouveau modèle** et sélectionnez **Décision** en tant que catégorie.
2. Utilisez un identifiant tel que `translation-quality`. Conservez `typesafe/jev-latest`, ou entrez une version TypeSafe Jev bloquée.
3. Entrez votre clé fournisseur TypeSafe. Laissez l'adresse de base vide pour utiliser l'endpoint natif TypeSafe ; une adresse personnalisée doit inclure son préfixe de version, tel que `https://api.typesafe.ai/v1`.
4. Définissez la note de qualité minimale de 1 à 10, puis enregistrez. Le premier modèle décisionnel devient le modèle de décision par défaut et active l'évaluation automatiquement.
5. Exécutez la traduction. Les dimensions de qualité échouées demandent une correction dans le `retries` budget configuré dans votre dépôt.

Les modèles génératifs et décisionnels ont des valeurs par défaut distinctes. Conservez les identifiants de vos modèles de traduction inchangés. Les modèles décisionnels ne peuvent pas être sélectionnés par les identifiants de traduction de dépôt ou les règles de routage de locale. Supprimez tous les modèles décisionnels pour désactiver l'évaluation.
