%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation et pourquoi la métrique d'écart est importante.",
  category: "explication",
  section: "analyses",
  order: 2
}
---
Choisir la prochaine langue de traduction est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne voyez généralement pas. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de collecter des données analytiques ici est précis et délibéré : pour répondre à « devons-nous localiser en langue X ? ». Les signaux sont choisis pour alimenter cette question, et non pour servir de suite analytique générale.

Trois entrées déterminent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les préférences linguistiques du navigateur et le pays indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà couverte ? La comparaison des langues préférées avec les langues cibles de votre projet révèle la part du trafic qui se heurte à une limitation.
3. **Valeur.** La localisation vaut-elle le coup ? L'écart d'engagement par locale, les pages où atterrit le trafic sous-servi et l'origine de ce trafic indiquent si une nouvelle localisation convertit.

## Pourquoi l'écart est calculé en temps d'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité à laquelle vous avez fait face à l'époque, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois suivant, l'écart du mois précédent ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui restait insatisfaite.

## Pourquoi sans cookie, spécifiquement

L'instinct, quand vous souhaitez des "visiteurs uniques", est de définir un cookie ou de générer une empreinte du navigateur. Les deux créent des identifiants à durée de vie longue, et l'empreintage est, dans la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun des deux n'est nécessaire ici.

Les visiteurs uniques d'une journée ne nécessitent qu'un identifiant stable *dans la journée*. Un hachage de l'IP et de l'User-Agent, actualisé quotidiennement et restreint par projet, fournit une comptabilité précise des visiteurs uniques quotidiens et hebdomadaires tout en rendant impossible de lier un visiteur entre des journées ou entre des sites. Vous renoncez au suivi à long terme des visiteurs de retour, ce qui correspond précisément à la fonctionnalité qui engendre l'exposition aux risques de confidentialité que vous auriez autrement besoin d'une bannière de consentement pour opérer légalement.

Le compromis est intentionnel : les analyses de localisation devraient être quelque chose que vous pouvez livrer partout, à chaque visiteur, sans contrainte juridique.