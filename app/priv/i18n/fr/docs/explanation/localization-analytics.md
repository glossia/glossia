%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation et pourquoi le métrique d'écart compte.",
  category: "Explication",
  order: 2
}
---
Choisir la prochaine langue à traduire est un pari : cela coûte du temps et de l'argent, et le rendement dépend d'une demande que vous ne pouvez généralement pas voir. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de collecter des analyses ici est précis et délibéré : répondre à « devrions-nous traduire vers la langue X ? ». Les signaux sont choisis pour répondre à cette question, pas pour constituer une suite d'analyses à vocation générale.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langages du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà couverte ? Comparer les langues préférées aux langues cibles de votre projet révèle la part de trafic se heurtant à une barrière.
3. **Valeur.** La localisation en vaut-elle le coup ? L'écart d'engagement par locale, les pages sur lesquelles atterrit le trafic non desservi, et l'origine de ce trafic indiquent si une nouvelle locale convertit.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous affrontiez alors, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui restait non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct lorsque vous souhaitez des « visiteurs uniques » est de définir un cookie ou de créer une empreinte du navigateur. Les deux créent des identifiants persistants, et l'empreinte, dans la plupart des régimes de confidentialité, est plus difficile à effacer qu'un cookie. L'un ni l'autre ne sont pas nécessaires ici.

Les visiteurs uniques d'un jour nécessitent seulement un identifiant stable *dans la journée*. Un hachage de l'IP et du User-Agent, roté quotidiennement et limité par projet, offre des uniques journaliers et hebdomadaires précis tout en rendant impossible de relier un visiteur d'un jour à l'autre ou d'un site à l'autre. Vous renoncez au suivi à long terme des visiteurs récurrents, ce qui est précisément la capacité qui crée l'exposition aux risques de confidentialité pour laquelle vous auriez autrement besoin d'un bandeau de consentement pour opérer légalement.

Le compromis est intentionnel : l'analytique de localisation doit être quelque chose que vous pouvez déployer partout, à chaque visiteur, sans friction juridique.