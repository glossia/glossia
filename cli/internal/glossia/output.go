package glossia

import "strings"

type OutputValues struct {
	Lang     string
	RelPath  string
	Basename string
	Ext      string
}

func expandOutput(template string, values OutputValues) string {
	out := template
	out = strings.ReplaceAll(out, "{lang}", values.Lang)
	out = strings.ReplaceAll(out, "{relpath}", strings.ReplaceAll(values.RelPath, "\\", "/"))
	out = strings.ReplaceAll(out, "{basename}", values.Basename)
	out = strings.ReplaceAll(out, "{ext}", values.Ext)
	return normalizeSlashesCollapsed(out)
}

func normalizeSlashesCollapsed(input string) string {
	var b strings.Builder
	b.Grow(len(input))

	lastSlash := false
	for _, r := range input {
		if r == '/' || r == '\\' {
			if !lastSlash {
				b.WriteByte('/')
			}
			lastSlash = true
			continue
		}

		b.WriteRune(r)
		lastSlash = false
	}
	return b.String()
}
