%{
  title: "Organisationsanmeldung konfigurieren",
  summary:
    "Anbinden Sie Google Workspace oder Okta, verifizieren Sie Ihre Domain und verwalten Sie Mitgliederberechtigungen.",
  category: "Anleitung",
  section: "platform",
  order: 8
}
---

## Verbinde deinen Identitätsanbieter

Organisationsadministratoren können einen Arbeitsidentitätsanbieter in **Einstellungen → Authentifizierung** verknüpfen.

1. Wähle **Google Workspace** oder **Okta** und gib die Arbeits-E-Mail-Domäne des Teams ein.
2. Für Okta erstelle eine Webanwendung mittels [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/). Gib ihren Issuer, Client-Identifizierer und Client-Geheimnis ein. Glossia unterstützt Standard-Okta-Organisations-Issuer und den `/oauth2/default` Autorisierungsserver. Geheimnisse werden im Ruhezustand verschlüsselt. Wenn du das Geheimnis beim Bearbeiten leer lässt, bleibt der gespeicherte Wert erhalten.
3. Verknüpfe für Okta die Umleitungsadresse, die in Glossia angezeigt wird, mit deinem Identitätsanbieter. Für Google Workspace verwaltet Glossia die Google-Verbindung; du musst keine Google-Anwendung erstellen oder eine Callback-Adresse registrieren.
4. Speichere die Einstellungen. Füge die angezeigte DNS-TXT-Eintragung über deinen Domain-Anbieter hinzu und wähle dann **Domain verifizieren**. Eine Änderung der E-Mail-Domäne erzeugt einen neuen Verifizierungstoken und deaktiviert die Organisationsanmeldung, bis sie erneut verifiziert wurde.
5. Teammitglieder geben im Login-Bildschirm ihre Arbeits-E-Mail ein und wählen **Mit deiner Organisation fortfahren**. Mitglieder von Google Workspace können alternativ **Mit Google anmelden** verwenden.

## Einrichtung von Google Workspace

Glossia verwaltet die Google-Anwendungsanmeldedaten. Du musst keine OAuth-Anwendung in Google Cloud erstellen, eine benutzerdefinierte SAML-Anwendung in Google Admin hinzufügen oder eine Umleitungsadresse registrieren. Für eine bestehende Google Workspace-Domäne erfolgt das Setup in Glossia und bei deinem DNS-Anbieter:

1. In **Einstellungen → Authentifizierung**, wähle **Google Workspace**, gib deine Arbeits-E-Mail-Domäne ein und wähle **Authentifizierungseinstellungen speichern**.
2. Öffne die DNS-Einstellungen deiner Domain im Anbieter, der deine DNS hosted, nicht unbedingt Google Workspace. Füge die im **Domainbesitz verifizieren** angezeigte Eintragung hinzu:

   | Feld | Wert |
   | --- | --- |
   | Typ | `TXT` |
   | Name / Host | Der in Glossia angezeigte **Eintragsname**, z. B. `_glossia-verification.example.com` |
   | Wert / Inhalt | Der in Glossia angezeigte **Eintragswert**, beginnend mit `glossia-domain-verification=` |

   Einige DNS-Anbieter fügen deine Domain automatisch hinzu. Gib in diesem Fall nur `_glossia-verification` als Host ein, damit die Domain nicht doppelt enthalten ist. Behalte die Eintragung nach der Verifizierung.
3. Gehe zurück zu Glossia und wähle **Domain verifizieren**. Wenn die Verifizierung fehlschlägt, überprüfe Name und Wert und warte auf die Ausbreitung von DNS-Änderungen, bevor du es erneut versuchst.
4. Bitte ein Teammitglied, im Login-Bildschirm keine seine Arbeits-E-Mail einzugeben und **Mit deiner Organisation fortfahren** auszuwählen, oder verwende **Mit Google anmelden**.

Glossia überprüft die verifizierte Google-E-Mail und den [hosted-domain-Anspruch](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload); ein persönliches Google-Konto mit dem gleichen E-Mail-Suffix qualifiziert sich nicht.

### Wenn Google die Anmeldung blockiert

