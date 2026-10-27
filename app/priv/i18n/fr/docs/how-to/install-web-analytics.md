%{
  title: "Installer des analyses web",
  summary:
    "Ajoutez le SDK web Glossia à votre site avec une seule ligne de HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Tutoriel",
  section: "analytics",
  order: 1
}
---

Cet guide suppose que vous avez un projet Glossia dont le domaine du site est configuré dans les paramètres analytiques du projet. La collecte est identifiée par ce domaine, il n'y a donc pas de clé ni de secret à copier.

## Option A : balise script

Ajoutez ce fragment à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK initialise automatiquement, envoie une vue de page au chargement et enregistre les vues de page ultérieures lors de la navigation côté client dans les applications one-page. `data-domain` est donc par défaut à `window.location.hostname` lorsqu'il est omis, vous pouvez donc l'ôter sur un site à domaine unique. Pour utiliser un endpoint de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

Si votre site utilise une politique de sécurité du contenu, autorisez `https://glossia.ai` dans `script-src` (ou `script-src-elem` lorsqu'il est présent) et `connect-src`. Le script charge depuis `/assets/glossia-web.js` et envoie les événements à `/v1/collect` de la même origine.

## Option B : npm

Installez le paquet :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans l'entrée de votre application :

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Définissez l'endpoint de collecte explicitement lorsque vous utilisez le paquet dans votre propre bundle, car il n'y a pas d'adresse de script hébergé à partir de laquelle le déduire.

Le `domain` est inféré à partir de `window.location.hostname` si le SDK enregistre contre le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour surcharger, par exemple pour envoyer des événements depuis une origine de staging vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Enregistrez les choix de langue explicites

Pour distinguer le choix d'un visiteur de sa préférence de navigateur, appelez le SDK dans le gestionnaire d'action utilisateur de votre sélecteur de langue, avant de naviguer :

```js
glossia.selectLanguage("zh-Hans");
```

Cette méthode est disponible sur le SDK importé après `glossia.init()`, et sur le global `glossia` lors de l'utilisation du script hébergé.

Alternativement, notez les liens de changement de langue d'origine du même :

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Utilisez une intégration par action, pas les deux. Les liens annotés enregistrent la véritable activation de l'utilisateur, y compris l'activation au clavier. Ils ignorent les clics scriptés, les téléchargements, les clics modifiés, les destinations cross-origin et les liens qui ouvrent un autre onglet ou frame, sans empêcher la navigation.

Le SDK envoie immédiatement un `language_selection` événement et inclut la langue choisie (`cl`) sur les événements ultérieurs. Le choix est stocké dans `sessionStorage` pour l'onglet et l'origine actuels jusqu'à ce qu'un autre choix le remplace. Si le stockage n'est pas disponible, il ne dure que jusqu'à ce que la page se décharge. Aucun choix n'est inféré des redirections, URLs ou modifications à `<html lang>`.

Le sélecteur enregistre l'intention, pas la navigation réussie. Préférence navigateur, langue réelle de la page et choix explicite restent séparés. Le collecteur vérifie un choix valide au lieu des préférences de navigateur lors du calcul du fossé de localisation. Un choix ne vide le fossé que s'il correspond à une cible projet, à une traduction annoncée ou à la langue réelle de la page ; une langue choisie non disponible a encore un fossé. Les choix manquants ou invalides utilisent les préférences du navigateur comme auparavant. Les totaux et les badges du tableau de bord utilisent la décision stockée de chaque événement ; les flags historiques ne changent pas.

## Vérifiez votre domaine

Dans les **Paramètres analytiques** de votre projet, sauvegardez le domaine de votre site. La carte **Vérifier la propriété du domaine** montre le nom exact de l'enregistrement et la valeur pour votre projet. Ajoutez un enregistrement de texte avec votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement de texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le token affichés dans vos paramètres. Certains fournisseurs ajoutent le domaine automatiquement ; dans ce cas, entrez uniquement `_glossia-verify` comme nom. Après avoir publié l'enregistrement, cliquez sur **Vérifiez le domaine**. Les changements peuvent prendre du temps pour être disponibles, essayez à nouveau si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, déployez **Alternative : vérifier avec une meta tag de page d'accueil**. Copiez le tag généré dans le `<head>` de votre page d'accueil et publiez-le :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

L'une ou l'autre méthode prouve le contrôle du domaine configuré. Glossia vérifie l'enregistrement ou la page d'accueil de ce domaine, alors copier le token sur un autre site web ne vérifie pas la propriété. Le token est une preuve publique, pas un mot de passe.

Une fois le domaine vérifié, Glossia enregistre des événements à partir de votre extrait de traçabilité. L'extrait seul ne vérifie pas la propriété. Changer le domaine configuré nécessite une nouvelle vérification.

## Vérifiez que cela fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez qu'une demande `POST` vers `https://glossia.ai/v1/collect` renvoie `202 Accepted`.
3. Après collecte et traitement, la vue de page apparaît sous **Analytiques** de votre tableau de bord de projet. Les exécutions de traduction sur la page Vue d'ensemble sont séparées du trafic web.

Une réponse `202 Accepted` confirme que la demande a atteint le collecteur. Les domaines inconnus ou non vérifiés sont également acceptés mais n'enregistrent pas d'événements, donc confirmez que le domaine configuré est vérifié dans les paramètres analytiques du projet.

## Qu'est-ce qui est collecté

Le navigateur envoie l'URL de la page, le référant, `navigator.languages`(), langue réelle de la page (`<html lang>`), traductions annoncées (`hreflang` liens), langue choisie explicitement observée, fuseau horaire et largeur d'écran, plus un id de session par onglet. Le serveur ajoute le pays (depuis GeoIP) et calcule le fossé de localisation par rapport aux langues cibles de votre projet, aux traductions annoncées et à la langue réelle de la page. L'id de session et le choix explicite utilisent `sessionStorage` ; aucun cookie n'est défini et rien n'est fingerprinté.
