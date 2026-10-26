%{
  title: "Notifications push natives",
  summary:
    "Configuration du fournisseur, enregistrement d'appareils opt-in, politique de livraison et payloads natives.",
  category: "Référence",
  section: "platform",
  order: 30
}
---

## Transport et identifiants

Glossia envoie directement aux APNs pour iOS et à FCM HTTP v1 pour Android. PostgreSQL stocke les inscriptions ; Oban met les commandes d'envoi en file d'attente. Aucun service de messagerie ou SDK Firebase iOS n'est nécessaire. L'acceptation par un fournisseur n'est ni un accusé de réception d'envoi ni un accusé de lecture. Les défaillances réseau ambiguës peuvent produire des alertes en doublon.

Les secrets de fournisseur appartiennent uniquement au système de gestion des secrets existant du serveur. Ne jamais mettre les clés privées APNs ou les JSON de compte Firebase dans les builds mobiles, les fichiers du dépôt, les journaux ou la configuration visible par le client. Les identifiants d'application Android publics de Firebase ne sont pas des identifiants de compte de service.

| Variable d'environnement | Signification |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | ID d'équipe Apple à dix caractères. |
| `GLOSSIA_APNS_KEY_ID` | ID de clé de signature Apple à dix caractères. |
| `GLOSSIA_APNS_PRIVATE_KEY` | Clé privée P-256 de signature encodée PEM, en conservant les retours à la ligne. |
| `GLOSSIA_APNS_TOPIC` | L'identifiant de paquet exact de l'application iOS signée. Les clients ne peuvent pas le choisir. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (par défaut), `sandbox` ou explicitement `both` pour une clé qui prend en charge les deux. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | JSON de compte de service Firebase Android avec `type`, `project_id`, `client_email` et RSA `private_key`. |

L'absence de crédentiels APNs désactive uniquement iOS. L'absence de crédentiels FCM désactive uniquement Android. Les fournisseurs configurés partiellement ou mal formatés échouent à l'analyse de configuration avec une erreur exée des secrets. L'environnement APNs est vérifié à l'inscription et lors de la livraison ; tirent-en l'origine du profil de provisionnement signé et non des hypothèses de mode de compilation. APNs utilise un pool de Finch dédié uniquement HTTP/2 et authentification ES256. FCM échange une assertion de compte de service RS256 au point d'accès OAuth fixe de Google, puis utilise son point d'accès fixe HTTP v1. Les réachèvements et les redémarrages du client HTTP sont désactivés.

## API d'inscription

Toutes les routes nécessitent un jeton d'accès OAuth de porteur émis au client PKCE public dynamique par installation de l'application native. Sa seule URI de redirection doit être `glossia://oauth/callback` ; refresh et revoke doivent être publics, sans méthodes d'authentification de client secret. Le client Expo générique partagé, les jetons de compte, les sessions navigateur et d'autres clients OAuth ne sont pas des identités d'installation et ne peuvent pas inscrire les appareils. Ceci vérifie la forme du client, pas l'attestation de dispositif.

