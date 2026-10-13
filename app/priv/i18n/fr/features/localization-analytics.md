%{
  title: "Analytiques de localisation",
  summary:
    "Voyez quelles langues et quels pays vos visiteurs veulent réellement, et où vous avez un écart de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic qui souhaite une langue que vous ne servez encore pas.",
      icon: "Globe"
    },
    %{
      title: "Sans cookie par conception",
      description:
        "Aucun cookie, aucun pistage, aucune bannière de consentement. Les visiteurs uniques proviennent d'un hachage quotidiennement rotatif qui ne peut pas être lié d'un jour à l'autre.",
      icon: "Éclair"
    },
    %{
      title: "Une ligne pour installer",
      description:
        "Ajoutez une simple balise script à votre site et Glossia se mesure elle-même. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---

## Décidez votre prochaine localisation avec des données

La plupart des équipes choisissent les langues cibles de façon intuitive. L'analyse de localisation remplace cela par du signal. Ajoutez le SDK web et Glossia vous montre les langues que les navigateurs de vos visiteurs sollicitent, les pays d'origine, et, nottement, le recoupement avec les langues que vous supportez déjà.

Le principal indicateur est le **écart de localisation** : le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction supportée. Approfondissez-le par pays, par source et par page pour voir exactement où la demande non couverte se concentre et quelle nouvelle localisation ferait la différence.

## Intimité sans compromis

L'analyse Glossia ne collecte rien dont elle n'a pas besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, le referrer, les langues préférées, l'heure et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hash quotidiennement pivoté de l'IP et de l'User-Agent, puis les supprime. Aucun cookie n'est défini, rien n'est fingerprinté et aucun visiteur ne peut être suivi d'un jour sur l'autre ou entre sites.

Le résultat est une analyse que vous pouvez déployer sans bandeau de consentement, alignée sur les attentes en matière d'intimité que vos visiteurs internationaux ont déjà.

## Installation en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. De toute façon, les vues de page, la navigation côté client et les événements personnalisés s'écoulent dans le même tableau de bord qui classe vos opportunités de localisation.
