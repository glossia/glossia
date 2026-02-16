package glossia

import (
	"path"
	"path/filepath"
	"strings"
)

func normalizeSlashes(input string) string {
	return strings.ReplaceAll(input, "\\", "/")
}

func relativePath(base string, target string) (string, error) {
	rel, err := filepath.Rel(base, target)
	if err != nil {
		return "", err
	}

	rel = normalizeSlashes(rel)
	if rel == "" || rel == "." {
		return ".", nil
	}
	return rel, nil
}

func isAncestor(dir string, targetPath string) (bool, error) {
	dirAbs, err := filepath.Abs(dir)
	if err != nil {
		return false, err
	}
	targetAbs, err := filepath.Abs(targetPath)
	if err != nil {
		return false, err
	}

	dirNorm := normalizeSlashes(dirAbs)
	targetNorm := normalizeSlashes(targetAbs)

	return targetNorm == dirNorm || strings.HasPrefix(targetNorm, dirNorm+"/"), nil
}

func globBase(pattern string) string {
	normalized := normalizeSlashes(pattern)

	wildcardIndex := -1
	for i := 0; i < len(normalized); i++ {
		switch normalized[i] {
		case '*', '?', '[':
			wildcardIndex = i
			i = len(normalized)
		}
	}

	if wildcardIndex < 0 {
		parent := normalizeSlashes(path.Dir(normalized))
		if parent == "" {
			return "."
		}
		return parent
	}

	prefix := normalized[:wildcardIndex]
	parent := normalizeSlashes(path.Dir(prefix))
	if parent == "" {
		return "."
	}
	return parent
}
