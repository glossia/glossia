package glossia

import (
	"path/filepath"
	"strings"
)

type Format string

const (
	FormatMarkdown Format = "markdown"
	FormatJSON     Format = "json"
	FormatYAML     Format = "yaml"
	FormatPO       Format = "po"
	FormatText     Format = "text"
)

func detectFormat(filePath string) Format {
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filePath), "."))

	switch ext {
	case "md", "markdown":
		return FormatMarkdown
	case "json":
		return FormatJSON
	case "yaml", "yml":
		return FormatYAML
	case "po", "pot":
		return FormatPO
	default:
		return FormatText
	}
}

func formatLabel(format Format) string {
	switch format {
	case FormatJSON:
		return "JSON"
	case FormatYAML:
		return "YAML"
	case FormatPO:
		return "PO"
	case FormatMarkdown:
		return "Markdown frontmatter"
	case FormatText:
		return "text"
	default:
		return "text"
	}
}
