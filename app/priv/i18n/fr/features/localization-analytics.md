%{
  title: "Analytiques de localisation",
  summary:
    "Découvrez quelles langues et pays vos visiteurs souhaitent réellement, et où vous présentez un écart de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas de vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic souhaitant une langue que vous ne proposez pas encore.",
      icon: "Globe"
    },
    %{
      title: "Sans cookie par conception",
      description:
        "Pas de cookies, pas de traçage, pas de bannières de consentement. Les visiteurs uniques proviennent d'un hachage rotatif quotidien impossible à lier entre les jours.",
      icon: "Éclair"
    },
    %{
      title: "Une ligne pour installer",
      description:
        "Intégrez une seule balise de script à votre site et Glossia se mesure. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---
## Précisez votre prochaine langue locale grâce aux données

La plupart des équipes choisissent les langues cibles par intuition. L'analyse de localisation remplace cela par des signaux. Ajoutez le Web SDK et Glossia vous montre les langues que les navigateurs de vos visiteurs demandent, les pays d'où ils viennent, et, crucialement, le recouvrement avec les langues que vous supportez déjà.

L'indicateur principal est **l'écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction supportée. Explorez-le par pays, par référenant et par page pour voir où la demande sous-représentée se concentre et quelle nouvelle langue locale ferait bouger l'aiguille.

## Confidentialité sans compromis

L'analyse Glossia ne collecte rien dont elle n'a pas besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL, le référent, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hachage quotidiennement renouvelé de l'IP et de l'User-Agent, puis les élimine. Aucun cookie n'est défini, rien n'est fingerprinté et aucun visiteur ne peut être suivi d'un jour à l'autre ou d'un site à l'autre.

Le résultat est une analyse que vous pouvez déployer sans bandeau de consentement, alignée avec les attentes en matière de confidentialité que vos visiteurs internationaux ont déjà.

## Installez en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez npm ? Installez `@glossia/web` et appelez `init({ domain })`. Quoi qu'il en soit, les vues de pages, la navigation côté client et les événements personnalisés rejoignent le même tableau de bord qui classe vos opportunités de localisation.