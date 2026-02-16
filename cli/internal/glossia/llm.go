package glossia

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"
)

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type TokenUsage struct {
	PromptTokens     int
	CompletionTokens int
	TotalTokens      int
}

var emptyUsageValue = TokenUsage{PromptTokens: 0, CompletionTokens: 0, TotalTokens: 0}

func emptyUsage() TokenUsage { return emptyUsageValue }

func addUsage(sum TokenUsage, next TokenUsage) TokenUsage {
	return TokenUsage{
		PromptTokens:     sum.PromptTokens + next.PromptTokens,
		CompletionTokens: sum.CompletionTokens + next.CompletionTokens,
		TotalTokens:      sum.TotalTokens + next.TotalTokens,
	}
}

func chat(cfg AgentConfig, model string, messages []ChatMessage) (string, TokenUsage, error) {
	provider := strings.ToLower(strings.TrimSpace(cfg.Provider))
	if provider == "anthropic" {
		return chatAnthropic(cfg, model, messages)
	}
	return chatOpenAI(cfg, model, messages)
}

type openAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Usage struct {
		PromptTokens     int `json:"prompt_tokens"`
		CompletionTokens int `json:"completion_tokens"`
		TotalTokens      int `json:"total_tokens"`
	} `json:"usage"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func chatOpenAI(cfg AgentConfig, model string, messages []ChatMessage) (string, TokenUsage, error) {
	if strings.TrimSpace(cfg.BaseURL) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm base_url is required")
	}
	if strings.TrimSpace(model) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm model is required")
	}

	url := strings.TrimRight(cfg.BaseURL, "/") + cfg.ChatCompletionsPath

	body := map[string]any{
		"model":    model,
		"messages": messages,
	}
	if cfg.Temperature != nil {
		body["temperature"] = *cfg.Temperature
	}
	if cfg.MaxTokens != nil {
		body["max_tokens"] = *cfg.MaxTokens
	}

	headers := resolveHeaders(cfg)
	if !hasHeader(headers, "content-type") {
		headers["Content-Type"] = "application/json"
	}
	if !hasHeader(headers, "user-agent") {
		headers["User-Agent"] = "glossia"
	}

	timeout := 300 * time.Second
	if cfg.TimeoutSeconds > 0 {
		timeout = time.Duration(cfg.TimeoutSeconds) * time.Second
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	encoded, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(encoded))
	if err != nil {
		return "", TokenUsage{}, err
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", TokenUsage{}, err
	}
	defer resp.Body.Close()

	rawBody, _ := io.ReadAll(resp.Body)
	normalized, err := normalizeResponseBody(rawBody)
	if err != nil {
		return "", TokenUsage{}, err
	}

	var parsed openAIResponse
	if err := json.Unmarshal(normalized, &parsed); err != nil {
		return "", TokenUsage{}, err
	}

	if resp.StatusCode >= 400 {
		msg := fmt.Sprintf("status %d", resp.StatusCode)
		if parsed.Error != nil && strings.TrimSpace(parsed.Error.Message) != "" {
			msg = parsed.Error.Message
		}
		return "", TokenUsage{}, fmt.Errorf("llm error: %s", msg)
	}

	text := ""
	if len(parsed.Choices) > 0 {
		text = parsed.Choices[0].Message.Content
	}
	if strings.TrimSpace(text) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm response missing choices")
	}

	return text, TokenUsage{
		PromptTokens:     parsed.Usage.PromptTokens,
		CompletionTokens: parsed.Usage.CompletionTokens,
		TotalTokens:      parsed.Usage.TotalTokens,
	}, nil
}

type anthropicResponse struct {
	Content []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	} `json:"content"`
	Usage struct {
		InputTokens  int `json:"input_tokens"`
		OutputTokens int `json:"output_tokens"`
	} `json:"usage"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func chatAnthropic(cfg AgentConfig, model string, messages []ChatMessage) (string, TokenUsage, error) {
	if strings.TrimSpace(cfg.BaseURL) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm base_url is required")
	}
	if strings.TrimSpace(model) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm model is required")
	}

	url := strings.TrimRight(cfg.BaseURL, "/") + cfg.ChatCompletionsPath

	var systemParts []string
	var anthropicMessages []map[string]string

	for _, m := range messages {
		if m.Role == "system" {
			if strings.TrimSpace(m.Content) != "" {
				systemParts = append(systemParts, m.Content)
			}
			continue
		}

		if m.Role == "user" || m.Role == "assistant" {
			anthropicMessages = append(anthropicMessages, map[string]string{
				"role":    m.Role,
				"content": m.Content,
			})
		}
	}

	if len(anthropicMessages) == 0 {
		return "", TokenUsage{}, fmt.Errorf("llm request requires user messages")
	}

	maxTokens := 1024
	if cfg.MaxTokens != nil && *cfg.MaxTokens > 0 {
		maxTokens = *cfg.MaxTokens
	}

	body := map[string]any{
		"model":      model,
		"max_tokens": maxTokens,
		"messages":   anthropicMessages,
	}
	if cfg.Temperature != nil {
		body["temperature"] = *cfg.Temperature
	}
	if len(systemParts) > 0 {
		body["system"] = strings.Join(systemParts, "\n\n")
	}

	headers := resolveHeaders(cfg)
	if !hasHeader(headers, "content-type") {
		headers["Content-Type"] = "application/json"
	}
	if !hasHeader(headers, "user-agent") {
		headers["User-Agent"] = "glossia"
	}

	timeout := 300 * time.Second
	if cfg.TimeoutSeconds > 0 {
		timeout = time.Duration(cfg.TimeoutSeconds) * time.Second
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	encoded, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(encoded))
	if err != nil {
		return "", TokenUsage{}, err
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", TokenUsage{}, err
	}
	defer resp.Body.Close()

	rawBody, _ := io.ReadAll(resp.Body)

	var parsed anthropicResponse
	if err := json.Unmarshal(rawBody, &parsed); err != nil {
		return "", TokenUsage{}, err
	}

	if resp.StatusCode >= 400 {
		msg := fmt.Sprintf("status %d", resp.StatusCode)
		if parsed.Error != nil && strings.TrimSpace(parsed.Error.Message) != "" {
			msg = parsed.Error.Message
		}
		return "", TokenUsage{}, fmt.Errorf("llm error: %s", msg)
	}

	var text strings.Builder
	for _, block := range parsed.Content {
		if block.Type == "text" {
			text.WriteString(block.Text)
		}
	}

	outText := text.String()
	if strings.TrimSpace(outText) == "" {
		return "", TokenUsage{}, fmt.Errorf("llm response missing text")
	}

	input := parsed.Usage.InputTokens
	output := parsed.Usage.OutputTokens

	return outText, TokenUsage{
		PromptTokens:     input,
		CompletionTokens: output,
		TotalTokens:      input + output,
	}, nil
}

