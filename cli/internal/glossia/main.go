package glossia

import (
	"fmt"
	"os"
)

func Main() int {
	parsed, err := parseArgs(os.Args[1:])
	if err != nil {
		// Match Bun CLI behavior: print a blank line first, then the error.
		fmt.Fprintln(os.Stdout)
		fmt.Fprintln(os.Stderr, err.Error())
		return 1
	}
	if parsed.ShowHelp {
		printHelp()
		return 0
	}

	cwd, err := os.Getwd()
	if err != nil {
		fmt.Fprintln(os.Stdout)
		fmt.Fprintln(os.Stderr, err.Error())
		return 1
	}

	baseDir, err := resolveBaseDir(cwd, parsed.Global.Path)
	if err != nil {
		fmt.Fprintln(os.Stdout)
		fmt.Fprintln(os.Stderr, err.Error())
		return 1
	}

	root, err := findRoot(baseDir)
	if err != nil {
		fmt.Fprintln(os.Stdout)
		fmt.Fprintln(os.Stderr, err.Error())
		return 1
	}

	reporter := NewConsoleReporter(parsed.Global.NoColor || os.Getenv("NO_COLOR") != "")

	if err := runCommand(root, reporter, parsed.Command, parsed.CommandArgs); err != nil {
		reporter.Blank()
		fmt.Fprintln(os.Stderr, err.Error())
		return 1
	}

	return 0
}
