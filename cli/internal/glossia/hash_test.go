package glossia

import "testing"

func TestHashString_StableSHA256(t *testing.T) {
	const want = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
	if got := hashString("hello"); got != want {
		t.Fatalf("unexpected hash: %s", got)
	}
}

func TestHashStrings_JoinsWithBlankLine(t *testing.T) {
	if got := hashStrings([]string{"a", "b"}); got != hashString("a\n\nb") {
		t.Fatalf("unexpected hashStrings output: %s", got)
	}
}
