%{
  title: "Installez des analyses web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "guide",
  section: "analytics",
  order: 1
}
---

Ce guide suppose que vous avez un projet Glossia avec son domaine de site configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ou secret à copier.

## Option A : balise script

Ajoutez cet extrait à toutes les pages, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK s'initialise automatiquement, envoie une vue de page au chargement et enregistre les vues de pages suivantes lors de la navigation côté client dans les applications en une seule page. `data-domain` se remplace par défaut par `window.location.hostname` s'il est omis, de sorte que vous pouvez le supprimer sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

Si votre site utilise une politique de sécurité des contenus, autorisez `https://glossia.ai` dans autant `script-src` (ou `script-src-elem` s'il est présent) et `connect-src`. Le script se charge depuis `/assets/glossia-web.js` et envoie des événements à `/v1/collect` d'origine identique.

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

Définissez explicitement le point de bout de collecte lors de l'utilisation du paquet dans votre propre bundle, car il n'y a pas d'adresse de script hôte à partir de laquelle le déduire.

`domain` est déduit de `window.location.hostname` de sorte que le SDK associe ces événements au projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour remplacer, par exemple pour envoyer des événements depuis l'origine de test vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Vérifiez votre domaine

Dans les paramètres d'analyse **Paramètres d'analyse** de votre projet, sauvegardez le domaine de votre site. La carte **Vérifier la propriété du domaine** affiche le nom et la valeur exacte de l'enregistrement pour votre projet. Ajoutez un enregistrement de texte avec votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement de texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le jeton affichés dans vos paramètres. Certains fournisseurs ajoutent le domaine automatiquement ; dans ce cas, entrez uniquement `_glossia-verify` comme nom. Après avoir publié l'enregistrement, cliquez sur **Vérifier le domaine**. Les modifications peuvent prendre du temps pour devenir disponibles, réessayez donc si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, développez **Autre : vérifier avec une balise meta d'accueil**. Copiez la balise générée dans le `<head>` de votre page d'accueil et publiez-la :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Les deux méthodes prouvent le contrôle du domaine configuré. Glossia vérifie l'enregistrement ou la page d'accueil de ce domaine, de sorte que copier le jeton sur un autre site web ne vérifie pas la propriété. Le jeton est une preuve publique, pas un mot de passe.

Une fois que le domaine est vérifié, Glossia enregistre les événements depuis votre extrait de suivi. L'extrait seul ne vérifie pas la propriété. Changer le domaine configuré nécessite une nouvelle vérification.

## Vérifiez que cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet Réseau et confirmez qu'une requête `POST` vers `https://glossia.ai/v1/collect` retourne `202 Accepted`.
3. Après collecte et traitement, la vue de page apparaît sous **Analyses** dans le tableau de bord de votre projet. Les exécutions de traduction sur la page Vue d'ensemble sont distinctes du trafic web.

Une réponse `202 Accepted` confirme que la requête a atteint le collecteur. Les domaines inconnus ou non vérifiés sont également acceptés mais n'enregistrent pas d'événements, de sorte que confirmez que le domaine configuré est vérifié dans les paramètres d'analyse du projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le referrer, `navigator.languages`, le fuseau horaire et la largeur d'écran, ainsi qu'un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet. Aucun cookie n'est défini et rien n'est fingerprinted.
