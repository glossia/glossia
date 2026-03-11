package glossia

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

func runCommand(root string, reporter Reporter, cmd command, argv []string) error {
	switch cmd {
	case cmdInit:
		ensureNoUnexpectedFlags(argv, "init")
		return initCommand(root, InitOptions{Reporter: reporter})
	case cmdTranslate:
		opts, err := parseTranslateOptions(argv)
		if err != nil {
			return err
		}
		opts.Reporter = reporter
		return translateCommand(root, opts)
	case cmdRevisit:
		opts, err := parseRevisitOptions(argv)
		if err != nil {
			return err
		}
		opts.Reporter = reporter
		return revisitCommand(root, opts)
	case cmdCheck:
		opts, err := parseCheckOptions(argv)
		if err != nil {
			return err
		}
		opts.Reporter = reporter
		return checkCommand(root, opts)
	case cmdStatus:
		if len(argv) > 0 {
			return fmt.Errorf("unknown status flag: %s", argv[0])
		}
		return statusCommand(root, StatusOptions{Reporter: reporter})
	case cmdClean:
		opts, err := parseCleanOptions(argv)
		if err != nil {
			return err
		}
		opts.Reporter = reporter
		return cleanCommand(root, opts)
	default:
		return fmt.Errorf("unknown command: %s", cmd)
	}
}

func ensureNoUnexpectedFlags(argv []string, name string) {
	_ = argv
	_ = name
	// TS CLI only errors for "status"; other commands accept flags.
}

type TranslateOptions struct {
	Force    bool
	Yolo     bool
	DryRun   bool
	CheckCmd string
	Reporter Reporter
}

func parseTranslateOptions(argv []string) (TranslateOptions, error) {
	force := false
	yolo := true
	noYolo := false
	dryRun := false
	checkCmd := ""

	for i := 0; i < len(argv); i++ {
		token := argv[i]

		switch token {
		case "--force":
			force = true
			continue
		case "--yolo":
			yolo = true
			continue
		case "--no-yolo":
			noYolo = true
			continue
		case "--dry-run":
			dryRun = true
			continue
		case "--check-cmd":
			value := ""
			if i+1 < len(argv) {
				value = argv[i+1]
			}
			if value == "" || strings.HasPrefix(value, "-") {
				return TranslateOptions{}, fmt.Errorf("--check-cmd requires a value")
			}
			checkCmd = value
			i++
			continue
		default:
			return TranslateOptions{}, fmt.Errorf("unknown translate flag: %s", token)
		}
	}

	if noYolo {
		yolo = false
	}

	return TranslateOptions{
		Force:    force,
		Yolo:     yolo,
		DryRun:   dryRun,
		CheckCmd: checkCmd,
	}, nil
}

type RevisitOptions struct {
	Force    bool
	DryRun   bool
	CheckCmd string
	Reporter Reporter
}

func parseRevisitOptions(argv []string) (RevisitOptions, error) {
	force := false
	dryRun := false
	checkCmd := ""

	for i := 0; i < len(argv); i++ {
		token := argv[i]

		switch token {
		case "--force":
			force = true
			continue
		case "--dry-run":
			dryRun = true
			continue
		case "--check-cmd":
			value := ""
			if i+1 < len(argv) {
				value = argv[i+1]
			}
			if value == "" || strings.HasPrefix(value, "-") {
				return RevisitOptions{}, fmt.Errorf("--check-cmd requires a value")
			}
			checkCmd = value
			i++
			continue
		default:
			return RevisitOptions{}, fmt.Errorf("unknown revisit flag: %s", token)
		}
	}

	return RevisitOptions{
		Force:    force,
		DryRun:   dryRun,
		CheckCmd: checkCmd,
	}, nil
}

type CheckCommandOptions struct {
	CheckCmd string
	Reporter Reporter
}

