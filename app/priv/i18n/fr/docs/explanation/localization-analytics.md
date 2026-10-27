%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart est importante.",
  category: "explication",
  section: "analytics",
  order: 2
}
---

Choisir la langue cible pour la traduction suivante est un pari : cela coûte du temps et de l'argent, et le retour sur investissement dépend d'une demande que vous ne pouvez généralement pas voir. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et délibéré : répondre à 'devrions-nous localiser en langue X ?'. Les signaux sont choisis pour éclairer cette question, et non pour former une suite d'analyse à vocation générale.

Trois facteurs pilotent la décision :

1. **La demande.** Combien de visiteurs souhaitent cette langue ? Les langages du navigateur et le pays vous indiquent où réside l'intérêt.
2. **L'écart.** Cette demande est-elle déjà comblée ? La comparaison des langues préférées avec les langues cibles de votre projet, la langue de la page et ses traductions annoncées révèle la part de trafic qui se heurte à une limitation.
3. **La valeur.** La localisation serait-elle rentable ? L'engagement par écart de localisation, les pages sur lesquelles aboutit le trafic sous-servi, et l'origine de ce trafic indiquent si une nouvelle localisation se traduit par des conversions.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` enregistre la langue réelle de la page déclarée dans `<html lang>`, non la langue supposée reçue par le visiteur. `has_locale_gap` compare un choix de langue explicite valide, ou les préférences du navigateur en l'absence de choix, avec les cibles de projet, la langue de la page et les traductions annoncées via `hreflang`. Un choix indique la demande, pas la disponibilité : choisir une langue non prise en charge laisse toujours un écart. Préférence navigateur, choix et langue de la page restent des signaux distincts.

La décision relative à l'écart est stockée par événement telle qu'elle était au moment de la visite. Les indicateurs historiques, y compris ceux collectés avant que les choix explicites n'aient affecté le calcul, ne sont pas recalculés à partir des cibles d'aujourd'hui ou de choix ultérieurs. La liste complète des préférences du navigateur et les traductions annoncées ne sont pas conservées ; elles ne peuvent pas être reconstruites de manière fiable. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez l'enregistrement initial de la demande.

## Pourquoi 'sans cookie', spécifiquement

Le réflexe lorsqu'on souhaite avoir des visiteurs uniques est de configurer un cookie ou d'identifier le navigateur par son empreinte. Tous deux créent des identifiants durables, et l'empreinte numérique est, sous la plupart des régimes de confidentialité, plus difficile à supprimer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques d'un jour nécessitent uniquement un identifiant stable *pendant la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et limité par projet, soutient les comptes de visiteurs quotidiens tout en rendant impossible de lier un visiteur entre les jours ou les sites. Cela ne fournit pas de suivi à long terme des visiteurs réguliers.

Cette conception limite les identifiants retenus par l'analyse. Elle ne détermine pas si un site web particulier nécessite un consentement ; cela dépend de la manière dont le site utilise les analyses et des règles qui lui sont applicables.