Normalerweise ist keine Google-seitige Konfiguration erforderlich. Wenn deine Organisation den Zugriff von Drittanbieter-Anwendungen einschränkt, kann ein Google Workspace-Administrator die Genehmigung von Glossia benötigen:

1. Melde dich im [Google Admin-Konsole](https://admin.google.com/) mit einem Administrator-Konto an.
2. Gehe zu **Sicherheit → Zugriff und Datenkontrolle → API-Steuerungen → Zugriff auf Drittanbieter-Apps verwalten**.
3. Finde Glossia in der Liste der durchgeführten Apps. Wenn es nicht aufgeführt ist, verwende **Neue App konfigurieren**, um es nach App-Name oder OAuth-Client-ID zu suchen. Die OAuth-Client-ID gehört zur gemeinsamen Google-Verbindung von Glossia, nicht zu einer Anwendung, die du erstellen musst.
4. Überprüfe die angeforderten Anmeldeberechtigungen und erlaube den relevanten Nutzern den Zugriff gemäß deiner Organisationsrichtlinie. Siehe die Google-Anleitung [Kontrolle, welche Drittanbieter- und interne Apps auf Google Workspace-Daten zugreifen](https://support.google.com/a/answer/7281227) für Zugriffsstufen und Administratoranforderungen.
5. Versuche die Anmeldung mit einem Arbeitskonto erneut, nachdem die Richtlinienänderung wirksam ist.

## Verwaltung von Registrierungen und Berechtigungen

Eine verifizierte Anbieteridentität mit exakt übereinstimmender Arbeits-E-Mail-Domäne wird automatisch der Organisation hinzugefügt. Für ein bestehendes Glossia-Konto, das Okta zum ersten Mal verbindet, melde dich mit der bestehenden Methode an, bevor du die Organisationsanmeldung startest. Dies verknüpft den Anbieter sicher, ohne einem Okta-Administrator die Übernahme eines anderen Glossia-Kontos zu ermöglichen. Die öffentliche Registrierung über andere Anbieter verwendet weiterhin das Personenformular. Das Deaktivieren des Anbieters stoppt die Organisationsanmeldung, ohne bestehende Mitgliedschaften zu löschen.

Neue Mitglieder erhalten einen grundlegenden Lesezugriff auf das Konto, die Organisation, Projekte, Voice, Glossar, Diskussionen und Tickets. Verfolge [Verwalten von Mitgliederberechtigungen](/docs/how-to/member-permissions), um Zugriff nach ihrer Registrierung zu gewähren.

## Schutzmaßnahmen für den Zugriff

Die Verifizierung der Domainbesitzdauer dauert 30 Tage und wird täglich automatisch überprüft. Behalte die Verifizierungseintragung erhalten. Wenn sie verschwindet, stoppt die Anmeldung, sobald die letzte erfolgreiche Verifizierung abläuft; stelle die Eintragung wieder her und verifiziere erneut unter Authentifizierungseinstellungen. Das Ändern von Anbitern oder das Deaktivieren der Organisationsanmeldung löscht die Verifizierung und entfernt die Anmeldeinformationen des vorherigen Anbieters. Unverifizierte Ansprüche reservieren keine Domain.

Für bestehende Konten melde dich zuerst mit der bestehenden Methode an, besuche dann `/auth/login` und starte die Arbeits-E-Mail-Anmeldung, um die Arbeitsidentität zu verbinden. Google kann auch eine bereits verknüpfte Google-Identität mit dem gleichen Provider-Subjekt verwenden. Eine Übereinstimmung einer E-Mail-Adresse allein verknüpft nie ein bestehendes Konto.

Das Entfernen eines Mitglieds blockiert die automatische Neuerregistrierung. Ein Administrator muss dieses Mitglied explizit erneut hinzufügen oder einladen, um den Zugriff wiederherzustellen, auch wenn seine Arbeitsidentität weiterhin aktiv ist.

Das Management von Mitgliedereinladungen, Zugriffsschlüsseln, Sprachmodellbearbeitung und der Löschungen von Organisationen verbleiben bei den Administratoren. Diese Berechtigungen können nicht über Mitgliederbereichs-Checkboxen delegiert werden. Authentifizierungskonfiguration, Domainverifizierung und Bereichsänderungen erzeugen Audit-Ereignisse.
