%{
  title: "Analytiques de localisation",
  summary:
    "Voyez quelles langues et quels pays vos visiteurs souhaitent réellement, et là où vous avez un écart de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Monde",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic qui souhaite une langue que vous ne servez pas encore.",
      icon: "Monde"
    },
    %{
      title: "Conçu sans cookies",
      description:
        "Pas de cookies, pas de fingerprinting, pas de bannières de consentement. Les visiteurs uniques proviennent d'un hachage rotatif quotidien qui ne peut pas être lié d'un jour à l'autre.",
      icon: "Éclair"
    },
    %{
      title: "Installation en une ligne",
      description:
        "Ajoutez une seule balise script à votre site et Glossia se mesure lui-même. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---
## Choisissez votre prochaine localisation avec les données

La plupart des équipes choisissent les langues cibles par intuition. L'analyse de localisation remplace cela par des signaux. Ajoutez le SDK Web et Glossia vous montre les langues que les navigateurs de vos visiteurs demandent, les pays d'origine, et, cruciallement, le recoupement avec les langues que vous supportez déjà.

L'indicateur principal est l'**écart de localisation** : le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction supportée. Parmi par pays, par source de provenance et par page pour voir où la demande sous-représentée se concentre et quel nouveau marché ferait bouger l'aiguille.

## Confidentialité sans compromis

L'analyse de Glossia ne collecte que le nécessaire et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, la source de provenance, les langues préférées, la zone horaire et la taille d'écran. Le serveur tire le visiteur unique à partir d'un hachage de l'IP et de l'User-Agent qui tourne quotidiennement, puis les supprime. Aucun cookie n'est défini, rien n'est fingerprinté et aucun visiteur ne peut être suivi entre les jours ou entre les sites.

Le résultat est une analyse que vous pouvez déployer sans bannière de consentement, alignée avec les attentes de vie privée que vos visiteurs internationaux possèdent déjà.

## Installation en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. De toute volonté, les vues de page, la navigation côté client, et les événements personnalisés convergent vers le même tableau de bord qui classe vos opportunités de localisation.