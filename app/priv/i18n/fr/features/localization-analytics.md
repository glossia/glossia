%{
  title: "Analyses de localisation",
  summary:
    "Voyez quelles langues et pays vos visiteurs souhaitent réellement, et où vous avez une lacune de traduction, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Mondial",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas vanité",
      description:
        "Les tableaux de bord sont construits autour du fossé de localisation : la part de trafic qui souhaite une langue que vous ne servez pas encore.",
      icon: "Mondial"
    },
    %{
      title: "Conçu sans cookies",
      description:
        "Pas de cookies, pas d'empreinte numérique, pas de bannières de consentement. Les visiteurs uniques proviennent d'un hachage quotidien qui ne peut être lié entre les jours.",
      icon: "Éclair"
    },
    %{
      title: "Une seule ligne pour installer",
      description:
        "Ajoutez une balise script à votre site et Glossia s'analyse. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---
## Décidez de votre prochaine localisation grâce aux données

La plupart des équipes choisissent les langues cibles selon l'intuition. L'analyse de localisation remplace cela par des indicateurs. Ajoutez le SDK Web et Glossia vous montre les langues demandées par les navigateurs de vos visiteurs, les pays d'où ils proviennent, et, surtout, le recoupement avec les langues que vous supportez déjà.

L'indicateur clé est le **écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a aucune traduction supportée. Explorez-le par pays, par source de provenance et par page pour voir exactement où s'accumule la demande sous-servie et quel nouveau marché fera bouger l'aiguille.

## Confidentialité sans compromis

L'analyse Glossia ne collecte rien de ce dont elle n'a pas besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, la source de provenance, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hachage quotidien de l'IP et du User-Agent, puis l'élimine. Aucun cookie n'est défini, rien n'est fingerprinté, et aucun visiteur ne peut être suivi sur plusieurs jours ou sur plusieurs sites.

Le résultat est une analyse que vous pouvez livrer sans bannière de consentement, alignée avec les attentes en matière de confidentialité que vos visiteurs internationaux ont déjà.

## Installez en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Dans tous les cas, les vues de page, la navigation côté client et les événements personnalisés s'intègrent dans le même tableau de bord qui classe vos opportunités de localisation.