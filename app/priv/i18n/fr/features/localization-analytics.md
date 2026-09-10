%{
  title: "Analytique de localisation",
  summary:
    "Voyez quelles langues et pays vos visiteurs souhaitent réellement, et où vous avez un fossé de localisation, avant d'investir dans une nouvelle langue.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas vanité",
      description:
        "Les tableaux de bord sont construits autour du fossé de localisation : la part du trafic qui souhaite une langue que vous ne servez pas encore.",
      icon: "globe"
    },
    %{
      title: "Sans cookie par conception",
      description:
        "Aucun cookie, pas de fingerprinting, pas de bannières de consentement. Les visiteurs uniques proviennent d'un hachage quotidien qui ne peut pas être lié entre les jours.",
      icon: "zap"
    },
    %{
      title: "Une ligne pour installer",
      description:
        "Insérez une balise script sur votre site et Glossia mesure elle-même. Déployez via npm ou CDN.",
      icon: "code"
    }
  ]
}
---
## Décidez de votre prochaine localisation avec des données

La plupart des équipes choisissent les langues cibles sur l'intuition. L'analyse de localisation remplace cela par du signal. Ajoutez le SDK Web et Glossia vous indique les langues que les navigateurs de vos visiteurs demandent, les pays dont ils proviennent et, essentiellement, le chevauchement avec les langues que vous soutenez déjà.

L'indicateur principal est le **écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction supportée. Analysez-le par pays, par référent et par page pour voir exactement où la demande sous-couverte se concentre et quelle nouvelle localisation déplacerait l'aiguille.

## Confidentialité sans compromis

L'analyse de Glossia ne collecte rien dont elle n'a pas besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, le référent, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hash rotatif quotidien de l'IP et de l'User-Agent, puis les supprime. Aucun cookie n'est défini, rien n'est fingerprinté, et aucun visiteur ne peut être suivi d'un jour à l'autre ou d'un site à l'autre.

Le résultat est une analyse que vous pouvez déployer sans bannière de consentement, alignée sur les attentes de confidentialité que vos visiteurs internationaux ont déjà.

## Installez en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Quoi que vous choisissiez, les vues de page, la navigation côté client et les événements personnalisés aboutissent dans le même tableau de bord qui classe vos opportunités de localisation.