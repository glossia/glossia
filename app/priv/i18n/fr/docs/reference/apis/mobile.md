%{
  title: "API mobile et API compagnon",
  summary:
    "Apparence native, profil, activité de traduction, analyses et conversations Toki privées.",
  category: "Référence",
  subcategory: "APIs",
  order: 4
}
---

Tous les endpoints autres que le catalogue d'apparence native public nécessitent un jeton Bearer. La [Spécification OpenAPI](/api/openapi.json) décrit les schémas complets. Obtenez les jetons via le flux [OAuth PKCE](/docs/reference/apis/authentication) existant. Ne jamais intégrer une clé de fournisseur d'inférence dans un client.

## Autorisation

| Endpoint | Portée de jeton |
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

Les portées du jeton constituent un plafond, pas une autorisation. Chaque endpoint de projet vérifie également l'autorisation de lecture de projet de l'utilisateur. Une seconde `project:read` **jeton** est pas obligatoire, mais une adhésion d'organisation avec des permissions explicites doit permettre à la fois la lecture de projet et la capacité demandée. Les nouvelles adhésions incluent ces capacités mobiles ; les adhésions explicites existantes ne sont pas automatiquement élargies.

Les projets personnels suivent les règles d'adhésion personnelle-organisation existantes. La visibilité du compte contrôle les lectures de projet publics ; un membre authentifié avec la portée requise peut lire l'activité de traduction et les analyses d'un projet public. Les écritures Toki requièrent une adhésion au compte, donc la visibilité publique seule ne décerne pas les crédits d'inférence d'un compte. Les conversations Toki restent privées à leur utilisateur créateur au sein de leur projet, même sur les comptes publics. Les administrateurs d'organisation et de plateformne ne peuvent pas lire la conversation d'un autre utilisateur. Connaître le UUID d'une conversation n'accorde pas l'accès.

## Apparence native

`GET /api/native/themes` retourne les métadonnées d'apparence sur l'instance sélectionnées chez le serveur Glossia, sans authentification ou données utilisateur/projet. Les réponses incluent `Cache-Control: public, max-age=300`. Cela ne change pas l'autorisation pour n'importe quel endpoint de projet.

La réponse comporte quatre champs requis :

| Champ | Valeur |
|---|---|
| `schema_version` | Entier `1` |
| `revision` | Révision de contenu non vide, au maximum 128 caractères |
| `default_theme_id` | `"glossia"` |
| `themes` | Tableau contenant le thème Glossia par défaut |

Le thème par défaut dispose de `id: "glossia"`, `name: "Glossia"`, une `description` non vide, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, et `light` et `dark` palettes. Les rayons sont des pixels logiques numériques. Chaque palette contient les neuf champs inférieurs, exprimés comme des couleurs `#RRGGBB` opaques :

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

Le catalogue est compilé à partir des jetons couleur et rayon canoniques `:root` dans `app/priv/static/assets/styles.css`. La palette sombre utilise des jetons sémantiques natifs uniquement et ne change pas le rendu web. Recharger après un changement de jeton met à jour le catalogue et sa révision déterministe. La révision couvre le contenu du catalogue, pas les modifications de la feuille de style non liées. Aucune préférence utilisateur ou configuration de thème en temps réel n'est incluse.

## Profil

`GET /api/me` retourne uniquement le profil de l'utilisateur authentifié :

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

`name` peut être `null`. L'identifiant appartient au compte personnel de l'utilisateur, pas à l'organisation sélectionnée. `server_version` est la version de l'application en cours d'exécution.

## Pagination

Les listes de traduction et de conversation acceptent `page` (par défaut `1`, plage `1–10000`) et `page_size` (par défaut `20`, plage `1–50`). Les valeurs invalides retournent `400` au lieu de limitation silencieuse. Les métadonnées utilisent la même forme que les autres listes API Glossia :

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

Les listes reflètent l'état actuel, pas une capture figée. L'ordre des conversations met en premier le plus récemment mis à jour, avec le UUID en tant que critique de départage déterministe.

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

Les états sont `pending`, `running`, `completed`, `failed`, ou `cancelled`. Le message de commit, le langage source et le résumé peuvent être `null` tant que le travail est en attente ou indisponible. Les résultats sont les plus récents d'abord et restreints au projet adressé.

`GET /api/:handle/projects/:project/translations/:id` retourne `{session: {...}}` avec exactement les champs session de liste plus `commit_sha` optionnel. C'est une recherche directe et exacte du UUID au sein du projet et du compte adressé, indépendant de la pagination ou de l'âge de la session. Identifiants malformés, manquants et de projet étranger retournent `404` avec `error: "not_found"` ; l'authentification et l'autorisation de projet s'exécutent d'abord (`401`/`403`). L'ouverture de cette ressource ne crée jamais une conversation, n'envoie pas un message, ni ne démarre une inférence. Elle fournit **provenance au niveau récapitulatif de session**, pas du texte de segment de traduction ou d'un examen de la sortie de traduction.

