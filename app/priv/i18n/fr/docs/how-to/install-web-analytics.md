%{
  title: "Installer une analyse web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "tutoriel",
  order: 1
}
---
Ce guide suppose que vous avez un projet Glossia dont le domaine du site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ni secret à copier.

## Option A : balise script

Ajoutez cet extrait à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Le SDK s'initialise automatiquement, envoie une vue de page au chargement et enregistre les vues de page ultérieures lors de la navigation côté client dans les applications à page unique. `data-domain` est par défaut `window.location.hostname` lorsqu'il est omis, donc vous pouvez l'omettre sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

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

Le `domain` est déduit de `window.location.hostname` afin que le SDK enregistre les données contre le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple pour envoyer des événements depuis une origine staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifier que cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et confirmez qu'une requête `POST` vers `/api/analytics/events` renvoie `202 Accepted`.
3. Dans la minute, la vue de page apparaît dans le tableau de bord d'analyse de votre projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le référent, `navigator.languages`, le fuseau horaire et la largeur de l'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est identifié par empreinte numérique.