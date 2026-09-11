%{
  title: "Installez des analyses web",
  summary:
    "Ajoutez le SDK web de Glossia sur votre site avec une seule ligne HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "guide pratique",
  order: 1
}
---
Ce guide suppose que vous disposez d'un projet Glossia dont le domaine de site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc pas de clé ou de secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Le SDK se initialise automatiquement, envoie une vue de page au chargement et enregistre les vues de page ultérieures lors de la navigation côté client dans les applications monopage. `data-domain` par défaut à `window.location.hostname` s'il est omis, vous pouvez donc l'utiliser sur un site à domaine unique. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

## Option B : npm

Installez le package :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans votre point d'entrée d'application :

```ts
import glossia from "@glossia/web";

glossia.init();
```

Le `domain` est inféré de `window.location.hostname` donc le SDK enregistre dans le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple envoyer des événements depuis une origine de staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez que cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et confirmez une `POST` requête vers `/api/analytics/events` renvoie `202 Accepted`.
3. En moins d'une minute, la vue de page apparaît dans le tableau de bord analytique de votre projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, l'URL de provenance, `navigator.languages`fuseau horaire, et la largeur d'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et aucun élément n'est utilisé pour créer une empreinte numérique.