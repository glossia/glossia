package glossia

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
)

type EntryKind string

const (
	EntryKindTranslate EntryKind = "translate"
	EntryKindRevisit   EntryKind = "revisit"
)

type OutputPlan struct {
	Lang       string
	OutputPath string
}

type LLMPlan struct {
	Coordinator AgentConfig
	Translator  AgentConfig
}

type SourcePlan struct {
	SourcePath        string
	AbsPath           string
	BasePath          string
	RelPath           string
	Format            Format
	Kind              EntryKind
	Entry             Entry
	ContextBodies     []string
	LangContextBodies map[string][]string
	ContextPaths      []string
	LLM               LLMPlan
	Outputs           []OutputPlan
}

type Plan struct {
	Root         string
	ContentFiles []*ContentFile
	Sources      []SourcePlan
}

type candidate struct {
	Entry    Entry
	BasePath string
}

func outputLangKey(output OutputPlan) string {
	if strings.TrimSpace(output.Lang) == "" {
		return "_"
	}
	return output.Lang
}

func outputFormatLabel(sourcePath string, output OutputPlan) string {
	if strings.TrimSpace(output.Lang) != "" {
		return fmt.Sprintf("%s -> %s (%s)", sourcePath, output.OutputPath, output.Lang)
	}
	return fmt.Sprintf("%s -> %s", sourcePath, output.OutputPath)
}

func contextPartsFor(source SourcePlan, langKey string) []string {
	parts := make([]string, 0, len(source.ContextBodies)+len(source.LangContextBodies[langKey]))
	parts = append(parts, source.ContextBodies...)
	parts = append(parts, source.LangContextBodies[langKey]...)
	return parts
}

func buildPlan(root string) (*Plan, error) {
	rootAbs, err := filepath.Abs(root)
	if err != nil {
		return nil, err
	}

	contentFiles, err := discoverContent(rootAbs)
	if err != nil {
		return nil, err
	}
	entries := collectEntries(contentFiles)

	fileList, err := walkFiles(rootAbs)
	if err != nil {
		return nil, err
	}

	candidates, err := resolveEntries(rootAbs, entries, fileList)
	if err != nil {
		return nil, err
	}

	sources := make([]SourcePlan, 0, len(candidates))

	for _, item := range candidates {
		sourcePath := item.SourcePath
		cand := item.Candidate

		absPath := filepath.Join(rootAbs, filepath.FromSlash(sourcePath))
		contextFilesForSource, err := ancestorsFor(absPath, contentFiles)
		if err != nil {
			return nil, err
		}

		isTranslate := len(cand.Entry.Targets) > 0
		kind := EntryKindRevisit
		if isTranslate {
			kind = EntryKindTranslate
		}

		contextBodies := []string{}
		contextPaths := []string{}
		langContextBodies := map[string][]string{}
		llmCfg := LLMConfig{Agent: []PartialAgentConfig{}}

		for _, file := range contextFilesForSource {
			if strings.TrimSpace(file.Body) != "" {
				contextBodies = append(contextBodies, file.Body)
				contextPaths = append(contextPaths, file.Path)
			}

			if isTranslate {
				for _, lang := range cand.Entry.Targets {
					body, err := readLangContext(file.Dir, lang)
					if err != nil {
						return nil, err
					}
					if strings.TrimSpace(body) != "" {
						langContextBodies[lang] = append(langContextBodies[lang], body)
					}
				}
			}

			llmCfg = mergeLlm(llmCfg, file.Config.LLM)
		}

		coordinator, translator, err := resolveAgents(llmCfg)
		if err != nil {
			return nil, err
		}

		relPath, err := relativePath(filepath.Join(rootAbs, filepath.FromSlash(cand.BasePath)), absPath)
		if err != nil {
			return nil, err
		}

		extWithDot := path.Ext(sourcePath)
		ext := strings.TrimPrefix(extWithDot, ".")
		basename := strings.TrimSuffix(path.Base(sourcePath), extWithDot)

		outputs := []OutputPlan{}
		if isTranslate {
			for _, lang := range cand.Entry.Targets {
				outputs = append(outputs, OutputPlan{
					Lang: lang,
					OutputPath: expandOutput(cand.Entry.Output, OutputValues{
						Lang:     lang,
						RelPath:  normalizeSlashes(relPath),
						Basename: basename,
						Ext:      ext,
					}),
				})
			}
		} else if strings.TrimSpace(cand.Entry.Output) == "" {
			outputs = append(outputs, OutputPlan{OutputPath: sourcePath})
		} else {
			outputs = append(outputs, OutputPlan{
				OutputPath: expandOutput(cand.Entry.Output, OutputValues{
					Lang:     "",
					RelPath:  normalizeSlashes(relPath),
					Basename: basename,
					Ext:      ext,
				}),
			})
		}

		sources = append(sources, SourcePlan{
			SourcePath:        sourcePath,
			AbsPath:           absPath,
			BasePath:          cand.BasePath,
			RelPath:           relPath,
			Format:            detectFormat(sourcePath),
			Kind:              kind,
			Entry:             cand.Entry,
			ContextBodies:     contextBodies,
			LangContextBodies: langContextBodies,
			ContextPaths:      contextPaths,
			LLM: LLMPlan{
				Coordinator: coordinator,
				Translator:  translator,
			},
			Outputs: outputs,
		})
	}

	sort.SliceStable(sources, func(i, j int) bool {
		return sources[i].SourcePath < sources[j].SourcePath
	})

	return &Plan{
		Root:         rootAbs,
		ContentFiles: contentFiles,
		Sources:      sources,
	}, nil
}

