%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart compte.",
  category: "explication",
  section: "analytics",
  order: 2
}
---

Choisir la langue dans laquelle se traduire à l'étape suivante constitue un pari : cela coûte du temps et de l'argent, et la rentabilité dépend d'une demande que vous ne pouvez généralement pas voir. L'analytique de localisation rend cette demande visible.

## ## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et délibéré : répondre à la question « devons-nous localiser vers la langue X ? ». Les signaux sont choisis pour servir cette question, pas pour former une suite d'analyses à usage général.

Trois entrants pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? La langue du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? Comparant les langues préférées à la langue cible de votre projet, la langue de la page et ses traductions annoncées, cela révèle la part de trafic qui se heurte à une impasse.
3. **Valeur.** La localisation rapporte-t-elle ? L'engagement par écart de localisation, les pages sur lesquelles arrive le trafic non couvert, et la provenance de ce trafic indiquent si une nouvelle localisation rapporte.

## Pourquoi l'écart est calculé en temps d'ingestion

`served_locale` enregistre la langue réelle de la page déclarée dans `<html lang>` , pas la langue que nous supposons que le visiteur a reçue. `has_locale_gap` compare les préférences du navigateur par rapport à vos cibles de projet, la langue de la page, et les traductions annoncées via `hreflang` liens. Les deux sont enregistrés par événement tel qu'ils étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité à laquelle vous étiez confronté alors, pas d'un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétrospectivement ; vous gardez un enregistrement honnête de la demande qui restait non satisfaite.

## Pourquoi spécifiquement sans cookies

L'instinct lorsque vous voulez des "visiteurs uniques" est de définir un cookie ou d'empreinter le navigateur. Les deux créent des identifiants de longue durée, et l'empreintage est, dans la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour une journée ne nécessitent qu'un identifiant qui est stable *pendant la journée*. Un hachage de l'IP et du User-Agent, tourné quotidiennement et portés par projet, prend en charge les comptes de visiteurs quotidiens tout en rendant impossible de lier un visiteur sur plusieurs journées ou sites. Cela ne permet pas un suivi sur le long terme des visiteurs revenants.

Cette conception limite les identifiants retenus par les analyses. Elle ne détermine pas si un site web particulier nécessite le consentement ; cela dépend de la manière dont le site utilise les analyses et des règles qui lui s'appliquent.
