%{
  title: "API mobile et API compagnon",
  summary:
    "Apparence native, profil, activité de traduction, analytiques et conversations Toki privées.",
  category: "Référence",
  subcategory: "APIs",
  order: 4
}
---

Tous les point d'extrémité autres que le catalogue d'apparence native public nécessitent un jeton porteur. La [spécification OpenAPI](/api/openapi.json) décrit les schémas complets. Obtenez les jetons via le [flux OAuth PKCE](/docs/reference/apis/authentication) existant. N'incrustez jamais une clé de fournisseur d'inférence dans un client.

## Autorisation

| Point d'extrémité | Portée du jeton |
|---|---|
| `GET /api/native/themes` | Aucune (métadonnées d'apparence publique) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Les portées de jeton constituent un plafond, non une attribution. Chaque point d'extrémité de projet vérifie également la permission de lecture de projet de l'utilisateur. Un autre `project:read` **jeton** de portée n'est pas requis, mais une appartenance à une organisation avec des autorisations explicites doit permettre à la fois la lecture de projets et la capacité demandée. Les nouvelles appellations incluent ces capacités mobiles ; les appellations explicites existantes ne sont pas automatiquement élargies.

Les projets personnels suivent les règles existantes d'appartenance personnelle-organisation. La visibilité du compte contrôle la lecture publique de projets ; un auditeur authentifié disposant de la portée requise peut lire les activités de traduction et les analyses d'un projet public. Les écritures de Toki nécessitent une appartenance au compte, de sorte que la visibilité publique seule ne consomme pas les crédits d'inférence d'un compte. Les conversations de Toki restent privées à leur utilisateur créant au sein de leur projet, même sur des comptes publics. Les admins de plateforme et de plateforme ne peuvent pas lire la conversation d'un autre utilisateur. Connaître l'UUID d'une conversation ne donne pas accès.

## Apparence native

`GET /api/native/themes` retourne les métadonnées d'apparence à l'échelle de l'instance depuis le serveur Glossia sélectionné, sans authentification ou données utilisateur/projet. Les réponses incluent `Cache-Control: public, max-age=300`. Cela ne modifie pas l'autorisation pour tout point d'extrémité de projet.

La réponse comporte quatre champs obligatoires :

| Champ | Valeur |
|---|---|
| `schema_version` | Entier `1` |
| `revision` | Version du contenu non vide, au plus 128 caractères |
| `default_theme_id` | `"glossia"` |
| `themes` | Tableau contenant le thème Glossia par défaut |

Le thème par défaut comprend `id: "glossia"`, `name: "Glossia"`, une `description` non vide, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, ainsi que les palettes `light` et `dark`. Les rayons sont des pixels logiques numériques. Chaque palette contient tous les neuf champs ci-dessous, exprimées sous forme de couleurs `#RRGGBB` opaques :

| Champ de palette | Clair | Sombre |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

Le catalogue est compilé à partir des tokens de couleur et de rayon canoniques `:root` dans `app/priv/static/assets/styles.css`. La palette sombre utilise des tokens sémantiques natifs uniquement et ne modifie pas le rendu web. La reconstruction suivant un changement de token met à jour le catalogue et sa révision déterminée. La révision couvre le contenu du catalogue, pas les modifications non liées de la feuille de style. Aucune configuration de thème par utilisateur ou en temps d'exécution n'est incluse.

## Profil

`GET /api/me` ne retourne que le profil de l'utilisateur authentifié :

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` peut être `null`. Le handle appartient au compte personnel de l'utilisateur, non à l'organisation sélectionnée. `server_version` est la version de l'application en cours d'exécution.

## Pagination

Les listes de traduction et de conversation acceptent `page` (défaut `1`, portée `1–10000`) et `page_size` (défaut `20`, portée `1–50`). Les valeurs invalides retournent `400` plutôt que de clamer en silence. Les métadonnées utilisent la même forme que les autres listes API Glossia :

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

Les listes reflètent l'état actuel, non un instantané gelé. L'ordre des conversations est de l'article en premier mis à jour, avec UUID en résolveur chronologique déterme par fois.

## Activité de traduction

`GET /api/:handle/projects/:project/translations?page=1` retourne :

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

Les états sont `pending`, `running`, `completed`, `failed`, ou `cancelled`. Le message de commit, la langue source et le résumé peuvent être `null` tant que le travail est en attente ou indisponible. Les résultats sont les derniers en date et restreints au projet adressé.

`GET /api/:handle/projects/:project/translations/:id` retourne `{session: {...}, progress: {...}}`. Le `session` a exactement les champs de session plus `commit_sha` nul, inchangé. `progress` est reconstruit à partir des événements durables en utilisant le même Elixir progress comme le tableau de bord web. C'est un regard exact directement exact de UUID au sein du projet et du compte abordé, indépendant de la pagination ou de l'âge de la session. Les états malformés, manquants et d'adhésion au projet étranger retournent `404` avec `error: "not_found"` ; l'authentification et l'autorisation de projet s'exécutent d'abord (`401`/`403`). Ouvrir cette ressource ne crée jamais une conversation, n'envoie un message ou ne démarre l'inférence. Il fournit **provenance de résumé de session** et du progrès par fichier, ni un traduction segment de texte ou un examen de sortie entré.

### Progress natif en direct

Ouvrez une connexion WebSocket Phoenix persistante à `/native/socket/websocket?vsn=2.0.0` (`wss` sur les serveurs HTTPS). Longpoll est désactivé. Envoyez le jeton d'accès uniquement par l'en-tête de sous-protocole WebSocket, jamais par des paramètres de requête :

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

Le serveur négocie `phoenix`. Rejoindre le sujet `translation:<session UUID>` avec `{"organization":"account-handle","project":"project-handle"}`. La valeur d'organisation est le même handle du compte utilisé par l'API HTTP, y compris les comptes personnels. Le message de réponse de jonction et chaque événement `snapshot` sont portés de la même projection complète que les détails HTTP :

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` est la séquence de progression durable, **non** une version unique de snapshot. Les modifications de statut/publication de session et les live=model-vues peuvent produire un nouveau snapshot avec la même séquence ; remplacer la projection précédente même si `seq` est inchangé. Les états de fichier sont `queued`, `running`, `done`, `failed` et `cancelled`. Les chemins, loc et références de fichiers peuvent être `null` avant d'être connus. Une session intouchée a une séquence zéro, des articles vides, et des zéros de compte. Le résumé couvre **tous** fichiers, même quand les articles sont omises. L'identifiants de glossaire/counts du résumé est l'agrégat du web-réducteur, non les metadonnées fournisseur.

Au plus 500 articles en ordre de prévue-index sont inclus, avec un budget d'article codé combiné de 512 000 bytes. Un article qui ne peut pas s'ommettre est omissions, et `omitted_items` compte chaque ligne exclue par l'une ou l'autre limite. Le contenu traduit brut, texte en flux, pensée, charge privée de fournisseur, et les détails de défauts brut ne sont jamais inclus. Commentaire public modèles-de-vous peut redémarrer après reconnection ou concordance ; les comptes finaux durables et les états de fichiers sont reconstruits. Snapshot natifs complets sont limités à 1 000 000 bytes JSON codés. Si métadonnées de session inchangés ou le résumé complet seul excède cette limite, la jonction échoue avec `{"reason":"payload_too_large"}`/, ou un canal existant découvre `error` avec cette raison et cloisonne, plutôt que d'envoyer un cadre de surdimensionnement ou en silencieusement tronquant la provenance.

Le serveur s'abonne à l'existant cross-node session PubSub **avant** la lecture du préfixe durable, plie la queue live avec déduplication de séquence et fusionne les notifications progression/état/publication en snapshots complets à environ 100 ms. Il n'est pas besoin de polling HTTP par client ni d'état local runner. Toutes les cinq secondes, il renouvelle l'autorisation et reconstruit l'état durable pour réparer les notifications manquantes. Reconnectez et rejoignez après mise au premier plan ou interruption de transport ; la projection de jonction suffit sans rejouer les deltas. Suivez le cycle de vie normal heartbeat Phoenix tant que connecté, et quittez le sujet lorsque vous ne le regardez plus.

Le permis de jeton persisté actuel, l'expiration/révocation, l'utilisateur, `translation:read` d'étendue jeton, les autorisations de politique, la visibilité de projet, et l'association précise compte/projet/session sont vérifiés à la jonction et avant chaque snapshot. L'étendue manquée ou l'autorisation de politique retourne `{"reason":"forbidden"}` ; une ressource manquante retourne `{"reason":"not_found"}` ; l'authentification expirée/révocée retourne `{"reason":"sign_in_required"}`. Après une jonction réussie, le refus émet `access_revoked` avec cette raison et ferme immédiatement le canal sans autre snapshot. Le renouvellement détecte également la révocation sur les canaux inactifs. Sur `sign_in_required`, rafraîchir/réauthentifiez et créez une nouvelle connexion ; sur les autres refus, arrêtez d'afficher le détail protégé. Les WebSockets sont un mécanisme de mise à jour live en premier plan, pas une garantie de livraison pendant que l'application mobile est suspendue.

## Analytics

`GET /api/:handle/projects/:project/analytics?days=30` retourne des métriques de résumé, jusqu'à dix pages principales et la série temporelle du trafic. Un projet vide retourne :

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` par défaut à `30` et doit être un entier de `1` à `365`. La fenêtre de reporting UTC courante se termine au moment de la requête. Il s'agit des mêmes agrégats ClickHouse limités au projet que les tableaux de bord, incluant ses identifiants de visiteurs en rotation quotidienne. Les échecs de stockage retournent `503` avec `error: "analytics_unavailable"`, jamais inventé de métriques zéro.

`traffic.granularity` est `"hour"` pour les fenêtres allant jusqu'à deux jours, `"day"` pour les fenêtres allant jusqu'à quatre-vingt-dix jours et `"month"` autrement. `traffic.points` est chronologique. Chaque point contient un horodatage de début de bucket UTC et des nombres entiers non négatifs :

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Les counts ne contiennent que les événements de la fenêtre de reporting sollicitée, de sorte que le premier et dernier buckets peuvent être partiels. Si des événements existent, les buckets silencieux dans cette fenêtre sont inclus avec des zéros de compte. Si aucun événement n'existe, `points` est vide plutôt qu'une tendance plate synthétique. `unique_visitors` compte les identifiants distincts **dans chaque bucket** ; sommer ces valeurs ne donne pas le total de visiteurs distincts de la période. Utilisez `summary.unique_visitors` pour ce total. Les clients doivent tracer les buckets retournés sans modifier plutôt que de reconstruire une tendance à partir des métriques de résumé.

## Toki conversations

### Create and list

`POST /api/:handle/projects/:project/toki/conversations` accepte un UUID généré par le client :

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Elle retourne `201` avec `{conversation, messages: []}`. Les conversations vides ont le titre `New conversation` et le statut `completed` (inactif, non générateur). Relancer le même UUID pour le même acteur, projet et origine retourne le détail existant sans créer une autre conversation. Réutiliser pour un autre acteur, projet ou origine retourne `409` avec `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retourne `{conversations: [...], meta: {...}}`. Une conversation contient `id`, `title`, `status`, `updated_at`, nullable `error` et nullable `translation_session_id`. Les titres sont dérivés du premier message utilisateur, non d'un deuxième appel modèle.

### Translation origin

La création accepte optionnellement un UUID de session de traduction du même projet :

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

L'origine est immutable ; l'omission et `null` signifient toutes deux pas d'origine. Une tentative doit fournir la même origine, y compris après l'envoi de messages. Vous ne pouvez pas attacher une origine plus tard ni la supprimer avec une tentative. Une origine malformed retourne `422` ; une source manquante ou de projet étranger retourne `404`. La création liée à la source nécessite en outre `translation:read` scope de jeton et permissions de politique actuelles, avec `toki:write` et permissions project-read. Les résumés, métadonnées, rôles et propriétés d'origine fournis par le client sont ignorés. Seule le UUID est persistent ; le serveur résout son contexte autorisé au moment de la réponse.

**Les conversations Source-linked échouent en mode fermé**, pas simplement en masquant l'UUID : sans le scope `translation:read` actuel ou permissions de politique, le détail, la replay d'origine match, l'envoi de message et la replay de message retournent `403`. Une origine mal assortie retourne toujours `409` sans retourner l'historique ou les métadonnées de la source. Les listes omis la conversation Source-linked entière, y compris son titre et sa contribution aux compte de pagination. Cela protège des messages d'assistant plus tôt qui pourraient mentionner la source. Les scopes manquants incluent la défi normal `WWW-Authenticate`. Les conversations sans lien gardent leur comportement d'autorisation Toki existant.

Les sources supprimées ou déplacées échouent également en mode fermé : détail lié à la source, envois et réessais de création rétro-match retournent `404`, et les listes omettent la conversation. L'UUID immutable reste stocké après la suppression de la source afin qu'une tentative ne puisse passer silencieusement non-liée. La référence n'a pas de clé étrangère en cascade ; chaque utilisation vérifie l'existence actuelle de la source et son projet/compte exact. Aucune référence source ne confère accès ou change une voix, glossaire ou contexte partagé.

Créer ou ouvrir une conversation liée à la source ne **pas** envoyer un message ou enqueue inference. La navigation native doit récupérer le détail de traduction en premier ; seule une action utilisateur explicite doit créer la conversation, et une soumission de message explicite séparée démarre un turn. Aucune publication de proposition, examen de discussion partagée ou outils d'écriture agent n'est fourni.

### Send and poll

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` accepte un UUID séparé client-généré **message** :

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La requête persiste le message utilisateur et un job Oban dans une seule transaction de base de données. Elle ne fait pas appel à un modèle. Elle retourne `202` avec le statut conversation `queued` et les messages actuels. Poll `GET /api/:handle/projects/:project/toki/conversations/:id` tant que le statut est `queued` ou `running` ; stop sur `completed` ou `failed`.

Les réponses aux détails ont cette forme :

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

Les messages ont le rôle `user` ou `assistant` et sont chronologiques. Une conversation tient au plus 100 messages, de sorte que le point de récupération de détail retourne son historique borné entier sans une demande de page supplémentaire.

La reprise d'un UUID de message avec un contenu identique ne met jamais une autre inférence en file d'attente, y compris après la complétion ou l'échec. Une reprise finalisée retourne `200`; une reprise en attente retourne `202`. Réutiliser un UUID avec un contenu différent ou dans une autre conversation retourne `409`. Un message différent soumis pendant qu'un tour est actif retourne `409` avec `error: "conversation_busy"`.

### Comportement et limites du modèle

- Chaque message utilisateur est un texte non vide, au plus 8 000 caractères et 32 000 octets UTF-8. Les UUID, types ou contenus invalides retournent `422`.
- Chaque utilisateur peut avoir au plus 100 conversations par projet et cinq en attente/execuées entre les projets. Plus de cinq tours en attente retournent `429`; les limites de conversation/historique retournent `422`.
- Les nouveaux messages sont limités à 30 par heure par utilisateur par serveur, en sus des limites normales de débit API. Les reprises ne consomment pas le quota d'inférence.
- La file dédiée Oban exécute deux tâches simultanément par serveur. Chaque tour nécessite au plus une requête HTTP fournisseur : ReqLLM prépare la requête fournisseur, puis le worker Oban l'exécute synchrones avec redémarrages HTTP et redirigations désactivés après l'attachement du fournisseur. Aucune session Condukt, tâche d'inférence détachée, outils, sous-agents ou chargement d'instructions système de fichiers n'est impliqué. Le fournisseur reçoit un plafond de 2 048 jetons de sortie ; les réponses de l'assistant sont également limitées à 8 000 caractères et 32 000 octets.
- Les attentes de connexion HTTP et de pile sont limitées à cinq secondes et les attentes de réception socket à soixante secondes. Le worker Oban a un délai dur de 90 secondes, y compris les réponses d'écoulement. La terminaison d'un worker termine également son exécution locale d'inférence. La déconnexion ne peut garantir l'annulation d'un calcul déjà accepté par un fournisseur distant, donc les échecs ambigus ne sont jamais redéclenchés automatiquement.
- Le modèle reçoit des métadonnées de projet bornées et au plus trois résumés de traduction récents lorsque le jeton et la participation actuelle autorisent `translation:read`. Les dix derniers extraits de conversation sont bornés indépendamment du stockage. Il n'a aucune capacité d'écriture ou accès général au référentiel, et aucune analyse n'est fournie au modèle.
- Pour une conversation liée à la source, le modèle reçoit en plus la source persistée exacte, même si elle n'est pas récente : UUID, statut, métadonnées de commit, langues, nombre et au plus 1 000 caractères de résumé. Le contexte est étiqueté `provenance: "session_summary"` et le prompt exige de signaler cette limitation de niveau résumé. Aucun texte de segment, fichier de référentiel ou contexte source fourni par le client n'est chargé.
- Les identifiants se résolvent via le modèle génératif et la configuration d'inférence du serveur existant du compte. Les sessions CLI/OAuth interactives ne sont pas utilisées pour Toki. Les identifiants manquants ou non pris en charge produisent le statut `failed` avec `error: "provider_unavailable"`.
- Les défaillances du fournisseur produisent `inference_failed` ; une réponse vide ou trop grande produit `invalid_provider_response`. Les erreurs brutes du fournisseur et secrets ne sont pas retournés. Aucune réponse de l'assistant synthétique n'est insérée en cas d'échec.
- L'accès compte/projet et l'existence de la source, l'association de projet/compte et l'autorisation de traduction sont de nouveau vérifiés avant et après l'inférence. L'accès révoqué ou les scopes en attente insuffisants font échouer le tour avec `not_authorized` ; une source supprimée ou déplacée échoue avec `source_unavailable`. Aucune réponse de l'assistant n'est persistée dans l'un ou l'autre échec.
- Un travail de récupération s'exécute chaque minute et marque les travaux en cours plus anciens que deux minutes, ou les travaux en attente plus anciens que quinze minutes, comme `failed` avec `inference_interrupted`. Cela stabilise les travaux temporisés, terminés et orphelins sans réessayer l'inférence. Un job retardé ne peut récupérer un message expiré ou écraser un tour plus récent. Un utilisateur peut délibérément envoyer un **nouveau** message UUID après un échec.

## Erreurs

`401` signifie que l'authentification a échoué. `403` signifie que le périmètre ou la politique de ressource a refusé l'accès ; les scopes manquants incluent un `WWW-Authenticate` défi. Les projets inconnus et UUID de conversation étrangers/privés retournent `404`. La validation utilise `422`, la pagination utilise `400`, les conflits UUID/busy utilisent `409` et l'épuisement de quota utilise `429`.
