%{
  title: "Analytique de localisation",
  summary:
    "Voyez quelles langues et pays vos visiteurs souhaitent réellement, et où se situent vos lacunes de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, pas de vanité",
      description:
        "Les tableaux de bord reposent sur la lacune de localisation : la part de trafic qui souhaite une langue que vous ne servez pas encore.",
      icon: "Globe"
    },
    %{
      title: "Sans cookies par conception",
      description:
        "Aucun cookie, aucune empreinte numérique, aucune bannière de consentement. Les visiteurs uniques proviennent d'un hachage quotidien qui ne peut être lié entre les jours.",
      icon: "Éclair"
    },
    %{
      title: "Une ligne pour installer",
      description:
        "Ajoutez une unique balise script dans votre site et Glossia se mesure lui-même. Publiez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---
## Décidez la langue cible suivante avec des données

La plupart des équipes choisissent les langues cibles à l'instinct. L'analyse de localisation remplace cela par du signal. Ajoutez l'SDK web et Glossia vous montre les langues que les navigateurs de vos visiteurs demandent, les pays d'où ils proviennent, et, crucialement, le chevauchement avec les langues que vous supportez déjà.

L'indicateur principal est le **écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a pas de traduction supportée. Approfondissez l'analyse par pays, par référent et par page pour voir exactement où se concentre la demande non desservie et quelle nouvelle langue bougerait l'aiguille.

## Vie privée sans compromis

L'analyse de Glossia ne collecte rien de ce dont elle n'a pas besoin et ne stocke rien d'identifiable. Le navigateur transmet l'URL de la page, le référent, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur déduit le visiteur unique à partir d'un hachage renouvelé quotidiennement de l'IP et du User-Agent, puis les efface. Aucun cookie n'est défini, aucune empreinte n'est créée, et aucun visiteur ne peut être suivi d'un jour à l'autre ou d'un site à l'autre.

Le résultat est une analyse que vous pouvez déployer sans bannière de consentement, alignée avec les attentes de vie privée déjà présentes chez vos visiteurs internationaux.

## Installation en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Dans tous les cas, les vues de page, la navigation côté client et les événements personnalisés s'intègrent dans le même tableau de bord qui classe vos opportunités de localisation.