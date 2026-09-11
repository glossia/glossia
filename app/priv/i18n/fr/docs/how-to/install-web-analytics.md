%{
  title: "Installer l'analyse web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Tutoriel",
  order: 1
}
---
Ce guide suppose que vous disposez d'un projet Glossia dont le domaine du site est configuré dans les paramètres d'analyse. La collection est identifiée par ce domaine, il n'y a donc pas de clé ou de secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

L'SDK s'initialise automatiquement, envoie une vue de page au chargement et enregistre les vues pages subséquentes lors de la navigation côté client dans les applications en une seule page. `data-domain` défaut à `window.location.hostname` omis, vous pouvez donc l'intégrer sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

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

Le `domain` est déduit de `window.location.hostname` de sorte que le SDK enregistre pour le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple pour envoyer des événements depuis une origine de staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez une `POST` requête vers `/api/analytics/events` retourne `202 Accepted`.
3. En moins d'une minute, la vue de page apparaît dans le tableau de bord analytique de votre projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le référent, `navigator.languages`, Le fuseau horaire, la largeur d'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et aucune donnée n'est fingerprintée.