func normalizeResponseBody(body []byte) ([]byte, error) {
	trimmed := bytes.TrimSpace(body)
	if len(trimmed) == 0 {
		return trimmed, nil
	}
	if trimmed[0] != '[' {
		return trimmed, nil
	}

	var arr []json.RawMessage
	if err := json.Unmarshal(trimmed, &arr); err != nil {
		return nil, err
	}
	if len(arr) != 1 {
		return nil, fmt.Errorf("llm response: unexpected array with %d elements", len(arr))
	}

	var first struct {
		Error *struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	_ = json.Unmarshal(arr[0], &first)
	if first.Error != nil && strings.TrimSpace(first.Error.Message) != "" {
		return nil, fmt.Errorf("llm error: %s", first.Error.Message)
	}

	return arr[0], nil
}

func resolveHeaders(cfg AgentConfig) map[string]string {
	headers := map[string]string{}
	for k, v := range cfg.Headers {
		headers[k] = expandEnv(v)
	}

	provider := strings.ToLower(strings.TrimSpace(cfg.Provider))
	if provider == "anthropic" {
		if !hasHeader(headers, "x-api-key") {
			key := resolveAPIKey(cfg)
			if strings.TrimSpace(key) != "" {
				headers["x-api-key"] = key
			}
		}
		if !hasHeader(headers, "anthropic-version") {
			headers["anthropic-version"] = "2023-06-01"
		}
		return headers
	}

	if !hasHeader(headers, "authorization") {
		key := resolveAPIKey(cfg)
		if strings.TrimSpace(key) != "" {
			headers["Authorization"] = "Bearer " + key
		}
	}

	return headers
}

func resolveAPIKey(cfg AgentConfig) string {
	fromInline := strings.TrimSpace(expandEnv(cfg.APIKey))
	if fromInline != "" {
		return fromInline
	}

	if strings.TrimSpace(cfg.APIKeyEnv) == "" {
		return ""
	}
	return os.Getenv(cfg.APIKeyEnv)
}

func hasHeader(headers map[string]string, name string) bool {
	normalized := strings.ToLower(name)
	for k := range headers {
		if strings.ToLower(k) == normalized {
			return true
		}
	}
	return false
}

var envTemplateRe = regexp.MustCompile(`\{\{\s*env\.([A-Za-z_][A-Za-z0-9_]*)\s*\}\}`)
var envInlineRe = regexp.MustCompile(`env:([A-Za-z_][A-Za-z0-9_]*)`)

func expandEnv(input string) string {
	withTemplate := envTemplateRe.ReplaceAllStringFunc(input, func(match string) string {
		sub := envTemplateRe.FindStringSubmatch(match)
		if len(sub) != 2 {
			return ""
		}
		return os.Getenv(sub[1])
	})

	if strings.HasPrefix(withTemplate, "env.") {
		return os.Getenv(strings.TrimPrefix(withTemplate, "env."))
	}

	return envInlineRe.ReplaceAllStringFunc(withTemplate, func(match string) string {
		sub := envInlineRe.FindStringSubmatch(match)
		if len(sub) != 2 {
			return ""
		}
		return os.Getenv(sub[1])
	})
}
