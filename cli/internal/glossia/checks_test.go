package glossia

import "testing"

func TestValidateSyntax_JSON(t *testing.T) {
	if err := validateSyntax(FormatJSON, `{"ok":true}`, ""); err != "" {
		t.Fatalf("expected valid json, got error: %s", err)
	}
	if err := validateSyntax(FormatJSON, `not-json`, ""); err == "" {
		t.Fatalf("expected json parse error")
	}
}

func TestValidate_PreserveInlineCode_OK(t *testing.T) {
	root := t.TempDir()
	err := validate(root, FormatText, "Hola `code` mundo", "Hello `code` world", CheckOptions{
		Preserve: []string{"inline_code"},
	})
	if err != nil {
		t.Fatalf("expected validate to succeed, got: %v", err)
	}
}

func TestValidate_PreserveInlineCode_Missing(t *testing.T) {
	root := t.TempDir()
	err := validate(root, FormatText, "Hola mundo", "Hello `code` world", CheckOptions{
		Preserve: []string{"inline_code"},
	})
	if err == nil {
		t.Fatalf("expected validate to fail")
	}
}