## Analyses

`GET /api/:handle/projects/:project/analytics?days=30` retourne :

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

`days` par défaut à `30` et doit être un entier de `1` à `365`. La fenêtre de rapport UTC en glissement se termine à l'heure de la demande. Ce sont les mêmes agrégats ClickHouse par projet que le tableau de bord, y compris ses identifiants de visiteur en rotation quotidienne. La liste top-pages contient au plus dix entrées. Les jeux de données vides retournent des zéros de compte, des chaînes de valeur vide et une liste de page vide. Les échecs de stockage retournent `503` avec `error: "analytics_unavailable"`, jamais des métriques zéro inventées.

## Conversations Toki

### Créer et lister

`POST /api/:handle/projects/:project/toki/conversations` accepte un UUID généré par le client :

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

Il retourne `201` avec `{conversation, messages: []}`. Les conversations vides ont un titre `New conversation` et un statut `completed` (inactif, pas en génération). La relance du même UUID pour le même acteur, projet et origine retourne le détail existant sans créer une autre conversation. Le réutiliser pour un autre acteur, projet ou origine retourne `409` avec `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` retourne `{conversations: [...], meta: {...}}`. Une conversation contient `id`, `title`, `status`, `updated_at`, `error` nultable, et `translation_session_id` nultable. Les titres sont dérivés du premier message utilisateur, pas d'un deuxième appel de modèle.

### Origine de traduction

La création accepte optionnellement un UUID de session de traduction du même projet :

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

L'origine est immuable ; l'omission et `null` signifient toutes deux qu'il n'y a pas d'origine. Une tentative de reprise doit fournir la même origine, y compris après avoir envoyé des messages. Vous ne pouvez pas attacher une origine plus tard ou la supprimer avec une tentative de reprise. Une origine malformée retourne `422` ; une source manquante ou d'un projet étranger retourne `404`. La création liée à une source nécessite en outre la portée de jeton `translation:read` et l'autorisation d'application courante, ainsi que `toki:write` et l'autorisation project-read. Les résumés de source fournis par le client, la métadonnées, les rôles et la propriété sont ignorés. Seul le UUID est persisté ; le serveur résout son contexte autorisé au moment de la réponse.

**Les conversations liées aux sources échouent en bloc**, et non en masquant seulement le UUID : sans portée de jeton `translation:read` actuelle ou autorisation d'application, le détail, la relance de création d'origine correspondante, l'envoi de message et la relance de message retournent `403`. Un origine non correspondante retourne toujours `409` sans retourner l'historique ou les métadonnées de source. Les listes omettent la conversation liée à la source intégralité, y compris son titre et sa contribution aux comptes de pagination. Cela protège les messages d'assistant antérieurs qui pourraient mentionner la source. Les portées manquantes incluent le défi `WWW-Authenticate` normal. Les conversations non liées conservent leur comportement d'autorisation Toki uniquement existant.

Les sources supprimées ou déplacées échouent également en bloc : les détails liés aux sources, les envois et les tentatives de reprise de création correspondante retournent `404`, et les listes omettent la conversation. Le UUID immuable reste stocké après la suppression de source de sorte qu'une tentative de reprise ne puisse pas devenir unlinked silencieusement. La référence n'a pas de clé étrangère en cascade ; chaque utilisation vérifie l'existence actuelle de la source et son projet/compte exact. Aucune référence à une source ne confère d'accès ou ne modifie une voix, un glossaire ou un contexte partagé.

La création ou l'ouverture d'une conversation liée à une source ne **présente pas** l'envoi de message ni le file d'attente d'inférence. La navigation native doit d'abord récupérer le détail de traduction ; seul une action explicite de l'utilisateur doit créer la conversation, et une soumission de message explicite séparée démarre un tour. Aucun outil d'écriture d'agent de publication, examen de discussion partagée ou agent n'est fourni.

