package glossia

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/pelletier/go-toml/v2"
	"gopkg.in/yaml.v3"
)

type CheckOptions struct {
	Preserve  []string
	CheckCmd  string
	CheckCmds map[string]string

	Reporter Reporter
	Label    string
	Current  int
	Total    int
}

var defaultPreserve = []string{"code_blocks", "inline_code", "urls", "placeholders"}

func validate(root string, format Format, output string, source string, options CheckOptions) error {
	if options.Reporter != nil && strings.TrimSpace(options.Label) != "" {
		options.Reporter.Step(verbValidating, options.Current, options.Total, options.Label)
	}

	if options.Reporter != nil {
		options.Reporter.Log(verbChecking, fmt.Sprintf("syntax-validator: parse %s", formatLabel(format)))
	}
	if syntaxErr := validateSyntax(format, output, source); strings.TrimSpace(syntaxErr) != "" {
		return fmt.Errorf("syntax-validator tool failed: %s", syntaxErr)
	}

	preserveKinds := resolvePreserve(options.Preserve)
	if len(preserveKinds) > 0 {
		if options.Reporter != nil {
			options.Reporter.Log(verbChecking, "preserve-check: verify preserved tokens")
		}
		if preserveErr := validatePreserve(output, source, preserveKinds); strings.TrimSpace(preserveErr) != "" {
			return fmt.Errorf("preserve-check tool failed: %s", preserveErr)
		}
	}

	command := selectCheckCommand(format, options.CheckCmd, options.CheckCmds)
	if strings.TrimSpace(command) != "" {
		if options.Reporter != nil {
			options.Reporter.Log(verbChecking, "custom-command: run check_cmd")
		}
		if err := runExternal(root, command, output); err != nil {
			return err
		}
	}

	return nil
}

func validateSyntax(format Format, output string, source string) string {
	switch format {
	case FormatJSON:
		var v any
		if err := json.Unmarshal([]byte(output), &v); err != nil {
			return err.Error()
		}
		return ""
	case FormatYAML:
		var v any
		if err := yaml.Unmarshal([]byte(output), &v); err != nil {
			return err.Error()
		}
		return ""
	case FormatPO:
		return validatePoThorough(output, source)
	case FormatMarkdown:
		return validateMarkdown(output)
	case FormatText:
		return ""
	default:
		return ""
	}
}

func validateMarkdown(content string) string {
	lines := strings.Split(content, "\n")
	if len(lines) == 0 {
		return ""
	}

	marker := strings.TrimSpace(lines[0])
	if marker != "---" && marker != "+++" {
		return ""
	}

	end := -1
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) == marker {
			end = i
			break
		}
	}
	if end < 0 {
		return fmt.Sprintf("markdown frontmatter missing closing %s", marker)
	}

	frontmatter := strings.Join(lines[1:end], "\n")
	if marker == "---" {
		var v any
		if err := yaml.Unmarshal([]byte(frontmatter), &v); err != nil {
			return fmt.Sprintf("markdown frontmatter invalid yaml: %s", err.Error())
		}
		return ""
	}

	var v any
	if err := toml.Unmarshal([]byte(frontmatter), &v); err != nil {
		return fmt.Sprintf("markdown frontmatter invalid toml: %s", err.Error())
	}
	return ""
}

func resolvePreserve(kinds []string) []string {
	if len(kinds) == 0 {
		out := make([]string, 0, len(defaultPreserve))
		out = append(out, defaultPreserve...)
		return out
	}

	for _, k := range kinds {
		if strings.ToLower(strings.TrimSpace(k)) == "none" {
			return []string{}
		}
	}

	out := make([]string, 0, len(kinds))
	for _, k := range kinds {
		n := strings.ToLower(strings.TrimSpace(k))
		if n != "" {
			out = append(out, n)
		}
	}
	return out
}

