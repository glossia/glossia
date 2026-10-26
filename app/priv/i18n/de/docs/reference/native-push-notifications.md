%{
  title: "Native Push-Benachrichtigungen",
  summary:
    "Provider-Konfiguration, Opt-in-Gerätereistrierung, Lieferrichtlinie und native Payloads.",
  category: "Referenz",
  section: "platform",
  order: 30
}
---

## Transport und Credentials

Glossia sendet direkt an APNs für iOS und an FCM HTTP v1 für Android. PostgreSQL speichert Registrierungen; Oban stellt die Lieferwarteschlangen. Keine Messaging-Service oder Firebase iOS SDK wird benötigt. Annahme eines Anbieters ist keine Zustellung oder Lesebestätigung. Unklare Netzwerkerknisse können duplizierte Alarme erzeugen.

Anbieterverschlüsselte Schlüssel gehören ausschließlich ins bestehende Geheimnismanagementsystem des Servers. Fügen Sie niemals APNs-Private-Schlüssel oder Firebase-Dienstkonten-JSON in mobile Builds, Repository-Dateien, Logs oder klientersichtige Konfigurationen ein. Öffentliche Android-App-Identifikatoren von Firebase sind keine Dienstkonten-Kennungen.

| Umgebungsvariable | Bedeutung |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | Zehnteilige Apple-Team-Identifikator. |
| `GLOSSIA_APNS_KEY_ID` | Zehnteilige Apple-Signierungs-Schlüssel-Identifikator. |
| `GLOSSIA_APNS_PRIVATE_KEY` | PEM-kodierter privater P-256-Signier-Schlüssel, Zeilenumbrüche erhalten. |
| `GLOSSIA_APNS_TOPIC` | Der genaue Bundle-Identifikator der signierten iOS-Anwendung. Clients können ihn nicht wählen. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (Standard), `sandbox` oder ausdrücklich `both` für einen Schlüssel, der beide unterstützt. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | Android-Firebase-Dienstkonten-JSON mit `type`, `project_id`, `client_email` und RSA `private_key`. |

Fehlende APNs-Kredentiale deaktivieren nur iOS. Fehlende FCM-Kredentiale deaktivieren nur Android. Teilweise oder falsch konfigurierte Anbieter versagen die Konfigurationsauswertung mit einem geheimnisfreien Fehler. APNs-Umgebung wird bei Registrierung und Lieferung geprüft; leiten Sie sie vom signierten Bereitstellungsprofil ab, nicht von Build-Modus-Voraussetzungen. APNs verwendet einen dedizierten HTTP/2-einig Finch-Pool und ES256-Authentifizierung. FCM tauscht eine RS256-Dienstkonten-Assert am festen Google OAuth-Endpunkt aus und nutzt dann sein festes HTTP v1-Endpunkt. Umleitungen und HTTP-Klienten-Wiederholungsanfragen sind deaktiviert.

## Registrierungs-API

Alle Routen benötigen einen bearer OAuth-Zugriffstoken, der an den Client der nativen App pro Installation dynamisch registrierten Public PKCE-Client erstellt wurde. Sein einziger Umleitungs-URI muss `glossia://oauth/callback`; Erfrischung und Widerruf müssen öffentlich sein, ohne Client-Secret-Authentifizierungsmethoden. Der veraltete gemeinsame Expo-Client, Konten-Token, Browser-Sitzungen und andere OAuth-Clients sind keine Installationsidentitäten und können Geräte nicht registrieren. Dies prüft die Client-Form, nicht Geräte-Attestation.

`PUT /api/me/push-devices/:installation_id` akzeptiert genau:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: clientgenerierter UUID. Er ist auch der zurückgelieferte `registration_id`.
- `platform`: `ios` oder `android`.
- `environment`: `sandbox` oder `production` für iOS; nur `production` für Android.
- iOS-Token: 32–512 hexadezimale Zeichen, gerade Länge, normalisiert in Kleinbuchstaben.
- Android-Token: 16–4096 druckbare Nicht-Zeichen-ASCII-Zeichen.
- Erfolgreicher PUT: `{"registered":true,"registration_id":"<installation UUID>"}`.
- Unbekannte Felder, einschließlich Besitzerselektoren, Topic, Host und Anbieter-URLs, werden abgelehnt.

