package glossia

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

type AgentConfig struct {
	Role                string
	Provider            string
	BaseURL             string
	ChatCompletionsPath string
	APIKey              string
	APIKeyEnv           string
	Model               string
	Temperature         *float64
	MaxTokens           *int
	Headers             map[string]string
	TimeoutSeconds      int
}

type ContentEntry struct {
	Source      string
	Path        string
	Targets     []string
	Output      string
	Exclude     []string
	Preserve    []string
	Frontmatter string
	Prompt      string
	CheckCmd    string
	CheckCmds   map[string]string
	Retries     *int
}

type PartialAgentConfig struct {
	Role                string
	Provider            string
	BaseURL             string
	ChatCompletionsPath string
	APIKey              string
	APIKeyEnv           string
	Model               string
	Temperature         *float64
	MaxTokens           *int
	Headers             map[string]string
	TimeoutSeconds      int
}

type LLMConfig struct {
	Provider            string
	BaseURL             string
	ChatCompletionsPath string
	APIKey              string
	APIKeyEnv           string
	CoordinatorModel    string
	TranslatorModel     string
	Temperature         *float64
	MaxTokens           *int
	Headers             map[string]string
	TimeoutSeconds      int
	Agent               []PartialAgentConfig
}

type ContentConfig struct {
	LLM     LLMConfig
	Content []ContentEntry
}

type ContentFile struct {
	Path   string
	Dir    string
	Depth  int
	Body   string
	Config ContentConfig
}

type Entry struct {
	Source      string
	Path        string
	Targets     []string
	Output      string
	Exclude     []string
	Preserve    []string
	Frontmatter string
	Prompt      string
	CheckCmd    string
	CheckCmds   map[string]string
	Retries     *int

	OriginPath  string
	OriginDir   string
	OriginDepth int
	Index       int
}

const (
	FrontmatterPreserve  = "preserve"
	FrontmatterTranslate = "translate"
)

type splitResult struct {
	Frontmatter    string
	Body           string
	HasFrontmatter bool
}

func splitTomlFrontmatter(contents string) (splitResult, error) {
	lines := strings.Split(contents, "\n")
	if len(lines) == 0 || strings.TrimSpace(lines[0]) != "+++" {
		return splitResult{
			Frontmatter:    "",
			Body:           contents,
			HasFrontmatter: false,
		}, nil
	}

	end := -1
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) == "+++" {
			end = i
			break
		}
	}

	if end < 0 {
		return splitResult{}, fmt.Errorf("frontmatter start found but no closing +++")
	}

	return splitResult{
		Frontmatter:    strings.Join(lines[1:end], "\n"),
		Body:           strings.Join(lines[end+1:], "\n"),
		HasFrontmatter: true,
	}, nil
}

func parseContentFile(filePath string) (*ContentFile, error) {
	raw, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	split, err := splitTomlFrontmatter(string(raw))
	if err != nil {
		return nil, err
	}

	cfg := ContentConfig{
		LLM:     LLMConfig{Agent: []PartialAgentConfig{}},
		Content: []ContentEntry{},
	}

	if split.HasFrontmatter {
		var parsed map[string]any
		if err := toml.Unmarshal([]byte(split.Frontmatter), &parsed); err != nil {
			return nil, err
		}

		cfg.LLM = parseLlm(parsed["llm"])

		contentEntries := append(asArray(parsed["content"]), asArray(parsed["translate"])...)
		cfg.Content = make([]ContentEntry, 0, len(contentEntries))
		for _, item := range contentEntries {
			obj, ok := item.(map[string]any)
			if !ok {
				continue
			}
			cfg.Content = append(cfg.Content, parseContentEntry(obj))
		}
	}

	// Apply entry defaults.
	for i := range cfg.Content {
		if strings.TrimSpace(cfg.Content[i].Source) == "" {
			cfg.Content[i].Source = cfg.Content[i].Path
		}
		if len(cfg.Content[i].Targets) > 0 && strings.TrimSpace(cfg.Content[i].Frontmatter) == "" {
			cfg.Content[i].Frontmatter = FrontmatterPreserve
		}
	}

	absPath, err := filepath.Abs(filePath)
	if err != nil {
		return nil, err
	}

	return &ContentFile{
		Path:   absPath,
		Dir:    filepath.Dir(absPath),
		Depth:  0,
		Body:   split.Body,
		Config: cfg,
	}, nil
}

