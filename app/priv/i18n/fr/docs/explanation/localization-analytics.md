%{
  title: "Pourquoi l'analyse de localisation",
  summary:
    "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart est importante.",
  category: "explication",
  order: 2
}
---
Choisir la langue cible suivante est un pari : il coûte du temps et de l'argent, et le retour dépend d'une demande que vous ne voyez généralement pas. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de collecter des analyses ici est limité et délibéré : répondre à « devrions-nous localiser dans la langue X ? ». Les signaux sont choisis pour alimenter cette question, pas pour constituer une suite d'analyse générique.

Trois entrées pilotent la décision :

1. **Demande.** Combien de visiteurs veulent cette langue ? La langue du navigateur et le pays indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà couverte ? La comparaison des langues préférées contre les langues cibles de votre projet révèle la part du trafic qui rencontre une barrière.
3. **Valeur.** La localisation se rentabiliserait-elle ? L'engagement par écart de localisation, les pages où s'arrête le trafic sous-servi, et d'où provient ce trafic indiquent si une nouvelle localisation se rentabilise.

## Pourquoi l'écart est calculé au moment de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous avez alors rencontrée, pas un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous conservez un enregistrement honnête de combien de demande restait non couverte.

## Pourquoi sans cookie, spécifiquement

L'instinct lorsque vous souhaitez des « visiteurs uniques » est de définir un cookie ou d'identifier l'empreinte du navigateur. Les deux créent des identifiants à longue durée de vie, et l'identification par empreinte est, sous la plupart des régimes de confidentialité, plus difficile à effacer qu'un cookie. Aucun n'est nécessaire ici.

Les visiteurs uniques pour un jour ne nécessitent qu'un identifiant stable *au cours de la journée*. Un hachage de l'IP et du User-Agent, pivoté quotidiennement et limité par projet, permet des uniques quotidiens et hebdomadaires précis tout en rendant impossible de relier un visiteur d'un jour à l'autre ou d'un site à l'autre. Vous renoncez au suivi des visiteurs de retour à long terme, ce qui est exactement la fonctionnalité qui crée l'exposition aux risques de confidentialité dont vous auriez autrement besoin d'une bannière de consentement pour opérer légalement.

Le compromis est intentionnel : l'analyse de localisation doit être quelque chose que vous pouvez déployer partout, vers chaque visiteur, sans frottement juridique.