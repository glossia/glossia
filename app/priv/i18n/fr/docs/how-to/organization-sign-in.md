%{
  title: "Configurer la connexion de l'organisation",
  summary:
    "Connecter Google Workspace ou Okta, vérifier votre domaine et gérer les permissions des membres.",
  category: "guide",
  section: "platform",
  order: 8
}
---
## Connectez votre fournisseur d'identité

Les administrateurs d'organisation peuvent connecter un fournisseur d'identité professionnel dans **Paramètres → Authentification**.

1. Choisir **Google Workspace** ou **Okta** et entrez le domaine d'e-mail professionnel de l'équipe.
2. Pour Okta, créez une application web utilisant [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Entrez son émetteur, son identifiant client et son secret client. Glossia prend en charge les émetteurs d'organisation Okta standards et le `/oauth2/default` serveur d'autorisation. Les secrets sont chiffrés au repos. Laisser le secret vide lors de l'édition conserve la valeur enregistrée.
3. Pour Okta, enregistrez l'adresse de redirection affichée dans Glossia avec votre fournisseur d'identité. Pour Google Workspace, Glossia gère la connexion Google ; vous n'avez pas besoin de créer une application Google ou d'enregistrer une adresse de rappel.
4. Enregistrez les paramètres. Ajoutez l'enregistrement DNS TXT affiché via votre fournisseur de domaine, puis sélectionnez **Vérifier le domaine**. Changer le domaine d'e-mail crée un nouveau jeton de vérification et désactive la connexion à l'organisation jusqu'à nouvelle vérification.
5. Les membres de l'équipe saisissent leur adresse professionnelle sur la page de connexion et choisissent **Continuer avec votre organisation**. Les membres de Google Workspace peuvent également utiliser **Se connecter avec Google**.

## Configurer Google Workspace

Glossia gère les identifiants de l'application Google. Vous n'avez pas besoin de créer une application OAuth dans Google Cloud, d'ajouter une application SAML personnalisée dans Google Admin, ou d'enregistrer une adresse de redirection. Pour un domaine Google Workspace existant, la configuration se déroule dans Glossia et auprès de votre fournisseur DNS:

1. Dans **Paramètres → Authentification**, choisissez **Google Workspace**, entrez votre domaine d'email professionnel, et sélectionnez **Enregistrer les paramètres d'authentification**.

2. Ouvrez les paramètres DNS de votre domaine chez le fournisseur hébergeant votre DNS, pas nécessairement Google Workspace. Ajoutez l'enregistrement indiqué dans **Vérifier la propriété du domaine**:
   
   | Champ | Valeur |
   | --- | --- |
   | Type | `TXT` |
   | Nom / Hôte | Le **Nom d'enregistrement** affiché dans Glossia, par exemple `_glossia-verification.example.com` |
   | Valeur / Contenu | La **Valeur d'enregistrement** affiché dans Glossia, en commençant par `glossia-domain-verification=` |
   
   Certains fournisseurs DNS ajoutent automatiquement votre domaine. Dans ce cas, entrez uniquement `_glossia-verification` comme hôte afin que le domaine ne soit pas inclus deux fois. Conservez l'enregistrement en place après la vérification.

3. Revenez à Glossia et sélectionnez **Vérifier le domaine**. Si la vérification échoue, vérifiez le nom et la valeur et laissez le temps nécessaire pour que les modifications DNS se propagent avant de réessayer.

4. Demandez à un membre de l'équipe d'entrer son adresse e-mail professionnelle sur la page de connexion et sélectionnez **Continuer avec votre organisation**, ou utiliser **Se connecter avec Google**.

Glossia vérifie l'adresse email vérifiée de Google et [l'attestation de domaine hébergé](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); un compte Google personnel avec le même suffixe d'adresse email ne convient pas.

### Si Google bloque la connexion

Aucune configuration côté Google n'est normalement requise. Si votre organisation restreint l'accès aux applications tierces, un administrateur Google Workspace peut devoir approuver Glossia :

1. Connectez-vous au [Console d'administration Google](https://admin.google.com/) avec un compte administrateur.
2. Aller à **Sécurité → Accès et contrôle des données → Contrôles API → Gestion de l'accès aux applications tierces**.
3. Trouvez Glossia dans la liste des applications ayant accès. S'il n'y est pas listé, utilisez **Configurer une nouvelle application** pour le rechercher par nom d'application ou ID de client OAuth. L'ID de client OAuth appartient à la connexion Google partagée de Glossia, et non à une application que vous devez créer.
4. Vérifiez les autorisations de connexion demandées et accordez l'accès aux utilisateurs concernés conformément à la politique de votre organisation. Voyez Google [Contrôler quelles applications tierces et internes accèdent aux données Google Workspace](https://support.google.com/a/answer/7281227) guide pour les niveaux d'accès et les exigences de l'administrateur.
5. Réessayez la connexion avec un compte professionnel une fois que le changement de politique prend effet.

## Gérer l'inscription et les autorisations

Une identité de fournisseur vérifiée dont le domaine de messagerie professionnelle correspond exactement rejoint automatiquement l'organisation. Pour un compte Glossia existant se connectant à Okta pour la première fois, connectez-vous avec la méthode existante avant de démarrer la connexion à l'organisation. Cela lie en toute sécurité le fournisseur sans permettre à un administrateur Okta de prendre le contrôle d'un autre compte Glossia. L'enregistrement public via d'autres fournisseurs continue d'utiliser le formulaire d'intérêt. La désactivation du fournisseur bloque la connexion à l'organisation sans supprimer les membres existants.

Les nouveaux membres reçoivent un accès en lecture de base au compte, à l'organisation, aux projets, à voix, au glossaire, aux discussions et aux tickets. Suivez [Gérer les autorisations des membres](/docs/how-to/member-permissions) pour accorder un accès supplémentaire après leur arrivée.

## Mesures de sécurité d'accès

La vérification de propriété du domaine dure 30 jours et est vérifiée automatiquement chaque jour. Conservez l'enregistrement de vérification en place. S'il disparaît, la connexion s'arrête dès que la dernière vérification réussie expire ; restaurez l'enregistrement et vérifiez à nouveau dans les paramètres d'authentification. Le changement de fournisseur ou la désactivation de la connexion à l'organisation efface la vérification et supprime les identifiants appartenant au fournisseur précédent. Les demandes non vérifiées ne réservent pas de domaine.

Pour les comptes existants, connectez-vous d'abord avec la méthode existante, puis visitez `/auth/login` et lancez la connexion par adresse professionnelle pour connecter l'identité professionnelle. Google peut également utiliser une identité Google déjà liée avec le même sujet du fournisseur. La simple correspondance d'une adresse e-mail ne connecte jamais un compte existant.

Supprimer un membre bloque l'inscription automatique. Un administrateur doit explicitement les réinviter ou les ajouter à nouveau pour rétablir l'accès, même si leur identité professionnelle reste active.

La gestion des invitations de membres, les identifiants d'accès, la modification des modèles de langue et la suppression de l'organisation restent des responsabilités de l'administrateur. Ces autorisations ne peuvent pas être déléguées via les cases à cocher du périmètre de membre. La configuration d'authentification, la vérification du domaine et les modifications de périmètre émettent des événements d'audit.