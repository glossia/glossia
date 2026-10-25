%{
  title: "Relectures linguistiques",
  summary:
    "Décisions humaines liées à la source, poursuites de traduction et directives du dépôt revues.",
  category: "référence",
  section: "translation",
  order: 31
}
---

## Escalade

Les exécutions de traduction de dépôt avec un modèle de décision configuré peuvent demander un apport linguistique pour le sens manquant de la source ou le contexte de domaine, des orientations contradictoires, ou une adaptation culturelle conséquente. Une faible confiance seule ne déclenche pas une question. Les erreurs correctibles à partir du contexte existant utilisent le budget de correction habituel ; les échecs de qualité restants après ce budget peuvent également demander de l'apport. Sans modèle de décision, l'escalade linguistique automatique est désactivée.

Seul le fichier ou la cible locale affectée s'arrête. Son candidat non approuvé n'est pas publié. Les fichiers indépendants se terminent et peuvent publier normalement. Une fois la publication achevée, la session devient `awaiting_input` et libère son exécutant. Elle ne consomme pas d'agent tant qu'un humain répond.

Chaque escalade ouvre une **conversation Toki commune à objectif linguistique défini**, liée à la session de traduction. Les participants discutent de la signification, posent des questions de suivi et affinent une décision proposée. La discussion seule n'approuve jamais une traduction ni n'écrit du contexte de dépôt. Les conversations Toki ordinaires restent privées à leur propriétaire, y compris pour les administrateurs.

Tous les collaborateurs actuellement autorisés dont les langues de fluidité déclarées correspondent à la cible locale sont invités à la même conversation. La fluidité est séparée de la langue d'affichage et n'accorde pas l'accès au projet ni l'autorisation d'approuver des décisions. Une catégorie de langue large telle que `es` correspond aux variants régionaux tels que `es-MX` ; les scripts explicites incompatibles ne correspondent pas. Les déclarations régionales telles que `zh-TW` utilisent leur script CLDR habituel, tandis que le large `zh` reste non restreint par le script.

Les participants éligibles reçoivent des notifications push mobiles génériques uniquement s'ils ont opté pour cela ; la livraison recheck la fluidité actuelle, la membre d'affiliation, l'accès au projet et l'objectif ouvert. Les notifications ouvrent la conversation partagée. Les conversations et les approbations sont disponibles depuis les applications natives et le tableau de bord web. Voir [Notifications push natives](/docs/reference/native-push-notifications) pour la configuration du fournisseur et la politique de livraison.

## Profil de langue fluente

`GET /api/me` inclut `user.fluent_languages`. `PUT /api/me/fluent-languages` nécessite `user:write` et n'accepte que `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. Elle remplace la liste de l'utilisateur authentifié et retourne l'enveloppe de profil. Les balises CLDR BCP47 prises en charge conservent la spécificité de région/script explicite et utilisent une casse canonique ; les doublons sont regroupés. Un tableau vide efface la fluence. Les balises invalides, les champs non pertinents ou plus de 50 entrées soumises retournent une erreur 422. Cela ne modifie jamais le locale de l'interface utilisateur.

## API de révision

`GET /api/:handle/projects/:project/translations/:id/reviews` nécessite `translation:read` et l'accès au projet. Elle retourne `{"reviews": [...]}` avec les questions ouvertes en premier, puis les plus anciennes, limité à 500 entrées. Actualisez après avoir répondu pour révéler toute question restante ; l'historique des réponses n'encaisse jamais une question ouverte derrière la limite.