func extractPreservables(source string, preserveKinds []string) []string {
	set := map[string]bool{}
	var output []string

	push := func(match string) {
		if !set[match] {
			set[match] = true
			output = append(output, match)
		}
	}

	working := source

	if containsString(preserveKinds, "code_blocks") {
		var stripped strings.Builder
		for i := 0; i < len(working); {
			start := strings.Index(working[i:], "```")
			if start < 0 {
				stripped.WriteString(working[i:])
				break
			}
			start += i
			stripped.WriteString(working[i:start])

			end := strings.Index(working[start+3:], "```")
			if end < 0 {
				// No closing fence: stop stripping.
				stripped.WriteString(working[start:])
				break
			}
			end = start + 3 + end + 3
			push(working[start:end])
			i = end
		}
		working = stripped.String()
	}

	if containsString(preserveKinds, "inline_code") {
		re := regexp.MustCompile("`[^`\\n]+`")
		for _, match := range re.FindAllString(working, -1) {
			push(match)
		}
	}

	if containsString(preserveKinds, "urls") {
		re := regexp.MustCompile(`https?://[^\s\)"'<>]+`)
		for _, match := range re.FindAllString(working, -1) {
			push(match)
		}
	}

	if containsString(preserveKinds, "placeholders") {
		re := regexp.MustCompile(`\{[^\s{}]+\}`)
		for _, match := range re.FindAllString(working, -1) {
			push(match)
		}
	}

	return output
}

func validatePreserve(output string, source string, preserveKinds []string) string {
	tokens := extractPreservables(source, preserveKinds)
	var missing []string

	for _, token := range tokens {
		if !strings.Contains(output, token) {
			missing = append(missing, token)
			if len(missing) >= 5 {
				break
			}
		}
	}

	if len(missing) > 0 {
		b, _ := json.Marshal(missing)
		return fmt.Sprintf("preserved tokens missing from output: %s", string(b))
	}
	return ""
}

func selectCheckCommand(format Format, fallback string, commands map[string]string) string {
	if strings.TrimSpace(commands[string(format)]) != "" {
		return strings.TrimSpace(commands[string(format)])
	}
	return strings.TrimSpace(fallback)
}

func runExternal(root string, commandTemplate string, content string) error {
	if strings.TrimSpace(root) == "" {
		return fmt.Errorf("external check requires root path")
	}

	tmpDir := filepath.Join(root, ".glossia", "tmp")
	if err := os.MkdirAll(tmpDir, 0o755); err != nil {
		return err
	}

	tmpFile := filepath.Join(tmpDir, fmt.Sprintf("check-%d-%s.tmp", time.Now().UnixMilli(), randHex(8)))
	if err := os.WriteFile(tmpFile, []byte(content), 0o644); err != nil {
		return err
	}

	command := strings.ReplaceAll(commandTemplate, "{path}", tmpFile)

	defer func() {
		_ = os.Remove(tmpFile)
	}()

	if err := runShellCommand(command, root); err != nil {
		return err
	}
	return nil
}

func runShellCommand(command string, cwd string) error {
	var shell string
	var args []string
	if runtime.GOOS == "windows" {
		shell = "cmd.exe"
		args = []string{"/d", "/s", "/c", command}
	} else {
		shell = "sh"
		args = []string{"-c", command}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	cmd := exec.CommandContext(ctx, shell, args...)
	cmd.Dir = cwd

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("external check failed: %s", err.Error())
	}

	err := cmd.Wait()
	if err == nil {
		return nil
	}

	exitCode := -1
	var ee *exec.ExitError
	if errors.As(err, &ee) {
		exitCode = ee.ExitCode()
	}

	combined := strings.TrimSpace(strings.Join(filterNonEmpty([]string{strings.TrimSpace(stderr.String()), strings.TrimSpace(stdout.String())}), "\n"))
	return fmt.Errorf("external check failed: exit %d\n%s", exitCode, combined)
}

func filterNonEmpty(parts []string) []string {
	var out []string
	for _, p := range parts {
		if strings.TrimSpace(p) != "" {
			out = append(out, p)
		}
	}
	return out
}

func containsString(list []string, value string) bool {
	for _, item := range list {
		if item == value {
			return true
		}
	}
	return false
}

// --- PO validation ---

type poEntry struct {
	Msgid        string
	Msgstr       string
	HasPlural    bool
	PluralMsgstr map[int]string
}

