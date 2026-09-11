%{
  title: "Analytique de localisation",
  summary:
    "Découvrez quelles langues et pays vos visiteurs souhaitent réellement, et où se situe votre écart de localisation, avant d'investir dans une nouvelle localisation.",
  order: 6,
  icon: "Globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Opportunité, non vanité",
      description:
        "Les tableaux de bord sont construits autour de l'écart de localisation : la part du trafic qui souhaite des langues que vous ne servez pas encore.",
      icon: "Globe"
    },
    %{
      title: "Sans cookies par conception",
      description:
        "Aucun cookie, aucun fingerprinting, aucune bannière de consentement. Les visiteurs uniques proviennent d'un hachage rotatif journalier qui ne peut être lié d'un jour à l'autre.",
      icon: "Zap"
    },
    %{
      title: "Une seule ligne à installer",
      description:
        "Intégrez une balise script dans votre site et Glossia se mesure. Déployez via npm ou CDN.",
      icon: "Code"
    }
  ]
}
---
## Choisissez votre prochaine locale avec les données

La plupart des équipes choisissent les langues cible au jugé. L'analyse de localisation remplace cela par des signaux. Ajoutez le web SDK et Glossia vous indique les langues que les navigateurs de vos visiteurs demandent, les pays d'origine, et, surtout, le recouvrement avec les langues que vous supportez déjà.

L'indicateur principal est le **écart de localisation**: le pourcentage de vos visiteurs dont la langue préférée n'a aucune traduction supportée. Analysez-la par pays, par référent et par page pour voir exactement où se concentre la demande moins bien desservie et quelle nouvelle locale bougerait l'aiguille.

## Confidentialité sans compromis

Glossia Analytics ne collecte rien dont il n'a pas besoin et ne stocke rien d'identifiable. Le navigateur envoie l'URL de la page, le référent, les langues préférées, le fuseau horaire et la taille de l'écran. Le serveur dérive le visiteur unique à partir d'un hachage quotidiennement roté de l'IP et du User-Agent, puis les supprime. Aucun cookie n'est défini, rien n'est identifié par empreinte, et aucun visiteur ne peut être suivi jour après jour ou site après site.

Le résultat est une analyse que vous pouvez déployer sans bannière de consentement, alignée sur les attentes de confidentialité de vos visiteurs internationaux.

## Installez en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à mesurer :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Préférez-vous npm ? Installez `@glossia/web` et appelez `init({ domain })`. Peu importe, les vues de page, la navigation côté client et les événements personnalisés aboutissent dans le même tableau de bord qui hiérarchise vos opportunités de localisation.