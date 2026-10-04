%{
  title: "Organisationsanmeldung einrichten",
  summary:
    "Google Workspace oder Okta verbinden, Domain verifizieren und Mitgliederberechtigungen verwalten.",
  category: "Anleitung",
  section: "platform",
  order: 8
}
---
## Anbinden Sie Ihren Identitätsanbieter

Organisationsadministratoren können einen Arbeitsidentitätsanbieter anbinden in **Einstellungen → Authentifizierung**.

1. Wählen Sie **Google Workspace** oder **Okta** und geben Sie die E-Mail-Domain Ihres Teams ein.
2. Für Okta erstellen Sie eine Webanwendung mit [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Geben Sie den Aussteller, den Client-Identifier und das Client-Secret ein. Glossia unterstützt Standard-Okta-Organisationsaussteller und den `/oauth2/default` Authorisierungs-Server. Geheimnisse werden im Ruhezustand verschlüsselt gespeichert. Das Leerlassen des Secret beim Bearbeiten bewahrt den gespeicherten Wert.
3. Für Okta registrieren Sie die in Glossia angezeigte Umleitungsadresse bei Ihrem Identitätsanbieter. Für Google Workspace verwaltet Glossia die Google-Verbindung; Sie müssen keine Google-Anwendung erstellen oder eine Callback-Adresse registrieren.
4. Speichern Sie die Einstellungen. Fügen Sie den angezeigten DNS-TXT-Eintrag über Ihren Domainanbieter hinzu, und wählen Sie dann **Domain verifizieren**. Das Ändern der E-Mail-Domain erstellt ein neues Verifizierungstoken und deaktiviert die Organisationsanmeldung, bis dies erneut verifiziert wird.
5. Teammitglieder geben ihre Arbeits-E-Mail auf der Anmeldeseite ein und wählen **Mit Ihrer Organisation fortfahren**. Mitglieder von Google Workspace können ebenfalls **Mit Google anmelden**.

## Google Workspace einrichten

Glossia verwaltet die Google-Anmeldeinformationen. Sie müssen keine OAuth-Anwendung in Google Cloud erstellen, keine benutzerdefinierte SAML-Anwendung in Google Admin hinzufügen oder eine Weiterleitungsadresse registrieren. Für einen bestehenden Google Workspace-Domain erfolgt die Einrichtung in Glossia und bei Ihrem DNS-Anbieter:

1. In **Einstellungen → Authentifizierung**, wählen Sie **Google Workspace**, geben Sie Ihre Arbeits-E-Mail-Domain ein, und wählen Sie **Authentifizierungseinstellungen speichern**.

2. Öffnen Sie die DNS-Einstellungen Ihrer Domain beim Anbieter, der Ihre DNS hostet, nicht unbedingt Google Workspace. Fügen Sie den gezeigten Eintrag hinzu, der in **Domainbesitz verifizieren**:
   
   | Feld | Wert |
   | --- | --- |
   | Typ | `TXT` |
   | Name / Host | Der **Eintragsname** in Glossia angezeigt, z. B. `_glossia-verification.example.com` |
   | Wert / Inhalt | Der **Wert des Eintrags** in Glossia angezeigt, beginnend mit `glossia-domain-verification=` |
   
   Einige DNS-Anbieter fügen Ihre Domain automatisch hinzu. In diesem Fall geben Sie nur `_glossia-verification` als Host, damit die Domain nicht doppelt enthalten ist. Lassen Sie den Eintrag nach der Verifizierung bestehen.

3. Zurück zu Glossia und auswählen **Domain verifizieren**. Falls die Verifizierung fehlschlägt, überprüfen Sie den Namen und den Wert und warten Sie auf die Propagation von DNS-Änderungen, bevor Sie erneut versuchen.

4. Bitten Sie ein Teammitglied, seine Geschäftsemail-Adresse auf der Anmeldeseite einzugeben und auszuwählen **Mit Ihrer Organisation fortfahren**, oder verwenden **Mit Google anmelden**.

Glossia überprüft die verifizierte Google-E-Mail und [Hosted-Domain-Anspruch](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); Ein persönliches Google-Konto mit demselben E-Mail-Suffix ist nicht qualifiziert.

### Wenn Google die Anmeldung blockiert

Es ist normalerweise keine Google-seitige Konfiguration erforderlich. Falls Ihre Organisation den Zugriff auf Drittanbieter-Apps einschränkt, muss ein Google Workspace Administrator Glossia möglicherweise genehmigen:

1. Melden Sie sich in der [Google Admin-Konsole](https://admin.google.com/) mit einem Administrator-Konto.
2. Gehe zu **Sicherheit → Zugriff und Datenkontrolle → API-Steuerung → Verwaltung des Zugriffs auf Drittanbieter-Apps**.
3. Finden Sie Glossia in der Liste der Apps mit Zugriff. Wenn es nicht aufgeführt ist, nutzen Sie **Neue App einrichten** um es nach App-Name oder OAuth-Client-ID zu suchen. Die OAuth-Client-ID gehört zur geteilten Google-Verbindung von Glossia, nicht zu einer Anwendung, die Sie erstellen müssen.
4. Überprüfen Sie die angeforderten Anmeldeberechtigungen und gewähren Sie den Zugang für die relevanten Benutzer gemäß Ihrer Organisationsrichtlinie. Siehe Google [Verwalten Sie den Zugriff von Drittanbieter- und internen Apps auf Google Workspace-Daten.](https://support.google.com/a/answer/7281227) Anleitung für Zugriffsebenen und Anforderungen für Administratoren.
5. Melde dich erneut mit einem Unternehmenskonto an, sobald die Richtlinienänderung wirksam ist.

## Verwalte Registrierung und Berechtigungen

Eine verifizierte Identität eines Anbieters mit einer exakt übereinstimmenden Berufse-Mail-Domäne wird automatisch der Organisation hinzugefügt. Für ein bestehendes Glossia-Konto, das Okta das erste Mal anschließt, melden Sie sich zunächst mit der bestehenden Methode an, bevor Sie mit der Anmeldung für die Organisation beginnen. Dies verknüpft den Anbieter sicher, ohne zu ermöglichen, dass ein Okta-Administrator ein anderes Glossia-Konto übernimmt. Die öffentliche Registrierung über andere Anbieter nutzt weiterhin das Interessenformular. Das Deaktivieren des Anbieters endet die Anmeldung für die Organisation, ohne bestehende Zugehörigkeiten zu löschen.

Neue Mitglieder erhalten Lesezugriff auf das Konto, die Organisation, Projekte, Stimme, Glossar, Diskussionen und Tickets. Verwenden Sie [Verwalten der Mitgliederberechtigungen](/docs/how-to/member-permissions), um nach ihrem Beitritt zusätzlichen Zugriff gewähren.

## Zugriffssicherungen

Die Verifizierung des Domainbesitzes dauert 30 Tage und wird täglich automatisch geprüft. Bewahren Sie die Verifizierungsbeschreibung auf. Wenn diese fehlt, stoppt die Anmeldung, sobald die letzte erfolgreiche Verifizierung abläuft; stellen Sie den Datensatz wieder her und verifizieren Sie erneut unter den Einstellungen für die Authentifizierung. Ein Anbieterwechsel oder die Deaktivierung der Organisationsanmeldung löscht die Verifizierung und entfernt Zugriffsdetails, die dem vorherigen Anbieter gehören. Unverifizierte Ansprüche reservieren keine Domain.

Für bestehende Konten melden Sie sich zuerst mit der bestehenden Methode an, besuchen Sie dann `/auth/login` und starten Sie die Anmeldung mit der Berufse-Mail, um die Berufsidentität zu verbinden. Google kann auch eine bereits verlinkte Google-Identität mit demselben Anbieter-Subjekt verwenden. Die Übereinstimmung einer E-Mail-Adresse allein verbindet kein bestehendes Konto.

Das Entfernen eines Mitglieds blockiert die automatische Nachemeldung. Ein Administrator muss dem Mitglied explizit hinzufügen oder erneut einladen, um den Zugang wiederherzustellen, auch wenn die Berufsidentität weiterhin aktiv ist.

Die Verwaltung von Mitgliedseinladungen, Zugriffsdetails, die Bearbeitung des Sprachmodells und die Löschung der Organisation verbleiben in der Verantwortung des Administrators. Diese Berechtigungen lassen sich nicht über Checkboxen des Mitgliederbereichs delegieren. die Authentifizierungskonfiguration, die Domain-Verifizierung und Bereichsänderungen lösen Audit-Events aus.