func parseCheckOptions(argv []string) (CheckCommandOptions, error) {
	checkCmd := ""

	for i := 0; i < len(argv); i++ {
		token := argv[i]

		if token == "--check-cmd" {
			value := ""
			if i+1 < len(argv) {
				value = argv[i+1]
			}
			if value == "" || strings.HasPrefix(value, "-") {
				return CheckCommandOptions{}, fmt.Errorf("--check-cmd requires a value")
			}
			checkCmd = value
			i++
			continue
		}

		return CheckCommandOptions{}, fmt.Errorf("unknown check flag: %s", token)
	}

	return CheckCommandOptions{CheckCmd: checkCmd}, nil
}

type CleanOptions struct {
	DryRun   bool
	Orphans  bool
	Reporter Reporter
}

func parseCleanOptions(argv []string) (CleanOptions, error) {
	dryRun := false
	orphans := false

	for _, token := range argv {
		switch token {
		case "--dry-run":
			dryRun = true
		case "--orphans":
			orphans = true
		default:
			return CleanOptions{}, fmt.Errorf("unknown clean flag: %s", token)
		}
	}

	return CleanOptions{DryRun: dryRun, Orphans: orphans}, nil
}

type InitOptions struct {
	Reporter Reporter
}

func initCommand(root string, options InitOptions) error {
	contentPath := filepath.Join(root, "LANGUAGE.md")

	if _, err := os.Stat(contentPath); err == nil {
		return fmt.Errorf("LANGUAGE.md already exists at %s", contentPath)
	}

	const starterContent = `+++
[llm]
provider = "openai"

[[llm.agent]]
role = "coordinator"
model = "gpt-4o-mini"

[[llm.agent]]
role = "translator"
model = "gpt-4o"

[[translate]]
source = "docs/*.md"
targets = ["es", "de"]
output = "docs/i18n/{lang}/{relpath}"
+++
Project context for translators goes here.
`

	if err := os.WriteFile(contentPath, []byte(starterContent), 0o644); err != nil {
		return err
	}
	options.Reporter.Log(verbCreated, "LANGUAGE.md")
	return nil
}

type translateWorkItem struct {
	Source        SourcePlan
	SourceBytes   []byte
	SourceHash    string
	Lock          *LockFile
	ContextHashes map[string]string
	TranslateMap  map[string]bool
}

