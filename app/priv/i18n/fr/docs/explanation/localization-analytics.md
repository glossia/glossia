%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart compte.",
  category: "explication",
  section: "analytics",
  order: 2
}
---

Choisir la langue pour laquelle traduire ensuite est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne pouvez généralement pas voir. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est restreint et délibéré : répondre à « devrions-nous localiser dans la langue X ? » ? Les signaux sont choisis pour nourrir cette question, pas pour former une suite d'analyse générale.

Trois entrées conduisent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà servie ? En comparant les langues préférées avec les langues cibles de votre projet, la langue de la page et ses traductions annoncées, on révèle la part du trafic heurtant un mur.
3. **Valeur.** La localisation serait-elle rentable ? L'engagement par écart local, les pages sur lesquelles se retrouve le trafic non servi, et l'origine de ce trafic indiquent si une nouvelle langue convertit.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` enregistre la langue réelle de la page déclarée dans `<html lang>`, pas la langue que nous supposons avoir été reçue. `has_locale_gap` compare les préférences du navigateur avec les langues cibles de votre projet, la langue de la page et les traductions annoncées via `hreflang`. Les deux sont stockés par événement tels qu'ils étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous facez alors, pas une recomputation par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne se rétrécit pas rétroactivement ; vous conservez une trace honnête de la quantité de demande qui restait non servie.

## Pourquoi sans cookie, spécifiquement

L'instinct quand on veut des « visiteurs uniques » est de configurer un cookie ou d'identifier le navigateur par empreinte. Les deux créent des identifiants à longue durée de vie, et l'identification par empreinte est, sous la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour un jour ne nécessitent qu'un identifiant qui est stable *au cours de la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et configuré par projet, prend en charge les comptes de visiteurs quotidiens tout en rendant impossible de relier un visiteur d'un jour à l'autre ou entre sites. Cela ne permet pas le suivi des visiteurs repliants à long terme.

Cette conception limite les identifiants retenus par les analyses. Elle ne détermine pas si un site web spécifique nécessite un consentement ; cela dépend de la manière dont le site utilise les analyses et des règles qui s'y appliquent.
