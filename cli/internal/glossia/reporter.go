package glossia

import (
	"fmt"
	"os"
	"strings"

	"golang.org/x/term"
)

type verb string

const (
	verbTranslating verb = "Translating"
	verbRevisiting  verb = "Revisiting"
	verbValidating  verb = "Validating"
	verbChecking    verb = "Checking"
	verbOk          verb = "Ok"
	verbStale       verb = "Stale"
	verbMissing     verb = "Missing"
	verbRemoved     verb = "Removed"
	verbSkipped     verb = "Skipped"
	verbCleaned     verb = "Cleaned"
	verbCreated     verb = "Created"
	verbUpdated     verb = "Updated"
	verbSummary     verb = "Summary"
	verbInfo        verb = "Info"
	verbDryRun      verb = "Dry run"
)

type Reporter interface {
	Log(v verb, message string)
	Step(v verb, current int, total int, message string)
	Blank()
}

const (
	colorReset  = "\u001b[0m"
	colorBold   = "\u001b[1m"
	colorDim    = "\u001b[2m"
	colorGreen  = "\u001b[32m"
	colorCyan   = "\u001b[36m"
	colorYellow = "\u001b[33m"
	colorRed    = "\u001b[31m"
	colorWhite  = "\u001b[37m"
)

func colorForVerb(v verb) string {
	switch v {
	case verbOk, verbRemoved, verbCleaned, verbCreated, verbUpdated:
		return colorGreen
	case verbTranslating, verbRevisiting, verbValidating, verbChecking:
		return colorCyan
	case verbStale, verbSkipped, verbDryRun:
		return colorYellow
	case verbMissing:
		return colorRed
	default:
		return colorWhite
	}
}

func formatVerb(v verb, useColor bool) string {
	padded := fmt.Sprintf("%12s", v)
	if !useColor {
		return padded
	}

	return strings.Join([]string{colorBold, colorForVerb(v), padded, colorReset}, "")
}

type ConsoleReporter struct {
	useColor bool
}

func NewConsoleReporter(noColor bool) *ConsoleReporter {
	return &ConsoleReporter{
		useColor: !noColor && term.IsTerminal(int(os.Stdout.Fd())),
	}
}

func (r *ConsoleReporter) Log(v verb, message string) {
	_, _ = os.Stdout.WriteString(fmt.Sprintf("%s  %s\n", formatVerb(v, r.useColor), message))
}

func (r *ConsoleReporter) Step(v verb, current int, total int, message string) {
	r.Log(v, fmt.Sprintf("[%d/%d] %s", current, total, message))
}

func (r *ConsoleReporter) Blank() {
	_, _ = os.Stdout.WriteString("\n")
}