func translateCommand(root string, options TranslateOptions) error {
	plan, err := buildPlan(root)
	if err != nil {
		return err
	}

	var sources []SourcePlan
	for _, s := range plan.Sources {
		if s.Kind == EntryKindTranslate {
			sources = append(sources, s)
		}
	}
	if len(sources) == 0 {
		return fmt.Errorf("no translate sources found")
	}

	var workItems []translateWorkItem
	total := 0

	for _, source := range sources {
		sourceBytes, err := os.ReadFile(source.AbsPath)
		if err != nil {
			return err
		}

		sourceHash := hashBytes(sourceBytes)
		lock, _ := readLock(root, source.SourcePath)
		if lock == nil {
			l := createLock(source.SourcePath)
			lock = &l
		}

		contextHashes := map[string]string{}
		translateMap := map[string]bool{}

		for _, output := range source.Outputs {
			langKey := outputLangKey(output)
			contextHash := hashStrings(contextPartsFor(source, langKey))
			contextHashes[langKey] = contextHash

			outputAbs := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			missing := !exists(outputAbs)

			outputLock, ok := lock.Outputs[langKey]
			lockedContextHash := lockContextHash(lock, langKey)

			upToDate := !missing &&
				ok &&
				lock.SourceHash == sourceHash &&
				outputLock.Path == output.OutputPath &&
				lockedContextHash == contextHash

			if !options.Force && upToDate {
				continue
			}

			translateMap[langKey] = true
			total++
		}

		workItems = append(workItems, translateWorkItem{
			Source:        source,
			SourceBytes:   sourceBytes,
			SourceHash:    sourceHash,
			Lock:          lock,
			ContextHashes: contextHashes,
			TranslateMap:  translateMap,
		})
	}

	if total == 0 {
		options.Reporter.Log(verbInfo, "no translations needed")
		return nil
	}

	first := workItems[0]
	coordModel := strings.TrimSpace(first.Source.LLM.Coordinator.Model)
	translatorModel := strings.TrimSpace(first.Source.LLM.Translator.Model)
	if coordModel != "" {
		options.Reporter.Log(verbInfo, fmt.Sprintf("coordinator: %s, translator: %s", coordModel, translatorModel))
	} else {
		options.Reporter.Log(verbInfo, fmt.Sprintf("model: %s", translatorModel))
	}

	usage := emptyUsage()
	current := 0

	for _, item := range workItems {
		sourceText := string(item.SourceBytes)

		for _, output := range item.Source.Outputs {
			langKey := outputLangKey(output)
			if !item.TranslateMap[langKey] {
				continue
			}

			step := current + 1
			label := outputFormatLabel(item.Source.SourcePath, output)
			options.Reporter.Step(verbTranslating, step, total, label)

			if options.DryRun {
				options.Reporter.Log(verbDryRun, label)
				current = step
				continue
			}

			checkCmds := map[string]string{}
			checkCmd := strings.TrimSpace(options.CheckCmd)
			if checkCmd == "" {
				checkCmd = strings.TrimSpace(item.Source.Entry.CheckCmd)
				checkCmds = copyStringMap(item.Source.Entry.CheckCmds)
			}

			result, err := translate(TranslationRequest{
				Source:          sourceText,
				TargetLang:      langKey,
				Format:          item.Source.Format,
				Context:         strings.Join(contextPartsFor(item.Source, langKey), "\n\n"),
				Preserve:        append([]string{}, item.Source.Entry.Preserve...),
				Frontmatter:     item.Source.Entry.Frontmatter,
				CheckCmd:        checkCmd,
				CheckCmds:       checkCmds,
				Reporter:        options.Reporter,
				ProgressLabel:   label,
				ProgressCurrent: step,
				ProgressTotal:   total,
				Coordinator:     item.Source.LLM.Coordinator,
				Translator:      item.Source.LLM.Translator,
				Root:            root,
			})
			if err != nil {
				return err
			}

			usage = addUsage(usage, result.Usage)

			outputAbs := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			if err := os.MkdirAll(filepath.Dir(outputAbs), 0o755); err != nil {
				return err
			}
			if err := os.WriteFile(outputAbs, []byte(result.Text), 0o644); err != nil {
				return err
			}

			item.Lock.SourceHash = item.SourceHash
			item.Lock.Outputs[langKey] = OutputLock{
				Path:        output.OutputPath,
				Hash:        hashString(result.Text),
				ContextHash: item.ContextHashes[langKey],
				CheckedAt:   nowISO(),
			}

			if err := writeLock(root, item.Source.SourcePath, item.Lock); err != nil {
				return err
			}

			current = step
		}
	}

	if usage.TotalTokens > 0 {
		options.Reporter.Log(
			verbSummary,
			fmt.Sprintf("%d prompt + %d completion = %d total tokens", usage.PromptTokens, usage.CompletionTokens, usage.TotalTokens),
		)
	}

	return nil
}

type revisitWorkItem struct {
	Source        SourcePlan
	SourceBytes   []byte
	SourceHash    string
	Lock          *LockFile
	ContextHashes map[string]string
	RevisitMap    map[string]bool
}

