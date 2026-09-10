%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se transforment en décisions de localisation et pourquoi la métrique d'écart compte.",
  category: "explication",
  order: 2
}
---
Choisir la langue vers laquelle traduire ensuite est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne voyez généralement pas. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de la collecte d'analyses ici est ciblé et délibéré : répondre à "devrions-nous localiser dans la langue X ?" Les signaux sont choisis pour alimenter cette question, et non pour former une suite d'analyse polyvalente.

Trois facteurs pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se trouve l'intérêt.
2. **L'écart.** Cette demande est-elle déjà couverte ? La comparaison des langues préférées avec les langues cibles de votre projet révèle la part de trafic se heurtant à un mur.
3. **Valeur.** La localisation vaut-elle le coup ? L'écart d'engagement par langue, les pages où atterrit le trafic non desservi, et l'origine de ce trafic indiquent si une nouvelle langue convertit.

## Pourquoi l'écart est calculé à l'ingestion

`served_locale` et `has_locale_gap` sont stockées par événement, calculées par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous affrontiez alors, pas un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui restait non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct, lorsque vous souhaitez des \\"visiteurs uniques\\", est de configurer un cookie ou de prendre l'empreinte du navigateur. Les deux créent des identifiants à longue durée de vie, et la prise d'empreinte est, dans la plupart des cadres de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour une journée ne nécessitent qu'un identifiant stable. *dans la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et limité par projet, fournit des uniques quotidiens et hebdomadaires précis tout en rendant impossible de lier un visiteur entre jours ou sites. Vous renoncez au suivi à long terme des visiteurs récurrents, ce qui est précisément la fonctionnalité générant l'exposition aux risques de confidentialité que vous auriez autrement besoin d'une bannière de consentement pour opérer légalement.

Le compromis est intentionnel : l'analyse de localisation doit être quelque chose que vous pouvez déployer partout, à chaque visiteur, sans friction juridique.