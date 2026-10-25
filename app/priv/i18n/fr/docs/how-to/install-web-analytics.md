%{
  title: "Installez l'analyse web",
  summary:
    "Ajoutez le Glossia web SDK à votre site avec une ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Tutoriel",
  section: "analytics",
  order: 1
}
---

Ce guide suppose que vous avez un projet Glossia dont le nom de domaine du site est configuré dans les paramètres analytiques du projet. La collecte est identifiée par ce domaine, de sorte qu'il n'y a pas de clé ni de secret à copier.

## Option A : balise script

Ajoutez cet extrait à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK s'initialise automatiquement, envoie une vue de page lors du chargement et enregistre les vues de page subséquentes lors de la navigation du côté client dans les applications monopage. `data-domain` se substitue par défaut à `window.location.hostname` lorsqu'il est omis, de sorte que vous pouvez l'omettre sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

Si votre site utilise une politique de sécurité du contenu, autorisez `https://glossia.ai` à la fois dans `script-src` (ou `script-src-elem` si présent) et `connect-src`. Le script est chargé depuis `/assets/glossia-web.js` et envoie des événements à `/v1/collect` sur la même origine.

## Option B : npm

Installez le paquet :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans le point d'entrée de votre application :

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Définissez explicitement le point de collecte lorsque vous utilisez le paquet dans votre propre bundle, car il n'y a pas d'adresse de script hébergée à partir de laquelle il peut être inféré.

`domain` est déduit à partir de `window.location.hostname` de sorte que le SDK enregistre par rapport au projet rattaché à votre site. Fournissez `{ domain: "example.com" }` pour surclasser, par exemple pour envoyer des événements depuis une origine de test vers le même projet que en production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez votre domaine

Dans les **Paramètres analytiques** de votre projet, enregistrez le nom de domaine de votre site. La carte **Vérifier la propriété du domaine** affiche le nom exact et la valeur de l'enregistrement pour votre projet. Ajoutez un enregistrement de texte avec votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement de texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le token affichés dans vos paramètres. Certains fournisseurs ajoutent le domaine automatiquement ; dans ce cas, saisissez uniquement `_glossia-verify` comme nom. Après avoir publié l'enregistrement, cliquez sur **Vérifier le domaine**. Les changements peuvent mettre du temps à devenir disponibles, donc réessayez si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, dépliez **Alternative : vérifier avec une balise meta d'accueil**. Copiez la balise générée dans le `<head>` de votre page d'accueil et publiez-la :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Les deux méthodes prouvent le contrôle du domaine configuré. Glossia vérifie l'enregistrement ou la page d'accueil de ce domaine, de sorte que copier le token sur un autre site ne vérifie pas la propriété. Le token est une preuve publique, pas un mot de passe.

Une fois le domaine vérifié, Glossia enregistre les événements depuis votre extrait de suivi. L'extrait seul ne vérifie pas la propriété. Le changement du domaine configuré nécessite une nouvelle vérification.

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez qu'une requête `POST` vers `https://glossia.ai/v1/collect` renvoie `202 Accepted`.
3. Après la collecte et le traitement, la vue de page apparaît sous **Analytique** dans le tableau de bord de votre projet. Les exécutions de traduction sur la page Vue d'ensemble sont séparées du trafic du site web.

Une réponse `202 Accepted` confirme que la requête a atteint le collecteur. Les domaines inconnus ou non vérifiés sont également acceptés mais n'enregistrent pas d'événements, de sorte que vérifiez que le domaine configuré est vérifié dans les paramètres analytiques du projet.

## Qu'est-ce qui est collecté

Le navigateur envoie l'URL de la page, le referrer, `navigator.languages`, la zone horaire et la largeur d'écran, plus un ID de session par onglet. Le serveur ajoute le pays (depuis GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est fingerprinté.
