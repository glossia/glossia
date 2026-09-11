%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se transforment en décisions de localisation, et pourquoi la métrique d'écart compte.",
  category: "explication",
  order: 2
}
---
Choisir la prochaine langue à localiser est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne voyez généralement pas. L'analytique de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et intentionnel : répondre à « Devrions-nous localiser dans la langue X ? ». Les signaux sont choisis pour servir cette question, pas pour constituer une suite d'analyses à usage général.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langages de navigateur et le pays indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? La comparaison des langues préférées avec les langues cibles de votre projet révèle la part du trafic qui frappe un mur.
3. **Valeur.** La localisation serait-elle rentable ? L'écart d'engagement par localisation, les pages où atterrit le trafic non desservi, et la provenance de ce trafic indiquent si une nouvelle localisation convertit.

## Pourquoi l'écart est-il calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés contre vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous affrontiez alors, pas un recalcul contre les cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous gardez un enregistrement honnête de la demande qui restait non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct qu'on veut des "visiteurs uniques" est de configurer un cookie ou d'empreinter le navigateur. Les deux créent des identifiants à durée de vie longue, et l'empreinte est, dans la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques d'un jour nécessitent uniquement un identifiant stable *dans la journée*. Un hachage de l'IP et de l'User-Agent, renouvelé quotidiennement et limité par projet, fournit des comptes exacts de visiteurs uniques quotidiens et hebdomadaires tout en rendant impossible de relier un visiteur entre plusieurs jours ou entre plusieurs sites. Vous renoncez au suivi des visiteurs récurrents à long terme, ce qui est exactement la fonctionnalité qui crée l'exposition aux risques de confidentialité pour laquelle vous auriez autrement besoin d'une bannière de consentement pour opérer.

Le compromis est intentionnel : l'analyse de localisation doit être quelque chose que vous pouvez déployer partout, pour chaque visiteur, sans friction juridique.