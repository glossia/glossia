%{
  title: "Installez de l'analytique web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Comment faire",
  section: "analytics",
  order: 1
}
---
Ce guide suppose que vous possédez un projet Glossia dont le nom de domaine de site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine ; il n'y a donc aucune clé ou secret à copier.

## Option A : script tag

Ajoutez ce fragment à chaque page, idéalement dans le `<head>`" :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK s'auto-initialise, envoie une vue de page au chargement, et enregistre les vues de page ultérieures lors de la navigation côté client dans les applications monopages. `data-domain` valeur par défaut `window.location.hostname` quand il est omis, vous pouvez ainsi l'omettre sur un site mono-domaine. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`".

Si votre site utilise une politique de sécurité des contenus, autorisez `https://glossia.ai` dans les deux `script-src` (ou `script-src-elem` lorsqu'il est présent) et `connect-src`. Le script charge depuis `/assets/glossia-web.js` et envoie des événements à `/v1/collect` sur la même origine.

## Option B : npm

Installez le paquet:

```bash
npm install @glossia/web
```

Initialisez-le une fois dans le point d'entrée de votre application:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Définissez explicitement l'endpoint de collecte lorsque vous utilisez le paquet dans votre propre bundle, car il n'y a pas d'adresse de script hébergée à partir de laquelle l'inférer.

`domain` est inféré à partir de `window.location.hostname` de sorte que l'SDK enregistre les événements vers le projet enregistré pour votre site. Fournissez `{ domain: "example.com" }` pour le remplacer, par exemple pour envoyer des événements depuis une origine de staging vers le même projet qu'en production.

Pour enregistrer un événement personnalisé, par exemple une inscription:

```ts
glossia.track("signup");
```

## Vérifiez votre domaine

Dans votre projet **Paramètres analytiques**, sauvegardez le domaine de votre site. Le **Vérification de la propriété du domaine** carte affiche le nom exact de l'enregistrement et la valeur pour votre projet. Ajoutez un enregistrement texte auprès de votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement de texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le jeton affichés dans vos paramètres. Certains fournisseurs ajoutent le domaine automatiquement ; dans ce cas, n'entrez que `_glossia-verify` comme son nom l'indique. Après avoir publié l'enregistrement, cliquez **Vérifier le domaine**. Les modifications peuvent prendre du temps pour être disponibles, réessayez donc si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, développez **Alternative : vérifiez avec une balise méta de la page d'accueil**. Copiez la balise générée dans le `<head>` de votre page d'accueil et publiez-la :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

L'une ou l'autre méthode prouve le contrôle du domaine configuré. Glossia vérifie l'enregistrement de ce domaine ou sa page d'accueil, de sorte que copier le jeton sur un autre site ne vérifie pas la propriété. Le jeton est une preuve publique, et non un mot de passe.

Une fois le domaine vérifié, Glossia enregistre les événements depuis votre fragment de suivi. Ce fragment seul ne vérifie pas la propriété. Changer le domaine configuré nécessite une nouvelle vérification.

## Vérifier qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez un `POST` requête vers `https://glossia.ai/v1/collect` retourne `202 Accepted`.
3. Après collecte et traitement, la vue de la page apparaît sous **Statistiques** dans le tableau de bord de votre projet. Les exécutions de traduction sur la page Aperçu sont distinctes du trafic du site web.

Une `202 Accepted` la réponse confirme que la demande a atteint le collecteur. Les domaines inconnus ou non vérifiés sont acceptés mais ne gravent pas d'événements, donc assurez-vous que le domaine configuré est vérifié dans les paramètres analytiques du projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le référent, `navigator.languages`"," fuseau horaire, et largeur d'écran, plus un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est fingerprinté.