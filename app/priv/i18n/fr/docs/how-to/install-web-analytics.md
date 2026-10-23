%{
  title: "Installer l'analyse web",
  summary:
    "Ajoutez le SDK web de Glossia à votre site avec une seule ligne HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Guide",
  section: "analytics",
  order: 1
}
---

Ce guide suppose que vous disposez d'un projet Glossia dont le domaine du site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ou secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK s'initialise automatiquement, envoie une vue de page au chargement et enregistre les vues de page suivantes lors des navigations côté client dans les applications à page unique. `data-domain` par défaut est `window.location.hostname` si omis, donc vous pouvez l'omettre sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

Si votre site utilise une politique de sécurité des contenus, autorisez `https://glossia.ai` dans les deux `script-src` (ou `script-src-elem` lorsqu'il est présent) et `connect-src`. Le script charge depuis `/assets/glossia-web.js` et envoie des événements vers `/v1/collect` sur la même origine.

## Option B : npm

Installez le paquet :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans votre point d'entrée d'application :

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Définissez le point de collecte de manière explicite lorsque vous utilisez le paquet dans votre propre bundle, car il n'y a pas d'adresse de script hébergé d'où l'inférer.

`domain` est déduit de `window.location.hostname` de sorte que le SDK enregistre contre le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple pour envoyer des événements depuis une origine de staging vers le même projet que production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez votre domaine

Dans les **Paramètres d'analyse** de votre projet, enregistrez le domaine de votre site. La carte **Vérifier la propriété du nom de domaine** affiche le nom et la valeur exacts de l'enregistrement pour votre projet. Ajoutez un enregistrement texte avec votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le token affichés dans vos paramètres. Certains fournisseurs ajoutent le nom de domaine automatiquement ; dans ce cas, entrez uniquement `_glossia-verify` comme nom. Après avoir publié l'enregistrement, cliquez sur **Vérifier le nom de domaine**. Les modifications peuvent prendre du temps avant d'être disponibles, donc réessayez si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, développez **Alternative : vérifier avec une balise meta de page d'accueil**. Copiez la balise générée dans le `<head>` de votre page d'accueil et publiez-la :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Les deux méthodes prouvent le contrôle du domaine configuré. Glossia vérifie cet enregistrement ou la page d'accueil de ce domaine, donc copier le token sur un autre site web ne vérifie pas la propriété. Le token est une preuve publique, pas un mot de passe.

Une fois le domaine vérifié, Glossia enregistre les événements depuis votre fragment de suivi. Le fragment seul ne vérifie pas la propriété. Changer le domaine configuré nécessite une nouvelle vérification.

## Vérifiez que cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez qu'une requête `POST` vers `https://glossia.ai/v1/collect` renvoie `202 Accepted`.
3. Après la collecte et le traitement, la vue page apparaît dans **Analytique** du tableau de bord de votre projet. Les traductions lancées sur la page Vue d'ensemble sont séparées du trafic du site web.

Une réponse `202 Accepted` confirme que la requête a atteint le collecteur. Les domaines inconnus ou non vérifiés sont également acceptés mais n'enregistrent pas d'événements, donc confirmez que le domaine configuré est vérifié dans les paramètres d'analyse du projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le référé, `navigator.languages`, le fuseau horaire et la largeur d'écran, plus un ID de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est fingerprinté.