func sourcePath(entry ContentEntry) string {
	source := strings.TrimSpace(entry.Source)
	if source != "" {
		return source
	}

	return strings.TrimSpace(entry.Path)
}

func validateContentEntry(entry ContentEntry) error {
	source := sourcePath(entry)
	if source == "" {
		return fmt.Errorf("content entry requires source/path")
	}

	if len(entry.Targets) > 0 && strings.TrimSpace(entry.Output) == "" {
		return fmt.Errorf("content entry %q has targets but no output", source)
	}

	if entry.Frontmatter != "" && entry.Frontmatter != FrontmatterPreserve && entry.Frontmatter != FrontmatterTranslate {
		return fmt.Errorf("content entry %q has invalid frontmatter mode %q", source, entry.Frontmatter)
	}

	return nil
}

func mergeLlm(base LLMConfig, over LLMConfig) LLMConfig {
	out := LLMConfig{
		Provider:            base.Provider,
		BaseURL:             base.BaseURL,
		ChatCompletionsPath: base.ChatCompletionsPath,
		APIKey:              base.APIKey,
		APIKeyEnv:           base.APIKeyEnv,
		CoordinatorModel:    base.CoordinatorModel,
		TranslatorModel:     base.TranslatorModel,
		Temperature:         base.Temperature,
		MaxTokens:           base.MaxTokens,
		Headers:             copyStringMap(base.Headers),
		TimeoutSeconds:      base.TimeoutSeconds,
		Agent:               mergeAgents(base.Agent, over.Agent),
	}

	if strings.TrimSpace(over.Provider) != "" {
		out.Provider = over.Provider
	}
	if strings.TrimSpace(over.BaseURL) != "" {
		out.BaseURL = over.BaseURL
	}
	if strings.TrimSpace(over.ChatCompletionsPath) != "" {
		out.ChatCompletionsPath = over.ChatCompletionsPath
	}
	if strings.TrimSpace(over.APIKey) != "" {
		out.APIKey = over.APIKey
	}
	if strings.TrimSpace(over.APIKeyEnv) != "" {
		out.APIKeyEnv = over.APIKeyEnv
	}
	if strings.TrimSpace(over.CoordinatorModel) != "" {
		out.CoordinatorModel = over.CoordinatorModel
	}
	if strings.TrimSpace(over.TranslatorModel) != "" {
		out.TranslatorModel = over.TranslatorModel
	}
	if over.Temperature != nil {
		out.Temperature = over.Temperature
	}
	if over.MaxTokens != nil {
		out.MaxTokens = over.MaxTokens
	}
	if over.TimeoutSeconds > 0 {
		out.TimeoutSeconds = over.TimeoutSeconds
	}

	if len(over.Headers) > 0 {
		if out.Headers == nil {
			out.Headers = map[string]string{}
		}
		for k, v := range over.Headers {
			out.Headers[k] = v
		}
	}

	return out
}

