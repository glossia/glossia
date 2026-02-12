---
title: "Automating translations in CI"
summary: "Every push to main triggers a CI job that detects stale translations and opens a pull request with fresh ones. Here's how to set it up and what we're planning next."
date: 2026-02-11
layout: layouts/post.njk
---
Eines der Dinge, die uns bei l10n von Anfang an wichtig waren, war, Übersetzungen zu einem natürlichen Bestandteil des Entwicklungsworkflows zu machen. Nichts, woran man vor einem Release denken muss. Kein Schritt, den jemand manuell auslösen muss. Sondern etwas, das automatisch geschieht, jedes Mal, wenn sich Inhalte ändern.

Die Idee ist einfach: Jeder Push nach `main` löst einen CI-Job aus, der prüft, ob Übersetzungen veraltet sind, und, falls ja, neue generiert und einen Pull Request öffnet. Der gesamte Vorgang dauert etwa eine Minute und funktioniert mit jedem CI-System.

## So funktioniert's

Der Ablauf besteht aus drei Schritten, die direkt l10n-Befehlen entsprechen.

**1. Prüfen, ob etwas veraltet ist.** Führen Sie `l10n status` aus. Dies vergleicht den aktuellen Zustand Ihrer Quelldateien und deren Übersetzungen mit den von l10n verwalteten Lock-Dateien. Wenn alles aktuell ist, beendet sich der Job vorzeitig. Keine unnötige Rechenzeit, keine unnötige Ausgabe.

**2. Übersetzen, was sich geändert hat.** Wenn `l10n status` feststellt, dass etwas veraltet ist – sei es, weil sich eine Quelldatei geändert hat, der Kontext aktualisiert wurde oder eine Übersetzung komplett fehlt – führen Sie `l10n translate` aus. Hier verrichtet das LLM seine Arbeit: Es liest Ihre Quellinhalte, wendet den Kontext an, den Sie in Ihren `L10N.md`-Dateien hinterlegt haben, und erstellt Übersetzungen, die den Ton und die Terminologie Ihres Projekts respektieren.

**3. Einen Pull Request öffnen.** Wenn sich Dateien geändert haben, erstellen Sie einen Branch, committen Sie die aktualisierten Übersetzungen und öffnen Sie einen Pull Request. Wenn bereits ein Übersetzungs-PR existiert, aktualisieren Sie diesen, anstatt Duplikate zu erstellen.

Wir öffnen bewusst einen Pull Request, anstatt Übersetzungen direkt nach `main` zu pushen. Dies gibt Ihnen die Möglichkeit, die Ausgabe zu überprüfen, den Übersetzungskontext in Ihren `L10N.md`-Dateien zu iterieren und Vertrauen in den agentenbasierten Workflow aufzubauen. Sobald Sie den Ergebnissen ausreichend vertrauen, ist es das Ziel, den PR-Schritt komplett zu überspringen und Übersetzungen direkt nach `main` zu committen, wodurch der Prozess vollständig unsichtbar wird.

Sie sollten auch Commits des Übersetzungsjobs selbst (um Endlosschleifen zu vermeiden) und Release-Commits überspringen.

## Beispiel: GitHub Actions

Hier ist ein konkretes Beispiel mit GitHub Actions, aber dieselbe Logik gilt für GitLab CI, CircleCI, Buildkite oder jedes andere CI-System:

```yaml
name: Translate

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  translate:
    name: Translate
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v5

      - uses: jdx/mise-action@v2

      - name: Check translation status
        id: status
        run: |
          if l10n status; then
            echo "stale=false" >> "$GITHUB_OUTPUT"
          else
            echo "stale=true" >> "$GITHUB_OUTPUT"
          fi

      - name: Run translations
        if: steps.status.outputs.stale == 'true'
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: l10n translate

      - name: Create PR with translations
        if: steps.status.outputs.stale == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          if [ -z "$(git status --porcelain)" ]; then
            exit 0
          fi
          BRANCH="l10n/update-translations"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "$BRANCH"
          git add -A
          git commit -m "[l10n] Update translations"
          git push --force origin "$BRANCH"
          gh pr create \
            --title "[l10n] Update translations" \
            --body "Automated translation update." \
            --head "$BRANCH" \
            --base main
```

