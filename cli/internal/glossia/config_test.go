package glossia

import "testing"

func TestSplitTomlFrontmatter_NoFrontmatter(t *testing.T) {
	res, err := splitTomlFrontmatter("hello world")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.HasFrontmatter {
		t.Fatalf("expected HasFrontmatter=false")
	}
	if res.Body != "hello world" {
		t.Fatalf("unexpected body: %q", res.Body)
	}
}

func TestSplitTomlFrontmatter_WithFrontmatter(t *testing.T) {
	res, err := splitTomlFrontmatter("+++\nkey = \"value\"\n+++\nbody")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !res.HasFrontmatter {
		t.Fatalf("expected HasFrontmatter=true")
	}
	if res.Frontmatter != "key = \"value\"" {
		t.Fatalf("unexpected frontmatter: %q", res.Frontmatter)
	}
	if res.Body != "body" {
		t.Fatalf("unexpected body: %q", res.Body)
	}
}

func TestSourcePath_PrefersSource(t *testing.T) {
	got := sourcePath(ContentEntry{
		Source:  "docs/*.md",
		Path:    "",
		Targets: []string{},
	})
	if got != "docs/*.md" {
		t.Fatalf("unexpected sourcePath: %q", got)
	}
}

func TestValidateContentEntry_RequiresOutputWhenTargetsExist(t *testing.T) {
	err := validateContentEntry(ContentEntry{
		Source:  "docs/*.md",
		Path:    "",
		Targets: []string{"es"},
		Output:  "",
	})
	if err == nil {
		t.Fatalf("expected error")
	}
}