func resolveAgents(llm LLMConfig) (coordinator AgentConfig, translator AgentConfig, _ error) {
	roleMap := map[string]PartialAgentConfig{}

	for _, agent := range llm.Agent {
		role := strings.ToLower(strings.TrimSpace(agent.Role))
		if role == "" {
			return AgentConfig{}, AgentConfig{}, fmt.Errorf("llm.agent requires role")
		}
		if role != "coordinator" && role != "translator" {
			return AgentConfig{}, AgentConfig{}, fmt.Errorf("unknown llm.agent role %q", role)
		}
		roleMap[role] = agent
	}

	base := createEmptyAgent()
	base.Provider = llm.Provider
	base.BaseURL = llm.BaseURL
	base.ChatCompletionsPath = llm.ChatCompletionsPath
	base.APIKey = llm.APIKey
	base.APIKeyEnv = llm.APIKeyEnv
	base.Temperature = llm.Temperature
	base.MaxTokens = llm.MaxTokens
	base.Headers = copyStringMap(llm.Headers)
	base.TimeoutSeconds = llm.TimeoutSeconds

	coord := mergeAgent(base, roleMap["coordinator"])
	if strings.TrimSpace(coord.Model) == "" {
		coord.Model = llm.CoordinatorModel
	}
	applyAgentDefaults(&coord)

	trans := mergeAgent(base, roleMap["translator"])
	if strings.TrimSpace(trans.Model) == "" {
		trans.Model = llm.TranslatorModel
	}

	if strings.TrimSpace(trans.Provider) == "" {
		trans.Provider = coord.Provider
	}
	if strings.TrimSpace(trans.BaseURL) == "" {
		trans.BaseURL = coord.BaseURL
	}
	if strings.TrimSpace(trans.ChatCompletionsPath) == "" {
		trans.ChatCompletionsPath = coord.ChatCompletionsPath
	}
	if strings.TrimSpace(trans.APIKey) == "" {
		trans.APIKey = coord.APIKey
	}
	if strings.TrimSpace(trans.APIKeyEnv) == "" {
		trans.APIKeyEnv = coord.APIKeyEnv
	}
	if trans.Temperature == nil {
		trans.Temperature = coord.Temperature
	}
	if trans.MaxTokens == nil {
		trans.MaxTokens = coord.MaxTokens
	}
	if trans.TimeoutSeconds == 0 {
		trans.TimeoutSeconds = coord.TimeoutSeconds
	}

	// Translator headers inherit coordinator headers, but translator overrides win.
	trans.Headers = mergeStringMaps(coord.Headers, trans.Headers)
	applyAgentDefaults(&trans)

	return coord, trans, nil
}

func mergeAgents(base []PartialAgentConfig, over []PartialAgentConfig) []PartialAgentConfig {
	if len(over) == 0 {
		out := make([]PartialAgentConfig, 0, len(base))
		out = append(out, base...)
		return out
	}

	out := make([]PartialAgentConfig, 0, len(base)+len(over))
	out = append(out, base...)

	for _, agent := range over {
		role := strings.ToLower(strings.TrimSpace(agent.Role))
		if role == "" {
			out = append(out, agent)
			continue
		}

		idx := -1
		for i := range out {
			if strings.ToLower(strings.TrimSpace(out[i].Role)) == role {
				idx = i
				break
			}
		}
		if idx >= 0 {
			out[idx] = agent
		} else {
			out = append(out, agent)
		}
	}

	return out
}

func createEmptyAgent() AgentConfig {
	return AgentConfig{
		Role:                "",
		Provider:            "",
		BaseURL:             "",
		ChatCompletionsPath: "",
		APIKey:              "",
		APIKeyEnv:           "",
		Model:               "",
		Headers:             map[string]string{},
		TimeoutSeconds:      0,
	}
}

func mergeAgent(base AgentConfig, over PartialAgentConfig) AgentConfig {
	out := base
	out.Headers = copyStringMap(base.Headers)

	if strings.TrimSpace(over.Provider) != "" {
		out.Provider = over.Provider
	}
	if strings.TrimSpace(over.BaseURL) != "" {
		out.BaseURL = over.BaseURL
	}
	if strings.TrimSpace(over.ChatCompletionsPath) != "" {
		out.ChatCompletionsPath = over.ChatCompletionsPath
	}
	if strings.TrimSpace(over.APIKey) != "" {
		out.APIKey = over.APIKey
	}
	if strings.TrimSpace(over.APIKeyEnv) != "" {
		out.APIKeyEnv = over.APIKeyEnv
	}
	if strings.TrimSpace(over.Model) != "" {
		out.Model = over.Model
	}
	if over.Temperature != nil {
		out.Temperature = over.Temperature
	}
	if over.MaxTokens != nil {
		out.MaxTokens = over.MaxTokens
	}
	if over.TimeoutSeconds > 0 {
		out.TimeoutSeconds = over.TimeoutSeconds
	}
	if len(over.Headers) > 0 {
		if out.Headers == nil {
			out.Headers = map[string]string{}
		}
		for k, v := range over.Headers {
			out.Headers[k] = v
		}
	}

	return out
}

func inferProviderFromModel(model string) string {
	normalized := strings.ToLower(strings.TrimSpace(model))
	switch {
	case strings.HasPrefix(normalized, "gemini"):
		return "gemini"
	case strings.HasPrefix(normalized, "claude"):
		return "anthropic"
	case strings.HasPrefix(normalized, "gpt"),
		strings.HasPrefix(normalized, "o1"),
		strings.HasPrefix(normalized, "o3"),
		strings.HasPrefix(normalized, "o4"):
		return "openai"
	default:
		return "openai"
	}
}

