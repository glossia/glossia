%{
  title: "Pourquoi les analyses de localisation",
  summary: "Comment les signaux collectés se traduisent en décisions de localisation, et pourquoi la métrique d'écart est importante.",
  category: "explication",
  order: 2
}
---
Choisir la langue de traduction suivante est un pari : cela coûte du temps et de l'argent, et le gain dépend d'une demande que vous ne pouvez généralement pas voir. L'analyse de localisation rend cette demande visible.

## La décision, pas le tableau de bord

Le but de la collecte d'analyses ici est précis et délibéré : répondre à « devrions-nous traduire dans la langue X ? ». Les signaux sont choisis pour alimenter cette question, et non pour constituer une suite d'analyses générale.

Trois entrées pilotent la décision :

1. **La demande.** Combien de visiteurs souhaitent cette langue ? La langue du navigateur et le pays indiquent où se situe l'intérêt.
2. **L'écart.** Cette demande est-elle déjà satisfaite ? Comparer les langues préférées avec les langues cibles de votre projet révèle la part de trafic qui rencontre un obstacle.
3. **La valeur.** La localisation se rentabiliserait-elle ? L'engagement par écart de localisation, les pages sur lesquelles atterrit le trafic non satisfait et d'où provient ce trafic indiquent si une nouvelle localisation génère des conversions.

## Pourquoi l'écart est calculé lors de l'ingestion

`served_locale` et `has_locale_gap` sont stockés par événement, calculés par rapport à vos langues cibles telles qu'elles étaient au moment de la visite. Cela signifie que les données historiques reflètent l'opportunité que vous aviez à l'époque, ni un recalcul par rapport aux cibles d'aujourd'hui. Si vous ajoutez le portugais le mois prochain, l'écart du mois dernier ne rétrécit pas rétroactivement ; vous gardez un enregistrement honnête de la quantité de demande qui restait non satisfaite.

## Pourquoi sans cookie, spécifiquement

L'instinct quand vous voulez des « visiteurs uniques » est de définir un cookie ou d'empreindre le navigateur. Les deux créent des identifiants à longue durée de vie, et l'empreinte est, selon la plupart des régimes de confidentialité, plus difficile à supprimer qu'un cookie. L'un ni l'autre n'est nécessaire ici.

Des « visiteurs uniques » quotidiens ne nécessitent qu'un identifiant stable *au cours de la journée*. Un hachage de l'IP et du User-Agent, renouvelé quotidiennement et limité à chaque projet, fournit des uniques quotidiens et hebdomadaires précis tout en rendant impossible la liaison d'un visiteur sur plusieurs jours ou entre plusieurs sites. Vous renoncez au suivi à long terme des visiteurs revenants, ce qui est exactement la capacité qui génère l'exposition de confidentialité pour laquelle vous auriez autrement besoin d'une bannière de consentement pour fonctionner légalement.

Le compromis est intentionnel : l'analyse de localisation devrait être quelque chose que vous pouvez déployer partout, à chaque visiteur, sans friction juridique.