package glossia

import (
	"fmt"
	"strings"
	"unicode"
)

type TranslationRequest struct {
	Source          string
	TargetLang      string
	Format          Format
	Context         string
	Frontmatter     string
	CheckCmd        string
	CheckCmds       map[string]string
	Reporter        Reporter
	ProgressLabel   string
	ProgressCurrent int
	ProgressTotal   int
	Coordinator     AgentConfig
	Translator      AgentConfig
	Root            string
}

type RevisitRequest struct {
	Source          string
	Format          Format
	Context         string
	Prompt          string
	CheckCmd        string
	CheckCmds       map[string]string
	Reporter        Reporter
	ProgressLabel   string
	ProgressCurrent int
	ProgressTotal   int
	Coordinator     AgentConfig
	Translator      AgentConfig
	Root            string
}

type TranslationResult struct {
	Text  string
	Usage TokenUsage
}

const defaultValidationAttempts = 2

func translate(req TranslationRequest) (*TranslationResult, error) {
	content := req.Source
	frontmatter := ""

	if req.Format == FormatMarkdown && req.Frontmatter == FrontmatterPreserve {
		split := splitMarkdownFrontmatter(req.Source)
		if split.OK {
			frontmatter = split.Frontmatter
			content = split.Body
		}
	}

	briefResult := buildBrief(req)
	usage := briefResult.Usage
	brief := briefResult.Text

	attempts := defaultValidationAttempts

	var lastErr error
	for attempt := 0; attempt <= attempts; attempt++ {
		result, err := translateOnce(req, brief, content, lastErr)
		if err != nil {
			lastErr = err
			continue
		}
		usage = addUsage(usage, result.Usage)

		translated := stripStructuredCodeFence(req.Format, trimEnd(result.Text))
		if frontmatter != "" {
			if strings.TrimSpace(translated) != "" {
				translated = frontmatter + "\n" + translated
			} else {
				translated = frontmatter + "\n"
			}
		}

		if err := validate(req.Root, req.Format, translated, req.Source, CheckOptions{
			CheckCmd:  req.CheckCmd,
			CheckCmds: req.CheckCmds,
			Reporter:  req.Reporter,
			Label:     req.ProgressLabel,
			Current:   req.ProgressCurrent,
			Total:     req.ProgressTotal,
		}); err == nil {
			return &TranslationResult{
				Text:  translated,
				Usage: usage,
			}, nil
		} else {
			lastErr = err
		}
	}

	if lastErr != nil {
		return nil, lastErr
	}
	return nil, fmt.Errorf("translation failed")
}

func revisit(req RevisitRequest) (*TranslationResult, error) {
	attempts := defaultValidationAttempts

	usage := emptyUsage()
	var lastErr error

	for attempt := 0; attempt <= attempts; attempt++ {
		result, err := revisitOnce(req, lastErr)
		if err != nil {
			lastErr = err
			continue
		}
		usage = addUsage(usage, result.Usage)

		output := stripStructuredCodeFence(req.Format, trimEnd(result.Text))

		if err := validate(req.Root, req.Format, output, req.Source, CheckOptions{
			CheckCmd:  req.CheckCmd,
			CheckCmds: req.CheckCmds,
			Reporter:  req.Reporter,
			Label:     req.ProgressLabel,
			Current:   req.ProgressCurrent,
			Total:     req.ProgressTotal,
		}); err == nil {
			return &TranslationResult{
				Text:  output,
				Usage: usage,
			}, nil
		} else {
			lastErr = err
		}
	}

	if lastErr != nil {
		return nil, lastErr
	}
	return nil, fmt.Errorf("revision failed")
}

type briefResult struct {
	Text  string
	Usage TokenUsage
}

func buildBrief(req TranslationRequest) briefResult {
	if strings.TrimSpace(req.Coordinator.Model) == "" {
		return briefResult{
			Text:  defaultBrief(req),
			Usage: emptyUsage(),
		}
	}

	text, usage, err := chat(req.Coordinator, req.Coordinator.Model, []ChatMessage{
		{Role: "system", Content: "You coordinate translations and produce concise briefs."},
		{
			Role: "user",
			Content: strings.Join([]string{
				"You are a localization coordinator.",
				"Create a short translation brief for the translator.",
				"The brief must be plain text and under 12 lines.",
				"",
				fmt.Sprintf("Target language: %s", req.TargetLang),
				fmt.Sprintf("Format: %s", req.Format),
				fmt.Sprintf("Frontmatter mode: %s", req.Frontmatter),
				"",
				"Context:\n" + req.Context,
			}, "\n"),
		},
	})
	if err != nil {
		return briefResult{
			Text:  defaultBrief(req),
			Usage: emptyUsage(),
		}
	}

	return briefResult{
		Text:  strings.TrimSpace(text),
		Usage: usage,
	}
}