func applyAgentDefaults(cfg *AgentConfig) {
	provider := strings.TrimSpace(cfg.Provider)
	if provider == "" {
		provider = inferProviderFromModel(cfg.Model)
	}
	cfg.Provider = provider

	switch provider {
	case "openai":
		if strings.TrimSpace(cfg.ChatCompletionsPath) == "" {
			cfg.ChatCompletionsPath = "/chat/completions"
		}
		if strings.TrimSpace(cfg.BaseURL) == "" {
			cfg.BaseURL = "https://api.openai.com/v1"
		}
		if strings.TrimSpace(cfg.APIKeyEnv) == "" {
			cfg.APIKeyEnv = "OPENAI_API_KEY"
		}
	case "gemini":
		if strings.TrimSpace(cfg.ChatCompletionsPath) == "" {
			cfg.ChatCompletionsPath = "/chat/completions"
		}
		if strings.TrimSpace(cfg.BaseURL) == "" {
			cfg.BaseURL = "https://generativelanguage.googleapis.com/v1beta/openai"
		}
		if strings.TrimSpace(cfg.APIKeyEnv) == "" {
			cfg.APIKeyEnv = "GEMINI_API_KEY"
		}
		// Gemini uses an OpenAI-compatible API surface.
		cfg.Provider = "openai"
	case "vertex":
		if strings.TrimSpace(cfg.ChatCompletionsPath) == "" {
			cfg.ChatCompletionsPath = "/chat/completions"
		}
	case "anthropic":
		if strings.TrimSpace(cfg.ChatCompletionsPath) == "" {
			cfg.ChatCompletionsPath = "/v1/messages"
		}
		if strings.TrimSpace(cfg.BaseURL) == "" {
			cfg.BaseURL = "https://api.anthropic.com"
		}
		if strings.TrimSpace(cfg.APIKeyEnv) == "" {
			cfg.APIKeyEnv = "ANTHROPIC_API_KEY"
		}
	}
}

func parseLlm(input any) LLMConfig {
	obj, ok := input.(map[string]any)
	if !ok || obj == nil {
		return LLMConfig{Agent: []PartialAgentConfig{}}
	}

	rawAgents := asArray(obj["agent"])
	agents := make([]PartialAgentConfig, 0, len(rawAgents))
	for _, item := range rawAgents {
		agents = append(agents, parsePartialAgent(item))
	}

	return LLMConfig{
		Provider:            asString(obj["provider"]),
		BaseURL:             asString(obj["base_url"]),
		ChatCompletionsPath: asString(obj["chat_completions_path"]),
		APIKey:              asString(obj["api_key"]),
		APIKeyEnv:           asString(obj["api_key_env"]),
		CoordinatorModel:    asString(obj["coordinator_model"]),
		TranslatorModel:     asString(obj["translator_model"]),
		Temperature:         asFloat(obj["temperature"]),
		MaxTokens:           asInt(obj["max_tokens"]),
		Headers:             asStringMap(obj["headers"]),
		TimeoutSeconds:      asIntValue(obj["timeout_seconds"]),
		Agent:               agents,
	}
}

func parsePartialAgent(input any) PartialAgentConfig {
	obj, ok := input.(map[string]any)
	if !ok || obj == nil {
		return PartialAgentConfig{}
	}

	return PartialAgentConfig{
		Role:                asString(obj["role"]),
		Provider:            asString(obj["provider"]),
		BaseURL:             asString(obj["base_url"]),
		ChatCompletionsPath: asString(obj["chat_completions_path"]),
		APIKey:              asString(obj["api_key"]),
		APIKeyEnv:           asString(obj["api_key_env"]),
		Model:               asString(obj["model"]),
		Temperature:         asFloat(obj["temperature"]),
		MaxTokens:           asInt(obj["max_tokens"]),
		Headers:             asStringMap(obj["headers"]),
		TimeoutSeconds:      asIntValue(obj["timeout_seconds"]),
	}
}

