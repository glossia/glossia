%{
  title: "Installer l'analyse web",
  summary: "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "guide",
  order: 1
}
---
Ce guide suppose que vous disposez d'un projet Glossia dont le domaine de site est configuré dans les paramètres analytiques du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ni secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, de préférence dans l'élément `<head>` :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

L’SDK s’initialise automatiquement, envoie une vue de page au chargement, et enregistre les vues de page suivantes lors de la navigation côté client dans les applications à page unique. La valeur par défaut de `data-domain` est `window.location.hostname` lorsqu'elle est omise, vous pouvez donc l'omettre sur un site à domaine unique. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

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

Le `domain` est déduit de `window.location.hostname`, de sorte que l’SDK enregistre les données dans le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple afin d’envoyer des événements depuis un environnement de staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifier si cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l’onglet réseau et confirmez qu’une requête `POST` vers `/api/analytics/events` renvoie `202 Accepted`.
3. Au cours d'une minute, la vue de page apparaît dans le tableau de bord analytique de votre projet.

## Ce qui est collecté

Le navigateur envoie l’URL de la page, le referrer, `navigator.languages`, le fuseau horaire, la largeur de l'écran, ainsi qu'un ID de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et aucune empreinte n'est capturée.