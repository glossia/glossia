%{
  title: "Pourquoi les analyses de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation et pourquoi la métrique d'écart compte.",
  category: "Explication",
  order: 2
}
---
Choisir dans quelle langue traduire ensuite est un pari : cela coûte du temps et de l'argent, et la rentabilité dépend d'une demande que vous ne pouvez généralement pas voir. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

L'objectif de collecter ces analyses ici est précis et intentionnel : répondre à "devrions-nous localiser dans la langue X ?" Les signaux sont sélectionnés pour alimenter cette question, et non pour former un ensemble d'analyses généraliste.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs souhaitent cette langue ? Les langues du navigateur et le pays vous indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? Comparer les langues préférées aux langues cibles de votre projet révèle la part du trafic qui se heurte à un mur.
3. **Valeur.** La localisation valoirait-elle ? L'écart d'engagement par langue, les pages sur lesquelles atterrit le trafic non desservi, et d'où provient ce trafic indiquent si une nouvelle langue génère des conversions.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockées par événement, calculées par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous avez connue à l'époque, pas un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous gardez un enregistrement honnête sur la part de demande non desservie.

## Pourquoi sans cookie, spécifiquement

L'instinct, lorsque vous souhaitez des "visiteurs uniques", est de définir un cookie ou d'identifier le navigateur. Les deux créent des identifiants de longue durée, et l'identification par empreinte est, dans la plupart des cadres de confidentialité, plus difficile à effacer qu'un cookie. Aucun des deux n'est nécessaire ici.

Les visiteurs uniques pour une journée seulement requièrent un identifiant stable. *dans la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et limité par projet, permet de compter avec précision les uniques quotidiens et hebdomadaires tout en rendant impossible de lier un visiteur d'un jour à l'autre ou d'un site à l'autre. Vous renoncez au suivi à long terme des visiteurs récurrents, ce qui est exactement la capacité qui crée l'exposition liée à la vie privée que vous auriez autrement besoin d'une bannière de consentement pour opérer de manière légale.

Le compromis est intentionnel : l'analyse de localisation doit être quelque chose que vous pouvez distribuer partout, à chaque visiteur, sans friction juridique.