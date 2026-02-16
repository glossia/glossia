package glossia

import "testing"

func TestExpandOutput_ExpandsPlaceholders(t *testing.T) {
	got := expandOutput("i18n/{lang}/{relpath}", OutputValues{
		Lang:     "es",
		RelPath:  "docs/guide.md",
		Basename: "guide",
		Ext:      "md",
	})
	if got != "i18n/es/docs/guide.md" {
		t.Fatalf("unexpected output: %q", got)
	}
}

func TestExpandOutput_NormalizesSlashes(t *testing.T) {
	got := expandOutput("out\\{lang}\\{basename}.{ext}", OutputValues{
		Lang:     "de",
		RelPath:  "docs\\guide.md",
		Basename: "guide",
		Ext:      "md",
	})
	if got != "out/de/guide.md" {
		t.Fatalf("unexpected output: %q", got)
	}
}