`PUT /api/me/push-devices/:installation_id` accepte exactement :

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id` : UUID généré par le client. Il est également l'identifiant `registration_id` retourné et livré.
- `platform` : `ios` ou `android`.
- `environment` : `sandbox` ou `production` pour iOS ; uniquement `production` pour Android.
- Jetons iOS : 32–512 caractères hexadécimaux, longueur paire, normalisés en minuscules.
- Jetons Android : 16–4096 caractères ASCII imprimables non espace.
- Success put : `{"registered":true,"registration_id":"<installation UUID>"}`.
- Les champs inconnus, y compris les sélecteurs de propriétaire, le sujet, l'hôte et les URLs de fournisseur, sont rejetés.

`DELETE /api/me/push-devices/:installation_id` retourne `{"deleted":true}` idempotentement. Les IDs inconnus deviennent des tombstones, donc un put en retard ne peut pas ressusciter une installation après déconnexion. Une installation inconnue d'utilisateur différent n'est modifiée à jamais. Le même client OAuth natif peut retirer l'installation de son utilisateur précédent pendant la récupération hors connexion de déconnexion, mais la propriété ne se déplace jamais. Tournez vers un UUID d'installation neuf après `409 installation_retired`.

`GET /api/me/push-devices/capabilities` retourne `{"ios":true,"android":false}` selon les fournisseurs configurés ; il a le même requirement d'authentification. Une vraie capacité iOS ne surcharge pas les restrictions d'environnement APNs.

Les réponses sont `no-store`. Les mutations sont limitées à 120 requêtes par utilisateur par heure, en addition à la limite API. L'authentification de porteur manquante/invalidse retourne 401 ; les crédentiels non natifs retournent 403 ; les données de dispositif invalides retournent 400 ; les installations retirées/conflit retournent 409 ; les fournisseurs indisponibles retournent 503. Le nettoyage reste disponible quand un fournisseur est désactivé.

## Intentions de livraison

Les appelants internes utilisent l'API fixe après leur transaction source s'engage :

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

Le kind peut aussi être l'atome correspondant. Le retournement est `{:ok, queued_count}` ou `{:error, :invalid_notification}`. Il n'y a pas d'API publique d'envoi de destinataire arbitraire, de texte de notification personnalisé, de redémarrage d'inférence, ou d'opt-in implicite.

`toki_completed` nécessite le message utilisateur **terminé** exact et sa réponse de assistant terminée. Dans les conversations privées le destinataire doit posséder l'historique ; dans les conversations de but partagées elles doivent toujours être un participant fluide invité éligible et le but doit être ouvert. Il vérifie l'accès actuel Toki/projet et, pour les conversations liées à source, l'accès actuel lecture de traduction et l'existence de source. Un message différent terminé ou un ID de message de assistant n'est pas un substitut.

`linguistic_input_needed` nécessite le but ouvert identifié sur la session de traduction spécifiée et un participant fluide invité éligible. Une source de session seule reste accepté pour compatibilité et résout un but ouvert éligible. Les recherches sur une autre session n'ont pas le droit. Tous les liens d'équipes autorisés correspondent rejoignent la même conversation de Toki ; livraison vérifie indépendamment fluence actuelle, accès Toki/traduction/projet, et adhésion.

Il y a au plus dix inscriptions actives par utilisateur. Les jetons sont chiffrés avec le cloak répertoire existant et indexés par une digeste SHA-256. Le mouvement de jeton retire l'ancienne inscription, et l'invalidation de fournisseur compare la digeste/physique tentée avant d'effacer quoi que ce soit. Les timestamps last-invalid APNs ne retirent pas les inscriptions rafraîchies après ce timestamp.

Les missions de livraison contiennent seulement les IDs, le kind, les IDs de source et l'expiration. Chaque tentative rerevère l'inscription, le propriétaire, l'autorisation de refresh actuelle persistante native OAuth et les scopes, la source, l'adhésion et l'expiration. Il vérifie à nouveau après l'acquisition de crédentiels de fournisseur, immédiatement avant transport. L'expiration de jeton d'accès seule ne termine pas une session de refresh encore valide. La révocation, expiration de refresh, l'accès manquant de source, la déconnexion, ou les recherches résolues annulent livraison.

Les deux types expirent après une heure. Il y a au plus cinq tentatives de fournisseur, y compris les pauses dues à la pression de fournisseur. Retry-After est respecté uniquement dans le temps de vie de la notification. Aucun corps de réponse ou jeton n'est retourné comme erreur de mission. Rafraîchir les inscriptions au premier plan ; les inscriptions non rafraîchies pendant 60 jours sont retirées. Le worker horaire de nettoyage scanne un lot rotatif borné de 1 000 lignes et supprime les jetons pour les sessions obsolètes ou terminées. Les tombstones ne conservent que les IDs d'installation/client, la plateforme/environnement, et les timestamps lifecycle indéfiniment pour bloquer les demandes en retard ; les lignes retirées n'ont pas d'utilisateur, de jeton ou de digest. La suppression du compte coupe la référence utilisateur, empêche toute livraison immédiatement, et le worker de nettoyage nettoie le jeton conservé.

Les crédentiels du fournisseur utilisent un cache Cachex borné, conscient de l'expiration. La rotation de clé modifie l'identité du cache. Les JWT APNs sont réutilisés pour 50 minutes ; les crédentiels FCM expirent cinq minutes avant l'expiration du fournisseur (au plus 50 minutes). Les échecs ne sont pas sauvegardés.

## Version du payload 1

APNs inclut l'alerte générique **Glossia / Vous avez une mise à jour dans Glossia.** FCM envoie uniquement des messages de données avec le même `title` et `body` pour le rendu local. Aucun n'inclut de prompts privés, de réponses, de questions, d'extrait de source ou de titres de projet. Les champs de routage sont des chaînes :

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

Les deux types de notifications ouvrent `/org/project/toki/CONVERSATION_UUID` ; les demandes d'aide linguistique ouvrent leur fil de but partagé. Le `server` est l'origine HTTPS de l'endpoint Phoenix configuré, jamais des en-têtes de requête ou des entrées client. Les configurations endpoint HTTP-only échouent en fermure à la livraison. Les clients natifs doivent rejeter les versions inconnues, les origines/inscriptions non correspondant et les routes non reconnues ; le tap nie jamais changer les serveurs ou exécuter des mutations. La destination récupérée doit toujours passer l'autorisation API normale.

## Intégration Runtime

L'application parent démarre `Glossia.Push.Supervisor` avant Oban, fournissant le cache des crédentiels et le pool APNs Finch dédié. La configuration Runtime appelle `Glossia.Push.Config.parse!(System.get_env())`. La file `push` d'Oban a une concurrence de cinq et exécute `Glossia.Push.Prune` par heure. Les trois routes d'inscription s'exécutent dans le pipeline API authentifié par porteur existant.

L'logging des requêtes efface les jetons d'appareil. L'endpoint étend le nettoyeur de corps par défaut de Sentry avec le filtre de paramètres Phoenix, préservant ses protections existantes :

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

Ne conservez pas les corps de demande push bruts dans les télémetries ou rapports d'exception personnalisés.

Seuls les processus web/worker parent ont besoin du superviseur push et de la file d'attente. Les pods de lancement de traduction peuvent enfile les IDs sans crédentiels, un pool APNs ou un nouveau service de message. Appliquez la migration via le flux de sortie normal. Conservez les données de compte exportées exempts de jetons de fournisseur. Ne supprimez pas les tombstones comme nettoyage de rétention de routine.

Les vérifications appareils physiques restent nécessaires : builds signés iOS/Android configurés, autorisation autorisée/denier, livraison premier plan/arrière-plan/terminée, appuis démarrage froid, rotation de jeton fournisseur, crédentiels expirés, nettoyage de déconnexion hors ligne, et changement de compte. Les tests de fournisseur mockés n'établissent pas de livraison en direct. Les builds natifs incluent le support du cycle de vie de notification et les dépendances Firebase Android, mais ce code ne provisionne pas de crédentiels, infrastructure partagée, profils de provisionnement signés, ou identifiants d'applications Firebase.