func revisitCommand(root string, options RevisitOptions) error {
	plan, err := buildPlan(root)
	if err != nil {
		return err
	}

	var sources []SourcePlan
	for _, s := range plan.Sources {
		if s.Kind == EntryKindRevisit {
			sources = append(sources, s)
		}
	}
	if len(sources) == 0 {
		return fmt.Errorf("no revisit sources found")
	}

	var workItems []revisitWorkItem
	total := 0

	for _, source := range sources {
		sourceBytes, err := os.ReadFile(source.AbsPath)
		if err != nil {
			return err
		}

		sourceHash := hashBytes(sourceBytes)
		lock, _ := readLock(root, source.SourcePath)
		if lock == nil {
			l := createLock(source.SourcePath)
			lock = &l
		}

		contextHashes := map[string]string{}
		revisitMap := map[string]bool{}

		for _, output := range source.Outputs {
			langKey := outputLangKey(output)
			contextHash := hashStrings(contextPartsFor(source, langKey))
			contextHashes[langKey] = contextHash

			outputLock, ok := lock.Outputs[langKey]
			upToDate := ok &&
				lock.SourceHash == sourceHash &&
				outputLock.Path == output.OutputPath &&
				lockContextHash(lock, langKey) == contextHash

			if !options.Force && upToDate {
				continue
			}

			revisitMap[langKey] = true
			total++
		}

		workItems = append(workItems, revisitWorkItem{
			Source:        source,
			SourceBytes:   sourceBytes,
			SourceHash:    sourceHash,
			Lock:          lock,
			ContextHashes: contextHashes,
			RevisitMap:    revisitMap,
		})
	}

	if total == 0 {
		options.Reporter.Log(verbInfo, "no revisions needed")
		return nil
	}

	first := workItems[0]
	coordModel := strings.TrimSpace(first.Source.LLM.Coordinator.Model)
	translatorModel := strings.TrimSpace(first.Source.LLM.Translator.Model)
	if coordModel != "" {
		options.Reporter.Log(verbInfo, fmt.Sprintf("coordinator: %s, model: %s", coordModel, translatorModel))
	} else {
		options.Reporter.Log(verbInfo, fmt.Sprintf("model: %s", translatorModel))
	}

	usage := emptyUsage()
	current := 0

	for _, item := range workItems {
		sourceText := string(item.SourceBytes)

		for _, output := range item.Source.Outputs {
			langKey := outputLangKey(output)
			if !item.RevisitMap[langKey] {
				continue
			}

			step := current + 1
			label := outputFormatLabel(item.Source.SourcePath, output)
			options.Reporter.Step(verbRevisiting, step, total, label)

			if options.DryRun {
				options.Reporter.Log(verbDryRun, label)
				current = step
				continue
			}

			checkCmds := map[string]string{}
			checkCmd := strings.TrimSpace(options.CheckCmd)
			if checkCmd == "" {
				checkCmd = strings.TrimSpace(item.Source.Entry.CheckCmd)
				checkCmds = copyStringMap(item.Source.Entry.CheckCmds)
			}

			result, err := revisit(RevisitRequest{
				Source:          sourceText,
				Format:          item.Source.Format,
				Context:         strings.Join(contextPartsFor(item.Source, langKey), "\n\n"),
				Prompt:          item.Source.Entry.Prompt,
				CheckCmd:        checkCmd,
				CheckCmds:       checkCmds,
				Reporter:        options.Reporter,
				ProgressLabel:   label,
				ProgressCurrent: step,
				ProgressTotal:   total,
				Coordinator:     item.Source.LLM.Coordinator,
				Translator:      item.Source.LLM.Translator,
				Root:            root,
			})
			if err != nil {
				return err
			}

			usage = addUsage(usage, result.Usage)

			outputAbs := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			if err := os.MkdirAll(filepath.Dir(outputAbs), 0o755); err != nil {
				return err
			}
			if err := os.WriteFile(outputAbs, []byte(result.Text), 0o644); err != nil {
				return err
			}

			item.Lock.SourceHash = item.SourceHash
			item.Lock.Outputs[langKey] = OutputLock{
				Path:        output.OutputPath,
				Hash:        hashString(result.Text),
				ContextHash: item.ContextHashes[langKey],
				CheckedAt:   nowISO(),
			}

			if err := writeLock(root, item.Source.SourcePath, item.Lock); err != nil {
				return err
			}

			current = step
		}
	}

	if usage.TotalTokens > 0 {
		options.Reporter.Log(
			verbSummary,
			fmt.Sprintf("%d prompt + %d completion = %d total tokens", usage.PromptTokens, usage.CompletionTokens, usage.TotalTokens),
		)
	}

	return nil
}

