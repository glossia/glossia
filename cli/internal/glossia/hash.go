package glossia

import (
	"crypto/sha256"
	"encoding/hex"
)

func hashString(input string) string {
	return hashBytes([]byte(input))
}

func hashBytes(input []byte) string {
	sum := sha256.Sum256(input)
	return hex.EncodeToString(sum[:])
}

func hashStrings(parts []string) string {
	// Match the Bun implementation: join with a blank line.
	if len(parts) == 0 {
		return hashString("")
	}

	joined := parts[0]
	for i := 1; i < len(parts); i++ {
		joined += "\n\n" + parts[i]
	}
	return hashString(joined)
}
