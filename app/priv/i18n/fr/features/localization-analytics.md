%{
  title: "Analyse de localisation",
  summary:
    "Voyez quelles langues et pays vos visiteurs souhaitent réellement, et où vous présentez un écart de localisation, avant d'investir dans une nouvelle langue.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Une opportunité, pas de vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic qui souhaite une langue que vous n'offrez pas encore.",
      icon: "globe"
    },
    %{
      title: "Sans cookie par conception",
      description:
        "Aucun cookie, aucun fingerprinting, aucune bannière de consentement. Les visiteurs uniques proviennent d'un hachage quotidiennement renouvelé qui ne peut être lié entre les jours.",
      icon: "zap"
    },
    %{
      title: "Une seule ligne à installer",
      description:
        "Ajoutez une seule balise script sur votre site et Glossia se mesure de lui-même. Distribuez via npm ou CDN.",
      icon: "code"
    }
  ]
}
---
## Décidez votre prochaine localisation avec des données

La plupart des équipes choisissent les langues cibles à l'intuition. L'analyse de localisation remplace cela par du signal. Ajoutez le SDK web et Glossia vous montre les langues que les navigateurs de vos visiteurs utilisent, les pays d'où ils viennent et, cruciallement, le recouvrement avec les langues que vous supportez déjà.

La métrique phare est l' **écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction disponible. Perforez-la par pays, par site de référence et par page pour voir exactement où se concentre la demande peu desservie et quelle nouvelle locale aurait un impact significatif.

## La confidentialité sans compromis

Glossia Analytics ne collecte rien qui ne soit nécessaire et ne stocke rien d'identifiant. Le navigateur envoie l'URL de la page, le site de référence, les langues préférées, les fuseaux horaires et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hachage quotidiennement tourné de l'IP et User-Agent, puis les élimine. Aucun cookie n'est défini, rien n'est fingerprinté, et aucun visiteur ne peut être suivi d'un jour à l'autre ou d'un site à l'autre.

Le résultat est une analyse que vous pouvez déployer sans une bannière de consentement, alignée avec les attentes en matière de confidentialité que vos visiteurs internationaux ont déjà.

## Installez en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Quoi qu'il en soit, les vues de page, la navigation côté client et les événements personnalisés affluent vers le même tableau de bord qui classe vos opportunités de localisation.