`DELETE /api/me/push-devices/:installation_id` gibt `{"deleted":true}` idempotent zurück. Unbekannte IDs werden Grabsteine, sodass ein verzögerter PUT eine Installation nach Abmeldung nicht wiederbeleben kann. Eine fremde Installation eines anderen Nutzers wird niemals geändert. Der gleiche native OAuth-Client kann während der Abmeldung auf Wiederherstellung die vorherige Installation seines Nutzers zurücksetzen, aber das Eigentum bewegt sich nie. Drehen Sie nach `409 installation_retired` auf einen frischen Installations-UUID.

`GET /api/me/push-devices/capabilities` gibt `{"ios":true,"android":false}` gemäß konfigurierten Anbietern zurück; es hat die gleiche Authentifizierungsanforderung. Eine wahre iOS-Fähigkeit überschreibt APNs-Umgebungsbeschränkungen nicht.

Antworten sind `no-store`. Mutationen sind auf 120 Anfragen pro Nutzer pro Stunde begrenzt, zusätzlich zur API-Quote. Fehlende/ungültige bearer-Authentifizierung gibt 401 zurück; nicht-native Kredentiale geben 403 zurück; ungültige Datengeräte geben 400 zurück; zurückgesetzte/konfliktbehaftete Installationen geben 409 zurück; nicht verfügbare Anbieter geben 503 zurück. Bereinigung bleibt verfügbar, wenn ein Anbieter deaktiviert ist.

## Lieferabsicht

Interne Aufrufe nutzen die feste API nach Abschluss ihrer Transaktion des Quellcodes:

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

Die Art kann auch das entsprechende Atom sein. Die Rückgabe ist `{:ok, queued_count}` oder `{:error, :invalid_notification}`. Es gibt keine öffentliche Send-API für willkürliche Empfänger, benutzerdefiniert Benachrichtigungstext, Inferenzwiederholungsanfragen oder implizite Opt-In.

`toki_completed` erfordert die genaue abgeschlossene **Benutzer**-Nachricht und seine abgeschlossene Assistenten-Reply. In privaten Gesprächen muss der Empfänger die Geschichte besitzen; in geteilten Zielgesprächen sind sie trotzdem berechtigte eingeladene fließende Teilnehmer und das Ziel muss offen sein. Es prüft aktuellen Toki/Projekt-Zugriff und, für quellverbundene Gespräche, aktuellen Übersetzungs-Lesearriff und Quellenexistenz. Eine andere abgeschlossene Nachricht oder eine Assistenten-Nachrichten-ID ist kein Ersatz.

`linguistic_input_needed` erfordert die identifizierte offene Aufgabe auf der angegebenen Übersitzungssitzung und einen berechtigten eingeladenen fließenden Teilnehmer. Eine nur-sitzungsbediente Quelle bleibt für Kompatibilität akzeptiert und erzwingt eine qualifizierte offene Task. Bewertungen in einer anderen Sitzung qualifizieren sich nicht. Alle abgestimmten berechtigten Teammitglieder betreten die gleiche Toki-Gespräch; Lieferung überprüft unabhängig aktuelle Sprachbeherrschung, Toki/Übersetzung/Projekt-Zugriff und Mitgliedschaft.

Es gibt maximal zehn aktive Registrierungen pro Nutzer. Token werden mit dem bestehenden Cloak-Verschlag verschlüsselt und nach einem SHA-256-Verdau indiziert. Tokenbewegungen setzen die alte Registrierung zurück, und Anbieterschwächung vergleicht den versuchten Verdau/Umfeld vor jedem Löschen. APNs letzte ungültige Zeitstempel setzen Registrierungen nach diesem Zeitpunkt nicht zurück.

Lieferjobs enthalten nur IDs, Art, Quell-IDs und Ablaufdatum. Jeder Versuch zählt erneut die Registrierung, den Besitzer, den aktuellen persistenten nativen OAuth-Refresh-Gewährung und Scopes, die Quelle, Mitgliedschaft und Ablaufdatum. Es prüft nochmals nach Anbietersondern-KlangleAufnahme, sofort vor Transport. Nur Access-Token-Ablauf beendet nicht noch gültige Refresh-Sitzung. Widerruf, Refresh-Ablauf, fehlende Quellenlwei, Abmeldung oder gelöste Bewertungen stellen Lieferungen ab.