type resolvedEntry struct {
	SourcePath string
	Candidate  candidate
}

func resolveEntries(root string, entries []Entry, fileList []string) ([]resolvedEntry, error) {
	candidates := map[string]candidate{}

	for _, entry := range entries {
		pattern, basePath, err := entryPattern(root, entry)
		if err != nil {
			return nil, err
		}

		matches, err := globFiles(pattern, fileList)
		if err != nil {
			return nil, err
		}
		excludes, err := resolveExcludes(root, entry, fileList)
		if err != nil {
			return nil, err
		}

		for _, match := range matches {
			if excludes[match] {
				continue
			}
			if path.Base(match) == "GLOSSIA.md" {
				continue
			}

			current, ok := candidates[match]
			if !ok || shouldOverride(current.Entry, entry) {
				candidates[match] = candidate{
					Entry:    entry,
					BasePath: basePath,
				}
			}
		}
	}

	keys := make([]string, 0, len(candidates))
	for k := range candidates {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	out := make([]resolvedEntry, 0, len(keys))
	for _, k := range keys {
		out = append(out, resolvedEntry{
			SourcePath: k,
			Candidate:  candidates[k],
		})
	}
	return out, nil
}

func shouldOverride(existing Entry, cand Entry) bool {
	if cand.OriginDepth > existing.OriginDepth {
		return true
	}
	return cand.OriginDepth == existing.OriginDepth && cand.Index > existing.Index
}

func entryPattern(root string, entry Entry) (pattern string, basePath string, _ error) {
	relDir, err := relativePath(root, entry.OriginDir)
	if err != nil {
		return "", "", err
	}

	src := strings.TrimSpace(entry.Source)
	if src == "" {
		src = strings.TrimSpace(entry.Path)
	}
	prefix := ""
	if relDir != "." {
		prefix = relDir
	}

	if prefix != "" {
		pattern = normalizeSlashes(prefix + "/" + src)
	} else {
		pattern = normalizeSlashes(src)
	}

	basePath = globBase(pattern)
	if basePath == "." {
		if prefix != "" {
			basePath = prefix
		} else {
			basePath = "."
		}
	}

	return pattern, basePath, nil
}

func resolveExcludes(root string, entry Entry, fileList []string) (map[string]bool, error) {
	excludes := map[string]bool{}
	if len(entry.Exclude) == 0 {
		return excludes, nil
	}

	relDir, err := relativePath(root, entry.OriginDir)
	if err != nil {
		return nil, err
	}

	prefix := ""
	if relDir != "." {
		prefix = relDir
	}

	for _, pattern := range entry.Exclude {
		scopedPattern := pattern
		if prefix != "" {
			scopedPattern = prefix + "/" + pattern
		}

		matches, err := globFiles(normalizeSlashes(scopedPattern), fileList)
		if err != nil {
			return nil, err
		}
		for _, file := range matches {
			excludes[file] = true
		}
	}

	return excludes, nil
}

func discoverContent(root string) ([]*ContentFile, error) {
	fileList, err := walkFiles(root)
	if err != nil {
		return nil, err
	}

	var contentPaths []string
	for _, file := range fileList {
		if path.Base(file) == "GLOSSIA.md" {
			contentPaths = append(contentPaths, file)
		}
	}

	files := make([]*ContentFile, 0, len(contentPaths))

	for _, relPath := range contentPaths {
		absPath := filepath.Join(root, filepath.FromSlash(relPath))
		parsed, err := parseContentFile(absPath)
		if err != nil {
			return nil, err
		}

		relDir, err := relativePath(root, parsed.Dir)
		if err != nil {
			return nil, err
		}

		depth := 0
		relDirNorm := normalizeSlashes(relDir)
		relDirNorm = strings.TrimPrefix(relDirNorm, "./")
		if relDirNorm != "." && relDirNorm != "" {
			depth = len(strings.Split(relDirNorm, "/"))
		}
		parsed.Depth = depth

		files = append(files, parsed)
	}

	sort.SliceStable(files, func(i, j int) bool {
		return files[i].Depth < files[j].Depth
	})
	return files, nil
}

func ancestorsFor(sourceAbsPath string, contentFiles []*ContentFile) ([]*ContentFile, error) {
	var out []*ContentFile
	for _, file := range contentFiles {
		ok, err := isAncestor(file.Dir, sourceAbsPath)
		if err != nil {
			return nil, err
		}
		if ok {
			out = append(out, file)
		}
	}
	sort.SliceStable(out, func(i, j int) bool {
		return out[i].Depth < out[j].Depth
	})
	return out, nil
}

func readLangContext(dir string, lang string) (string, error) {
	trimmed := strings.TrimSpace(lang)
	if trimmed == "" {
		return "", fmt.Errorf("empty language code")
	}
	if strings.Contains(trimmed, "/") || strings.Contains(trimmed, "\\") {
		return "", fmt.Errorf("invalid language code %q", lang)
	}

	filePath := filepath.Join(dir, "GLOSSIA", trimmed+".md")

	if _, err := os.Stat(filePath); err != nil {
		return "", nil
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		return "", err
	}

	split, err := splitTomlFrontmatter(string(data))
	if err != nil {
		return "", err
	}

	if split.HasFrontmatter {
		return split.Body, nil
	}
	return string(data), nil
}
