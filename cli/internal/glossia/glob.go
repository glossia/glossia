package glossia

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func walkFiles(root string) ([]string, error) {
	var files []string

	var visit func(string) error
	visit = func(current string) error {
		entries, err := os.ReadDir(current)
		if err != nil {
			return err
		}

		for _, entry := range entries {
			absolute := filepath.Join(current, entry.Name())

			if entry.IsDir() {
				if entry.Name() == ".git" {
					continue
				}
				if err := visit(absolute); err != nil {
					return err
				}
				continue
			}

			info, err := entry.Info()
			if err != nil {
				continue
			}
			if !info.Mode().IsRegular() {
				continue
			}

			rel, err := filepath.Rel(root, absolute)
			if err != nil {
				continue
			}
			files = append(files, normalizeSlashes(rel))
		}
		return nil
	}

	if err := visit(root); err != nil {
		return nil, err
	}
	return files, nil
}

func matchesGlob(candidatePath string, pattern string) (bool, error) {
	re, err := globToRegexp(pattern)
	if err != nil {
		return false, err
	}
	return re.MatchString(normalizeSlashes(candidatePath)), nil
}

func globToRegexp(pattern string) (*regexp.Regexp, error) {
	normalized := normalizeSlashes(pattern)
	var b strings.Builder
	b.Grow(len(normalized) + 8)

	b.WriteByte('^')

	for i := 0; i < len(normalized); i++ {
		char := normalized[i]

		if char == '*' {
			next := byte(0)
			if i+1 < len(normalized) {
				next = normalized[i+1]
			}

			if next == '*' {
				nextNext := byte(0)
				if i+2 < len(normalized) {
					nextNext = normalized[i+2]
				}

				if nextNext == '/' {
					b.WriteString("(?:.*/)?")
					i += 2
					continue
				}

				b.WriteString(".*")
				i++
				continue
			}

			b.WriteString(`[^/]*`)
			continue
		}

		if char == '?' {
			b.WriteString(`[^/]`)
			continue
		}

		if char == '[' {
			close := strings.IndexByte(normalized[i+1:], ']')
			if close >= 0 {
				close = i + 1 + close
				cls := normalized[i : close+1]
				b.WriteString(cls)
				i = close
				continue
			}
		}

		if strings.ContainsRune(`\.^$+(){}|`, rune(char)) {
			b.WriteByte('\\')
			b.WriteByte(char)
			continue
		}

		b.WriteByte(char)
	}

	b.WriteByte('$')
	return regexp.Compile(b.String())
}

func globFiles(pattern string, files []string) ([]string, error) {
	re, err := globToRegexp(pattern)
	if err != nil {
		return nil, err
	}

	out := make([]string, 0, len(files))
	for _, file := range files {
		if re.MatchString(normalizeSlashes(file)) {
			out = append(out, file)
		}
	}
	return out, nil
}