func parseContentEntry(input map[string]any) ContentEntry {
	return ContentEntry{
		Source:      asString(input["source"]),
		Path:        asString(input["path"]),
		Targets:     asStringArray(input["targets"]),
		Output:      asString(input["output"]),
		Exclude:     asStringArray(input["exclude"]),
		Preserve:    asStringArray(input["preserve"]),
		Frontmatter: asString(input["frontmatter"]),
		Prompt:      asString(input["prompt"]),
		CheckCmd:    asString(input["check_cmd"]),
		CheckCmds:   asStringMap(input["check_cmds"]),
		Retries:     asInt(input["retries"]),
	}
}

func asString(value any) string {
	s, ok := value.(string)
	if !ok {
		return ""
	}
	return s
}

func asFloat(value any) *float64 {
	switch v := value.(type) {
	case float64:
		if v != v {
			return nil
		}
		out := v
		return &out
	case int64:
		out := float64(v)
		return &out
	case int:
		out := float64(v)
		return &out
	default:
		return nil
	}
}

func asInt(value any) *int {
	switch v := value.(type) {
	case int64:
		out := int(v)
		return &out
	case int:
		out := v
		return &out
	case float64:
		if v != v {
			return nil
		}
		out := int(v)
		return &out
	default:
		return nil
	}
}

func asIntValue(value any) int {
	v := asInt(value)
	if v == nil {
		return 0
	}
	return *v
}

func asStringArray(value any) []string {
	items := asArray(value)
	if len(items) == 0 {
		return []string{}
	}

	out := make([]string, 0, len(items))
	for _, item := range items {
		if s, ok := item.(string); ok {
			out = append(out, s)
		}
	}
	return out
}

func asArray(value any) []any {
	switch v := value.(type) {
	case []any:
		return v
	case []map[string]any:
		out := make([]any, 0, len(v))
		for _, item := range v {
			out = append(out, item)
		}
		return out
	default:
		return []any{}
	}
}

func asStringMap(value any) map[string]string {
	if value == nil {
		return map[string]string{}
	}

	switch obj := value.(type) {
	case map[string]any:
		out := map[string]string{}
		for k, raw := range obj {
			if s, ok := raw.(string); ok {
				out[k] = s
			}
		}
		return out
	case map[string]string:
		out := map[string]string{}
		for k, v := range obj {
			out[k] = v
		}
		return out
	default:
		return map[string]string{}
	}
}

func collectEntries(contentFiles []*ContentFile) []Entry {
	entries := make([]Entry, 0, len(contentFiles))

	for _, file := range contentFiles {
		for idx, raw := range file.Config.Content {
			if err := validateContentEntry(raw); err != nil {
				fmt.Fprintf(os.Stderr, "warning: skipping invalid content entry: %s\n", err.Error())
				continue
			}

			frontmatter := raw.Frontmatter
			if strings.TrimSpace(frontmatter) == "" && len(raw.Targets) > 0 {
				frontmatter = FrontmatterPreserve
			}

			entries = append(entries, Entry{
				Source:      firstNonEmpty(raw.Source, raw.Path),
				Path:        firstNonEmpty(raw.Path, raw.Source),
				Targets:     append([]string{}, raw.Targets...),
				Output:      raw.Output,
				Exclude:     append([]string{}, raw.Exclude...),
				Preserve:    append([]string{}, raw.Preserve...),
				Frontmatter: frontmatter,
				Prompt:      raw.Prompt,
				CheckCmd:    raw.CheckCmd,
				CheckCmds:   copyStringMap(raw.CheckCmds),
				Retries:     raw.Retries,
				OriginPath:  file.Path,
				OriginDir:   file.Dir,
				OriginDepth: file.Depth,
				Index:       idx,
			})
		}
	}

	return entries
}

func firstNonEmpty(a string, b string) string {
	if strings.TrimSpace(a) != "" {
		return a
	}
	return b
}

func copyStringMap(input map[string]string) map[string]string {
	if len(input) == 0 {
		return map[string]string{}
	}

	out := make(map[string]string, len(input))
	for k, v := range input {
		out[k] = v
	}
	return out
}

func mergeStringMaps(base map[string]string, over map[string]string) map[string]string {
	out := copyStringMap(base)
	if out == nil {
		out = map[string]string{}
	}
	for k, v := range over {
		out[k] = v
	}
	return out
}
