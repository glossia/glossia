%{
  title: "Installer des analyses web",
  summary:
    "Ajoutez le SDK web de Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "guide",
  order: 1
}
---
Ce guide suppose que vous avez un projet Glossia dont le domaine du site est configuré dans les paramètres analytiques du projet. La collection est identifiée par ce domaine, il n'y a donc aucune clé ou secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

L'SDK s'initialise automatiquement, transmet une visite de page au chargement et enregistre les visites de page suivantes lors de la navigation côté client dans les applications à page unique. `data-domain` par défaut à `window.location.hostname` lorsqu'il est omis, vous pouvez le placer sur un site à domaine unique. Pour utiliser un endpoint de collection personnalisé, ajouter `data-endpoint="https://collect.your-host.com"`.

## Option B : npm

Installez le paquet :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans le point d'entrée de votre application :

```ts
import glossia from "@glossia/web";

glossia.init();
```

Le `domain` est déduit de `window.location.hostname` de sorte que le SDK enregistre pour le projet enregistré sur votre site. Passez `{ domain: "example.com" }` pour le remplacer, par exemple pour envoyer des événements depuis une origine de test vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et confirmez une `POST` requête vers `/api/analytics/events` renvoie `202 Accepted`.
3. En moins d'une minute, la vue de page apparaît dans votre tableau de bord analytique du projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le référent, `navigator.languages`fuseau horaire et largeur d'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et aucune empreinte n'est créée.