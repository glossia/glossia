%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart est importante.",
  category: "explication",
  order: 2
}
---
Choisir dans quelle langue traduire ensuite est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne voyez généralement pas.

## La décision, pas le tableau de bord

L'objectif de collecter des analyses ici est précis et délibéré : répondre à la question "devrions-nous traduire dans la langue X ?" Les signaux sont choisis pour nourrir cette question, pas pour être une suite analytique à usage général.

Trois éléments pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? La langue du navigateur et le pays vous indiquent où réside l'intérêt.
2. **Le fossé.** Cette demande est-elle déjà satisfaite ? Comparer les langues préférées aux langues cibles de votre projet révèle la part du trafic qui rencontre un mur.
3. **Valeur.** La localisation en vaut-elle la peine ? L'écart d'engagement par localisation, les pages sur lesquelles atterrit le trafic non desservi, et la source de ce trafic indiquent si une nouvelle localisation génère des conversions.

## Pourquoi le calcul de l'écart est effectué au moment de l'ingestion

`served_locale` et `has_locale_gap` et stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité à laquelle vous étiez confronté à l'époque, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne diminue pas rétroactivement ; vous gardez une trace honnête de la part de la demande qui restait insatisfaite.

## Pourquoi, spécifiquement, sans cookie

Le réflexe lorsque vous souhaitez des \\"visiteurs uniques\\" est de définir un cookie ou de prendre l'empreinte du navigateur. Les deux créent des identifiants à longue durée de vie, et l'empreinte est, selon la majorité des régimes de protection des données, plus difficile à effacer qu'un cookie. Ni l'un ni l'autre n'est nécessaire ici.

Les visiteurs uniques pour une journée nécessitent uniquement un identifiant stable *dans la journée*. Un hachage de l'IP et de l'User-Agent, roté quotidiennement et restreint par projet, offre des uniques quotidiens et hebdomadaires précis tout en rendant impossible le lien d'un visiteur entre les jours ou entre les sites. Vous renoncez au suivi à long terme des visiteurs récurrents, ce qui est exactement la fonctionnalité qui crée l'exposition aux risques de confidentialité pour laquelle vous auriez autrement besoin d'un bandeau de consentement pour opérer légalement.

Ce compromis est intentionnel : les analyses de localisation devraient être quelque chose que vous puissiez déployer partout, à chaque visiteur, sans friction juridique.