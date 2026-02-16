package glossia

import "testing"

func TestDetectFormat(t *testing.T) {
	if got := detectFormat("docs/guide.md"); got != FormatMarkdown {
		t.Fatalf("expected markdown, got %q", got)
	}
	if got := detectFormat("readme.markdown"); got != FormatMarkdown {
		t.Fatalf("expected markdown, got %q", got)
	}

	cases := map[string]Format{
		"data.json":     FormatJSON,
		"config.yaml":   FormatYAML,
		"messages.po":   FormatPO,
		"notes.txt":     FormatText,
		"unknown.file":  FormatText,
		"file.POT":      FormatPO,
		"file.YML":      FormatYAML,
		"file.MARKDOWN": FormatMarkdown,
	}

	for input, want := range cases {
		if got := detectFormat(input); got != want {
			t.Fatalf("detectFormat(%q) expected %q, got %q", input, want, got)
		}
	}
}
