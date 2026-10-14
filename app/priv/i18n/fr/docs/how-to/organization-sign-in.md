%{
  title: "Configurer la connexion à l'organisation",
  summary:
    "Connectez Google Workspace ou Okta, vérifiez votre domaine et gérez les autorisations des membres.",
  category: "Tutoriel",
  section: "platform",
  order: 8
}
---

## Connectez votre fournisseur d'identité

Les administrateurs de l'organisation peuvent connecter un fournisseur d'identité de travail dans **Paramètres → Authentification**.

1. Choisissez **Google Workspace** ou **Okta** et entrez le domaine de messagerie de travail de l'équipe.
2. Pour Okta, créez une application Web à l'aide de [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Entrez son éditeur, son identifiant client et son secret client. Glossia prend en charge les éditeurs d'organisation Okta standards et le `/oauth2/default` serveur d'autorisation. Les secrets sont chiffrés au repos. Laisser le secret vide lors de la modification conserve la valeur enregistrée.
3. Pour Okta, enregistrez l'adresse de redirection affichée dans Glossia auprès de votre fournisseur d'identité. Pour Google Workspace, Glossia gère la connexion Google ; vous n'avez pas besoin de créer une application Google ou d'enregistrer une adresse de rappel.
4. Enregistrez les paramètres. Ajoutez l'enregistrement DNS TXT affiché par l'intermédiaire de votre fournisseur de domaine, puis sélectionnez **Vérifier le domaine**. Modifier le domaine d'email crée un nouveau token de vérification et désactive l'inscription d'organisation jusqu'à ce qu'elle soit à nouveau vérifiée.
5. Les membres de l'équipe entrent leur email de travail sur la page de connexion et sélectionnent **Continuer avec votre organisation**. Les membres Google Workspace peuvent également utiliser **Se connecter avec Google**.

## Configurez Google Workspace

Glossia gère les identifiants de l'application Google. Vous n'avez pas besoin de créer une application OAuth dans Google Cloud, d'ajouter une application SAML personnalisée dans Google Admin, ou d'enregistrer une adresse de redirection. Pour un domaine Google Workspace existant, la configuration se fait dans Glossia et chez votre fournisseur DNS :

1. Dans **Paramètres → Authentification**, choisissez **Google Workspace**, entrez votre domaine de messagerie de travail et sélectionnez **Enregistrer les paramètres d'authentification**.
2. Ouvrez les paramètres DNS de votre domaine chez le fournisseur qui héberge votre DNS, pas nécessairement Google Workspace. Ajoutez l'enregistrement affiché dans **Vérifier la propriété du domaine** :

   | Champ | Valeur |
   | --- | --- |
   | Type | `TXT` |
   | Nom / Hôte | Le **Nom d'enregistrement** affiché dans Glossia, tel que `_glossia-verification.example.com` |
   | Valeur / Contenu | La **valeur d'enregistrement** affichée dans Glossia, commençant par `glossia-domain-verification=` |

   Certains fournisseurs DNS ajoutent automatiquement votre nom de domaine. Dans ce cas, saisissez uniquement `_glossia-verification` comme hôte pour que le domaine ne soit pas inclus deux fois. Conservez l'enregistrement en place après la vérification.
3. Retournez à Glossia et sélectionnez **Vérifier le domaine**. Si la vérification échoue, contrôlez le nom et la valeur et autorisez le temps nécessaire à la propagation des changements DNS avant de réessayer.
4. Demandez à un membre de l'équipe d'entrer son email de travail sur la page de connexion et de sélectionner **Continuer avec votre organisation**, ou d'utiliser **Se connecter avec Google**.

Glossia vérifie l'email vérifié de Google et le [résultat de vérification de domaine-hébergé](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload) ; un compte Google personnel avec le même suffixe d'email ne donne pas droit.

### Si Google bloque la connexion

Aucune configuration du côté Google n'est normalement requise. Si votre organisation restreint l'accès aux applications tierces, un administrateur Google Workspace peut devoir approuver Glossia :

1. Connectez-vous au [Console d'administration Google](https://admin.google.com/) avec un compte administrateur.
2. Allez à **Sécurité → Contrôle de l'accès et des données → Contrôles API → Gestion de l'accès aux applications tierces**.
3. Trouvez Glossia dans la liste des applications utilisées. S'il n'est pas répertorié, utilisez **Configurer une nouvelle application** pour le rechercher par nom d'application ou ID client OAuth. L'ID client OAuth appartient à la connexion Google partagée de Glossia, pas à une application que vous devez créer.
4. Examinez les autorisations de connexion demandées et autorisez l'accès pour les utilisateurs concernés selon la politique de votre organisation. Consultez le guide Google [Contrôler quelles applications tierces et internes accèdent aux données Google Workspace](https://support.google.com/a/answer/7281227) pour les niveaux d'accès et les exigences administrateur.
5. Réessayez la connexion avec un compte professionnel après que la modification de politique soit effective.

## Gérer l'inscription et les permissions

Une identité de fournisseur vérifiée avec un domaine d'email de travail exactement correspondant s'inscrit automatiquement à l'organisation. Pour un compte Glossia existant connectant Okta pour la première fois, connectez-vous avec la méthode existante avant de commencer l'inscription d'organisation. Cela lie en toute sécurité le fournisseur sans permettre à un administrateur Okta de prendre le contrôle d'un autre compte Glossia. L'inscription publique via d'autres fournisseurs continue d'utiliser le formulaire d'intérêt. Désactiver le fournisseur arrête l'inscription d'organisation sans supprimer les membres existants.

Les nouveaux membres reçoivent un accès de lecture de base au compte, à l'organisation, aux projets, à la voix, au glossaire, aux discussions et aux tickets. Suivez [Gérer les permissions des membres](/docs/how-to/member-permissions) pour accorder un accès supplémentaire après leur inscription.

## Précautions d'accès

La vérification de propriété du domaine dure 30 jours et est vérifiée automatiquement chaque jour. Gardez l'enregistrement de vérification en place. S'il disparaît, la connexion s'arrête une fois la dernière vérification réussie expire ; restaurez l'enregistrement et vérifiez à nouveau depuis les paramètres d'authentification. Changer de fournisseur ou désactiver l'inscription d'organisation efface la vérification et supprime les identifiants appartenant au fournisseur précédent. Les revendications non vérifiées ne réservent pas un domaine.

Pour les comptes existants, connectez-vous d'abord avec la méthode existante, puis visitez `/auth/login` et initiez la connexion par e-mail professionnel pour connecter l'identité professionnelle. Google peut également utiliser une identité Google déjà liée avec le même sujet fournisseur. Faire correspondre uniquement une adresse e-mail ne connecte jamais un compte existant.

Supprimer un membre bloque l'inscription automatique. Un administrateur doit explicitement les ajouter ou les inviter à nouveau pour restaurer l'accès, même si leur identité professionnelle est toujours active.

La gestion des invitations de membres, les identifiants d'accès, la modification des modèles linguistiques et la suppression de l'organisation restent des responsabilités de l'administrateur. Ces permissions ne peuvent pas être délégées via les cases à cocher de portée du membre. La configuration d'authentification, la vérification du domaine et les modifications de portée émettent des événements d'audit.
