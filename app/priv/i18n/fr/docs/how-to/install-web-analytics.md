%{
  title: "Installer l’analyse web",
  summary: "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, puis commencez à collecter des signaux de localisation.",
  category: "how-to",
  order: 1
}
---
Ce guide suppose que vous disposez d'un projet Glossia dont le domaine du site est configuré dans les paramètres d'analyse du projet. La collecte est associée à ce domaine. Il n'y a donc aucune clé ni aucun secret à copier.

## Option A : balise de script

Ajoutez cet extrait à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Le kit de développement logiciel s'initialise automatiquement, envoie une vue de page lors du chargement et enregistre les vues de page suivantes lors de la navigation côté client dans les applications monopages. `data-domain` utilise `window.location.hostname` par défaut lorsqu'il est omis. Vous pouvez donc l'intégrer directement à un site utilisant un seul domaine. Pour auto-héberger le point de terminaison de collecte, ajoutez `data-endpoint="https://collect.your-host.com"`.

## Option B : npm

Installez le paquet :

```bash
npm install @glossia/web
```

Initialisez-le une seule fois dans le point d'entrée de votre application :

```ts
import glossia from "@glossia/web";

glossia.init();
```

Le `domain` est déduit de `window.location.hostname`, afin que le kit de développement logiciel associe les données au projet enregistré pour votre site. Transmettez `{ domain: "example.com" }` pour remplacer cette valeur, par exemple afin d'envoyer les événements d'une origine de préproduction vers le même projet que celui de production.

Pour enregistrer un événement personnalisé, comme une inscription :

```ts
glossia.track("signup");
```

## Vérifier le fonctionnement

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et vérifiez qu'une requête `POST` vers `/api/analytics/events` renvoie `202 Accepted`.
3. Dans un délai d'une minute, la vue de page apparaît dans le tableau de bord d'analyse de votre projet.

## Données collectées

Le navigateur envoie l'adresse de la page, la page référente, le `navigator.languages`, le fuseau horaire et la largeur de l'écran, ainsi qu'un identifiant de session propre à chaque onglet. Le serveur ajoute le pays, déterminé par géolocalisation de l'adresse IP, et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est déposé et aucune technique d'empreinte numérique n'est utilisée.