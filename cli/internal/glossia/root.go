package glossia

import (
	"os"
	"path/filepath"
	"strings"
)

func findRoot(start string) (string, error) {
	current, err := filepath.Abs(start)
	if err != nil {
		return "", err
	}

	for {
		if _, err := os.Stat(filepath.Join(current, ".git")); err == nil {
			return current, nil
		}

		parent := filepath.Dir(current)
		if parent == current {
			// Fall back to the original start directory (matching the Bun CLI).
			return filepath.Abs(start)
		}
		current = parent
	}
}

func resolveBaseDir(cwd string, overridePath string) (string, error) {
	if strings.TrimSpace(overridePath) == "" {
		return cwd, nil
	}

	rawPath := strings.TrimSpace(overridePath)
	candidate := rawPath
	if !filepath.IsAbs(rawPath) {
		candidate = filepath.Join(cwd, rawPath)
	}

	meta, err := os.Stat(candidate)
	if err != nil {
		// If it doesn't exist, still return the resolved candidate.
		return candidate, nil
	}

	if meta.IsDir() {
		return candidate, nil
	}

	return filepath.Dir(candidate), nil
}