func translateOnce(req TranslationRequest, brief string, sourceContent string, lastErr error) (*TranslationResult, error) {
	model := strings.TrimSpace(req.Translator.Model)
	if model == "" {
		return nil, fmt.Errorf("translator model is required")
	}

	userMessage := strings.Join([]string{
		fmt.Sprintf("Translate to %s.", req.TargetLang),
		"",
		"Context:\n" + req.Context,
		"",
		"Source:\n" + sourceContent,
		func() string {
			if lastErr == nil {
				return ""
			}
			return "\nPrevious output failed validation: " + lastErr.Error() + "\nReturn a corrected full translation."
		}(),
	}, "\n")

	text, usage, err := chat(req.Translator, model, []ChatMessage{
		{Role: "system", Content: "You are a translation engine. Follow this brief:\n" + brief},
		{Role: "user", Content: userMessage},
	})
	if err != nil {
		return nil, err
	}

	return &TranslationResult{Text: text, Usage: usage}, nil
}

func revisitOnce(req RevisitRequest, lastErr error) (*TranslationResult, error) {
	model := strings.TrimSpace(req.Translator.Model)
	if model == "" {
		return nil, fmt.Errorf("translator model is required")
	}

	promptInstruction := req.Prompt
	if strings.TrimSpace(promptInstruction) == "" {
		promptInstruction = "Review and improve this content for clarity and quality."
	}

	var parts []string
	if strings.TrimSpace(req.Context) != "" {
		parts = append(parts, "Context:\n"+req.Context)
	}
	parts = append(parts, "Source:\n"+req.Source)
	if lastErr != nil {
		parts = append(parts, "\nPrevious output failed validation: "+lastErr.Error()+"\nReturn a corrected version.")
	}

	userMessage := strings.Join(filterNonEmpty(parts), "\n\n")

	text, usage, err := chat(req.Translator, model, []ChatMessage{
		{
			Role: "system",
			Content: strings.Join([]string{
				"You are a content revision engine.",
				promptInstruction,
				"Return only the revised content. Do not add commentary or explanations.",
			}, "\n"),
		},
		{Role: "user", Content: userMessage},
	})
	if err != nil {
		return nil, err
	}

	return &TranslationResult{Text: text, Usage: usage}, nil
}

func defaultBrief(req TranslationRequest) string {
	lines := []string{
		"Translate the content faithfully and naturally.",
		"Keep code blocks, inline code, URLs, and placeholders unchanged.",
		"Keep formatting, lists, and headings intact.",
		"Return only the translated content.",
	}

	if isStructuredFormat(req.Format) {
		lines = append(lines, fmt.Sprintf("Return valid %s only. Do not wrap in markdown fences.", req.Format))
	}

	if req.Frontmatter == FrontmatterPreserve {
		lines = append(lines, "Frontmatter is preserved separately; do not add new frontmatter.")
	}

	return strings.Join(lines, "\n")
}

func isStructuredFormat(format Format) bool {
	return format == FormatJSON || format == FormatYAML || format == FormatPO
}

func stripStructuredCodeFence(format Format, text string) string {
	if !isStructuredFormat(format) {
		return text
	}

	trimmed := strings.TrimSpace(text)
	if !strings.HasPrefix(trimmed, "```") {
		return text
	}

	lines := strings.Split(trimmed, "\n")
	if len(lines) < 2 || strings.TrimSpace(lines[len(lines)-1]) != "```" {
		return text
	}

	return strings.Join(lines[1:len(lines)-1], "\n")
}

type markdownSplit struct {
	Frontmatter string
	Body        string
	OK          bool
}

func splitMarkdownFrontmatter(content string) markdownSplit {
	lines := strings.Split(content, "\n")
	if len(lines) == 0 {
		return markdownSplit{Frontmatter: "", Body: content, OK: false}
	}

	marker := strings.TrimSpace(lines[0])
	if marker != "---" && marker != "+++" {
		return markdownSplit{Frontmatter: "", Body: content, OK: false}
	}

	end := -1
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) == marker {
			end = i
			break
		}
	}
	if end < 0 {
		return markdownSplit{Frontmatter: "", Body: content, OK: false}
	}

	return markdownSplit{
		Frontmatter: strings.Join(lines[:end+1], "\n"),
		Body:        strings.Join(lines[end+1:], "\n"),
		OK:          true,
	}
}

func trimEnd(input string) string {
	return strings.TrimRightFunc(input, unicode.IsSpace)
}
