%{
  title: "Organisationsanmeldung einrichten",
  summary:
    "Binden Sie Google Workspace oder Okta an, verifizieren Sie Ihre Domäne und verwalten Sie die Berechtigungen für Mitglieder.",
  category: "Anleitung",
  section: "platform",
  order: 8
}
---

## Verbinden Sie Ihren Identity Provider

Organisationsadministratoren können einen Arbeits-Identity-Provider in **Einstellungen → Authentifizierung** verbinden.

1. Wählen Sie **Google Workspace** oder **Okta** und geben Sie die Domäne der Arbeits-E-Mail des Teams ein.
2. Für Okta erstellen Sie eine Webanwendung unter Verwendung von [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Geben Sie den Issuer, den Client-Identifikator und den Client-Schlüssel ein. Glossia unterstützt Standard-Issuer für Okta-Organisationen und den `/oauth2/default` Autorisierungs-Server. Geheimnisse werden im Ruhezustand verschlüsselt. Wenn Sie den Schlüssel beim Bearbeiten leer lassen, bleibt der gespeicherte Wert erhalten.
3. Für Okta registrieren Sie die in Glossia angezeigte Umleitungsadresse bei Ihrem Identity Provider. Bei Google Workspace verwaltet Glossia die Google-Verbindung; Sie müssen keine Google-Anwendung erstellen oder eine Callback-Adresse registrieren.
4. Speichern Sie die Einstellungen. Fügen Sie den angezeigten DNS-TXT-Eintrag über Ihren Domain-Anbieter hinzu und wählen Sie **Domain verifizieren**. Das Ändern der E-Mail-Domäne erstellt ein neues Verifizierungstoken und deaktiviert die Organisationsanmeldung, bis diese erneut verifiziert wurde.
5. Teammitglieder geben ihre Arbeits-E-Mail auf der Anmeldeseite ein und wählen **Mit Ihrer Organisation fortfahren**. Mitglieder von Google Workspace können außerdem **Mit Google anmelden** verwenden.

## Google Workspace einrichten

Glossia verwaltet die Google-Anwendungsanmeldedaten. Sie müssen keine OAuth-Anwendung in Google Cloud erstellen, keine benutzerdefinierten SAML-Anwendung in Google Admin hinzufügen oder eine Umleitungsadresse registrieren. Für einen bestehenden Google Workspace-Bereich erfolgt die Einrichtung in Glossia und bei Ihrem DNS-Anbieter:

1. Wählen Sie in **Einstellungen → Authentifizierung** **Google Workspace**, geben Sie Ihre Arbeits-E-Mail-Domäne ein und wählen Sie **Authentifizierungseinstellungen speichern**.
2. Öffnen Sie die DNS-Einstellungen Ihrer Domäne beim Anbieter, der Ihre DNS hostet, nicht unbedingt Google Workspace. Fügen Sie den Eintrag hinzu, der in **Domainbesitz verifizieren** angezeigt wird:

   | Feld | Wert |
   | --- | --- |
   | Typ | `TXT` |
   | Name / Host | Der in Glossia angezeigte **Eintragsname**, wie z. B. `_glossia-verification.example.com` |
   | Wert / Inhalt | Der in Glossia angezeigte **Eintragswert**, beginnend mit `glossia-domain-verification=` |

   Manche DNS-Anbieter fügen Ihre Domäne automatisch hinzu. In diesem Fall geben Sie nur `_glossia-verification` als Host ein, sodass die Domäne nicht zweimal enthalten ist. Behalten Sie den Eintrag nach der Verifizierung aufrecht.
3. Gehen Sie zurück zu Glossia und wählen Sie **Domain verifizieren**. Wenn die Verifizierung fehlschlägt, überprüfen Sie Name und Wert und gewähren Sie Zeit für die Ausbreitung der DNS-Änderungen, bevor Sie es erneut versuchen.
4. Bitten Sie ein Teammitglied, seine Arbeits-E-Mail auf der Anmeldeseite einzugeben und **Mit Ihrer Organisation fortfahren** zu wählen, oder verwenden Sie **Mit Google anmelden**.

Glossia überprüft die verifizierte E-Mail von Google und den [Host-Domain-Anspruch](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); ein privates Google-Konto mit demselben E-Mail-Suffix kommt nicht infrage.

### Falls Google die Anmeldung blockiert

Normalerweise ist eine Google-seitige Konfiguration nicht erforderlich. Wenn Ihre Organisation den Zugriff auf Drittanbieter-Anwendungen einschränkt, muss ein Google Workspace-Administrator Glossia möglicherweise genehmigen:

1. Melden Sie sich mit einem Administrator-Konto in der [Google Admin Console](https://admin.google.com/) an.
2. Gehen Sie zu **Sicherheit → Zugriff und Datenschutz → API-Kontrollen → Zugang zur Verwaltung von Drittanbieter-Apps**.
3. Suchen Sie Glossia in der Liste der zugriffbaren Apps. Wenn diese nicht aufgelistet ist, verwenden Sie **Neue App konfigurieren**, um danach nach App-Name oder OAuth-Client-ID zu suchen. Die OAuth-Client-ID gehört der geteilten Google-Verbindung von Glossia und nicht einer von Ihnen zu erstellenden Anwendung.
4. Prüfen Sie die angeforderten Anmeldeberechtigungen und gewähren Sie den relevanten Benutzern gemäß Ihrer Organisationsrichtlinie Zugang. Lesen Sie die Google-[Steuerung, welche Drittanbieter- und interne Apps auf Google Workspace-Daten zugreifen](https://support.google.com/a/answer/7281227)-Anleitung für Zugriffsebenen und Administratoren-Voraussetzungen.
5. Versuchen Sie die Anmeldung erneut mit einem Arbeitskonto, nachdem die Richtlinie wirksam geworden ist.

## Mitgliedschaftsanmeldung und Berechtigungen verwalten

Eine verifizierte Provider-Identität mit einer genau übereinstimmenden Arbeits-E-Mail-Domäne tritt automatisch der Organisation bei. Für ein bestehendes Glossia-Konto, das Okta zum ersten Mal verbindet, melden Sie sich mit der vorhandenen Methode an, bevor Sie die Organisationsanmeldung beginnen. Dies verknüpft den Provider sicher, ohne dass ein Okta-Administrator ein anderes Glossia-Konto übernehmen kann. Die Registrierung der Öffentlichkeit über andere Anbieter verwendet weiterhin das Interessenformular. Das Deaktivieren des Providers stoppt die Organisationsanmeldung, ohne bestehende Mitgliedschaften zu löschen.

Neue Mitglieder erhalten einen Basis-Lesezugriff auf Konto, Organisation, Projekte, Stimme, Glossar, Diskussionen und Tickets. Folgen Sie [Verwaltung von Mitgliederberechtigungen](/docs/how-to/member-permissions), um nach ihrem Beitritt zusätzlichen Zugriff zu gewähren.

## Zugriffssicherungen

Die Verifizierung des Domain-Besitzes dauert 30 Tage und wird täglich automatisch überprüft. Behalten Sie den Verifizierungseintrag aufrecht. Wenn er verschwindet, stoppt die Anmeldung, sobald die letzte erfolgreiche Verifizierung abläuft; stellen Sie den Eintrag wieder her und verifizieren Sie erneut unter Authentifizierungseinstellungen. Das Wechseln von Anbietern oder das Deaktivieren der Organisationsanmeldung löscht die Verifizierung und entfernt die Zugangsdaten des vorherigen Anbieters. Unverifizierte Ansprüche reservieren keine Domäne.

Für bestehende Konten melden Sie sich zuerst mit der vorhandenen Methode an, besuchen Sie dann `/auth/login` und starten Sie die Anmeldung mit der Arbeits-E-Mail, um die Arbeitsidentität zu verbinden. Google kann auch eine bereits verknüpfte Google-Identität mit demselben Provider-Subjekt verwenden. Nur die Übereinstimmung einer E-Mail-Adresse verbindet kein bestehendes Konto.

Das Entfernen eines Mitgliedes blockiert die automatische Neuanmeldung. Ein Administrator muss sie explizit erneut hinzufügen oder einladen, um den Zugriff wiederherzustellen, selbst wenn ihre Arbeitsidentität aktiv ist.

Die Verwaltung von Mitglieder-Einladungen, Zugangsdaten, Sprachmodellbearbeitung und die Löschung der Organisation bleiben Aufgaben des Administrators. Diese Berechtigungen können nicht über Mitgliederbereich-Checkboxen delegiert werden. Authentifizierungs-Konfiguration, Domain-Verifizierung und Bereichsänderungen erzeugen Audit-Ereignisse.