Chaque révision inclut `id`, `translation_session_id`, `conversation_id`, `participants` (`id` et `name` nullable), `status`, `source_path`, `output_path`, `locale`, `question`, delimité `source_excerpt` et `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, et `inserted_at`. Le statut est `open`, `answered` ou `stale`.

Utilisez les endpoints Toki de conversation et de message existants du projet pour la discussion. Les conversations à objectif partagé apparaissent aux côtés des conversations privées de l'acteur dans l'historique Toki. Les historiques partagés requièrent la permission de politique d'accès lecture/écriture Toki actuelle et l'accès de lecture de la traduction ; les historiques ordinaires restent un propriétaire seulement. Les messages humains incluent leur identité d'auteur, et les réponses incluent `status` et `reply_to_id`. Toki reçoit des extraits sources/candidats bornés et l'objectif, pas l'accès d'écriture du dépôt.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` nécessite à la fois `translation:read` et `translation:write` et l'accès au projet :

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` doit identifier la réponse d'assistant **réponse** terminée la plus récente dans la conversation à objectif, pas sa question d'ouverture. `answer` est la décision approuvée par l'humain et est requise et non vide. `guidance` et `context_scope` sont optionnels ; la portée par défaut est `locale` et peut être aussi `project`. La réponse et l'orientation autorisent chacune jusqu'à 8 000 caractères et 32 000 octets UTF-8. L'orientation ne peut pas contenir les commentaires réservés marqueurs de révision de Glossia. Le serveur choisit les chemins du dépôt ; un chemin fourni par le client n'est jamais utilisé.

Une réponse réussie est `{"review": {...}}`. Relancer la même décision, le message de résolution, l'orientation et la portée est idempotent. Une conversation occupée retourne `409 conversation_busy` ; un message plus récent ou une référence de résolution invalide retourne `409 resolution_outdated`. Rechargez et révisez la discussion actuelle avant d'approuver à nouveau. Une décision différente sur un objectif résolu retourne `409 already_answered` ; approuver un objectif annulé ou remplacé retourne `409 stale`. Texte invalide ou portée indisponible retourne 422. Poids manquant et IDs de projet étranger retournent 404. L'authentification normale et l'autorisation de projet s'appliquent à chaque demande, y compris les rejeux. Les objectifs fermés rejettent de nouveaux messages de discussion avec `409 goal_closed`.

## Continuations et contexte obsolète

Les décisions peuvent être approuvées tandis que le travail indépendant est toujours en cours. Elles n'en démarreraient jamais un deuxième exécutant. Une fois que l'exécutant a libéré et que tous les objectifs de cette exécution sont résolus, Glossia queue atomiquement une session de continuation. `resumed_session_id` l'identifie ; la session originale reste historique `awaiting_input`. Le tableau de bord et les conversations natives lient tous deux la suite.

La suite a une identité d'exécution fraîche et conserve la branche de publication de la traduction et les sorties validées. Chaque réponse s'applique uniquement à la source identique et à l'empreinte de contexte de traduction résolue. Source, voix, glossaire, modèle ou instructions de dépôt modifiées empêchent le réemploi de réponses. Un envoi par défaut en branche plus récente annule les sessions en attentes et marque les questions ouvertes obsolètes. L'annulation marque également les questions ouvertes obsolètes.

## Orientation de dépôt réutilisable

L'orientation réutilisable est une modification humaine séparée et explicite. Une réponse seule ne devient pas du contexte du dépôt, et les transcriptions de discussion privées ne sont jamais copiées automatiquement.

`locale` cible la surcouche locale applicable, telle que `L10N/es.md` ; `project` cible la `L10N.md` applicable. Les fichiers de contexte de portée existants sont respectés. Les surcouches locales manquantes reçoivent les métadonnées locales. Les métadonnées et les textes existants sont préservés, et chaque décision est ajoutée avec son UUID de révision pour la provenance et l'idempotence.

L'orientation est proposée dans la demande de fusion de traduction normale, et non insérée silencieusement dans la branche par défaut. Le dépôt doit toujours correspondre à l'empreinte de contexte enregistrée ; une modification conflictuelle échoue la publication plutôt que de l'écraser. Les chemins doivent être des documents de localisation relatifs au dépôt, sans traversée ni liens symboliques. Chaque document de contexte est limité à 1 MiB. La fusion de la demande de fusion rend l'orientation un contexte de localisation versionné ordinaire pour les exécutions ultérieures.
