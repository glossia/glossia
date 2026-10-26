%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se transforment en décisions de localisation et pourquoi la métrique d'écart est importante.",
  category: "explication",
  section: "analytics",
  order: 2
}
---

Choisir quelle langue traduire ensuite est un pari : cela coûte du temps et de l'argent, et le rendement dépend de la demande que vous ne pouvez généralement pas voir. Les analyses de localisation rendent cette demande visible.

## La décision, pas le tableau de bord

L'objectif de la collecte d'analyses ici est limité et délibéré : répondre à « devrions-nous traduire dans la langue X ? ». Les signaux sont choisis pour servir cette question, pas pour former une suite d'analyse à usage général.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues des navigateurs et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà desservie ? La comparaison des langues préférées avec les langues cibles de votre projet, la langue de la page et ses traductions annoncées révèle la part de trafic qui se heurte à un mur.
3. **Valeur.** La localisation rentabilisera-t-elle ? L'engagement par écart de localisation, les pages sur lesquelles atterrit le trafic non desservi, et l'origine de ce trafic indiquent si une nouvelle localisation est rentable.

## Pourquoi le décalage est calculé à l'ingestion

`served_locale` enregistre la langue réelle de la page déclarée dans `<html lang>`, pas la langue que nous supposons reçue. `has_locale_gap` compare les préférences du navigateur avec les cibles de votre projet, la langue de la page et les traductions annoncées via `hreflang` liens. Les deux sont stockés par événement tel qu'ils étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous affrontiez alors, pas un recalcul contre les cibles de ce jour. Si vous ajoutez le portugais ce mois-ci, le décalage du dernier mois ne rétrécit pas rétroactivement ; vous gardez un enregistrement honnête de combien de demande était non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct quand vous voulez des « visiteurs uniques » est de créer un cookie ou d'identifier le navigateur. Les deux créent des identifiants persistants, et l'identification par empreinte est, dans la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. L'un ni l'autre n'est nécessaire ici.

Les visiteurs uniques pour une journée nécessitent uniquement un identifiant stable *dans la journée*. Un hash de l'IP et de User-Agent, généré quotidiennement et limité par projet, permet les comptes quotidiens de visiteurs tout en rendant impossible de relier un visiteur entre les jours ou entre les sites. Ce design ne fournit pas le suivi à long terme des visiteurs revenants.

Ce design limite les identifiants conservés par les analyses. Il ne détermine pas si un site particulier nécessite un consentement ; cela dépend de la manière dont le site utilise les analyses et des règles qui s'y appliquent.
