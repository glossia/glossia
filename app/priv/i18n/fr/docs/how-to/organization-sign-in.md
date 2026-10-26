%{
  title: "Configurer la connexion de l'organisation",
  summary:
    "Connecter Google Workspace ou Okta, vérifier votre domaine et gérer les permissions des membres.",
  category: "tutoriel",
  section: "platform",
  order: 8
}
---

## Connectez votre fournisseur d'identité

Les administrateurs de l'organisation peuvent connecter un fournisseur d'identité professionnel dans **Paramètres → Authentification**.

1. Choisissez **Google Workspace** ou **Okta** et entrez le domaine de messagerie professionnel de l'équipe.
2. Pour Okta, créez une application web via [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Entrez son éditeur, identifiant client et secret client. Glossia prend en charge les fournisseurs d'organisation Okta standard et `/oauth2/default`. Les secrets sont chiffrés au repos. Si vous laissez le secret vide lors de l'édition, la valeur sauvegardée est conservée.
3. Pour Okta, enregistrez l'adresse de redirection affichée dans Glossia auprès de votre fournisseur d'identité. Pour Google Workspace, Glossia gère la connexion Google ; vous n'avez pas besoin de créer une application Google ou d'enregistrer une adresse de rappel.
4. Sauvegardez les paramètres. Ajoutez l'enregistrement DNS TXT affiché via votre fournisseur de domaine, puis sélectionnez **Vérifier le domaine**. Le changement du domaine de messagerie crée un nouveau jeton de vérification et désactive la connexion à l'organisation jusqu'à une nouvelle vérification.
5. Les membres de l'équipe entrent sur la page de connexion et sélectionnent **Continuer avec votre organisation**. Les membres Google Workspace peuvent également utiliser **Se connecter avec Google**.

## Configurer Google Workspace

Glossia gère les identifiants d'application Google. Vous n'avez pas besoin de créer une application OAuth dans Google Cloud, d'ajouter une application SAML personnalisée dans Google Admin, ou d'enregistrer une adresse de redirection. Pour un domaine Google Workspace existant, la configuration se fait dans Glossia et chez votre fournisseur DNS :

1. Dans **Paramètres → Authentification**, choisissez **Google Workspace**, entrez votre domaine de messagerie professionnel et sélectionnez **Sauvegarder les paramètres d'authentification**.
2. Ouvrez les paramètres DNS de votre domaine chez le fournisseur qui héberge votre DNS, pas nécessairement Google Workspace. Ajoutez l'enregistrement affiché dans **Vérifier la propriété du domaine** :

   | Champ | Valeur |
   | --- | --- |
   | Type | `TXT` |
   | Nom / Hôte | Le **Nom de l'enregistrement** affiché dans Glossia, tel que `_glossia-verification.example.com` |
   | Valeur / Contenu | La **Valeur de l'enregistrement** affichée dans Glossia, commençant par `glossia-domain-verification=` |

   Certains fournisseurs DNS ajoutent automatiquement votre domaine. Dans ce cas, entrez uniquement `_glossia-verification` comme hôte afin que le domaine ne soit inclus qu'une seule fois. Maintenez l'enregistrement en place après la vérification.
3. Revenez dans Glossia et sélectionnez **Vérifier le domaine**. Si la vérification échoue, vérifiez le nom et la valeur et attendez que les modifications DNS se propagent avant d'essayer à nouveau.
4. Demandez à un membre de l'équipe d'entrer son adresse e-mail professionnelle sur la page de connexion et sélectionnez **Continuer avec votre organisation**, ou utilisez **Se connecter avec Google**.

Glossia vérifie l'e-mail vérifié de Google et l'[assertion hosted-domain](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload) ; un compte Google personnel avec le même suffixe d'e-mail ne qualifie pas.

### Si Google bloque la connexion

Aucune configuration côté Google n'est normalement requise. Si votre organisation restreint l'accès aux applications tierces, un administrateur Google Workspace peut devoir approuver Glossia :

1. Connectez-vous à la [Google Admin console](https://admin.google.com/) avec un compte administrateur.
2. Allez à **Sécurité → Contrôle de l'accès et des données → Contrôles API → Gérer l'accès aux applications tierces**.
3. Recherchez Glossia dans la liste des applications interagées. S'il n'est pas listé, utilisez **Configurer une nouvelle application** pour le trouver par son nom d'application ou son identifiant client OAuth. L'identifiant client OAuth appartient à la connexion Google partagée de Glossia, pas à une application que vous devez créer.
4. Vérifiez les permissions de connexion demandées et autorisez l'accès pour les utilisateurs concernés selon la politique de votre organisation. Consultez le guide Google [Contrôler quelles applications tierces et internes accèdent aux données Google Workspace](https://support.google.com/a/answer/7281227) pour les niveaux d'accès et les exigences des administrateurs.
5. Réessayez la connexion avec un compte professionnel après que le changement de politique ait pris effet.

## Gérer l'inscription et les permissions

Une identité de fournisseur vérifiée avec un domaine de messagerie professionnel correspondant exactement rejoint automatiquement l'organisation. Pour un compte Glossia existant connectant Okta pour la première fois, connectez-vous avec la méthode existante avant de commencer la connexion à l'organisation. Cela lie en toute sécurité le fournisseur sans permettre à un administrateur Okta de prendre le contrôle d'un autre compte Glossia. L'inscription publique via d'autres fournisseurs continue d'utiliser le formulaire d'intérêt. Désactiver le fournisseur arrête la connexion à l'organisation sans supprimer les membreships existants.

Les nouveaux membres reçoivent un accès de lecture basique au compte, à l'organisation, aux projets, à la voix, au glossaire, aux discussions et aux tickets. Suivez [Gérer les permissions des membres](/docs/how-to/member-permissions) pour accorder un accès supplémentaire après leur inscription.

## Mesures de sécurisation de l'accès

La vérification de la propriété du domaine dure 30 jours et est vérifiée automatiquement chaque jour. Maintenez l'enregistrement de vérification en place. S'il disparaît, la connexion s'arrête dès que la dernière vérification réussie expire ; restaurez l'enregistrement et vérifiez à nouveau via les paramètres d'Authentification. Le changement de fournisseur ou la désactivation de la connexion à l'organisation efface la vérification et retire les identifiants appartenant au fournisseur précédent. Les demandes non vérifiées ne réservent pas de domaine.

Pour les comptes existants, connectez-vous avec la méthode existante en premier, puis visitez `/auth/login` et commencez la connexion au moyen de l'e-mail professionnel pour connecter l'identité professionnelle. Google peut également utiliser une identité Google déjà liée avec le même sujet de fournisseur. Matcher une adresse e-mail seul ne connecte jamais un compte existant.

Supprimer un membre bloque la réinscription automatique. Un administrateur doit explicitement les ajouter ou les inviter à nouveau pour restaurer l'accès, même si leur identité professionnelle est toujours active.

La gestion des invitations de membres, les identifiants d'accès, l'édition des modèles de langage et la suppression de l'organisation restent des responsabilités de l'administrateur. Ces permissions ne peuvent pas être déléguées via les cases à cocher de portée des membres. La configuration d'authentification, la vérification du domaine et les modifications de portée émettent des événements d'audit.
