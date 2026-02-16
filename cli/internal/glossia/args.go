package glossia

import (
	"fmt"
	"os"
	"strings"
)

type command string

const (
	cmdInit      command = "init"
	cmdTranslate command = "translate"
	cmdRevisit   command = "revisit"
	cmdCheck     command = "check"
	cmdStatus    command = "status"
	cmdClean     command = "clean"
)

type parsedGlobalFlags struct {
	NoColor bool
	Path    string
}

type parsedArgs struct {
	ShowHelp    bool
	Command     command
	CommandArgs []string
	Global      parsedGlobalFlags
}

func parseArgs(argv []string) (parsedArgs, error) {
	if len(argv) == 0 || containsHelp(argv) {
		return parsedArgs{ShowHelp: true}, nil
	}

	global := parsedGlobalFlags{NoColor: false}

	var cmd command
	var haveCommand bool
	var commandArgs []string

	for i := 0; i < len(argv); i++ {
		token := argv[i]

		if token == "--no-color" {
			global.NoColor = true
			continue
		}

		if token == "--path" {
			value := ""
			if i+1 < len(argv) {
				value = argv[i+1]
			}
			if value == "" || strings.HasPrefix(value, "-") {
				return parsedArgs{}, fmt.Errorf("--path requires a value")
			}
			global.Path = value
			i++
			continue
		}

		if !haveCommand && !strings.HasPrefix(token, "-") {
			if !isCommand(token) {
				return parsedArgs{}, fmt.Errorf("unknown command: %s", token)
			}
			cmd = command(token)
			haveCommand = true
			continue
		}

		if haveCommand {
			commandArgs = append(commandArgs, token)
			continue
		}

		return parsedArgs{}, fmt.Errorf("unknown option: %s", token)
	}

	if !haveCommand {
		return parsedArgs{}, fmt.Errorf("missing command (expected one of: init, translate, revisit, check, status, clean)")
	}

	return parsedArgs{
		Command:     cmd,
		CommandArgs: commandArgs,
		Global:      global,
	}, nil
}

func containsHelp(argv []string) bool {
	for _, t := range argv {
		if t == "--help" || t == "-h" {
			return true
		}
	}
	return false
}

func isCommand(value string) bool {
	switch value {
	case string(cmdInit),
		string(cmdTranslate),
		string(cmdRevisit),
		string(cmdCheck),
		string(cmdStatus),
		string(cmdClean):
		return true
	default:
		return false
	}
}

func printHelp() {
	// Keep the Bun CLI help text verbatim (including whitespace).
	_, _ = os.Stdout.WriteString(`glossia - Localize like you ship software.

USAGE:
  glossia <command> [options]

COMMANDS:
  init       Initialize Glossia in this repo
  translate  Translate content to other languages
  revisit    Revisit content in the source language
  check      Validate outputs
  status     Report missing or stale outputs
  clean      Remove generated outputs and lockfiles

GLOBAL OPTIONS:
  --no-color        Disable color output
  --path <path>     Run as if in this directory

Run 'glossia <command> --help' for command-specific flags.
`)
}
