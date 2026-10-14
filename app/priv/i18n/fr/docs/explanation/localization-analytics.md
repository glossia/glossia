%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart est importante.",
  category: "explication",
  section: "analytics",
  order: 2
}
---

Choisir quelle langue traduire ensuite est un pari : cela coûte du temps et de l'argent, et le retour sur investissement dépend de la demande que vous ne voyez généralement pas. L'analyse de localisation rend cette demande visible.

## ## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et délibéré : répondre à la question « devrions-nous localiser dans la langue X ? ». Les signaux sont choisis pour alimenter cette question, pas pour être une suite d'analyses généraliste.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **Le décalage.** Cette demande est-elle déjà couverte ? La comparaison des langues préférées par rapport aux langues cibles de votre projet, à la langue de la page et à ses traductions annoncées révèle la part de trafic qui se heurte à un blocage.
3. **Valeur.** La localisation rapportera-t-elle ? L'engagement selon le décalage de localisation, les pages sur lesquelles atterrit le trafic non assuré, et l'origine de ce trafic indiquent si une nouvelle localisation se convertit.

## Pourquoi le décalage est calculé au moment de l'ingestion

`served_locale` enregistre la langue de page réelle déclarée dans `<html lang>`, non la langue que nous supposons reçue par le visiteur. `has_locale_gap` compare les préférences du navigateur aux cibles de projet, la langue de page et les traductions annoncées via `hreflang` liens. Les deux sont stockés par événement tels qu'ils étaient à l'époque de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous étiez face alors, pas un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez portugais le mois prochain, le décalage du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui attendait.

## Pourquoi sans cookie, spécifiquement

L'instinct lorsque vous souhaitez des « visiteurs uniques » est de définir un cookie ou d'établir une empreinte du navigateur. Les deux créent des identifiants à longue durée de vie, et l'identification est, sous la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques d'une journée nécessitent uniquement un identifiant stable *au cours de la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et limité par projet, supporte les comptes quotidiens de visiteurs tout en rendant impossible le lien d'un visiteur entre des jours ou entre sites. Cela ne fournit pas la traçabilité des visiteurs retournant sur le long terme.

Cette conception limite les identifiants conservés par l'analyse. Elle n'établit pas si un site web particulier nécessite un consentement ; cela dépend de la manière dont le site utilise l'analyse et des règles qui s'y appliquent.
