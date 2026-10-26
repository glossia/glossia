%{
  title: "Revues linguistiques",
  summary:
    "Décisions humaines liées à la source, continuations de traduction et orientations du référentiel révisées.",
  category: "Référence",
  section: "translation",
  order: 31
}
---

## Remontée

Les sessions de traduction de dépôt avec un modèle de décision configuré peuvent demander une entrée linguistique pour un sens source manquant ou un contexte de domaine, des directives conflictuelles, ou une adaptation culturelle conséquente. La faible confiance seule ne déclenche pas de question. Les erreurs correctibles depuis le contexte existant utilisent le budget de correction ordinaire ; les échecs de qualité restants après ce budget peuvent également demander une entrée. Sans un modèle de décision, l'escalade linguistique automatique est désactivée.

Seul le fichier ou le locale affecté s'arrête. Son candidat non approuvé n'est pas publié. Les fichiers indépendants se terminent et peuvent être publiés normalement. Après la fin de la publication, la session devient `awaiting_input` et libère son runner. Elle ne consomme pas de worker tant qu'un humain est en train de répondre.

Chaque escalade ouvre une **conversation Toki partagée avec un objectif linguistique défini**, liée à la session de traduction. Les participants discutent du sens, posent des questions complémentaires et affinent une décision proposée. La discussion seule ne valide jamais une traduction ou n'écrit pas le contexte de dépôt. Les conversations Toki ordinaires restent privées à leur propriétaire, y compris aux administrateurs.

Tous les associés actuellement autorisés dont les langues fluentes déclarées correspondent au locale cible sont invités à la même conversation. La fluidité est distincte de la langue d'affichage et n'accorde pas l'accès au projet ni la permission d'approuver des décisions. Une langue large telle que `es` correspond aux variantes régionales telles que `es-MX` ; les scripts explicites incompatibles ne correspondent pas. Les déclarations régionales telles que `zh-TW` utilisent leur script CLDR habituel, tandis que `zh` large reste non restreint par script.

Les participants éligibles reçoivent des notifications push mobiles génériques uniquement s'ils ont opté ; la livraison vérifie à nouveau la fluidité actuelle, la participation, l'accès au projet et l'objectif ouvert. Les notifications ouvrent la conversation partagée. Les conversations et les approbations sont disponibles depuis les deux applications natives et le tableau de bord web. Voir [Notifications natives](/docs/reference/native-push-notifications) pour la configuration du fournisseur et la stratégie de livraison.

## Profil des langues fluides

`GET /api/me` inclut `user.fluent_languages`. `PUT /api/me/fluent-languages` demande `user:write` et accepte uniquement `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Il remplace la liste de l'utilisateur authentifié et renvoie l'enveloppe du profil. Les balises CLDR BCP47 supportées conservent une spécificité de région/script explicite et utilisent une casse canonique ; les doublons s'effacent. Un tableau vide efface la fluidité. Des balises invalides, des champs non pertinents ou plus de 50 entrées soumises retournent 422. Cela ne change jamais le locale d'interface utilisateur.

## API Revue

`GET /api/:handle/projects/:project/translations/:id/reviews` exige `translation:read` et l'accès au projet. Il retourne `{"reviews": [...]}`, les questions ouvertes en premier, puis les plus anciennes, limité à 500 entrées. Actualisez après avoir répondu pour révéler toute question restante ; l'historique des réponses n'enter jamais cache une question ouverte derrière la limite.

Chaque revue inclut `id`, `translation_session_id`, `conversation_id`, `participants` (`id` et `name` optionnel), `status`, `source_path`, `output_path`, `locale`, `question`, `source_excerpt` borné et `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, et `inserted_at`. Le statut est `open`, `answered` ou `stale`.

`answered_by` identifie l'humain qui a approuvé la décision comme `{"id": "<user UUID>", "name": "<current display name>"}` ; `name` peut être null. Le champ est null avant l'approbation ou lorsque l'approbateur n'est pas disponible. Il ne contient aucun e-mail ou autre champ de profil privé, et la reprise de l'approbation ne change pas l'approbateur. Le même champ est inclus dans `linguistic_review` imbriqué sur les conversations Toki partagées. Aucun horodatage d'approbation n'est exposé ; `inserted_at` est l'heure de création de la revue, pas son heure d'approbation.

