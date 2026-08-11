%{
  title: "Analyses de localisation",
  summary: "Identifiez les langues et les pays réellement demandés par vos visiteurs, ainsi que vos lacunes de localisation, avant d’investir dans une nouvelle langue.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Des opportunités, pas des indicateurs flatteurs", description: "Les tableaux de bord s’articulent autour des lacunes de localisation : la part du trafic qui souhaite une langue que vous ne proposez pas encore.", icon: "globe"},
    %{title: "Conçu sans cookies", description: "Aucun cookie, aucune empreinte numérique, aucune bannière de consentement. Les visiteurs uniques sont déterminés au moyen d’un hachage renouvelé chaque jour, qui ne permet pas de les relier d’un jour à l’autre.", icon: "zap"},
    %{title: "Une seule ligne à installer", description: "Ajoutez une seule balise de script à votre site et Glossia effectue les mesures automatiquement. Déployez-la via npm ou CDN.", icon: "code"}
  ]
}
---
## Choisissez votre prochaine langue à partir des données

La plupart des équipes choisissent les langues cibles selon leur intuition. Les analyses de localisation la remplacent par des données concrètes. Ajoutez le kit de développement web et Glossia vous indique les langues demandées par les navigateurs de vos visiteurs, les pays dont ils proviennent et, surtout, leur correspondance avec les langues que vous prenez déjà en charge.

L’indicateur principal est l’**écart de localisation** : le pourcentage de visiteurs dont la langue préférée ne dispose d’aucune traduction prise en charge. Analysez-le par pays, par site référent et par page pour déterminer précisément où se concentre la demande non satisfaite et quelle nouvelle langue aurait le plus d’impact.

## La confidentialité sans compromis

Les analyses de Glossia ne collectent que les données nécessaires et ne stockent aucune information permettant une identification. Le navigateur envoie l’adresse de la page, le site référent, les langues préférées, le fuseau horaire et la taille de l’écran. Le serveur détermine le visiteur unique à partir d’un hachage de l’adresse IP et du User-Agent, renouvelé quotidiennement, puis supprime ces données. Aucun cookie n’est créé, aucune empreinte numérique n’est générée et aucun visiteur ne peut être suivi d’un jour à l’autre ou d’un site à l’autre.

Vous obtenez ainsi des analyses que vous pouvez déployer sans bandeau de consentement, conformément aux attentes de vos visiteurs internationaux en matière de confidentialité.

## Installation en quelques secondes

Ajoutez une ligne à votre site et Glossia commence à effectuer les mesures :

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Vous préférez npm ? Installez `@glossia/web` et appelez `init({ domain })`. Dans les deux cas, les pages vues, la navigation côté client et les événements personnalisés alimentent le même tableau de bord, qui classe vos possibilités de localisation.