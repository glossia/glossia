%{
  title: "Installer les analyses Web",
  summary:
    "Ajoutez le SDK web Glossia à votre site en une seule ligne HTML ou via npm, et commencez à collecter des signaux de localisation.",
  category: "Tutoriel",
  section: "analytics",
  order: 1
}
---

Ce guide suppose que vous avez un projet Glossia pour lequel le domaine du site est configuré dans les paramètres d'analyse du projet. La collecte est identifiée par ce domaine, il n'y a donc aucune clé ou secret à copier.

## Option A : balise script

Ajoutez cet extrait à chaque page, idéalement dans le `<head>` :

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

Le SDK s'initialise automatiquement, envoie une consultation de page au chargement et enregistre les consultations de page ultérieures lors de la navigation côté client dans les applications monopages. `data-domain` se définit sur `window.location.hostname` par défaut lorsqu'il est omis, vous pouvez donc le supprimer sur un site à domaine unique. Pour utiliser un point de collecte personnalisé, ajoutez `data-endpoint="https://collect.your-host.com"`.

Si votre site utilise une politique de sécurité du contenu, autorisez `https://glossia.ai` tant dans `script-src` (ou `script-src-elem` s'il est présent) que dans `connect-src`. Le script se charge depuis `/assets/glossia-web.js` et envoie des événements à `/v1/collect` sur la même origine.

## Option B : npm

Installez le package :

```bash
npm install @glossia/web
```

Initialisez-le une fois dans votre point d'entrée d'application :

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Définissez le point de collecte explicitement lorsque vous utilisez le package dans votre propre bundle, car il n'existe pas d'adresse de script hébergée à partir de laquelle le déduire.

`domain` se déduit de `window.location.hostname` afin que le SDK enregistre sur le projet enregistré pour votre site. Passez `{ domain: "example.com" }` pour remplacer, par exemple pour envoyer des événements depuis une origine de test vers le même projet que la production.

Pour enregistrer un événement personnalisé, par exemple une inscription :

```ts
glossia.track("signup");
```

## Enregistrer les choix explicites de langue

Pour distinguer le choix d'un visiteur de la préférence de son navigateur, appelez le SDK dans le gestionnaire d'action utilisateur de votre sélecteur de langue, avant la navigation :

```js
glossia.selectLanguage("zh-Hans");
```

Cette méthode est disponible sur le SDK importé après `glossia.init()`/, et sur l'objet global `glossia` lorsque vous utilisez le script hébergé.

Alternativement, annotez les liens de basculement de langue même origine :

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Utilisez une seule intégration par action, pas les deux. Les liens annotés enregistrent l'activation réelle de l'utilisateur, y compris l'activation au clavier. Ils ignorent les clics scriptés, les téléchargements, les clics modifiés, les destinations cross-origin, et les liens qui ouvrent un autre onglet ou cadre, sans empêcher la navigation.

Le SDK envoie immédiatement un événement `language_selection` et inclut la langue choisie (`cl`) sur les événements ultérieurs. Le choix est stocké dans `sessionStorage` pour l'onglet et l'origine actuels jusqu'à ce qu'un autre choix le remplace. Si le stockage n'est pas disponible, il ne dure que jusqu'au déchargement de la page. Aucun choix n'est déduit des redirections, des URL, ou des modifications de `<html lang>`.

La sélection enregistre l'intention, pas la navigation réussie. La préférence du navigateur, la langue réelle de la page et le choix explicite restent séparés. Le collecteur stocke le choix, le calcul d'écart du tableau de bord basé sur le navigateur actuel est inchangé.

## Vérifiez votre domaine

Dans les **Paramètres d'analyse** de votre projet, enregistrez le domaine de votre site. La carte **Vérifier la propriété du domaine** affiche le nom et la valeur exacts de l'enregistrement pour votre projet. Ajoutez un enregistrement texte avec votre fournisseur de domaine :

| Champ | Valeur |
| --- | --- |
| Type | `TXT` ([enregistrement texte](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Nom | `_glossia-verify.example.com` |
| Valeur | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Utilisez le domaine et le jeton affichés dans vos paramètres. Certains fournisseurs ajoutent le domaine automatiquement ; dans ce cas, entrez seulement `_glossia-verify` comme nom. Après avoir publié l'enregistrement, cliquez sur **Vérifiez le domaine**. Les modifications peuvent mettre du temps à devenir disponibles, tentez donc à nouveau si l'enregistrement n'est pas trouvé immédiatement.

Si vous ne pouvez pas modifier vos enregistrements de domaine, développez **Alternative : vérifier avec une balise méta de page d'accueil**. Copiez la balise générée dans le `<head>` de votre page d'accueil et publiez-la :

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

L'une ou l'autre méthode prouve le contrôle du domaine configuré. Glossia vérifie l'enregistrement ou la page d'accueil de ce domaine, de sorte que la copie du jeton sur un autre site ne vérifie pas la propriété. Le jeton est une preuve publique, pas un mot de passe.

Une fois le domaine vérifié, Glossia enregistre les événements depuis votre extrait de suivi. L'extrait seul ne vérifie pas la propriété. Il faut une nouvelle vérification pour modifier le domaine configuré.

## Vérifiez qu'il fonctionne

1. Ouvrez votre site dans un navigateur.
2. Ouvrez l'onglet réseau et confirmez qu'une demande `POST` vers `https://glossia.ai/v1/collect` retourne `202 Accepted`.
3. Après collecte et traitement, la consultation de page apparaît sous **Analyses** dans le tableau de bord de votre projet. Les exécutions de traduction sur la page Vue d'ensemble sont séparées du trafic web.

Une réponse `202 Accepted` confirme que la demande a atteint le collecteur. Les domaines inconnus ou non vérifiés sont également acceptés mais n'enregistrent pas les événements, vérifiez donc que le domaine configuré est vérifié dans les paramètres d'analyse du projet.

## Ce qui est collecté

Le navigateur envoie l'URL de la page, le referrer, `navigator.languages`, la langue réelle de la page (`<html lang>`), les traductions annoncées (liens `hreflang`), la langue explicitement choisie si observée, le fuseau horaire et la largeur d'écran, plus un identifiant de session par onglet. Le serveur ajoute le pays (via GeoIP) et calcule l'écart de localisation par rapport aux langues cibles de votre projet, aux traductions annoncées et à la langue réelle de la page. L'identifiant de session et le choix explicite utilisent `sessionStorage` ; aucun cookie n'est défini et rien n'est fingerprinté.
