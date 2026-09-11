%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart compte.",
  category: "Explication",
  order: 2
}
---
Choisir la langue de traduction suivante est un pari : il coûte du temps et de l'argent, et le rendement dépend de la demande que vous ne pouvez généralement pas anticiper. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et délibéré : répondre à la question "devons-nous localiser dans la langue X ?". Les indicateurs sont choisis pour alimenter cette question, et non pour constituer une suite d'analyse généraliste.

Trois facteurs guident la décision :

1. **La demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà couverte ? La comparaison des langues préférées avec les langues cibles de votre projet révèle la part du trafic qui se heurte à une limite.
3. **Valeur.** La localisation vaut-elle le coup ? Les écarts d'engagement par localisation, les pages où atterrit le trafic non desservi, et l'origine de ce trafic indiquent si une nouvelle localisation permet la conversion.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité à laquelle vous avez fait face alors, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui restait non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct pour obtenir des "visiteurs uniques" est de définir un cookie ou d'identifier le navigateur par empreinte. Les deux créent des identifiants à longue durée de vie, et l'identification par empreinte est, sous la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Les deux ne sont pas nécessaires ici.

Les visiteurs uniques d'un jour nécessitent uniquement un identifiant stable *dans la journée*. Un hachage de l'IP et de l'User-Agent, roté quotidiennement et limité par projet, fournit des uniques quotidiens et hebdomadaires précis tout en rendant impossible de lier un visiteur d'un jour à l'autre ou entre sites. Vous renoncez au suivi à long terme des visiteurs récurrents, ce qui est exactement la fonctionnalité qui crée l'exposition à la vie privée pour laquelle vous auriez autrement besoin d'une bannière de consentement pour opérer légalement.

Ce compromis est intentionnel : les analyses de localisation doivent pouvoir être déployées partout, à chaque visiteur, sans friction juridique.