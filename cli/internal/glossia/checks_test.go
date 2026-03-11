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

func TestValidate_Text_OK(t *testing.T) {
	root := t.TempDir()
	err := validate(root, FormatText, "Hola mundo", "Hello world", CheckOptions{})
	if err != nil {
		t.Fatalf("expected validate to succeed, got: %v", err)
	}
}

func TestValidate_SyntaxError(t *testing.T) {
	root := t.TempDir()
	err := validate(root, FormatJSON, "not-json", "{}", CheckOptions{})
	if err == nil {
		t.Fatalf("expected validate to fail")
	}
}
