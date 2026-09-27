%{
  title: "Installer l'analyse Web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une simple ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Guide pratique",
  section: "Analyses",
  order: 1
}
---
Ce guide suppose que vous avez un projet Glossia avec son domaine de site configuré dans les paramètres analytiques du projet. La collection est identifiée par ce domaine, donc il n'y a pas de clé ni de secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

L' SDK s'auto-initialise, envoie une vue de page au chargement et enregistre les vues de page suivantes lors de la navigation côté client dans les applications en une seule page. `data-domain` par défaut `window.location.hostname` lorsqu'elle est omise, vous pouvez l'utiliser sur un site à domaine unique. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

## Option B : npm

Installez le package :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans le point d'entrée de votre application :

```ts
import glossia from "@glossia/web";

glossia.init();
```

Le `domain` est inféré de `window.location.hostname` Ainsi, l'SDK enregistre pour le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surclasser, par exemple pour envoyer des événements depuis une origine de staging vers le même projet que pour la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et confirmez une `POST` requête vers `/api/analytics/events` renvoie `202 Accepted`.
3. Dans moins d'une minute, la consultation de page apparaît dans le tableau de bord analytique de votre projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le referrer, `navigator.languages`, l'heure du fuseau horaire, et la largeur de l'écran, plus un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est fingerprinté.