func checkCommand(root string, options CheckCommandOptions) error {
	plan, err := buildPlan(root)
	if err != nil {
		return err
	}
	if len(plan.Sources) == 0 {
		return fmt.Errorf("no sources found")
	}

	total := 0
	for _, source := range plan.Sources {
		total += len(source.Outputs)
	}

	current := 0

	for _, source := range plan.Sources {
		sourceTextBytes, err := os.ReadFile(source.AbsPath)
		if err != nil {
			return err
		}
		sourceText := string(sourceTextBytes)

		for _, output := range source.Outputs {
			outputAbs := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			outputTextBytes, err := os.ReadFile(outputAbs)
			if err != nil {
				return fmt.Errorf("missing output: %s", output.OutputPath)
			}

			current++
			label := outputFormatLabel(source.SourcePath, output)
			options.Reporter.Step(verbValidating, current, total, label)

			checkCmd := strings.TrimSpace(options.CheckCmd)
			checkCmds := map[string]string{}
			if checkCmd == "" {
				checkCmd = strings.TrimSpace(source.Entry.CheckCmd)
				checkCmds = source.Entry.CheckCmds
			}

			if err := validate(root, source.Format, string(outputTextBytes), sourceText, CheckOptions{
				Preserve:  source.Entry.Preserve,
				CheckCmd:  checkCmd,
				CheckCmds: checkCmds,
				Reporter:  options.Reporter,
				Label:     label,
				Current:   current,
				Total:     total,
			}); err != nil {
				return err
			}
		}
	}

	return nil
}

type StatusOptions struct {
	Reporter Reporter
}

func statusCommand(root string, options StatusOptions) error {
	plan, err := buildPlan(root)
	if err != nil {
		return err
	}
	if len(plan.Sources) == 0 {
		return fmt.Errorf("no sources found")
	}

	missing := 0
	stale := 0
	ok := 0

	for _, source := range plan.Sources {
		sourceBytes, err := os.ReadFile(source.AbsPath)
		if err != nil {
			return err
		}
		sourceHash := hashBytes(sourceBytes)

		lock, _ := readLock(root, source.SourcePath)

		for _, output := range source.Outputs {
			outputAbs := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			langKey := outputLangKey(output)
			label := outputFormatLabel(source.SourcePath, output)

			if !exists(outputAbs) {
				missing++
				options.Reporter.Log(verbMissing, label)
				continue
			}

			contextHash := hashStrings(contextPartsFor(source, langKey))
			if lock == nil {
				stale++
				options.Reporter.Log(verbStale, label)
				continue
			}

			if lock.SourceHash != sourceHash {
				stale++
				options.Reporter.Log(verbStale, label)
				continue
			}

			outputLock, okLock := lock.Outputs[langKey]
			if !okLock {
				stale++
				options.Reporter.Log(verbStale, label)
				continue
			}

			if lockContextHash(lock, langKey) != contextHash {
				stale++
				options.Reporter.Log(verbStale, label)
				continue
			}

			if outputLock.Path != output.OutputPath {
				stale++
				options.Reporter.Log(verbStale, label)
				continue
			}

			ok++
			options.Reporter.Log(verbOk, label)
		}
	}

	options.Reporter.Log(verbSummary, fmt.Sprintf("%d ok, %d stale, %d missing", ok, stale, missing))

	if stale > 0 || missing > 0 {
		return fmt.Errorf("outputs out of date")
	}
	return nil
}

func lockContextHash(lock *LockFile, langKey string) string {
	if lock == nil {
		return ""
	}
	if out, ok := lock.Outputs[langKey]; ok {
		if strings.TrimSpace(out.ContextHash) != "" {
			return out.ContextHash
		}
	}
	return lock.ContextHash
}

func exists(filePath string) bool {
	_, err := os.Stat(filePath)
	return err == nil
}