func validatePo(content string) string {
	lines := strings.Split(content, "\n")
	state := ""
	hasMsgid := false
	hasMsgstr := false

	for _, rawLine := range lines {
		line := strings.TrimSpace(rawLine)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		if strings.HasPrefix(line, "msgid ") {
			if hasMsgid && !hasMsgstr {
				return "po entry missing msgstr"
			}
			hasMsgid = true
			hasMsgstr = false
			state = "msgid"
			if !hasQuotedString(line) {
				return "po msgid missing quoted string"
			}
			continue
		}

		if strings.HasPrefix(line, "msgid_plural ") {
			if state != "msgid" {
				return "po msgid_plural without msgid"
			}
			if !hasQuotedString(line) {
				return "po msgid_plural missing quoted string"
			}
			continue
		}

		if strings.HasPrefix(line, "msgstr") {
			if !hasMsgid {
				return "po msgstr without msgid"
			}
			hasMsgstr = true
			state = "msgstr"
			if !hasQuotedString(line) {
				return "po msgstr missing quoted string"
			}
			continue
		}

		if strings.HasPrefix(line, "\"") {
			if state == "" {
				return "po stray quoted string"
			}
			continue
		}

		return fmt.Sprintf("po invalid line: %s", line)
	}

	if hasMsgid && !hasMsgstr {
		return "po entry missing msgstr"
	}
	return ""
}

func validatePoThorough(content string, source string) string {
	if baseErr := validatePo(content); strings.TrimSpace(baseErr) != "" {
		return baseErr
	}

	entries := parsePoEntries(content)
	hasHeader := false
	for _, e := range entries {
		if e.Msgid == "" && e.Msgstr != "" {
			hasHeader = true
			break
		}
	}
	if !hasHeader && len(entries) > 0 {
		return `po file missing header entry (msgid "" with Content-Type)`
	}

	var headerEntry *poEntry
	for i := range entries {
		if entries[i].Msgid == "" {
			headerEntry = &entries[i]
			break
		}
	}
	pluralCount := 0
	if headerEntry != nil {
		if n := extractPluralFormsCount(headerEntry.Msgstr); n > 0 {
			pluralCount = n
		}
	}

	if pluralCount > 0 {
		for _, entry := range entries {
			if !entry.HasPlural || entry.Msgid == "" {
				continue
			}

			maxPlural := -1
			for idx := range entry.PluralMsgstr {
				if idx > maxPlural {
					maxPlural = idx
				}
			}
			if maxPlural+1 != pluralCount {
				return fmt.Sprintf(
					`po plural forms mismatch: header declares nplurals=%d but entry for "%s" has %d forms`,
					pluralCount,
					truncate(entry.Msgid, 40),
					maxPlural+1,
				)
			}
		}
	}

	if strings.TrimSpace(source) != "" {
		sourceEntries := parsePoEntries(source)
		formatRe := regexp.MustCompile(`%[sdfiu%]|%\([^)]+\)[sdfiu]|\{[0-9]+\}|\{[a-zA-Z_][a-zA-Z0-9_]*\}`)

		for _, srcEntry := range sourceEntries {
			if strings.TrimSpace(srcEntry.Msgid) == "" {
				continue
			}

			var translated *poEntry
			for i := range entries {
				if entries[i].Msgid == srcEntry.Msgid {
					translated = &entries[i]
					break
				}
			}
			if translated == nil || strings.TrimSpace(translated.Msgstr) == "" {
				continue
			}

			srcFormats := formatRe.FindAllString(srcEntry.Msgstr, -1)
			for _, fmtStr := range srcFormats {
				if !strings.Contains(translated.Msgstr, fmtStr) {
					return fmt.Sprintf(
						`po format string "%s" in source msgstr for "%s" missing from translation`,
						fmtStr,
						truncate(srcEntry.Msgid, 40),
					)
				}
			}
		}
	}

	untranslated := 0
	for _, entry := range entries {
		if entry.Msgid == "" && entry.Msgstr == "" && len(entry.PluralMsgstr) == 0 {
			untranslated++
		}
	}
	if untranslated > 0 {
		return fmt.Sprintf("po has %d untranslated entries", untranslated)
	}

	return ""
}

