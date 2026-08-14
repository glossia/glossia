%{
  title: "Pourquoi utiliser l’analyse de la localisation",
  summary: "Comment les signaux collectés orientent les décisions de localisation et pourquoi la mesure des écarts est importante.",
  category: "explanation",
  order: 2
}
---
Choisir la prochaine langue cible est un pari : cela coûte du temps et de l’argent, et les bénéfices dépendent d’une demande que vous ne pouvez généralement pas observer. Les analyses de localisation rendent cette demande visible.

## La décision, pas le tableau de bord

L’objectif de la collecte de données analytiques est ici précis et délibéré : répondre à la question « devons-nous localiser dans la langue X ? ». Les indicateurs sont choisis pour éclairer cette décision, et non pour constituer une suite d’analyse généraliste.

Trois facteurs orientent la décision :

1. **La demande.** Combien de visiteurs souhaitent utiliser cette langue ? Les langues du navigateur et le pays indiquent d’où vient l’intérêt.
2. **L’écart.** Cette demande est-elle déjà satisfaite ? Comparer les langues préférées aux langues cibles de votre projet révèle la part du trafic qui ne trouve pas de contenu adapté.
3. **La valeur.** La localisation serait-elle rentable ? L’engagement selon l’écart de langue, les pages consultées par le trafic mal desservi et l’origine de ce trafic indiquent si une nouvelle locale favorise la conversion.

## Pourquoi l’écart est calculé au moment de l’ingestion

`served_locale` et `has_locale_gap` sont enregistrés pour chaque événement et calculés par rapport à vos langues cibles telles qu’elles étaient au moment de la visite. Ainsi, les données historiques reflètent l’opportunité qui se présentait alors, et non un nouveau calcul effectué à partir des langues cibles actuelles. Si vous ajoutez le portugais le mois prochain, l’écart du mois dernier ne diminuera pas rétroactivement. Vous conservez une représentation fidèle de la demande qui n’était pas satisfaite.

## Pourquoi précisément sans cookies

Pour mesurer les « visiteurs uniques », le réflexe consiste à définir un cookie ou à générer une empreinte du navigateur. Ces deux méthodes créent des identifiants persistants et, dans la plupart des cadres de protection de la vie privée, une empreinte est plus difficile à supprimer qu’un cookie. Aucune n’est nécessaire ici.

Le calcul du nombre de visiteurs uniques sur une journée exige uniquement un identifiant stable *au cours de cette journée*. Un hachage de l’adresse IP et du User-Agent, renouvelé quotidiennement et limité à chaque projet, permet d’obtenir un décompte précis des visiteurs uniques quotidiens et hebdomadaires, tout en empêchant d’associer un visiteur à plusieurs jours ou à plusieurs sites. Vous renoncez au suivi à long terme des visiteurs récurrents, qui est précisément la fonctionnalité créant le risque pour la vie privée qui vous obligerait autrement à afficher une bannière de consentement pour exercer cette activité légalement.

Ce compromis est délibéré : les analyses de localisation doivent pouvoir être déployées partout, auprès de chaque visiteur, sans contrainte juridique.