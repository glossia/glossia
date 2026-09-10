%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation et pourquoi la métrique d'écart est importante.",
  category: "explication",
  order: 2
}
---
Choisir la langue suivante à traduire est un pari : cela coûte du temps et de l'argent, et le rendement dépend d'une demande que vous voyez rarement. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de cette collecte d'analyses est précis et intentionnel : répondre à "devrions-nous localiser en langue X ?" Les signaux sont sélectionnés pour alimenter cette question, et non pour constituer une suite analytique généraliste.

Trois entrées pilotent la décision,

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays indiquent où réside l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? Comparer les langues préférées aux langues cibles de votre projet révèle la part de trafic qui se heurte à un obstacle.
3. **Valeur.** La localisation vaut-elle le coup ? L'écart d'engagement par locale, les pages sur lesquelles atterrit le trafic sous-servi, et l'origine de ce trafic indiquent si une nouvelle locale convertit.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous aviez à l'époque, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous gardez une trace honnête de la demande qui restait non satisfaite.

## Pourquoi sans cookie, spécifiquement

L'instinct quand on souhaite des « visiteurs uniques » est de mettre un cookie ou de fingerprinter le navigateur. Les deux créent des identifiants à longue durée de vie, et le fingerprinting est, selon la plupart des régimes de protection de la vie privée, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour une journée ne nécessitent qu'un identifiant stable *""dans la journée"*"". Un hachage de l'IP et de l'User-Agent, roté quotidiennement et limité par projet, fournit des visiteurs uniques quotidiens et hebdomadaires précis tout en rendant impossible le lien d'un visiteur d'un jour à l'autre ou d'un site à l'autre. Vous abandonnez le suivi à long terme des visiteurs qui reviennent, ce qui est exactement la capacité créant l'exposition à la vie privée que vous auriez autrement besoin d'une bannière de consentement pour opérer légalement."

""Le compromis est intentionnel : les analyses de localisation devraient être quelque chose que vous pouvez déployer partout, pour chaque visiteur, sans contrainte juridique."