func cleanCommand(root string, options CleanOptions) error {
	plan, err := buildPlan(root)
	if err != nil {
		return err
	}
	if len(plan.Sources) == 0 {
		return fmt.Errorf("no sources found")
	}

	plannedSources := map[string]bool{}
	for _, source := range plan.Sources {
		plannedSources[source.SourcePath] = true
	}

	removed := 0
	missing := 0
	lockRemoved := 0

	for _, source := range plan.Sources {
		for _, output := range source.Outputs {
			absolute := filepath.Join(root, filepath.FromSlash(output.OutputPath))
			result := removeFile(absolute, options.DryRun)

			if result == "removed" {
				removed++
				options.Reporter.Log(verbRemoved, output.OutputPath)
			} else if result == "missing" {
				missing++
				options.Reporter.Log(verbSkipped, fmt.Sprintf("%s (not found)", output.OutputPath))
			}
		}

		lockFilePath := lockPath(root, source.SourcePath)
		lockResult := removeFile(lockFilePath, options.DryRun)

		if lockResult == "removed" {
			lockRemoved++
			options.Reporter.Log(verbRemoved, lockFilePath)
		} else if lockResult == "missing" {
			missing++
			options.Reporter.Log(verbSkipped, fmt.Sprintf("%s (not found)", lockFilePath))
		}
	}

	if options.Orphans {
		lockDir := filepath.Join(root, ".glossia", "locks")
		lockFiles := []string{}

		if allFiles, err := walkFiles(lockDir); err == nil {
			for _, file := range allFiles {
				if strings.HasSuffix(file, ".lock") {
					lockFiles = append(lockFiles, filepath.Join(lockDir, filepath.FromSlash(file)))
				}
			}
		}

		for _, lockFilePath := range lockFiles {
			lock := readJSONLock(lockFilePath)
			if lock == nil {
				continue
			}

			sourcePath := strings.TrimSpace(lock.SourcePath)
			if sourcePath == "" {
				sourcePath = sourcePathFromLock(root, lockFilePath)
			}

			if plannedSources[sourcePath] {
				continue
			}

			for _, output := range lock.Outputs {
				absolute := filepath.Join(root, filepath.FromSlash(output.Path))
				result := removeFile(absolute, options.DryRun)

				if result == "removed" {
					removed++
					options.Reporter.Log(verbRemoved, output.Path)
				} else if result == "missing" {
					missing++
					options.Reporter.Log(verbSkipped, fmt.Sprintf("%s (not found)", output.Path))
				}
			}

			result := removeFile(lockFilePath, options.DryRun)
			if result == "removed" {
				lockRemoved++
				options.Reporter.Log(verbRemoved, lockFilePath)
			} else if result == "missing" {
				missing++
				options.Reporter.Log(verbSkipped, fmt.Sprintf("%s (not found)", lockFilePath))
			}
		}
	}

	options.Reporter.Log(verbCleaned, fmt.Sprintf("%d files removed, %d not found, %d lockfiles removed", removed, missing, lockRemoved))
	return nil
}

func removeFile(filePath string, dryRun bool) string {
	if dryRun {
		return "skipped"
	}

	if _, err := os.Stat(filePath); err != nil {
		return "missing"
	}

	if err := os.Remove(filePath); err != nil {
		return "missing"
	}
	return "removed"
}

func readJSONLock(filePath string) *LockFile {
	raw, err := os.ReadFile(filePath)
	if err != nil {
		return nil
	}

	var lock LockFile
	if err := json.Unmarshal(raw, &lock); err != nil {
		return nil
	}

	return &lock
}

func sourcePathFromLock(root string, lockFilePath string) string {
	base := filepath.Join(root, ".glossia", "locks") + string(os.PathSeparator)
	normalizedLock := normalizeSlashes(lockFilePath)
	normalizedBase := normalizeSlashes(base)

	relative := normalizedLock
	if strings.HasPrefix(normalizedLock, normalizedBase) {
		relative = normalizedLock[len(normalizedBase):]
	}

	relative = strings.TrimSuffix(relative, ".lock")
	return normalizeSlashes(relative)
}

// Sort helper: stable ordering of orphans.
func sortStrings(list []string) []string {
	out := append([]string{}, list...)
	sort.Strings(out)
	return out
}
