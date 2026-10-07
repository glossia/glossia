%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique de l'écart compte.",
  category: "explication",
  section: "analytics",
  order: 2
}
---
Choisir la langue dans laquelle traduire ensuite est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne pouvez pas voir habituellement. L'analytique de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de la collecte d'analytics ici est ciblé et délibéré : pour répondre à "devrions-nous localiser vers la langue X ?" Les signaux sont choisis pour répondre à cette question, pas pour être une suite d'analytique générale.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se concentre l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? En comparant les langues préférées aux langues cibles de votre projet, la langue de la page et ses traductions annoncées, cela révèle la part du trafic qui rencontre un obstacle.
3. **Valeur.** La localisation en vaudrait-elle la peine ? L'écart d'engagement par localisation, les pages sur lesquelles atterrit le trafic non desservi, et l'origine de ce trafic indiquent si une nouvelle localisation génère des conversions.

## Pourquoi le décalage est calculé au moment de l'ingestion

`served_locale` enregistre la langue réelle de la page déclarée dans `<html lang>`, mais pas la langue que nous supposons avoir été reçue par le visiteur. `has_locale_gap` compare les préférences du navigateur par rapport à vos cibles de projet, la langue de la page et les traductions annoncées via `hreflang` liens. Les deux sont stockés par événement tels qu'ils étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous affrontiez alors, pas un recalcul par rapport aux objectifs d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, le décalage du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement fidèle de la demande qui restait non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct lorsque vous souhaitez des \\"visiteurs uniques\\" consiste à définir un cookie ou à \\"fingerprinter\\" le navigateur. Les deux créent des identifiants à longue durée de vie, et le fingerprinting est, dans la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour une journée n'exigent qu'un identifiant stable *dans la journée*. Un hachage de l'IP et de l'User-Agent, renouvelé quotidiennement et restreint par projet, prend en charge les comptages de visiteurs quotidiens tout en rendant impossible de lier un visiteur entre les jours ou entre les sites. Cela ne permet pas de suivre les visiteurs récurrents sur le long terme.

Cette approche limite les identifiants conservés par l'analyse. Elle ne détermine pas si un site spécifique nécessite un consentement ; cela dépend de la manière dont le site utilise l'analyse et des règles qui lui s'appliquent.