Sie müssen Ihren LLM-API-Schlüssel als Secret in Ihrer CI-Umgebung hinzufügen. Wir verwenden Anthropic's Claude, daher ist unserer `ANTHROPIC_API_KEY`. Wenn Sie OpenAI verwenden, tauschen Sie ihn gegen `OPENAI_API_KEY` aus und aktualisieren Sie Ihre `L10N.md`-Konfiguration entsprechend.

## Darum ist das wichtig

Das Wichtige ist, dass Entwickler niemals unterbrochen werden. Sie schreiben Inhalte in der Quellsprache, öffnen ihren PR, lassen ihn prüfen und mergen ihn. Keine zusätzlichen Schritte, keine Übersetzungs-Gates, die ihre Arbeit blockieren.

Ja, es gibt ein kurzes Zeitfenster linguistischer Inkonsistenz nach einem Merge, in dem sich der Quellinhalt geändert hat, die Übersetzungen aber noch nicht aktualisiert wurden. Für die meisten Projekte ist das völlig in Ordnung. Und es ist kurzlebig: Innerhalb einer Minute nach dem Merge erkennt CI die Änderung und öffnet einen Übersetzungs-PR mit neuer Ausgabe.

Anfangs überprüft und mergt jemand im Team diesen Übersetzungs-PR. Dies ist die Phase, in der Sie Vertrauen in die Ergebnisse aufbauen und Ihre `L10N.md`-Kontextdateien iterieren, um Ton und Terminologie korrekt zu gestalten. Mit der Zeit, wenn Sie der Ausgabe vertrauen, können Sie den PR-Schritt vollständig überspringen und Übersetzungen direkt nach `main` pushen lassen, wodurch der gesamte Prozess unsichtbar wird.

Da l10n seine eigene Ausgabe validiert (Syntaxprüfungen, Preserve-Token-Verifizierung und alle von Ihnen konfigurierten benutzerdefinierten Befehle), haben die Übersetzungen bereits Qualitätsprüfungen bestanden, bevor sie Sie erreichen.

## Nächste Schritte: Menschliche Reviews in linguistisches Gedächtnis umwandeln

Wenn heute ein Reviewer ein Übersetzungsproblem entdeckt und manuell behebt, existiert dieses Wissen nur im Git-Diff. Das nächste Mal, wenn l10n eine ähnliche Phrase übersetzt, hat es keine Möglichkeit, von der Korrektur zu wissen.

Das wollen wir ändern. Wir untersuchen, wie menschliche Reviews von Übersetzungs-PRs in ein linguistisches Gedächtnis umgewandelt werden können, das l10n auf zukünftige Übersetzungen anwenden kann. Die Idee ist einfach: Wenn ein Reviewer "click here" in einem mobilen Kontext zu "tap here" ändert, sollte l10n diese Präferenz lernen und zukünftig anwenden.

Hier geht es nicht darum, eine traditionelle Translation Memory-Datenbank aufzubauen. Es geht darum, den Feedback-Loop zu erfassen, der bereits in Pull-Request-Reviews existiert, und diesen wieder in den Übersetzungskontext einzuspeisen. Die Korrekturen finden bereits in Ihrem Repository statt. Wir müssen sie nur verankern.

Wir arbeiten noch an der genauen Ausgestaltung, aber die Richtung ist klar: Jede menschliche Überprüfung sollte zukünftige Übersetzungen automatisch verbessern.

## Los geht's

Wenn Sie dies für Ihr Projekt einrichten möchten, installieren Sie l10n und initialisieren Sie Ihre Konfiguration:

```bash
mise use github:tuist/l10n
l10n init
```

Konfigurieren Sie Ihre Quelldateien und Zielsprachen in `L10N.md`, fügen Sie einen Übersetzungs-Job zu Ihrer CI-Pipeline hinzu und hinterlegen Sie Ihren API-Schlüssel als Secret. Von diesem Zeitpunkt an hält jeder Push nach `main` Ihre Übersetzungen synchron.