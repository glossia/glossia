%{
  title: "Configurer l'authentification de l'organisation",
  summary:
    "Connectez Google Workspace ou Okta, vérifiez votre domaine et gérez les autorisations des membres.",
  category: "guide",
  section: "platform",
  order: 8
}
---

## Connectez votre fournisseur d'identité

Les administrateurs d'organisation peuvent connecter un fournisseur d'identité professionnel dans **Paramètres → Authentification**.

1. Choisissez **Google Workspace** ou **Okta** et entrez le domaine de messagerie professionnelle de l'équipe.
2. Pour Okta, créez une application Web en utilisant [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Entrez son émetteur, l'identifiant de client et le secret du client. Glossia supporte les émetteurs d'organisation Okta standards et le serveur d'autorisation `/oauth2/default` . Les secrets sont cryptés au repos. Laisser le secret vide lors de l'édition conserve la valeur enregistrée.
3. Pour Okta, enregistrez l'adresse de redirection affichée dans Glossia auprès de votre fournisseur d'identité. Pour Google Workspace, Glossia gère la connexion Google ; vous n'avez pas besoin de créer une application Google ou d'enregistrer une adresse de retour.
4. Enregistrez les paramètres. Ajoutez l'enregistrement DNS TXT affiché via votre fournisseur de domaine, puis sélectionnez **Vérifier le domaine**. Modifier le domaine de messagerie crée un nouveau jeton de vérification et désactive la connexion de l'organisation jusqu'à nouvel authentification.
5. Les membres de l'équipe entrent leur adresse e-mail professionnelle sur la page de connexion et sélectionnent **Continuer avec votre organisation**. Les membres de Google Workspace peuvent également utiliser **Se connecter avec Google**.

## Configurer Google Workspace

Glossia gère les identifiants de l'application Google. Vous n'avez pas besoin de créer une application OAuth dans Google Cloud, ajouter une application SAML personnalisée dans Google Admin, ou enregistrer une adresse de redirection. Pour un domaine Google Workspace existant, la configuration a lieu dans Glossia et chez votre fournisseur DNS :

1. Dans **Paramètres → Authentification**, choisissez **Google Workspace**, entrez votre domaine de messagerie professionnelle et sélectionnez **Enregistrer les paramètres d'authentification**.
2. Ouvrez les paramètres DNS de votre domaine chez le fournisseur qui héberge votre DNS, pas nécessairement Google Workspace. Ajoutez l'entrée affichée dans **Vérifier la propriété du domaine** :

   | Champ | Valeur |
   | --- | --- |
   | Type | `TXT` |
   | Nom / Hôte | Le **Nom d'enregistrement** affiché dans Glossia, tel que `_glossia-verification.example.com` |
   | Valeur / Contenu | La **Valeur d'enregistrement** affiché dans Glossia, commençant par `glossia-domain-verification=` |

   Certains fournisseurs DNS ajoutent automatiquement votre domaine. Dans ce cas, entrez uniquement `_glossia-verification` comme hôte pour que le domaine ne soit pas inclus deux fois. Gardez l'entrée en place après la vérification.
3. Retournez à Glossia et sélectionnez **Vérifier le domaine**. Si la vérification échoue, vérifiez le nom et la valeur et laissez le temps nécessaire pour que les changements DNS se propagent avant de réessayer.
4. Demandez à un membre de l'équipe d'entrer son adresse e-mail professionnelle sur la page de connexion et de sélectionner **Continuer avec votre organisation**, ou d'utiliser **Se connecter avec Google**.

Glossia vérifie l'e-mail vérifié de Google et l'[affirmation de domaine hébergé](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload) ; un compte Google personnel avec le même suffixe d'e-mail n'est pas éligible.

### Si Google bloque la connexion

Aucune configuration côté Google n'est normalement requise. Si votre organisation restreint l'accès aux applications tierces, un administrateur Google Workspace peut avoir besoin d'approuver Glossia :

1. Connectez-vous à la [Console Google Admin](https://admin.google.com/) avec un compte administrateur.
2. Allez à **Sécurité → Contrôle de l'accès et des données → Contrôles API → Gérer l'accès aux applications tierces**.
3. Recherchez Glossia dans la liste des applications accédées. S'il n'est pas listé, utilisez **Configurer une nouvelle application** pour le rechercher par nom d'application ou par ID de client OAuth. L'ID de client OAuth appartient à la connexion Google partagée de Glossia, pas à une application que vous devez créer.
4. Examinez les permissions de connexion demandées et autorisez l'accès aux utilisateurs pertinents selon la politique de votre organisation. Consultez le guide de Google [Contrôler quelles applications tierces et internes accèdent aux données Google Workspace](https://support.google.com/a/answer/7281227) pour les niveaux d'accès et les exigences administrateur.
5. Réessayez la connexion avec un compte professionnel après que la modification de la politique aura pris effet.

## Gérer l'inscription et les autorisations

Une identité de fournisseur vérifiée avec un domaine de messagerie professionnelle correspondant exactement rejoint automatiquement l'organisation. Pour un compte Glossia existant se connectant à Okta pour la première fois, connectez-vous avec la méthode existante avant de commencer la connexion de l'organisation. Cela lie sûrement le fournisseur sans permettre à un administrateur Okta de prendre le contrôle d'un autre compte Glossia. L'enregistrement public via d'autres fournisseurs continue d'utiliser le formulaire d'intérêt. Désactiver le fournisseur arrête la connexion de l'organisation sans supprimer les inscriptions existantes.

Les nouveaux membres reçoivent un accès en lecture de base au compte, à l'organisation, aux projets, à la voix, au glossaire, aux discussions et aux tickets. Suivez [Gérer les permissions des membres](/docs/how-to/member-permissions) pour accorder un accès supplémentaire après leur adhésion.

## Mesures de sécurité d'accès

La vérification de propriété de domaine dure 30 jours et est vérifiée automatiquement chaque jour. Gardez l'enregistrement de vérification en place. S'il disparaît, la connexion s'arrête une fois la dernière vérification réussie expirée ; restaurez l'enregistrement et vérifiez à nouveau dans les paramètres d'authentification. Modifier les fournisseurs ou désactiver la connexion de l'organisation efface la vérification et supprime les identifiants appartenant au fournisseur précédent. Les affirmations non vérifiées ne réservent pas un domaine.

Pour les comptes existants, connectez-vous d'abord avec la méthode existante, puis visitez `/auth/login` et lancez la connexion par e-mail professionnel pour connecter l'identité professionnelle. Google peut également utiliser une identité Google déjà liée avec le même sujet de fournisseur. Correspondre à une seule adresse e-mail ne connecte jamais un compte existant.

Supprimer un membre bloque l'inscription automatique. Un administrateur doit ajouter ou reinviter explicitement ce membre pour restaurer l'accès, même si leur identité professionnelle est toujours active.

La gestion des invitations de membres, les identifiants d'accès, la modification des modèles de langage et la suppression de l'organisation restent des responsabilités administrateur. Ces autorisations ne peuvent pas être déléguées via les cases à cocher de portée du membre. La configuration d'authentification, la vérification de domaine et les changements de portée émettent des événements d'audit.