### Envoyer et interroger

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` accepte un UUID de message **separately généré par le client** :

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

La demande persiste le message utilisateur et un job Oban dans une seule transaction de base de données. Elle n'appelle pas un modèle. Elle retourne `202` avec l'état de conversation `queued` et les messages actuels. Interrogez `GET /api/:handle/projects/:project/toki/conversations/:id` pendant que l'état est `queued` ou `running` ; arrêtez sur `completed` ou `failed`.

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

Les messages ont un rôle `user` ou `assistant` et sont chronologiques. Une conversation contient au plus 100 messages, donc l'endpoint de détail retourne son historique borné complet sans une autre demande de page.

La relance d'UUID de message avec contenu identique n'enfile jamais une autre inférence, y compris après complétion ou échec. Une relance fixée retourne `200` ; une relance dans l'attente retourne `202`. Le réutilisation d'un UUID avec contenu différent ou dans une autre conversation retourne `409`. Un message différent soumis pendant qu'un tour est actif retourne `409` avec `error: "conversation_busy"`.

### Comportement et limites du modèle

- Chaque message utilisateur est un texte non vide, au plus 8 000 caractères et 32 000 octets UTF-8. Les UUID, types ou contenu invalides retournent `422`.
- Chaque utilisateur peut détenir au plus 100 conversations par projet et cinq conversations en file/running à travers les projets. Plus de cinq tours en attente retournent `429` ; les limites conversation/historique retournent `422`.
- Les nouveaux messages sont limités à 30 par heure par utilisateur par serveur, en plus des limites de débit API normales. Les replays n'ont pas de consommer la quota d'inférence.
- La file d'attente Oban dédiée exécute deux jobs simultanément par serveur. Chaque tour effectue au plus une requête HTTP fournisseur : ReqLLM prépare la requête fournisseur, puis le worker Oban l'exécute synchrones avec reprises HTTP et redirections désactivées après attachement fournisseur. Aucune session Condukt, tâche d'inférence détachée, outils, sous-agents ou chargement d'instructions système n'est impliqué. Le fournisseur reçoit un plafond de 2 048 jéttons de sortie ; les réponses d'assistant sont aussi limitées à 8 000 caractères et 32 000 octets.
- Les attentes de connexion HTTP et de pool sont limitées à cinq secondes et les attentes de réception socket à soixante secondes. Le worker Oban dispose d'une deadline horaire murale dure de quatre-vingt-dix secondes, y compris les réponses en file细小的. La termination du worker termine aussi son exécution d'inférence locale. Déconnecter ne peut garantir l'annulation du calcul déjà accepté par un fournisseur distant, donc les échecs ambigus ne sont jamais repris automatiquement.
- Le modèle reçoit un métadonnées de projet bornées et au plus trois résumés de traduction récents lorsque le jeton et l'affiliation actuelle permettent `translation:read`. Les dix derniers extraits de conversation sont bornés indépendamment du stockage. Il n'a pas de capacités d'écriture ou accès de dépôt générale, et aucune analyses ne sont fournies au modèle.
- Pour une conversation liée à une source, le modèle reçoit en outre la source persistée exacte, même si elle n'est pas récente : UUID, statut, métadonnées de commit, langues, compteur, et au plus 1 000 caractères de résumé. Le contexte est étiqueté `provenance: "session_summary"`, et la demande exige de rapporter cette limitation de niveau-résumé. Aucun texte de segment, fichiers de dépôt ou contexte de source fourni par le client n'est chargé.
- Les identifiants se résolvent par le modèle génératif et la configuration d'inférence de serveur existants du compte. Les sessions interactive CLI/OAuth ne sont pas utilisées pour Toki. Les identifiants manquants ou non supports produisent le statut `failed` avec `error: "provider_unavailable"`.
- Les échecs de fournisseur produisent `inference_failed` ; une sortie vide ou trop grande produit `invalid_provider_response`. Les erreurs brutes de fournisseur et secrets ne sont pas retournées. Aucune réponse d'assistant synthétique n'est insérée sur échec.
- L'accès projet/compte et l'existence de source, l'association projet/compte, et l'autorisation de traduction sont vérifiés à nouveau avant et après inférence. L'accès révoqué ou les portées en file insuffisantes échouent le tour avec `not_authorized` ; une source supprimée ou déplacée échoue avec `source_unavailable`. Aucune réponse d'assistant n'est persistée sur l'un ou l'autre échec.
- Une tâche de récupération s'exécute toutes les minutes et marque les travaux en cours âgés de plus de deux minutes, ou les travaux en file d'attente âgés de plus de quinze minutes, en `failed` avec `inference_interrupted`. Cela règle les tâches expirées, terminées et orphelines sans relancer l'inférence. Une tâche retardée ne peut pas revendiquer un message expiré ou remplacer un tour plus récent. Un utilisateur peut intentionnellement envoyer un **nouveau** UUID de message après un échec.

## Erreurs

`401` signifie une échec d'authentification. `403` signifie que la portée ou la politique de ressource a refusé l'accès ; les portées manquantes incluent un `WWW-Authenticate` défi. Les projets inconnus et les UUID de conversations étrangers ou privés retournent `404`. La validation utilise `422`, la pagination utilise `400`, les conflits d'identité/occupation utilisent `409` et l'épuisement du quota utilise `429`.
