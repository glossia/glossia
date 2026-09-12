%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart compte.",
  category: "explication",
  order: 2
}
---
Choisir dans quelle langue traduire ensuite est un pari : cela coûte du temps et de l'argent, et le retour dépend d'une demande que vous ne voyez généralement pas. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de la collecte d'analyses ici est restreint et délibéré : répondre à "devrions-nous localiser dans la langue X ?" Les signaux sont choisis pour alimenter cette question, non pour constituer une suite d'analyses généraliste.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays indiquent où se situe l'intérêt.
2. **L'écart.** La demande est-elle déjà couverte ? Comparer les langues préférées aux langues cibles de votre projet révèle la part du trafic qui rencontre un obstacle.
3. **Valeur.** Est-ce que la localisation se rentabilise ? L'écart d'engagement par langue, les pages où atterrit le trafic sous-servi et l'origine de ce trafic indiquent si une nouvelle langue génère des conversions.

## Pourquoi l'écart est-il calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockées par événement, calculées par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous aviez alors, et non un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de la demande qui restait non satisfaite.

## Pourquoi sans cookie, spécifiquement

L'instinct lorsqu'on veut des "visiteurs uniques" est de configurer un cookie ou d'identifier l'empreinte du navigateur. Les deux créent des identifiants à longue durée de vie, et l'identification par empreinte est, dans la plupart des régimes de confidentialité, plus difficile à supprimer qu'un cookie. Aucun des deux n'est nécessaire ici.

Les visiteurs uniques par jour n'exigent qu'un identifiant stable. *dans la journée*. Un hachage de l'IP et de l'User-Agent, pivoté quotidiennement et isolé par projet, fournit des uniques quotidiens et hebdomadaires précis tout en rendant impossible de lier un visiteur d'un jour à l'autre ou entre sites. Vous renoncez au suivi à long terme des visiteurs revenants, ce qui est exactement la capacité qui engendre l'exposition à la vie privée que vous auriez autrement besoin d'une bannière de consentement pour opérer légalement.

Le compromis est intentionnel : les analyses de localisation devraient être quelque chose que vous pouvez déployer partout, à chaque visiteur, sans friction juridique.