%{
  title: "Configurer un fournisseur de modèle",
  summary:
    "Ajouter un modèle de compte et y faire référence de manière sécurisée depuis les dépôts.",
  category: "Guide",
  section: "translation",
  order: 3
}
---
La configuration du projet et les exécutions de traduction utilisent des modèles configurés pour le compte actuel de Glossia.

## Ajouter un modèle

1. Ouvrir **Paramètres** et sélectionner **Modèles**.
2. Sélectionner **Nouveau modèle**.
3. Entrez un identifiant unique, tel que `translation-default`.
4. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
5. Sélectionnez un modèle et entrez sa clé de fournisseur.
6. Enregistrer le modèle.

L'identifiant est stable même lorsque vous modifiez plus tard le modèle du fournisseur sous-jacent. Le premier modèle ajouté à un compte devient son modèle par défaut.

## Référencez le modèle depuis un dépôt

Définissez `model` dans le pertinent `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Le dépôt stocke uniquement le handle. La clé du fournisseur reste dans les paramètres du compte.

## Choisissez quel modèle est utilisé par défaut

Lorsque `L10N.md` ommet `model`, Glossia utilise le modèle par défaut du compte. Pour le modifier, ouvrez le modèle qui doit devenir par défaut et sélectionnez **Définir comme par défaut**.

Pour un comportement prévisible à travers plusieurs modèles, référez explicitement un handle dans `L10N.md`.

Vous pouvez placer un différent `model` paramètre dans une imbriquée `L10N.md` pour une zone de contenu, ou dans `L10N/<locale>.md` pour une seule locale cible. Glossia utilise le paramètre applicable le plus pertinent pour chaque document et locale. Elle ne répartit pas automatiquement le travail entre les modèles configurés.

Si un handle explicite n'existe pas dans le compte, la traduction s'arrête avec une erreur. Elle ne bascule pas sur un autre modèle.

## Modifier ou renouveler une clé de fournisseur

Ouvrir **Paramètres**, sélectionner **Modèles**, et ouvrez le handle du modèle. Saisissez une nouvelle clé de fournisseur et enregistrez. Laisser le champ clé vide conserve la clé actuelle.

Les dépôts qui font référence au handle n'ont pas besoin d'être modifiés.

## Ajouter Jev pour les décisions de qualité de traduction

1. Ouvrir **Paramètres → Modèles → Nouveau modèle** et sélectionnez **Décision** comme catégorie.
2. Utilisez un handle tel que `translation-quality`. Conserver `typesafe/jev-latest`, ou entrez une version de modèle TypeSafe Jev verrouillée.
3. Entrez votre clé de fournisseur TypeSafe. Laissez l'adresse de base vide pour utiliser le point de terminaison TypeSafe natif ; une adresse personnalisée doit inclure son préfixe de version, tel que `https://api.typesafe.ai/v1`.
4. Définissez le score de qualité minimum de 1 à 10, puis enregistrez. Le premier modèle de décision devient le modèle de décision par défaut et active automatiquement l'évaluation.
5. Lancez la traduction. Les dimensions de qualité échouées demandent une correction dans le `retries` budget configuré dans votre dépôt.

Les modèles génératifs et décisionnels ont des valeurs par défaut séparées. Gardez les identifiants de modèle de traduction inchangés. Les modèles de décision ne peuvent pas être sélectionnés par les identifiants de traduction du dépôt ou les règles de routage de localisation. Supprimez tous les modèles de décision pour désactiver l'évaluation.