Beide Arten nach einer Stunde ablaufend. Höchstens fünf Anbieter-Versuche, einschließlich Anbieter-Rückdruck-Pausen. Retry-After wird nur innerhalb der Lebensdauer der Benachrichtigung berücksichtigt. Keine Anbieter-Antwort-Körperform oder wird als Job-Fehler zurückgegeben. Registrierungen aktualisieren sich im Vordergrund; Registrierungen, die seit 60 Tagen nicht aktualisiert wurden, werden zurückgezogen. Die stündliche Abschaltpflege-Werkzeug abtastet eine begrenzte rotierende Baugruppe von 1.000 Zeilen und entfernt Token für veraltete oder beendete Sitzungen. Grabsteine behalten nur Installations/Client-IDs, Plattform/Umfeld und Lebenszyklus-Zeitstempel für immer, um verzögerte Anfragen umzäunen; zurückgezogene Reihen haben keinen Benutzer, Token oder Verdau. Kontodeletierung trennt die Benutzerreferenz, verhindert alle Lieferungen sofort, und die Abschaltpflege-Werkzeug schließt das behaltenen Token.

Anbieter-Schlüssel verwenden ein begrenztes, ablaufbewusstes Cachex-Cache. Schüsselrotation ändert Cache-Identität. APNs JWTs werden für 50 Minuten wiederverwendet; FCM-Zertifikate laufen fünf Minuten vor Anbieterverschluss ab (höchstens 50 Minuten). Versagen werden nicht gecacht.

## Payload-Version 1

APNs enthält die allgemeine Warnung **Glossia / Sie haben ein Update in Glossia.** FCM sendet nur-Daten-Nachrichten mit dem gleichen `title` und `body`, für lokale Darstellung. Keines enthält private Aufforderungen, Antworten, Fragen, Quell-Auszüge oder Projekttitel. Routing-Felder sind Zeichenketten:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

Beide Benachrichtigungs-Arten öffnen `/org/project/toki/CONVERSATION_UUID`; linguistische Hilfsanfragen öffnen ihre gemeinsame Ziel-Thread. Das `server` ist der konfigurierter Phoenix-Endpunkt's HTTPS Ursprung, niemals Anforderungs-Header oder Client-Eingabe. HTTP-endpunktkonfigurationen fehler verfolgt am Abschluss. Native-Client müssen unbekannte Versionen, nicht passende Ursprünge/Registrierungen und nicht erkannte Routen ablehnen; Tappen verändert niemals Server oder führt Mutationen aus. Das geholte Ziel muss weiterhin normale API-Autorisierung bestehen.

## Echtzeit-Integration

Die übergeordnete Anwendung startet `Glossia.Push.Supervisor` vor Oban, bereitstellend die Schlüssel-Casche und dedizierten APNs Finch-Pool. Echtzeit-Konfiguration ruft `Glossia.Push.Config.parse!(System.get_env())`. Obans `push`-Prioritäten-Stapel hat Konvergenz fünf und läuft `Glossia.Push.Prune` stündlich. Die drei Registrierungs-Routen laufen in der beständigen Träger-authentifizierten API-Pipeline.

Anfrageprotokollierung streicht Gerätestoken. Der Endpunkt erweitert Sentries Standard-Körper-Reinigungsprozess mit Phoenixs Parameter-Filter, bewahrend seine bestehenden Schutz:

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

Behalten Sie rohe Push-Anfrage-Körper in individuellen Telemetrie oder Fehlerberichten nicht.

Nur übergeordnete Web/Worker-Prozesse benötigen den Push-Verwalter und Stapel. Übersetzungsfahrer-Pods können IDs ohne Zertifikate, einen APNs-Pool oder einen neuen Messaging-Dienst einreihen. Die Migration durch das normale Veröffentlichen-Arbeitsablauf anwenden. Halten Sie exportierte Kontodaten frei von Anbieter-Token. Löschen Sie Grabsteine nicht als reguläre Aufbewahrung-Säuberung.

Physische-Gerät-Prüfungen bleiben notwendig: konfigurierte signierung iOS/Android-Aufbauten, Zugriff-ermäßigt/verweigert, Vordergrund/Hintergrund/abgebrochenes Lieferung, Kaltstart-Taps, Anbieter-Token-Rotation, abgelaufene Zertifikate, Offline-Abmeldung-Säuberung und Account-Schaltens. Falsche-Anbieter-Tests etablieren keine live Lieferungen. Native-Aufbauten enthalten Benachrichtigungs-Lebenszyklus-Support und Android-Firebase-Abhängigkeiten, aber dieser Code liefert nicht Zertifikate, geteilte Infrastruktur, signierte Bereitstellung-Profilen oder Firebase-App-Identifier.
