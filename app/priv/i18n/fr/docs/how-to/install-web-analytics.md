%{
  title: "Installez l'analytique web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de code HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Guide",
  order: 1
}
---
Ce guide suppose que vous avez un projet Glossia dont le domaine du site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ou secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Le SDK s'auto-initialise, envoie une vue de page au chargement, et enregistre les vues de page ultérieures lors de la navigation côté client dans les applications à page unique. `data-domain` par défaut `window.location.hostname` lorsqu'il est omis, vous pouvez donc l'omettre sur un site à domaine unique. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

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

Le `domain` est déduit de `window.location.hostname` de sorte que le SDK enregistre sur le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple pour envoyer des événements depuis une origine staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez une `POST` requête vers `/api/analytics/events` retourne `202 Accepted`.
3. Dans une minute, la pageview apparaît dans le tableau de bord analytique de votre projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le referrer, `navigator.languages`l'heure, et la largeur de l'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est associé à une empreinte.