Utilisez les points de conversation Toki et de messages de projet existants pour discuter. Les conversations d'objectifs partagées apparaissent à côté des conversations privées de l'acteur dans l'historique Toki. Les historiques partagés nécessitent la permission de politique de lecture/écriture Toki actuelle et l'accès de lecture de traduction ; les historiques ordinaires restent propriétaires uniquement. Les messages humains incluent leur identité d'auteur, et les réponses incluent `status` et `reply_to_id`. Toki reçoit des extraits de source/candidat bornés et l'objectif, pas l'accès d'écriture du dépôt.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` exige à la fois `translation:read` et `translation:write`, plus l'accès au projet :

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` doit identifier la dernière réponse assistée **réponse** dans la conversation d'objectif, pas la question d'ouverture. `answer` est la décision humaine approuvée et est requise et non vide. `guidance` et `context_scope` sont optionnels ; le périmètre par défaut est `locale` et peut être `project`. La réponse et les directives autorisent jusqu'à 8 000 caractères et 32 000 octets UTF-8. Les directives ne peuvent pas contenir les commentaires de repérage de revue réservés à Glossia. Le serveur choisit les chemins de dépôt ; un chemin fourni par le client n'est jamais utilisé.

Une réponse réussie est `{"review": {...}}`. Rejouer la même décision, le message de résolution, les directives et le périmètre est idempotent. Une conversation occupée retourne `409 conversation_busy` ; un message plus récent ou une référence de résolution invalide retourne `409 resolution_outdated`. Actualisez et revoyez la discussion actuelle avant d'approuver à nouveau. Une décision différente sur un objectif résolu retourne `409 already_answered` ; approuver un objectif annulé ou remplacé retourne `409 stale`. Un texte invalide ou un périmètre indisponible retourne 422. Les identifiants manquants ou hors projet retournent 404. L'authentification normale et l'autorisation du projet s'appliquent à chaque demande, y compris les relances. Les objectifs fermés rejettent les nouveaux messages de discussion avec `409 goal_closed`.

## Continuités et contexte obsolète

Les décisions peuvent être approuvées pendant que le travail indépendant est toujours en cours. Elles ne lancent jamais un deuxième runner ensuite. Une fois que le runner a libéré et que chaque objectif dans cette exécution est résolu, Glossia met atomiquement en file d'attente une session de continuation. `resumed_session_id` l'identifie ; la session originale reste historique `awaiting_input`. Le tableau de bord et les conversations natives lient la suite.

La suite a une identité d'exécution fraîche et conserve la branche de publication de traduction et les sorties validées. Chaque réponse s'applique uniquement à la source identique et à l'empreinte numérique du contexte de traduction résolu. Les modifications de source, voix, glossaire, modèle ou instructions de dépôt empêchent la réutilisation de la réponse. Un commit de branche par défaut plus récent supprime les sessions en attente et marque les questions ouvertes obsolètes. L'annulation marque également les questions ouvertes obsolètes.

## Guidance de dépôt réutilisable

Guidance réutilisable est une modification humaine explicite et distincte. Une réponse seule ne devient pas un contexte de dépôt, et les transcriptions de discussions privées ne sont jamais copiées automatiquement.

`locale` cible la surcouche locale applicable, telle que `L10N/es.md` ; `project` cible la `L10N.md` applicable. Les fichiers de contexte existants du domaine sont respectés. Les surcouches locales manquantes reçoivent leur en-tête locale. L'en-tête existant et le texte sont préservés, et chaque décision est complétée avec son identifiant UUID de révision pour la provenance et l'idempotence.

Guidance est proposée dans la demande de traduction normale, et non écrite silencieusement dans la branche par défaut. Le dépôt doit toujours correspondre au digest de contexte enregistré ; une modification conflictuelle échoue la publication au lieu de la remplacer. Les chemins doivent être des documents de localisation relatifs au dépôt, sans traversée ni liens symboliques. Chaque document de contexte est limité à 1 MiB. La fusion de la demande de tirage rend la guidance un contexte de localisation versionné ordinaire pour les exécutions ultérieures.
