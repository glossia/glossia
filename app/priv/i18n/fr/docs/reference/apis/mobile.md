%{
  title: "API mobile et API compagnon",
  summary:
    "Apparence native, profil, activité de traduction, analyses et conversations Toki privées.",
  category: "Référence",
  subcategory: "APIs",
  order: 4
}
---

Tous les points de terminaison, sauf le catalogue d'apparence native public, nécessitent un jeton Bearer. La [Spécification OpenAPI](/api/openapi.json) décrit les schémas complets. Obtenez des jetons via le flux [OAuth PKCE](/docs/reference/apis/authentication) existant. N'incrustez jamais une clé de fournisseur d'inférence dans un client.

## Autorisation

| Point de terminaison | Portée de jeton |
|---|---|
| `GET /api/native/themes` | Aucun (métadonnées d'apparence public) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Les portées de jeton sont une limite, non une attribution. Chaque point de terminaison de projet vérifie également la permission de lecture du projet de l'utilisateur. Un deuxième `project:read` **jeton** de portée n'est pas requis, mais une affiliation à une organisation avec des permissions explicites doit permettre à la fois les lectures de projet et la capacité requise. Les nouvelles adhésions incluent ces capacités mobiles ; les adhésions explicites existantes ne sont pas automatiquement élargies.

Les projets personnels suivent les règles d'adhésion personnelle-organisation existantes. La visibilité du compte contrôle les lectures de projet public ; un tiers authentifié disposant de la portée requise peut lire l'activité de traduction et les analyses d'un projet public. Les écritures Toki nécessitent une affiliation au compte, donc la visibilité publique seule ne consomme pas les crédits d'inférence d'un compte. Les conversations Toki restent privées pour leur utilisateur créateur à l'intérieur de leur projet, même sur des comptes publics. Les administrateurs d'organisation et de plateforme ne peuvent pas lire la conversation d'un autre utilisateur. La connaissance d'un UUID de conversation ne donne pas accès.

## Apparence native

`GET /api/native/themes` renvoie des métadonnées d'apparence globales à l'instance depuis le serveur Glossia sélectionné, sans authentification ou données utilisateur/projet. Les réponses incluent `Cache-Control: public, max-age=300`. Cela ne change pas l'autorisation pour n'importe quel point de terminaison de projet.

La réponse possède quatre champs obligatoires :

| Champ | Valeur |
|---|---|
| `schema_version` | Entier `1` |
| `revision` | Révision de contenu non vide, au plus 128 caractères |
| `default_theme_id` | `"glossia"` |
| `themes` | Tableau contenant le thème Glossia par défaut |

Le thème par défaut possède `id: "glossia"`, `name: "Glossia"`, une `description` non vide, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` et `light` et `dark` palettes. Les radii sont des pixels logiques numériques. Chaque palette contient les neuf champs ci-dessous, exprimés en `#RRGGBB` couleurs opaques :

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

Le catalogue est compilé à partir des balises de couleur et de rayon canoniques `:root` dans `app/priv/static/assets/styles.css`. La palette sombre utilise des tokens sémantiques natifs uniquement et ne modifie pas le rendu web. La reconstruction après un changement de token met à jour le catalogue et sa révision déterministe. La révision couvre le contenu du catalogue, pas les modifications de feuille de style non connexes. Aucune préférence utilisateur ou configuration de thème temps d'exécution n'est incluse.

## Profil

`GET /api/me` renvoie uniquement le profil de l'utilisateur authentifié :

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

`name` peut être `null`. L'identifiant appartient au compte personnel de l'utilisateur, non à l'organisation sélectionnée. `server_version` est la version de l'application en cours d'exécution.

## Pagination

Les listes de traduction et de conversation acceptent `page` (défaut `1`, plage `1–10000`) et `page_size` (défaut `20`, plage `1–50`). Les valeurs invalides retournent `400` plutôt que de limiter silencieusement. Les métadonnées utilisent la même forme que les autres listes d'API Glossia :

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

Les listes reflètent l'état actuel, pas une instantanée figée. L'ordre des conversations place les plus récemment mises à jour en premier, avec un UUID comme partageur déterministe.

## Activité de traduction

`GET /api/:handle/projects/:project/translations?page=1` renvoie :

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

Les statuts sont `pending`, `running`, `completed`, `failed` ou `cancelled`. Le message de commit, la langue source et le résumé peuvent être `null` pendant que le travail est en attente ou lorsque non disponible. Les résultats sont les plus récents en premier et limités au projet adressé.

`GET /api/:handle/projects/:project/translations/:id` retourne `{session: {...}, progress: {...}}`. Le `session` possède exactement les champs de session de liste plus `commit_sha` nullable, inchangé. `progress` est reconstruit à partir d'événements pérennes en utilisant le même réduiseur de progression Elixir que le tableau de bord web. Il s'agit d'une recherche exacte d'UUID directe au sein du projet et du compte adressés, indépendante de la pagination ou de l'âge de la session. Les IDs malformés, manquants et de projet étranger retournent `404` avec `error: "not_found"` ; l'authentification et l'autorisation du projet continuent tout de même d'exécuter en premier (`401`/`403`). Ouvrir cette ressource ne crée jamais une conversation, n'envoie pas de message, ni ne lance une inférence. Elle fournit **provenance au niveau du résumé de session** et une progression par fichier, non le texte de segment traduit ou une revue du rendu traduit.

### Progression native en direct

Ouvrir un WebSocket Phoenix persistant à `/native/socket/websocket?vsn=2.0.0` (`wss` sur les serveurs HTTPS). Le longpoll est désactivé. Envoyer le jeton d'accès uniquement à travers l'en-tête de sous-protocole WebSocket, jamais à travers les paramètres de requête :

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

Le serveur négocie `phoenix`. Rejoindre le sujet `translation:<session UUID>` avec `{"organization":"account-handle","project":"project-handle"}`. La valeur d'organisation est le même identifiant de compte utilisé par l'API HTTP, y compris les comptes personnels. Le message de retour de jonction et chaque événement `snapshot` portent la même projection complète que les détails HTTP :

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

`seq` est la séquence de progression pérenne, **non** une version d'instantané unique. Les changements de statut/de publication de session et les comptes d'appels de modèle en direct peuvent produire un nouvel instantané avec la même séquence ; remplacer la projection précédente même si `seq` est inchangé. Les statuts par fichier sont `queued`, `running`, `done`, `failed` et `cancelled`. Les chemins, les locales et les références de fichier peuvent être `null` avant d'être connus. Une session intacte a une séquence zéro, des éléments vides et des comptes zéro. Le récapitulatif couvre **tous** les fichiers, même si des éléments sont omis. Les identifiants/comptes de glossaire du récapitulatif sont l'agrégat du réduiseur web, pas des métadonnées du fournisseur.

Au maximum, 500 éléments dans l'ordre d'indexation prévue sont inclus, avec un budget combiné d'éléments codés de 512 000 octets. Un élément qui ne peut pas s'insérer est omis, et `omitted_items` compte chaque ligne exclue par l'une ou l'autre limite. La sortie traduite brute, le texte de flux, la réflexion, les charges de fournisseur privées et les détails d'échec bruts ne sont jamais inclus. Les comptes d'appels de modèle publics en direct peuvent être réinitialisés après la reconnexion ou la réconciliation ; les comptages définitifs pérennes et les états de fichier sont reconstruits. Les instantanés natifs complets sont limités à 1 000 000 d'octets JSON codés. Si les métadonnées de session inchangées ou le récapitulatif complet seul dépassent cette limite, l'adhésion échoue avec `{"reason":"payload_too_large"}` , ou un canal existant reçoit `error` avec cette raison et se ferme, plutôt que d'envoyer un cadre de taille excessive ou de troncer silencieusement la provenance.

Le serveur s'abonne à PubSub de session inter-nœud existant **avant** la lecture du préfixe pérenne, replie la queue live avec déduplication de séquence, et fusionne les notifications de progression/statut/de publication en instantanés complets à approximativement 100 ms. Aucun HTTP polling par client ou état local runner n'est nécessaire. Toutes les cinq secondes, l'authentification est renouvelée et l'état pérenne reconstruit pour réparer les notifications manquantes. Reconnectez-vous et rejoignez après foregrounding ou l'interruption du transport ; la projection de jonction suffit sans rejou des deltas. Suivez le cycle de vie normal d'heartbeat Phoenix lors de la connexion, et quittez le sujet lorsque vous ne le regardez plus.

L'attribution de jeton persistante actuelle, expiration/révocation, utilisateur, `translation:read` champ de jeton, permissions de politique, visibilité de projet, et association exacte compte/projet/session sont vérifiées à la jonction et avant chaque instantané. Champ manquant ou permission de politique retourne `{"reason":"forbidden"}` ; une ressource manquante retourne `{"reason":"not_found"}` ; authentification expirée/révocée retourne `{"reason":"sign_in_required"}`. Après une jonction réussie, la démission émet `access_revoked` avec cette raison et ferme immédiatement le canal sans autre instantané. Le renouvellement détecte également la révocation sur les canaux inactifs. Sur `sign_in_required`, rafraîchir/re-authentifier et créer une nouvelle connexion ; sur autres déniions, arrêtez d'afficher le détail protégé. WebSockets sont un mécanisme de mise à jour live en avant-plan, non une garantie de livraison tandis que l'app mobile est suspendu.

## Analytics

`GET /api/:handle/projects/:project/analytics?days=30` retourne des métriques de résumé, jusqu'à dix pages les plus haut de page, et la série chronologique du trafic. Un projet vide retourne :

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

`days` est par défaut à `30` et doit être un entier de `1` à `365`. La fenêtre de rapport UTC glissante se termine au moment de la requête. Ce sont les mêmes agrégats ClickHouse de portée projet que le tableau de bord, incluant ses identifiants de visiteur rotatifs journaliers. Les échecs de stockage retournent `503` avec `error: "analytics_unavailable"`, jamais inventé des zéros de métriques.

`traffic.granularity` est `"hour"` pour les fenêtres jusqu'à deux jours, `"day"` pour les fenêtres jusqu'à quatre-vingt-dix jours, et `"month"` autre chose. `traffic.points` est chronologique. Chaque point contient un timestamp UTC bucket-de-départ et des comptes d'entier non-négatifs :

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

Les comptes incluent uniquement les événements dans la fenêtre de rapport demandée, donc les premiers et derniers buckets peuvent être partiels. Quand des événements existent, les buckets silencieux dans cette fenêtre sont inclus avec zéro de comptes. Quand aucun événement n'existe, `points` est vide plutôt qu'une tendance plate synthétique. `unique_visitors` compte des identifiants distincts **dans chaque bucket** ; sommer ces valeurs ne donne pas la période de nombre de visiteur distinct. Utilisez `summary.unique_visitors` pour ce total. Les clients devraient tracer les buckets retournés inchangés plutôt que de reconstruire une tendance des métriques de résumé.

## Conversations Toki

### Créer et lister

`POST /api/:handle/projects/:project/toki/conversations` accepte un UUID généré client :

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Il retourne `201` avec `{conversation, messages: []}`. Les conversations vides ont une titre `New conversation` et status `completed` (entrepaux, ne générant pas). Rejouant le même UUID pour le même acteur, projet, et origine retourne le détail existant sans créer une autre conversation. Le réutilisant pour un autre acteur, projet, ou origine retourne `409` avec `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retourne `{conversations: [...], meta: {...}}`. Une conversation contient `id`, `title`, `status`, `updated_at`, unale `error`, et alable `translation_session_id`. Les titres sont dérivés du premier message utilisateur, pas depuis un second appel de modèle.

### Origine de traduction

La création accepte optionnellement un UUID de session de traduction du même projet :

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

L'origine est immuable ; l'omission et `null` signifient toutes les deux aucune origine. Un réessai doit fournir la même origine, incluant après envoyer des messages. Vous ne pouvez pas attacher une origine plus tard ou enlever avec un réessai. Une origine malformée retourne `422` ; une origine manquante ou d'un objet étranger retourne `404`. La création reliée-sourcine nécessite additionally `translation:read` champ de jeton et permission de politique actuelle, avec `toki:write` et permission-de-porte-projet. Les résumés de métadonnées, rôles, et propriété sources-fournis-client sont ignorés. Uniquement l'UUID est persisté ; le serveur résout son contexte autorisé au moment de la réponse.

**Les conversations liées à la source échouent**, plutôt que de simplement masquer l'UUID : sans le périmètre actuel `translation:read` ou autorisation de politique, le détail, la création de réponse à l'origine correspondante, l'envoi de message et le rejeu de message retournent `403`. Une origine incorrecte retourne toujours `409` sans retourner l'historique ou les métadonnées de source. Les listes omettent l'intégralité de la conversation liée à la source, y compris son titre et sa contribution aux comptes de pagination. Ceci protège les messages antérieurs de l'assistant qui pourraient mentionner la source. Les périmètres manquants incluent la normale `WWW-Authenticate` challenge. Les conversations non liées conservent leur comportement d'autorisation Toki seul.

Sources supprimées ou déplacées aussi échouent fermées : détail relié-source, envoie, et création relayes de création correspondent retournent `404`, et les listes omettent la conversation. L'UUID immuable reste stocké après la suppression de source si un réessay ne peut pas silencieusement devenir relié. La référence n'a pas foreign clé clé ; chaque usage vérifie l'existence actuelle source et son compte/projet exact. Aucun lien de source confère un accès ou change une voie, glossaire, ou contexte partagé.

Créer ou ouvrir une conversation reliée source ne **pas** envoier un message ou enfile inference. Navigation native devrait chercher détail de traduction d'abord ; seulement une action utilisateur explicite devrait créer la conversation, et une soumission de message explicite séparée commence un tour. Aucune publication de proposition, discussion partagée revue, ou outils d'agent écrit n'est fourni.

### Envoyer et voter

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` accepte un UUID de message distinct généré par le client : **message**

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La requête persiste le message utilisateur et un job Oban dans une seule transaction base de données. Cela ne connaît pas un modèle. Il retourne `202` avec statut de conversation `queued` et les messages existants. Voter `GET /api/:handle/projects/:project/toki/conversations/:id` tandis que status est `queued` ou `running` ; et `completed` ou `failed`.

Les réponses de détail ont cette forme :

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

Les messages ont rôle `user` ou `assistant` et sont chronologiques. Une conversation contient au plus 100 messages, donc l'endpoint de détail retourne son historique entier borné sans demande de page additionnelle.

Rejouer un UUID de message avec un contenu identique n'enfile jamais une autre inference, y compris après réussite ou échec. Un replay réglé retourne `200`; un replay en attente retourne `202`. Réutiliser un UUID avec un contenu différent ou dans une autre conversation retourne `409`. Un message différent soumis pendant qu'un tour est actif retourne `409` avec `error: "conversation_busy"`.

### Comportement et limites du modèle

- Chaque message utilisateur est du texte non vide, au plus 8 000 caractères et 32 000 octets UTF-8. Les UUID, types ou contenus invalides retournent `422`.
- Chaque utilisateur peut tenir au plus 100 conversations par projet et cinq conversations en file/en cours parmi les projets. Plus de cinq tours en attente retourne `429`; les limites conversation/historique retournent `422`.
- Les nouveaux messages sont limités à 30 par heure par utilisateur par serveur, en plus des limites normales de taux d'API. Les rejeux ne consomment pas de quota d'inference.
- La file oban dédiée exécute deux tâches simultanément par serveur. Chaque tour réalise au plus une requête HTTP du fournisseur : ReqLLM prépare la requête du fournisseur, puis le travailleur oban l'exécute synchroniquement avec des redémarrages HTTP et des redirections désactivées après attachement du fournisseur. Aucune session Condukt, tâche d'inference détachée, outils, sous-agents ou chargement d'instructions système n'est impliqué. Le fournisseur reçoit un plafond de 2 048 tokens de sortie ; les réponses de l'assistant sont également limitées à 8 000 caractères et 32 000 octets.
- Les attentes de connexion HTTP et de pool sont limitées à cinq secondes et les attentes de réception de socket à soixante secondes. Le travailleur oban a un délai horaire strict de quatre-vingt-dix secondes, incluant les réponses filtrées. La terminaison du travailleur termine également son exécution locale d'inference. La déconnexion ne peut pas garantir l'annulation d'un calcul déjà accepté par un fournisseur distant, donc les échecs ambigus ne sont jamais redémarrés automatiquement.
- Le modèle reçoit des métadonnées de projet bornées et au plus trois récents résumés de traduction lorsque le jeton et la participation actuelle permettent `translation:read`. Les dix derniers extraits de conversation sont bornés indépendamment du stockage. Il n'a pas de capacités d'écriture ou d'accès généralisé au référentiel, et aucune analyse n'est fournie au modèle.
- Pour une conversation reliée source, le modèle reçoit en outre la source persistée exacte, même si elle n'est pas récente : UUID, statut, métadonnées de commit, langues, compteur, et au plus 1 000 caractères de résumé. Le contexte est étiqueté `provenance: "session_summary"` et le prompt exige de rapporter cette limitation de niveau résumé. Aucun texte de segment, fichiers du référentiel ou contexte source fourni par le client n'est chargé.
- Les identifiants se résolvent par le modèle génératif existant du compte et la configuration serveur d'inference. Les sessions CLI/OAuth interactives ne sont pas utilisées pour Toki. Des identifiants manquants ou non pris en charge produisent un statut `failed` avec `error: "provider_unavailable"`.
- Les échech du fournisseur produisent `inference_failed` ; une sortie vide ou trop grande produit `invalid_provider_response`. Les erreurs brutes du fournisseur et les secrets ne sont pas retournés. Aucune réponse de l'assistant synthétique n'est insérée en cas d'échec.
- L'accès compte/projet et l'existence de la source, l'association compte/projet et l'autorisation de traduction sont vérifiés de nouveau avant et après l'inference. L'accès révoqué ou les portées en attente insuffisantes échouent le tour avec `not_authorized` ; une source supprimée ou déplacée échoue avec `source_unavailable`. Aucune réponse de l'assistant n'est stockée en cas de l'un ou l'autre échec.
- Un job de récupération s'exécute toutes les minutes et marque les travaux en cours plus anciens de deux minutes, ou les travaux en attente plus anciens de quinze minutes, en `failed` avec `inference_interrupted`. Cela règle les jobs déchu, terminés et orphelins sans redémarrage d'inference. Un job décalé ne peut pas réclamer un message expiré ou écraser un tour plus récent. Un utilisateur peut intentionnellement envoyer un **nouveau** UUID de message après un échec.

## Erreurs

`401` signifie que l'authentification a échoué. `403` signifie que la portée ou la politique de ressources a refusé l'accès ; les portées manquantes incluent un `WWW-Authenticate` challenge. Les projets inconnus et les UUID de conversation étrangers/privés retournent `404`. La validation utilise `422`, la pagination utilise `400`, les conflits UUID/busy utilisent `409` et l'épuisement du quota utilise `429`.