func parsePoEntries(content string) []poEntry {
	var entries []poEntry

	msgid := ""
	msgstr := ""
	hasPlural := false
	pluralMsgstrs := map[int]string{}
	state := ""
	var pluralIndex *int
	inEntry := false

	pushCurrent := func() {
		if !inEntry {
			return
		}

		entries = append(entries, poEntry{
			Msgid:        msgid,
			Msgstr:       msgstr,
			HasPlural:    hasPlural,
			PluralMsgstr: copyIntStringMap(pluralMsgstrs),
		})

		msgid = ""
		msgstr = ""
		hasPlural = false
		pluralMsgstrs = map[int]string{}
		state = ""
		pluralIndex = nil
		inEntry = false
	}

	for _, rawLine := range strings.Split(content, "\n") {
		line := strings.TrimSpace(rawLine)

		if line == "" || strings.HasPrefix(line, "#") {
			pushCurrent()
			continue
		}

		if strings.HasPrefix(line, "msgid ") {
			pushCurrent()
			inEntry = true
			state = "msgid"
			msgid = extractQuoted(line)
			continue
		}

		if strings.HasPrefix(line, "msgid_plural ") {
			hasPlural = true
			state = "msgid_plural"
			continue
		}

		if strings.HasPrefix(line, "msgstr[") {
			idxText := line[7:]
			idx, err := strconv.Atoi(idxText)
			if err != nil {
				idx = 0
			}
			pluralIndex = &idx
			state = "msgstr_plural"
			pluralMsgstrs[idx] = extractQuoted(line)
			continue
		}

		if strings.HasPrefix(line, "msgstr ") {
			state = "msgstr"
			msgstr = extractQuoted(line)
			continue
		}

		if strings.HasPrefix(line, "\"") {
			cont := extractQuotedRaw(line)
			if state == "msgid" {
				msgid += cont
			} else if state == "msgstr" {
				msgstr += cont
			} else if state == "msgstr_plural" && pluralIndex != nil {
				pluralMsgstrs[*pluralIndex] = pluralMsgstrs[*pluralIndex] + cont
			}
		}
	}

	pushCurrent()
	return entries
}

func copyIntStringMap(input map[int]string) map[int]string {
	out := map[int]string{}
	for k, v := range input {
		out[k] = v
	}
	return out
}

func hasQuotedString(line string) bool {
	count := 0
	escaped := false
	for _, r := range line {
		if r == '\\' && !escaped {
			escaped = true
			continue
		}
		if r == '"' && !escaped {
			count++
		}
		escaped = false
	}
	return count >= 2
}

func extractQuoted(line string) string {
	first := strings.IndexByte(line, '"')
	if first < 0 {
		return ""
	}
	return extractQuotedRaw(line[first:])
}

func extractQuotedRaw(line string) string {
	trimmed := strings.TrimSpace(line)
	if len(trimmed) < 2 || !strings.HasPrefix(trimmed, "\"") || !strings.HasSuffix(trimmed, "\"") {
		return ""
	}

	out := trimmed[1 : len(trimmed)-1]
	out = strings.ReplaceAll(out, `\n`, "\n")
	out = strings.ReplaceAll(out, `\t`, "\t")
	out = strings.ReplaceAll(out, `\"`, `"`)
	out = strings.ReplaceAll(out, `\\`, `\`)
	return out
}

func extractPluralFormsCount(header string) int {
	lines := append(strings.Split(header, `\n`), strings.Split(header, "\n")...)
	for _, line := range lines {
		normalized := strings.ToLower(strings.TrimSpace(line))
		if !strings.HasPrefix(normalized, "plural-forms:") {
			continue
		}

		idx := strings.Index(normalized, "nplurals=")
		if idx < 0 {
			continue
		}

		rest := normalized[idx+len("nplurals="):]
		digits := ""
		for i := 0; i < len(rest); i++ {
			if rest[i] < '0' || rest[i] > '9' {
				break
			}
			digits += string(rest[i])
		}
		if digits != "" {
			n, err := strconv.Atoi(digits)
			if err == nil {
				return n
			}
		}
	}

	return 0
}

func truncate(input string, max int) string {
	if len(input) <= max {
		return input
	}
	return input[:max] + "..."
}

// --- small helpers ---

func randHex(n int) string {
	if n <= 0 {
		return ""
	}
	b := make([]byte, (n+1)/2)
	if _, err := rand.Read(b); err != nil {
		// Extremely defensive fallback: don't fail checks due to entropy issues.
		for i := range b {
			b[i] = byte(time.Now().UnixNano() >> uint((i%8)*8))
		}
	}

	out := hex.EncodeToString(b)
	if len(out) > n {
		out = out[:n]
	}
	return out
}
