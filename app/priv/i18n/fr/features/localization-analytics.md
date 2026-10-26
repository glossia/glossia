%{
  title: "Analytique de localisation",
  summary:
    "Découvrez les langues et pays que vos visiteurs souhaitent réellement, et où se situent vos écarts de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Terre",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic qui souhaite une langue que vous ne proposez pas encore.",
      icon: "Terre"
    },
    %{
      title: "Sans cookie par conception",
      description: "Aucun cookie, aucune empreinte numérique, aucune bannière de consentement.",
      icon: "Éclair"
    },
    %{
      title: "Une seule ligne à installer",
      description:
        "Ajoutez une simple balise script à votre site et Glossia se mesure. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---

## Décidez de votre prochaine locale avec des données

La plupart des équipes choisissent les langues cibles sur l'intuition. L'analyse de localisation remplace cela par du signal. Ajoutez le SDK Web et Glossia vous montre les langues demandées par les navigateurs de vos visiteurs, les pays qu'ils proviennent de, et, crucialement, le chevauchement avec les langues que vous supportez déjà.

L'indicateur principal est l'**écart de localisation** : le pourcentage de vos visiteurs dont la langue préférée n'a aucune traduction prise en charge. Analysez-le par pays, par referrer et par page pour voir exactement où la demande insatisfaite se concentre et quelle nouvelle locale bougera l'aiguille.

## Confidentialité sans compromis

L'analyse Glossia ne recueille que ce dont elle a besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, le referrer, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur dérive le visiteur unique à partir d'un hachage de l'IP et du User-Agent rotatif quotidien, puis les élimine. Aucun cookie n'est défini, rien n'est fingerprinted, et aucun visiteur ne peut être suivi d'un jour sur l'autre ou d'un site à l'autre.

Le résultat est une analyse que vous pouvez lancer sans bannière de consentement, alignée sur les attentes de confidentialité que vos visiteurs internationaux ont déjà.

## Installation en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Dans les deux cas, les pageviews, la navigation côté client et les événements personnalisés transitent dans le même tableau de bord qui classe vos opportunités de localisation.
